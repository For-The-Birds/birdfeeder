
bash apicall.sh \
    sendPhoto \
    -F chat_id="$1" \
    -F caption="${@:3}" \
    -F photo=@$2

