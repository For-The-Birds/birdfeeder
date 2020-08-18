import tensorflow as tf
import tensorflow_hub as hub
from PIL import Image, ImageOps
import numpy as np
import sys, csv

from flask import Flask, request
app = Flask(__name__)


IMAGE_SIZE = (224, 224)

np.set_printoptions(suppress=True)

with open('aiy_birds_V1_labelmap.csv', mode='r') as infile:
    reader = csv.reader(infile)
    next(reader, None)
    birds_dict = dict((int(rows[0]),rows[1]) for rows in reader)

MODULE_HANDLE = 'https://tfhub.dev/google/aiy/vision/classifier/birds_V1/1'
model_yesno = tf.keras.models.load_model('model_yesno.hdf5')
model_eye = tf.keras.models.load_model('model_eye.hdf5')
model_yn1 = tf.keras.models.load_model('yn1_model.h5')
model_birds = tf.keras.Sequential([
        hub.KerasLayer(MODULE_HANDLE, input_shape=IMAGE_SIZE+(3,))
        ])

@app.route('/eye', methods=['POST'])
def eye():
    p = pred(request.form['filename'], model_eye).round(decimals=4)
    return "{0:.4g} {1:.4g}".format(p[0], p[1])

@app.route('/yesnobird', methods=['POST'])
def yesno():
    p = pred(request.form['filename'], model_yesno).round(decimals=4)
    return "{0:.4g} {1:.4g}".format(p[0], p[1])

@app.route('/yesnobird1', methods=['POST'])
def yesno1():
    p = pred1(request.form['filename'], model_yn1).round(decimals=4)
    return "{0:.4g}".format(p)

@app.route('/bird', methods=['POST'])
def bird():
    im = Image.open(request.form['filename']).resize(IMAGE_SIZE)
    im = np.array(im)/255.0
    p = model_birds.predict(im[np.newaxis, ...])
    p = p[0]
    K = int(request.form['K'])
    klargest = np.flip(np.argpartition(p,-K)[-K:])
    #ids = (np.take(p, klargest))
    result = ''
    for i in klargest:
        result += "{0} _ {1:.4g} _ {2}\n".format(i, p[i], birds_dict[i])
    return result

def pred(filename, model):
    image = Image.open(filename)

    size = (224, 224)
    image = ImageOps.fit(image, size, Image.ANTIALIAS)
    image_array = np.asarray(image)
    normalized_image_array = (image_array.astype(np.float32) / 127.0) - 1
    data = np.ndarray(shape=(1, 224, 224, 3), dtype=np.float32)
    data[0] = normalized_image_array
    prediction = model.predict(data).flatten()
    print(prediction)
    return prediction

def pred1(filename, m):
    i = tf.keras.preprocessing.image.load_img(filename, target_size = (224, 224))
    ia = tf.keras.preprocessing.image.img_to_array(i)
    iae = tf.expand_dims(ia, 0)
    return m.predict(iae)[0][0]

