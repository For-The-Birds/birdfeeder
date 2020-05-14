#!/bin/bash

trap "echo >&2" SIGINT EXIT

l=$1
cat $2 | while read f; do

    cat << EOF
    {
        "image_id": "$f",
        "label": "$l"
    }
    ,
EOF

    [ -f images/$f ] || gm convert ../li/$f -resize '224x224!' images/$f

    echo -n . >&2

done

