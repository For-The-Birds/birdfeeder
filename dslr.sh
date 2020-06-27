#!/bin/bash

mkdir li confusing

ch_birds="-1001189666913"
ch_nobirds="-1001396273178"

function tg {
    lis=$1-sharp.jpg
    # FIXME: hope convert is faster than dslr
    gm convert $1 -unsharp 0x2+1.5+0 -resize 70% $lis

    pid=$(echo $li | sed 's,^li/,, ; s/.jpg$//')
    bash sendPhoto.sh $2 $lis ''
    bash sendMessage.sh $2 "$et $f $iso $yb $exp $pid"
    rm $lis
}

function postgif {
    log=$(bash -vx makegif.sh li/ $1 $2 birds_video.mp4)
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
                gphoto2 --set-config-index $botcmd
            fi
            set +vx
        fi

}

while true; do
    if [ -f motion-detected ] ; then
        check_cmd

        gphoto2 --capture-image-and-download --force-overwrite
        if [ $? -ne 0 ] || ! ls IMG_*.JPG  ; then
            bash sendMessage.sh $ch_nobirds "dslr reset"
            bash reset-dslr.sh
            continue
        fi

        lastimage=$(ls -1 IMG_*.JPG | tail -n1)

        read n <imagen
        n=$(( n + 1 ))
        nn=$( printf '%.8d' $n )
        li=li/$nn.jpg
        mv -v $lastimage $li || continue
        echo $n >imagen

        #sharpness=$(python3 sharpness.py $li)

        et=$(exif  -m --tag=0x829a --no-fixup $li)
        f=$(exif   -m --tag=0x829d --no-fixup $li)
        iso=$(exif -m --tag=0x8827 --no-fixup $li)
        exp=$(exif -m --tag=0x9204 --no-fixup $li)

        li224=$li-224.jpg
        gm convert $li -resize '224x224!' $li224

        yesno=$(curl --silent http://127.0.0.1:5000/yesnobird -F filename="$PWD/$li224")
        rm $li224

        read nb yb <<< "$yesno"
        echo "-=-=-=-=-= n:$nb yes:$yb =-=-=-=-=-"
        if (( $(echo "$nb > 0.5" | bc -l) )); then
            rm -v $li
            continue
        fi
        if (( $(echo "$yb > 0.97" | bc -l) )); then
            # yesbird
            ch=$ch_birds
            #if (( $(echo "$ass > 0.2" | bc -l) )); then
            #    ch="-1001436929738"
            #fi
        else
            # nobird
            ch="$ch_nobirds"
            ln -s ../$li confusing/$(basename $li)
        fi
        tg $li $ch &
    fi
    [ -f motion-detected ] || sleep 1
done
