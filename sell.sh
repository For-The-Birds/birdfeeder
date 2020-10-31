for f in $@; do
    bird=$(bash findbird.sh $f)
    [ ! -s "$bird" ] && continue
    curl -T $bird ftp://ftp.contributor.adobestock.com -u $(<.sstock)
done
