#!/usr/bin/env bash

# ansible-tf2network: server autoupdater

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
    echo ""

    if [ -f updater-active.lock ]; then
        echo "[$(date +'%D %H:%M:%S')] A job is already active. Cancelling..."
        exit 0
    fi
    touch updater-active.lock

    echo "[$(date +'%D %H:%M:%S')] Checking..."

    CURRENT=$(cat current_tf2_buildid)
    LATEST=$(docker run --quiet --pull always --rm --entrypoint=/bin/bash cm2network/steamcmd -c './steamcmd.sh +login anonymous +app_info_update 232250 +app_info_print 232250 +quit' | perl -n -e'/"buildid"\s+"([    0-9]+)"/ && print "$1\n"' | head -n1)

    echo "[$(date +'%D %H:%M:%S')] Current: $CURRENT; Latest: $LATEST"

    if [ ! -f current_tf2_buildid ]; then
        echo "[$(date +'%D %H:%M:%S')] No current version saved, saving latest as current and doing nothing!"
        echo $LATEST > current_tf2_buildid

        rm updater-active.lock
        exit 0

    elif [[ "$CURRENT" -ne "$LATEST" ]]; then
        # rebuild (update) the base image
        echo "[$(date +'%D %H:%M:%S')] Updating base image..."
        docker buildx build -t jackavery/base-tf2server:latest /home/tf2server/build/base

        get_networks

        # rebuild servers
        for network in ${NETWORKS[@]} ; do
            echo "[$(date +'%D %H:%M:%S')] Processing $network..."

            get_servers_for_network $network

            for server in ${SERVERS[@]} ; do
                echo "[$(date +'%D %H:%M:%S')] Rebuilding $network/$server..."
                cd /home/tf2server/build/servers/$network/$server
                docker buildx build -t srcds-$network-$server:latest .
                cd /home/tf2server
            done

            echo "[$(date +'%D %H:%M:%S')] Docker recomposing $network..."
            docker compose -f /home/tf2server/docker-compose_$network.yml up -d
        done

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
