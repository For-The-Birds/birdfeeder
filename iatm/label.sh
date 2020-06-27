
[ -z "$1" ] && echo "first arg 'project name' is empty" && exit -1
project=$1

declare -a L=( nobird yesbird )
L=(dummy ${L[@]}) # make labels start from 1 for easier keyboard logistics

function maintain_focus {
    wid=$(xdotool getwindowfocus)

    while true; do
        xdotool windowfocus $wid
        sleep 0.1
    done
}

maintain_focus &
mf=$!
trap "kill $mf" EXIT
sleep 0.3

# NB: can be launched with emply stdin

prompt=$(
    for l in ${L[@]}; do
        echo $i : $l
        i=$(( $i + 1 ))
        mkdir -p label/$l
        mkdir -p label224/$l
    done
    echo 's : skip'
    echo 'q : end'
)

while read f; do
    i=$(( $i + 1 ))
    #[ -L $f ] && f=$ARCHIVEDIR/$(readlink $f)
    im224=images224/$(basename $f)
    [ -s "$im224" ] && continue
    [ ! -s "$f" ] && echo "no such file $f" && continue

    sxiv $f &

    echo "$prompt"
    echo -n "$f $i label: "
    read -n 1 ln </dev/tty

    killall sxiv
    [ "$ln" = "q" ] && break
    [ "$ln" = "s" ] && continue
    echo $f _ $ln >> f-label.txt

    gm convert $f -resize '224x224!' $im224 &
    ln -s $f label/${L[$ln]}/
    ln -s ../../$im224 label224/${L[$ln]}/
done

set -vx

kill $mf

json=data-$project.json
rm -v $json

#cat no.txt      | sed 's/$/ _ 1/' >>f-label.txt
#cat yes-all.txt | sed 's/$/ _ 2/' >>f-label.txt
t=$(mktemp -p .)
sort -k 1,1 -u f-label.txt >>$t
mv $t f-label.txt

set +vx

#cat f-label.txt | while IFS=_ read f ln ; do
for label in ${L[@]}; do
    ldir=label224/$label

    ls -1 $ldir | while read f; do

        cat >>$json << EOF
        {
            "image_id": "$(basename $f)",
            "label": "$label"
        }
        ,
EOF
    echo -n .
    done
done
echo

echo "[" >$t
head -n -1 $json >>$t
echo "]" >>$t
mv $t $json


echo docker run -t --rm -v $PWD:/home -w /home python:3.6 \
    bash -c "pip install imageatm nbconvert && python train.py $project"


