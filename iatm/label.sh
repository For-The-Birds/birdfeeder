
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
trap "kill $mf" EXIT SIGINT SIGTERM
sleep 0.3

# NB: can be launched with emply stdin

prompt=$(
    for l in ${L[@]}; do
        echo $i : $l
        i=$(( $i + 1 ))
    done
    echo 's : skip'
    echo 'q : end'
    echo -n "Label: "
)

while read f; do
    sxiv $f &

    echo -n "$prompt"
    read -n 1 ln </dev/tty

    killall sxiv
    [ "$ln" = "q" ] && break
    [ "$ln" = "s" ] && continue
    echo $f _ $ln | tee -a f-label.txt

    im224=images224/$(basename $f)
    [ -s "$im224" ] || gm convert $f -resize '224x224!' images224/$(basename $f) &
done

set -vx

kill $mf
json=data-$project.json
rm -v $json

cat no.txt      | sed 's/$/ _ 1/' >>f-label.txt
cat yes-all.txt | sed 's/$/ _ 2/' >>f-label.txt
t=$(mktemp -p .)
sort -k 1,1 -u f-label.txt >>$t
mv $t f-label.txt

set +vx

cat f-label.txt | while IFS=_ read f ln ; do
    label="${L[$ln]}"
    [ -z "$label" ] && echo "ERROR: empty label, skipping $f" && continue

    cat >>$json << EOF
    {
        "image_id": "$(basename $f)",
        "label": "$label"
    }
    ,
EOF
echo -n .
done

echo "[" >$t
head -n -1 $json >>$t
echo "]" >>$t
mv $t $json

docker run -t --rm -v $PWD:/home -w /home python:3.6 \
    bash -c "pip install imageatm nbconvert && python train.py $project"


