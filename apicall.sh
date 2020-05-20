#!/bin/bash

read token <token

curl --silent \
    -X POST https://api.telegram.org/bot$token/$1 \
    "${@:2}"

