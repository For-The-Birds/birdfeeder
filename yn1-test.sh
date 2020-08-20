#!/bin/bash

rm -r _p _yes _no
mkdir -p _p _yes _no

while read f; do
    echo -n "$f "
    read p <<< $(curl -s http://127.0.0.1:5000/yesnobird1 -F filename="$f")
    echo "[$p]"
    ln -s $f "_p/$p.jpg"
    if (( $(echo "$p > 3.0" | bc -l) )); then
        ln -s $f _yes/
        continue
    fi
    ln -s $f _no/
done
