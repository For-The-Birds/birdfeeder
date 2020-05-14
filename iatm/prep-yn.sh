
fn=data-yn.json

echo "[" >$fn
for f in no yes-all; do
    bash data.json.sh $f $f.txt >>$fn
done

head -n -1 $fn >$fn.tmp
mv $fn.tmp $fn

echo "]" >>$fn

