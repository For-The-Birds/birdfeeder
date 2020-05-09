
bash apicall.sh \
    sendVideo \
    -F chat_id="$1" \
    -F caption="${@:3}" \
    -F video=@$2

