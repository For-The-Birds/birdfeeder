#!/bin/bash

. tglib.sh
. VARS.sh

#apicall sendPhoto \
#    -F reply_markup="$(cat kbd.json)" \
#    -F photo=@test.jpg \
#    -F chat_id=$ch_nobirds

update_id=-1

while true; do
    updates=$(apicall getUpdates -F offset=$update_id -F allowed_updates='["callback_query"]' -F timeout=10)
    #echo "$updates" | jq
    len=$(jq '.result | length' <<< "$updates")
    [ $len -lt 1 ] && continue
    update_id=$(echo $updates | jq '.result[-1].update_id')
    update_id=$(( $update_id + 1 ))
    from=$(jq '.result[-1].callback_query.from.id' <<< "$updates")
    cid=$(jq '.result[-1].callback_query.id' <<< "$updates")
    bdata=$(jq '.result[-1].callback_query.data' <<< "$updates")
    fid=$(jq '.result[-1].callback_query.message.photo[0].file_id' <<< "$updates")
    echo "from $from, data $bdata"
    if [ "$from" = "235802612" ] ||
        [ "$from" = "216236682" ] ; then
        apicall sendPhoto -F chat_id=$ch_feeder -F photo=$fid # -F caption="$bdata"
        apicall answerCallbackQuery -F callback_query_id=$cid text="ok $bdata"
    else
        apicall answerCallbackQuery -F callback_query_id=$cid text="nope"
    fi
done

