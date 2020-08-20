#!/bin/bash

[ -z "$1" ] && echo "first arg 'project name' is empty" && exit -1
project=$1

#L=$@
declare -a L=( nobird yesbird )
#declare -a L=( noeye yeseye )
for l in ${L[@]}; do
    mkdir -p label-$project/$l
done

L=(dummy ${L[@]}) # make labels start from 1 for easier keyboard logistics

t=$(mktemp -p .)
#sort -k 1,1 -u labels-$project.txt >>$t
#mv $t labels-$project.txt

fatal() {
    echo $@
    exit -1
}

json=data-$project.json
rm $json

while IFS=_ read f ln ; do
    label=${L[$ln]}
    [ -z "$label" ] && fatal "cant find label for index $ln"
    id=$(basename $f)
    cat >>$json << EOF
    {
        "image_id": "$id",
        "label": "$label"
    }
    ,
EOF
    pic=$(bash findbird.sh $id)
    [ -s "$pic" ] || fatal "cant find original image for id $id"
    ln -s $pic label-$project/${L[$ln]}/ &
    im224=images224/$id
    [ -s "$im224" ] || gm convert $pic -resize '224x224!' $im224 &
    echo -n .
done
echo

echo "[" >$t
head -n -1 $json >>$t
echo "]" >>$t
mv $t $json


#echo docker run -t --rm -v $PWD:/home -w /home python:3.6 \
#    bash -c "pip install imageatm nbconvert && python train.py $project"

