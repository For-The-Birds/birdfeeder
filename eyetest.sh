#!/bin/bash

[ -z "$1" ] && exit -1

mkdir _eye _noeye

find -L $1 -type f | shuf | while read f; do
    echo -n "$f "
    read n y <<< $(curl -s http://127.0.0.1:5000/eye -F filename="$PWD/$f")
    echo -n "[$n $y] "
    if (( $(echo "$y > 0.7" | bc -l) )); then
        echo yes
        ln -s $f _eye
    else
        echo no
        ln -s $f _noeye
    fi
done

