#!/bin/bash -e

. tglib.sh
. VARS.sh

trap "killall gate_recorder; exit" SIGINT SIGTERM

process_audio() {
    bn=$(basename $1)
    wav=$WAVD/$bn
    opus=$OPUSD/$bn.opus
    flac=$FLACD/$bn.opus
    gain=$OPUSD/$bn-gain.wav
    png=$PNGD/$bn.png
    sox $wav $gain gain -n -3
    sox $gain -n spectrogram -o $png
    opusenc $gain $opus
    o=${opus%%.wav.opus}
    ln -s $opus $o
    rm $gain
    sendPhoto $ch_audio $png "$bn"
    sendAudio $ch_audio $o
    rm $o $png
    flac --best --delete-input-file -o $flac $wav
}

pushd .
cd $WAVD
pgrep gate_recorder || gate_recorder -l -12 &
popd

while true; do
    wav=$(inotifywait -q -e close_write --format '%f' $WAVD/)
    process_audio $wav &
done

