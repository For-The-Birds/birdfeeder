#!/bin/bash

mkdir -p _p

while read f; do
    echo -n "$f "
    read p <<< $(curl -s http://127.0.0.1:5000/yesnobird1 -F filename="$f")
    echo "[$p] "
    ln -s $f "_p/$p.jpg"
done
