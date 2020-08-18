#!/bin/bash

mkdir _yes _no _p

while read f; do
    echo -n "$f "
    read n y <<< $(curl -s http://127.0.0.1:5000/yesnobird -F filename="$f")
    echo "[$n $y] "
    ln -s $f _p/$y.jpg
    continue #!!

    if [ "$y" == "1" ]; then
        echo yes
        ln -sf $f _yes/
        continue
    fi
    if (( $(echo "$n > 0.99" | bc -l) )); then
        echo no
        ln -sf $f _no/
        continue
    fi
    echo confusing
done

#echo "yes: $(ls -1 _yes | wc -l) no: $(ls -1 _no | wc -l)"
