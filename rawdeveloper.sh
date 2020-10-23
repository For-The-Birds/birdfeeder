. tglib.sh
. VARS.sh

set -u

develop_raw() {
    SECONDS=0
    cr2=$1
    nn=$(basename $cr2)
    nn=${nn%%.cr2}
    hq=${cr2%%.cr2}.jpg
    tglog $ch_nobirds "raw developing $cr2"
    nice darktable-cli $cr2 birds.xmp $hq --core --configdir ./.dt-hq
    hq_small=$hq-resize.jpg
    gm convert $hq -resize 70% $hq_small
    #nice darktable-cli $cr2 $hq --core --configdir ./.dt-hq
    minutes=$(bc -l <<< "scale=2; $SECONDS / 60.0")
    if [ ! -s $hq_small ] ; then
        tglog $ch_nobirds "raw developing failed in $minutes minutes $nn"
    else
        msg=$(tgmono "raw developing ok in $minutes minutes $nn")
        ans=$(apicall sendPhoto \
            -F reply_markup='{"inline_keyboard":[[{"text":"post","callback_data":"post '$nn'"}]]}' \
            -F photo=@$hq_small \
            -F chat_id=$ch_raw \
            -F parse_mode=MarkdownV2 \
            -F caption="$msg")
        chatname=$(jq '.result.chat.username' <<< "$ans")
        message_id=$(jq '.result.message_id' <<< "$ans")
        file_id=$(jq '.result.photo[0].file_id' <<< "$ans")
        echo "$nn $chatname/$message_id $file_id _RAW_" >> birdsdb
    fi
}

while true; do
    ls -1 birds-hq/*.cr2 2>/dev/null | while read cr2; do
        develop_raw $cr2
        rm -v $cr2
    done
    sleep 1
done
