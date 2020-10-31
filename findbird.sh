#!/bin/bash

declare -a D=( "/mnt/0/bak/birds" "/mnt/0/bak/birdsdeep" "/home/yekm/src/yekm/acer-birds/bf/birds" "/mnt/0/bak/nonono" "/home/birds/bf/birds" )

for f in $@; do
    for d in ${D[@]}; do
        if [ -s "$d/$f.jpg" ]; then
            echo "$d/$f.jpg"
            break
        fi
        if [ -s "$d/$f" ]; then
            echo "$d/$f"
            break
        fi
    done
done

