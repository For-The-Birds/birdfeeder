#!/bin/bash

mkdir li

function tg {
	lis=$1-sharp.jpg
	# FIXME: hope convert is faster than dslr
	convert $1 -unsharp 1x2+1.5+0 -resize 70% $lis
	
	bash sendPhoto.sh $2 $lis "$et $f iso $iso n:$nb y:$yb"
	rm $lis
}

while true; do
	if [ -f motion-detected ] ; then
		if ! gphoto2 --capture-image-and-download --force-overwrite ; then
			sleep 1
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

		yesno=$(curl http://127.0.0.1:5000/yesnobird -F filename="$PWD/$li")
		read nb yb <<< "$yesno"
		if (( $(echo "$nb > 0.9" | bc -l) )); then
		    rm -v $li
			continue
		fi
		if (( $(echo "$yb > 0.9998" | bc -l) )); then
			# yesbird
			ch="-1001189666913"
		else
			# nobird
			ch="-1001396273178"
		fi
		tg $li $ch &
	fi
	[ -f motion-detected ] || sleep 1
done
