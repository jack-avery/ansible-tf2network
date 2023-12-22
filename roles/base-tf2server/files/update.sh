#!/bin/bash
cd $STEAMCMDDIR

mkdir $HOMEDIR/.lock
touch $HOMEDIR/.lock/lock

./steamcmd.sh +force_install_dir $HOMEDIR/tf-dedicated +login anonymous +app_update 232250 +quit

rm -r $HOMEDIR/.lock
