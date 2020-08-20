
[ -z "$1" ] && echo "first arg 'project name' is empty" && exit -1
project=$1

declare -a L=( yesbird nobird )
#declare -a L=( noeye yeseye )
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
    echo $f _ $ln _ ${L[$ln]} >> labels-$project.txt

    gm convert $f -resize '224x224!' $im224 &
done

kill $mf

#echo docker run -t --rm -v $PWD:/home -w /home python:3.6 \
#    bash -c "pip install imageatm nbconvert && python train.py $project"

