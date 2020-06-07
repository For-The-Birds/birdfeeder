#!/bin/bash

mkdir li confusing

function tg {
    lis=$1-sharp.jpg
    # FIXME: hope convert is faster than dslr
    gm convert $1 -unsharp 0x2+1.5+0 -resize 70% $lis

    pid=$(echo $li | sed 's,^li/,, ; s/.jpg$//')
    bash sendPhoto.sh $2 $lis "$et $f iso $iso $yb $pid"
    rm $lis
}

ch_birds="-1001189666913"
ch_nobirds="-1001396273178"

while true; do
    if [ -f motion-detected ] ; then
        if ! gphoto2 --capture-image-and-download --force-overwrite ; then
            #sleep 1
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
        if (( $(echo "$yb > 0.9" | bc -l) )); then
            # yesbird
            ch=$ch_birds
            #if (( $(echo "$ass > 0.2" | bc -l) )); then
            #    ch="-1001436929738"
            #fi
        else
            # nobird
            ch="$ch_nobirds"
            ln -s $ln confusing/$li
        fi
        tg $li $ch &
    fi
    [ -f motion-detected ] || sleep 1
done
