#!/usr/bin/env bash

# ansible-tf2network: server autoupdater

set -eu

get_networks() {
    NETWORKS=()
    for network in /home/tf2server/build/servers/*; do
        network=${network##*/}
        NETWORKS+=( $network )
    done
}

get_servers_for_network() {
    SERVERS=()
    for server in /home/tf2server/build/servers/$1/*; do
        server=${server##*/}
        SERVERS+=( $server )
    done
}

main() {
    if [ -f updater-active.lock ]; then
        echo "[$(date +'%D %H:%M:%S')] ($$) A job is already active."
        exit 0
    fi
    touch updater-active.lock

    echo ""
    echo "[$(date +'%D %H:%M:%S')] ($$) Checking..."

    LATEST=$(podman run --quiet --pull always --rm --entrypoint=/bin/bash cm2network/steamcmd -c "timeout $UPDATE_TIMEOUT ./steamcmd.sh +login anonymous +app_info_update 232250 +app_info_print 232250 +quit" | perl -n -e'/"buildid"\s+"([    0-9]+)"/ && print "$1\n"' | head -n1)

    if [ ! -f current_tf2_buildid ]; then
        echo "[$(date +'%D %H:%M:%S')] No current version saved, saving latest as current and doing nothing!"
        echo $LATEST > current_tf2_buildid

        rm updater-active.lock
        exit 0
    fi
    CURRENT=$(cat current_tf2_buildid)
    UPDATE_TIMEOUT=30

    echo "[$(date +'%D %H:%M:%S')] Current: $CURRENT; Latest: $LATEST"

    if [ -z "$LATEST" ]; then
        echo "[$(date +'%D %H:%M:%S')] Failed to fetch latest, doing nothing"

        rm updater-active.lock
        exit 0

    elif [[ "$CURRENT" -ne "$LATEST" ]]; then
        # rebuild (update) the base image
        echo "[$(date +'%D %H:%M:%S')] Updating base image..."
        podman buildx build --no-cache -t jackavery/base-tf2server:latest /home/tf2server/build/base

        get_networks

        # rebuild servers
        for network in ${NETWORKS[@]} ; do
            echo "[$(date +'%D %H:%M:%S')] Processing $network..."

            get_servers_for_network $network

            for server in ${SERVERS[@]} ; do
                echo "[$(date +'%D %H:%M:%S')] Rebuilding $network/$server..."
                cd /home/tf2server/build/servers/$network/$server
                podman buildx build -t srcds-$network-$server:latest .
                cd /home/tf2server
            done

            echo "[$(date +'%D %H:%M:%S')] Podman recomposing $network..."
            podman compose -f /home/tf2server/podman-compose_$network.yml up -d
        done

        echo "[$(date +'%D %H:%M:%S')] Pruning Podman..."
        podman system prune -af

        echo $LATEST > current_tf2_buildid

        rm updater-active.lock
        exit 0

    else
        echo "[$(date +'%D %H:%M:%S')] Current is latest, nothing to do"

        rm updater-active.lock
        exit 0
    fi
}

main $@
