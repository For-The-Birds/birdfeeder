#!/bin/bash

apicall() {
    read token <token

    curl --silent \
        -X POST https://api.telegram.org/bot$token/$1 \
        "${@:2}"
}

sendAudio() {
    apicall \
        sendAudio \
        -F chat_id="$1" \
        -F caption="${@:3}" \
        -F audio=@$2
}

sendMessage() {
    apicall \
        sendMessage \
        -F parse_mode=MarkdownV2 \
        -F chat_id="$1" \
        -F text="${@:2}"
}

sendPhoto() {
    apicall \
        sendPhoto \
        -F chat_id="$1" \
        -F caption="${@:3}" \
        -F photo=@$2
}


sendVideo() {
    apicall \
        sendVideo \
        -F chat_id="$1" \
        -F caption="${@:3}" \
        -F video=@$2
}

function tglog {
    l=$(echo -e "\x60${@:2}\x60")
    sendMessage $1 "$l"
}

