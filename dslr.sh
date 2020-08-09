#!/bin/bash


SHOT_URL="http://192.168.1.89:8080/shot"
CONF_URL="http://192.168.1.89:8080/config"
BIRDPRED_URL="http://127.0.0.1:5000/yesnobird"
EYEPRED_URL="http://127.0.0.1:5000/eye"
MOTION_URL="http://192.168.1.89:8080/motion"

ch_birds="-1001189666913"
ch_nobirds="-1001396273178"
ch_noeye="-1001455880770"

RM_THR=0.2
POST_THR=0.9
EYE_THR=0.8
NOEYE_THR=0.001

function tg {
    lis=$1-sharp.jpg
    # FIXME: hope convert is faster than dslr
    gm convert $1 -unsharp 0x2+1.5+0 -resize 70% $lis

    #pid=$(echo $li | sed 's,^li/,, ; s/.jpg$//')
    bash sendPhoto.sh $2 $lis ''
    l=$(echo -e "\x60$et $f $iso $exp $yb $yeye $nn\x60") # -e \x60 instead of "\`", vim syntax highlight is happy now
    bash sendMessage.sh $2 "$l"
    rm $lis
}

function postgif {
    log=$(bash -vx makegif.sh birds/ $1 $2 birds_video.mp4)
    bash sendMessage.sh $ch_nobirds "$log"
    bash sendVideo.sh $ch_nobirds birds_video.mp4 "${@:3}"
}

l=$(echo -e "\x60starting rm:$RM_THR post:$POST_THR eye:$EYE_THR noeye:$NOEYE_THR\x60") # dot must be escaped or put into `
bash sendMessage.sh $ch_nobirds "$l"

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
    bash sendMessage.sh $ch_nobirds "rpi reset"
    bash reset-rpi.sh
    wget -q -O - $MOTION_URL
    while [ $? -eq 4 ] ; do
        net_err=$(( $net_err + 1 ))
        if [ $net_err -ge 600 ] ; then
            bash sendMessage.sh $ch_nobirds "rpi reset"
            bash reset-rpi.sh
        fi
        sleep 1
        wget -q -O - $MOTION_URL
    done
    net_err=0
}

while true; do
    if wget -q --tries=1 --timeout=6 -O - $MOTION_URL ; then
        check_cmd

        read n <imagen
        n=$(( n + 1 ))
        nn=$( printf '%.8d' $n )
        li=birds/$nn.jpg
        wget --progress=bar:force:noscroll --tries=1 --timeout=20 $SHOT_URL -O $li
        if [ ! -s $li ] ; then
            rm $li
            bash sendMessage.sh $ch_nobirds "dslr reset"
            bash reset-dslr.sh
            continue
        fi
        if [ $? -ne 0 ] ; then
            bash sendMessage.sh $ch_nobirds "dslr reset"
            bash reset-dslr.sh
            continue
        fi
        echo $n >imagen

        #sharpness=$(python3 sharpness.py $li)

        et=$(exiv2  -q -g Exif.Photo.ExposureTime      -Pt $li)
        iso=$(exiv2 -q -g Exif.Photo.ISOSpeedRatings   -Pt $li)
        f=$(exiv2   -q -g Exif.Photo.ApertureValue     -Pt $li)
        exp=$(exiv2 -q -g Exif.Photo.ExposureBiasValue -Pt $li)

        li224=$li-224.jpg
        gm convert $li -resize '224x224!' $li224

        yesno=$(curl --silent $BIRDPRED_URL -F filename="$PWD/$li224")
        eye=$(curl -s $EYEPRED_URL -F filename="$PWD/$li224")
        rm $li224

        read nb yb <<< "$yesno"
        read neye yeye <<< "$eye"
        echo "-=-=-=-=-=-=-= bird:$yb eye:$yeye =-=-=-=-=-=-=-"
        if (( $(echo "$yb < $RM_THR" | bc -l) )); then
            rm -v $li
            continue
        fi
        if (( $(echo "$yb > $POST_THR" | bc -l) )); then
            # yesbird
            ch=$ch_birds
            if (( $(echo "$yeye < $EYE_THR" | bc -l) )); then
                if (( $(echo "$yeye < $NOEYE_THR" | bc -l) )); then
                    bash sendMessage.sh $ch_noeye "not posted $yb $yeye $nn"
                    continue
                fi
                ch=$ch_noeye
            fi
        else
            # nobird
            ch="$ch_nobirds"
            ln -s ../$li confusing/$(basename $li)
        fi
        tg $li $ch &
    else
        if [ $? -eq 20 ] ; then
            net_err=$(( $net_err + 1 ))
            if [ $net_err -ge 5 ] ; then
                reset_rpi
            fi
        fi
        sleep 0.5
    fi
done
