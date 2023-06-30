#!/bin/bash -e
# sourcemod linux compile.sh configured to use spcomp64
cd "$(dirname "$0")"

test -e compiled || mkdir compiled

if [[ $# -ne 0 ]]; then
	for sourcefile in "$@"
	do
		smxfile="`echo $sourcefile | sed -e 's/\.sp$/\.smx/'`"
		echo -e "\nCompiling $sourcefile..."
		./spcomp64 $sourcefile -ocompiled/$smxfile
	done
else
	for sourcefile in *.sp
	do
		smxfile="`echo $sourcefile | sed -e 's/\.sp$/\.smx/'`"
		echo -e "\nCompiling $sourcefile ..."
		./spcomp64 $sourcefile -ocompiled/$smxfile
	done
fi
