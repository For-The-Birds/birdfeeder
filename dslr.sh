#!/bin/bash


SHOT_URL="http://192.168.1.89:8080/shot"
CONF_URL="http://192.168.1.89:8080/config"
BIRDPRED_URL="http://127.0.0.1:5000/yesnobird"
EYEPRED_URL="http://127.0.0.1:5000/eye"
MOTION_URL="http://192.168.1.89:8080/motion"

ch_birds="-1001189666913"
ch_nobirds="-1001396273178"
ch_noeye="-1001455880770"

function tg {
    lis=$1-sharp.jpg
    # FIXME: hope convert is faster than dslr
    gm convert $1 -unsharp 0x2+1.5+0 -resize 70% $lis

    #pid=$(echo $li | sed 's,^li/,, ; s/.jpg$//')
    bash sendPhoto.sh $2 $lis ''
    bash sendMessage.sh $2 "\`$et $f $iso $exp $yb $yeye $nn\`"
    rm $lis
}

function postgif {
    log=$(bash -vx makegif.sh birds/ $1 $2 birds_video.mp4)
    bash sendMessage.sh $ch_nobirds "$log"
    bash sendVideo.sh $ch_nobirds birds_video.mp4 "${@:3}"
}

bash sendMessage.sh $ch_nobirds "starting"

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

while true; do
    if wget -q -O - $MOTION_URL ; then
        check_cmd

        read n <imagen
        n=$(( n + 1 ))
        nn=$( printf '%.8d' $n )
        li=birds/$nn.jpg
        wget --progress=bar:force:noscroll $SHOT_URL -O $li
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

        read nb yb <<< "$yesno"
        echo "-=-=-=-=-= bird:$yb =-=-=-=-=-"
        if (( $(echo "$nb > 0.8" | bc -l) )); then
            rm -v $li
            continue
        fi
        if (( $(echo "$yb > 0.9" | bc -l) )); then
            # yesbird
            ch=$ch_birds
            #if (( $(echo "$ass > 0.2" | bc -l) )); then
            #    ch="-1001436929738"
            #fi
            eye=$(curl -s $EYEPRED_URL -F filename="$PWD/$li224")
            read neye yeye <<< "$eye"
            if (( $(echo "$neye > 0.8" | bc -l) )); then
                ch=$ch_noeye
            fi
        else
            # nobird
            ch="$ch_nobirds"
            ln -s ../$li confusing/$(basename $li)
        fi
        rm $li224
        tg $li $ch &
    else
        if [ $? -eq 4 ] ; then
            bash reset-rpi.sh
            while ! wget -q -O - $MOTION_URL ; do
                sleep 1
            done
        fi
        sleep 0.5
    fi
done
