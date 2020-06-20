
imdir=$1

if [ -z $2 ]; then
    #use all images from dir $1
    imdir=$1
    first=$(ls -1 $1 | head -n1)
    last=$(ls -1 $1 | tail -n1)

    first=${first%%.jpg}
    last=${last%%.jpg}
else
    first=$2
    last=$3
fi

t=$(mktemp -p .)
trap "rm -v $t" EXIT

existing=$imdir/$first.jpg
seq -w $first $last | while read n; do
    f=$imdir/$n.jpg
    if ls $f >/dev/null 2>&1 ; then
        existing=$f
        echo -n '.'
    else
        echo -n '<'
    fi
    echo "file $existing" >> $t
done

ffmpeg -y -f concat -safe 0 -i $t -c:v libx264 -vf "scale=-1:1080,fps=60,format=yuv420p" $4

