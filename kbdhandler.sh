#!/bin/bash

. tglib.sh
. VARS.sh

#apicall sendPhoto \
#    -F reply_markup="$(cat kbd.json)" \
#    -F photo=@test.jpg \
#    -F chat_id=$ch_nobirds

update_id=-1

while true; do
    u=$(apicall getUpdates -F offset=$update_id -F allowed_updates='["message", "callback_query"]' -F timeout=60)
    len=$(jq '.result | length' <<< "$u")
    [ $len -lt 1 ] && continue
    update_id=$(jq '.result[-1].update_id' <<< "$u")
    update_id=$(( $update_id + 1 ))
    #jq <<< "$u"
    if ! jq -e '.result[-1] | has("callback_query")' <<< "$u"; then
        telegram=$(jq '.result[-1].message.from.id' <<< "$u")
        chat_id=$(jq '.result[-1].message.chat.id' <<< "$u")
        fwd_id=$(jq '.result[-1].message.forward_from_chat.id' <<< "$u")
        message_id=$(jq '.result[-1].message.message_id' <<< "$u")
        file_id=$(jq '.result[0].message.photo[0].file_id' <<< "$u")
        nn=$(grep $file_id birdsdb | cut -f1 -d' ')
        nn=$(grep "^$nn" birdsdb | grep -v RAW | cut -f1 -d' ')
        link=$(grep "^$nn" birdsdb | grep -v RAW | cut -f2 -d' ')
        if [ -z "$file_id" ] ||
            [ -z "$link" ] ||
            [ -z "$nn" ] ||
            [ "$fwd_id" != "$ch_feeder" ] ||
            [ "$chat_id" != "$ch_or" ] ||
            [ "$telegram" != "777000" ] ; then
            continue
        fi
        #[ -z "$cb_chat_name" ] && continue
        apicall sendMessage \
            -F chat_id=$ch_or \
            -F text="https://t.me/$link $nn" \
            -F disable_notification=true \
            -F disable_web_page_preview=true \
            -F reply_to_message_id=$message_id
        continue
    fi
    #cb_chat_name=$(jq '.result[-1].callback_query.message.chat.username' <<< "$u" | tr -d \")
    #cb_message_id=$(jq '.result[-1].callback_query.message.message_id' <<< "$u")
    from=$(jq '.result[-1].callback_query.from.id' <<< "$u")
    cid=$(jq '.result[-1].callback_query.id' <<< "$u")
    bdata=$(jq '.result[-1].callback_query.data' <<< "$u" | tr -d \")
    # Resending a photo by file_id will send all of its sizes.
    fid=$(jq '.result[-1].callback_query.message.photo[0].file_id' <<< "$u")
    echo "from $from, data $bdata"
    if [ "$from" = "235802612" ] ||
        [ "$from" = "216236682" ] ; then
        if [[ "$bdata" == "post "* ]] ; then
            apicall sendPhoto -F chat_id=$ch_feeder -F photo=$fid # -F caption="$bdata"
        fi
        if [[ "$bdata" == "develop "* ]] ; then
            nn=$(echo "$bdata" | cut -f2 -d' ')
            hq=birds-hq/$nn.jpg
            ln -s ../rawbirds/$nn.cr2 birds-hq/$nn.cr2
        fi
        apicall answerCallbackQuery -F callback_query_id=$cid text="ok $bdata"
    else
        apicall answerCallbackQuery -F callback_query_id=$cid text="nope"
    fi
done

