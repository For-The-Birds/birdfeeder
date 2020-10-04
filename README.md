# birdfeeder

Tracking birds in feeder using 
- [x] motion detection from webcam https://github.com/Motion-Project/motion
- [x] photo capturing with gphoto2 https://github.com/gphoto/gphoto2
- [x] telegram bot api https://t.me/moscow_birds
- [x] tf transfer learning https://colab.research.google.com/drive/1J7HmH3fxNEfsmfNY1A99RIl-Lw8A7xBA?usp=sharing
- [ ] ffmpeg stream to better machine for bird detection and counting
- [ ] gnuplot or d3.js based visualisation of birds visits

# setup

Everything split in three parts.
* First one is runnig on raspberry pi 2. Webcam and dslr are connected to rpi. It runs `motion` daemon and `pibird` go service.
* Second is a computer with main loops in `dslr.sh` and `kbdhandler.sh`. And bird detection service with tensorflow written in python3.
* Third, optional, is the esp32 board with the tcs34725 rgb sensor (for setting up dslr's exposure) and couple of relays (for the case if camra or dslr hungs up).

Everything is powered by single ATX PSU.

# Licence
MIT
