# birdfeeder

Tracking birds in feeder using 
- [x] motion detection from webcam https://github.com/Motion-Project/motion
- [x] photo capturing with gphoto2 https://github.com/gphoto/gphoto2
- [x] telegram bot api https://t.me/moscow_birds
- [x] ~~google's teachable machine~~ imageatm for filtering out empty frames https://github.com/idealo/imageatm
- [ ] imageai for video object detection https://github.com/OlafenwaMoses/ImageAI
- [ ] gnuplot or d3.js based visualisation of birds visits

# usage

* fix paths in `motion.conf`
* connect usb webcam and a dslr (tesed with old defender webcam and canon eos350)
* generate h5 model with photos from the dslr camera (`./iatm` directory)
  * place photos in `./images`
  * create files `yes-all.txt` and `no.txt` with photo's filenames one by line
  * prepare data.json from them `prep-yn.sh`
  * run trainig `docker.sh`
* create `token` and setup two channles in telegram (`dslr.sh`)
* read `runall.sh`

# Licence
MIT
