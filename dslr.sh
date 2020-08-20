#!/bin/bash


SHOT_URL="http://192.168.1.89:8080/shot"
CONF_URL="http://192.168.1.89:8080/config"
BIRDPRED_URL="http://127.0.0.1:5000/yesnobird1"
FINDBIRD_URL="http://127.0.0.1:5000/find_birds"
MOTION_URL="http://192.168.1.89:8080/motion"
RPI_REBOOT_URL="http://192.168.1.89:8080/reboot"

ch_birds="-1001189666913"
ch_nobirds="-1001396273178"
ch_noeye="-1001455880770"

RM_THR=-0.1
POST_THR=2.0
EYE_THR=0.5
NOEYE_THR=0.001

function tglog {
    l=$(echo -e "\x60${@:2}\x60")
    bash sendMessage.sh $1 "$l"
}

function tg {
    lis=$1-sharp.jpg
    # FIXME: hope convert is faster than dslr
    gm convert $1 -unsharp 0x2+1.5+0 -resize 70% $lis

    #pid=$(echo $li | sed 's,^li/,, ; s/.jpg$//')
    bash sendPhoto.sh $2 $lis ''
    [ -n "$3" ] && bash sendPhoto.sh $ch_nobirds $3 ''
    tglog $2 "$et $f $iso $exp  $nn $p"
    [ -n "$bname" ] && tglog $2 "$bname"
    rm $lis
}

function postgif {
    log=$(bash -vx makegif.sh birds/ $1 $2 birds_video.mp4)
    tglog $ch_nobirds "$log"
    bash sendVideo.sh $ch_nobirds birds_video.mp4 "${@:3}"
}

tglog $ch_nobirds "starting rm:$RM_THR post:$POST_THR eye:$EYE_THR noeye:$NOEYE_THR"

function check_cmd {
        updates=$(bash apicall.sh getUpdates offset=-1)

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
        if [ $net_err -ge 600 ] ; then
            tglog $ch_nobirds "rpi reset"
            bash reset-rpi.sh
        fi
        sleep 1
        wget -q -O - $MOTION_URL
    done
    net_err=0
}

#set -vx
while true; do
    if wget -q --tries=1 --timeout=10 -O - $MOTION_URL ; then
        check_cmd

        read n <imagen
        n=$(( n + 1 ))
        nn=$( printf '%.8d' $n )
        li=birds/$nn.jpg
        wget --progress=bar:force:noscroll --tries=3 --timeout=30 $SHOT_URL -O $li
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
        if (( $(echo "$p < $RM_THR" | bc -l) )); then
            rm -v $li
            continue
        fi
        if (( $(echo "$p > $POST_THR" | bc -l) )); then
            # yesbird
            ch=$ch_birds
            birds=$(curl -s $FINDBIRD_URL -F filename="$PWD/$li" -F plt_filename="$PWD/plt/$li")
            bcount=$(echo "$birds" | jq 'length')
            if [ "$bcount" = "0" ]; then
                ch=$ch_nobirds
            else
                plt=plt/$li
                bid=$(echo "$birds" | jq '.[] | .bird.id')
                bname=$(echo "$birds" | jq '.[] | .bird.name')
                if [ $(echo "$bid" | grep -v 695 | wc -l) = "0" ]; then
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
            if [ $net_err -ge 6 ] ; then
                reset_rpi
            fi
        fi
        sleep 0.5
    fi
done
