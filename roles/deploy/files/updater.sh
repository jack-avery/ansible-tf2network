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

log() {
	echo "[$(date +'%D %H:%M:%S')] ($$) $1"
}

die() {
	if [ -e updater-active.lock ]; then
		rm updater-active.lock
	fi
	log "Finished. Exit message: $1"
	exit 0
}

main() {
	if [ -f updater-active.lock ]; then
		log "A job is already active."
		exit 0
	fi
	touch updater-active.lock

	echo ""
	log "Checking..."
	UPDATE_TIMEOUT=30
	LATEST=$(docker run --quiet --pull always --rm --entrypoint=/bin/bash cm2network/steamcmd -c "timeout $UPDATE_TIMEOUT ./steamcmd.sh +login anonymous +app_info_print 232250 +login anonymous +app_info_print 232250 +logout +quit" | perl -n -e'/"buildid"\s+"([    0-9]+)"/ && print "$1\n"' | head -n1)

	if [ ! -f current_tf2_buildid ]; then
		echo $LATEST > current_tf2_buildid
		die "No current version saved, saving and exiting."
	fi
	CURRENT=$(cat current_tf2_buildid)

	if [ -z "$LATEST" ]; then
		die "Failed: could not fetch latest"

	elif [[ "$CURRENT" -ne "$LATEST" ]]; then
		log "Current: $CURRENT; Latest: $LATEST"

		# rebuild (update) the base image
		log "Reached base rebuild phase."
		if ! docker buildx build --no-cache -t jackavery/base-tf2server:latest /home/tf2server/build/base; then
			die "Failed: base image failed to build"
		fi

		# rebuild servers
		log "Reached network rebuild phase."
		get_networks
		for network in ${NETWORKS[@]} ; do
			log "Processing $network..."

			get_servers_for_network $network

			for server in ${SERVERS[@]} ; do
				log "Rebuilding $network/$server..."
				cd /home/tf2server/build/servers/$network/$server
				if ! docker buildx build -t srcds-$network-$server:latest .; then
					log "Warning: failed to build image for Network: $network Server: $server"
				fi
				cd /home/tf2server
			done

			log "Docker recomposing $network..."
			if ! docker compose -f /home/tf2server/docker-compose_$network.yml up -d; then
				log "Warning: failed to compose $network"
			fi
		done

		log "Reached cleanup phase."
		log "Pruning Docker..."
		docker system prune -f

		log "Saving latest version $LATEST..."
		echo $LATEST > current_tf2_buildid

		die "Update was successful!"
	else
		die "Current is latest, nothing to do"
	fi
}

main $@
