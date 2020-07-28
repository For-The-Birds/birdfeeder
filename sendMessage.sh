
bash apicall.sh \
    sendMessage \
    -F parse_mode=MarkdownV2 \
    -F chat_id="$1" \
    -F text="${@:2}"

