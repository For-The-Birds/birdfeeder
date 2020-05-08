#!/bin/bash

function t {
    pkill -fe dslr.sh
    pkill -fe motion
    pkill -fe flask
}

trap t SIGINT SIGTERM EXIT

cd $(dirname $0)
FLASK_APP=pred.py python3 -m flask run &
motion -c motion.conf
bash dslr.sh &
tail -f motion.log

