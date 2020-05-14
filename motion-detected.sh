#!/bin/bash

cd $(dirname $0)

if [ $1 = "start" ] ; then
    touch motion-detected
    date +%s >start_time
fi

if [ $1 = "end" ] ; then
    read st <start_time
    duration=$( echo "$(date +%s) - $st" | bc )
    echo $(date --date=@$st) _ $st _ $(date +%u) _ $(date +%R) _ $duration | tee -a motions.txt
    rm -v motion-detected
fi

