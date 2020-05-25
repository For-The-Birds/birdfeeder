
bash apicall.sh \
    sendMessage \
    -F chat_id="$1" \
    -F text="${@:2}"

