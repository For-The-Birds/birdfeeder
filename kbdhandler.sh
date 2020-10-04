#!/bin/bash

. tglib.sh
. VARS.sh

#apicall sendPhoto \
#    -F reply_markup="$(cat kbd.json)" \
#    -F photo=@test.jpg \
#    -F chat_id=$ch_nobirds

update_id=-1

while true; do
    u=$(apicall getUpdates -F offset=$update_id -F allowed_updates='["message", "callback_query"]' -F timeout=30)
    len=$(jq '.result | length' <<< "$u")
    [ $len -lt 1 ] && continue
    update_id=$(jq '.result[-1].update_id' <<< "$u")
    update_id=$(( $update_id + 1 ))
    #jq <<< "$u"
    if ! jq -e '.result[-1] | has("callback_query")' <<< "$u"; then
        telegram=$(jq '.result[-1].message.from.id' <<< "$u")
        [ "$telegram" != "777000" ] && continue
        chat_id=$(jq '.result[-1].message.chat.id' <<< "$u")
        [ "$chat_id" != "$ch_or" ] && continue
        fwd_id=$(jq '.result[-1].message.forward_from_chat.id' <<< "$u")
        [ "$fwd_id" != "$ch_feeder" ] && continue
        message_id=$(jq '.result[-1].message.message_id' <<< "$u")
        [ -z "$cb_chat_name" ] && continue
        apicall sendMessage \
            -F chat_id=$ch_or \
            -F text="https://t.me/$cb_chat_name/$cb_message_id" \
            -F disable_notification=true \
            -F disable_web_page_preview=true \
            -F reply_to_message_id=$message_id
        continue
    fi
    cb_chat_name=$(jq '.result[-1].callback_query.message.chat.username' <<< "$u" | tr -d \")
    cb_message_id=$(jq '.result[-1].callback_query.message.message_id' <<< "$u")
    from=$(jq '.result[-1].callback_query.from.id' <<< "$u")
    cid=$(jq '.result[-1].callback_query.id' <<< "$u")
    bdata=$(jq '.result[-1].callback_query.data' <<< "$u")
    fid=$(jq '.result[-1].callback_query.message.photo[0].file_id' <<< "$u")
    echo "from $from, data $bdata"
    if [ "$from" = "235802612" ] ||
        [ "$from" = "216236682" ] ; then
        apicall sendPhoto -F chat_id=$ch_feeder -F photo=$fid # -F caption="$bdata"
        apicall answerCallbackQuery -F callback_query_id=$cid text="ok $bdata"
    else
        apicall answerCallbackQuery -F callback_query_id=$cid text="nope"
    fi
done

