#!/bin/bash -vxe

files=$(ls -1 birds | sort | head -n 10000)
begin=$(echo "$files" | head -n1 | sed 's/.jpg//')
end=$(echo "$files" | tail -n1 | sed 's/.jpg//')
t=$begin-$end.tar
echo "$files" | tar -C birds -c -v -f $t -T -
ls -lah $t
aws s3 cp $t s3://birdsdeep/ --storage-class DEEP_ARCHIVE
cd birds
echo "$files" | xargs mv -t ../birdsdeep/
cd ..

