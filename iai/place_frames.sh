
[ -z "$ODIR" || -z "$XMLDIR" ] && exit -1

mkdir -vp $ODIR/{validation,train}/{annotations,images}

shopt -s nullglob
xml=($XMLDIR/*.xml)
cp "${xml[@]}" $ODIR/train/annotations
jpg=$(basename -s .xml "${xml[@]}" | sed 's/$/.jpg/;s,^,frames/,')
cp $jpg $ODIR/train/images/
#for f in labelimg/*.xml ; do
#    cp -v frames/$(basename ${f/.xml/.jpg}) birds/train/images
#    cp -v $f birds/train/annotations birds/train/annotations/
#done

tags=$(egrep '<name>' $ODIR/train/annotations/*.xml | cut -f2- | sort -u)
echo "$tags" | while read t; do
    ttotal=$(egrep "$t" $ODIR/train/annotations/*.xml | wc -l)
    percent=$(echo "$ttotal * 0.20" | bc | cut -f1 -d.)
    validations=$(egrep "$t" $ODIR/train/annotations/*.xml | shuf | head -n $percent | cut -f1 -d:)
    echo "$t: train:$ttotal validation:$percent"
    mv $validations $ODIR/validation/annotations
    mv $(basename -s .xml $validations | sed "s/$/.jpg/;s,^,$ODIR/train/images/,") $ODIR/validation/images/
done

