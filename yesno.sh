#!/bin/bash

[ -z "$1" ] && exit -1

mkdir yes no

find $1 -type f | sort | while read f; do
    echo -n "$f "
    [ -f "yes/$(basename $f)" ] && continue
    [ -f  "no/$(basename $f)" ] && continue
    read n y <<< $(curl -s http://127.0.0.1:5000/yesnobird -F filename="$PWD/$f")
    echo -n "[$n $y] "
    if [ "$y" == "1" ]; then
        echo yes
        cp $f yes
    else
        echo no
        cp $f no
    fi
done

echo "yes: $(ls -1 yes | wc -l) no: $(ls -1 no | wc -l)"
