#!/bin/bash

# compile
chmod +x ./compile-64.sh
./compile-64.sh

# disable all plugins by default
for file in $(ls compiled); do
    if [[ "$file" == *.smx ]]; then
        mv ./compiled/$file ../plugins/disabled
    fi
done
for file in $(ls ../plugins); do
    if [[ "$file" == *.smx ]]; then
        mv ../plugins/$file ../plugins/disabled
    fi
done
