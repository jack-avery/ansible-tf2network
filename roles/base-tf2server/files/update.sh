touch $HOMEDIR/.lock
cd $STEAMCMDDIR
./steamcmd.sh +force_install_dir $HOMEDIR/tf-dedicated +login anonymous +app_update 232250 +quit
rm $HOMEDIR/.lock
