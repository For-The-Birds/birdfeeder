#!/bin/bash -e

. tglib.sh
. VARS.sh

process_audio() {
    bn=$(basename $1)
    wav=$WAVD/$bn
    opus=$OPUSD/$bn.opus
    gain=$OPUSD/$bn-gain.wav
    png=$PNGD/$bn.png
    sox $wav $gain gain -n -3
    sox $gain -n spectrogram -o $png
    opusenc $gain $opus
    rm $gain
    sendPhoto $ch_audio $png "$bn"
    sendAudio $ch_audio $opus
}

while true; do
    wav=$(inotifywait -q -e close_write --format '%f' $WAVD/)
    process_audio $wav &
done

