#docker run -it --rm -v $PWD:/home -w /home python:3.6 bash -c "pip install imageatm nbconvert && python train.py"
docker run -it --rm -v $PWD:/home -w /home iatm-p bash -c "pip install imageatm nbconvert && python train-yn.py"
