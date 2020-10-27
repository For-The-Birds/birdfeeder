#!/bin/bash

. tglib.sh
. VARS.sh

oldexpc=-1

function illuminance {
    printf "%.2f" $(curl -s livingroom.local/sensor/livingroom_illuminance | jq '.value')
}

# Choice: 0 +2
# Choice: 1 +1 2/3
# Choice: 2 +1 1/2
# Choice: 3 +1 1/3
# Choice: 4 +1
# Choice: 5 +2/3
# Choice: 6 +1/2
# Choice: 7 +1/3
# Choice: 8 0
# Choice: 9 -1/3
# Choice: 10 -1/2
# Choice: 11 -2/3
# Choice: 12 -1
# Choice: 13 -1 1/3
# Choice: 14 -1 1/2
# Choice: 15 -1 2/3
# Choice: 16 -2

function lt {
    (( $(bc <<< "$1 < $2") ))
}

function expconfig {
    lx=$1
    c=8
    lt $lx 13 && c=7
    lt $lx 10 && c=6
    lt $lx 08 && c=5
    lt $lx 06 && c=4
    lt $lx 04 && c=3
    lt $lx 03 && c=2
    lt $lx 02 && c=1
    lt $lx 01 && c=0
    echo $c
}

function tg {
    lis=$1-sharp.jpg
    # FIXME: hope convert is faster than dslr
    #gm convert $1 -unsharp 0x2+1.5+0 -resize 70% $lis
    gm convert $1 -resize 70% $lis

    #pid=$(echo $li | sed 's,^li/,, ; s/.jpg$//')
    log=$(tgmono "$et $f $iso [$expc:$exp|$lx]  $nn $p")
    ans=$(apicall sendPhoto \
        -F reply_markup='{"inline_keyboard":[[{"text":"post","callback_data":"post '$nn'"}]]}' \
        -F photo=@$lis \
        -F chat_id=$2 \
        -F parse_mode=MarkdownV2 \
        -F caption="$log")

    chatname=$(jq '.result.chat.username' <<< "$ans" | tr -d '"')
    message_id=$(jq '.result.message_id' <<< "$ans")
    file_id=$(jq '.result.photo[] | .file_unique_id' <<< "$ans" | tr -d '"' | tr '\n' ' ')
    echo "$nn $chatname/$message_id $file_id" >> birdsdb
    #sendPhoto $2 $lis ''
    #tglog $2 "$et $f $iso [$expc:$exp|$lx]  $nn $p"
    rm $lis
}

function postgif {
    log=$(bash -vx makegif.sh birds/ $1 $2 birds_video.mp4)
    tglog $ch_nobirds "$log"
    sendVideo $ch_nobirds birds_video.mp4 "${@:3}"
}

tglog $ch_nobirds "starting rm:$RM_THR post:$POST_THR eye:$EYE_THR"

function check_cmd {
        updates=$(apicall getUpdates offset=-1)

        new_update_id=$(echo $updates | jq '.result[-1].update_id')
        [ "$new_update_id" = "$old_update_id" ] && return
        old_update_id=$new_update_id

        from=$(echo $updates | jq '.result[-1].message.from.id')
        if [ "$from" = "235802612" ] ; then
            botcmd=$(echo $updates | jq '.result[-1].message.text' | tr -d '/\\;\n#[]"@' | tr '_' '=')
            set -vx

            if echo $botcmd | grep gif ; then
                postgif ${botcmd##gif } &
            fi

            if echo $botcmd | grep exp ; then
                curl $CONF_URL -F arg="$botcmd"
            fi
            set +vx
        fi

}

net_err=0

function reset_rpi {
    tglog $ch_nobirds "rpi reset"
    bash reset-rpi.sh
    wget -q -O - $MOTION_URL
    while [ $? -eq 4 ] ; do
        net_err=$(( $net_err + 1 ))
        if [ $net_err -ge 300 ] ; then
            tglog $ch_nobirds "rpi reset"
            bash reset-rpi.sh
            net_err=0
        fi
        sleep 1
        wget -q -O - $MOTION_URL
    done
    net_err=0
}

#set -vx
while true; do
    #if wget --no-verbose --tries=1 --timeout=10 -O - $MOTION_URL ; then
    if wget -q --tries=1 --timeout=15 -O - $MOTION_URL >/dev/null ; then
        net_err=0
        #check_cmd

        lx=$(illuminance)
        if lt $lx 0.5 ; then
            echo "low illuminance $lx"
            sleep 5
            continue
        fi
        expc=$(expconfig $lx)
        if [ "$oldexpc" != "$expc" ]; then
            oldexpc=$expc
            #curl -s $CONF_URL -F arg="exposurecompensation=$expc"
        fi

        read n <imagen
        n=$(( n + 1 ))
        nn=$( printf '%.8d' $n )
        li=birds/$nn.jpg
        wget --progress=bar:force:noscroll --tries=3 --timeout=60 $SHOT_URL -O $li
        if [ $? -ne 0 ] || [ ! -s $li ] ; then
            rm $li
            tglog $ch_nobirds "dslr reset, rpi reboot"
            wget --progress=bar:force:noscroll --tries=1 --timeout=10 $RPI_REBOOT_URL -O -
            bash reset-dslr.sh
            continue
        fi
        echo $n >imagen

        #sharpness=$(python3 sharpness.py $li)

        et=$(exiv2  -q -g Exif.Photo.ExposureTime      -Pt $li)
        iso=$(exiv2 -q -g Exif.Photo.ISOSpeedRatings   -Pt $li)
        f=$(exiv2   -q -g Exif.Photo.ApertureValue     -Pt $li)
        exp=$(exiv2 -q -g Exif.Photo.ExposureBiasValue -Pt $li)

        unset plt bname

        p=$(curl --silent $BIRDPRED_URL -F filename="$PWD/$li")
        echo "-=-=-=-=-=-=-= bird:$p =-=-=-=-=-=-=-=-=-"
        if (( `bc <<< "$p < $RM_THR"` )); then
            rm -v $li
            continue
        fi
        if (( `bc <<< "$p > $POST_THR"` )); then
            # yesbird
            ch=$ch_birds
            birds=$(curl -s $FINDBIRD_URL -F filename="$PWD/$li")
            bcount=$(echo "$birds" | jq 'length')
            if [ "$bcount" = "0" ]; then
                ch=$ch_nobirds
            else
                max_eye=$(echo "$birds" | jq '.[] | .eye' | sort -n | tail -n1)
                if (( `bc <<< "$max_eye < $EYE_THR"` )); then
                    ch=$ch_noeye
                fi
            fi
        else
            # nobird
            ch=$ch_nobirds
            ln -s ../$li confusing/$(basename $li)
        fi
        tg $li $ch $plt &
    else
        if [ $? -eq 4 ] ; then
            net_err=$(( $net_err + 1 ))
            if [ $net_err -eq 10 ] ; then
                bash reset-dslr.sh
            fi
            if [ $net_err -ge 90 ] ; then
                reset_rpi
            fi
        fi
        sleep 0.5
    fi
done
