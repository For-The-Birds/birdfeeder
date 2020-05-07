import tensorflow.keras
from PIL import Image, ImageOps
import numpy as np
import sys
from flask import Flask, request
app = Flask(__name__)

np.set_printoptions(suppress=True)

model = tensorflow.keras.models.load_model('keras_model.h5')

data = np.ndarray(shape=(1, 224, 224, 3), dtype=np.float32)

@app.route('/yesnobird', methods=['POST'])
def yesno():
    p = yesnobird(request.form['filename']).round(decimals=4)
    return "{0:.4g} {1:.4g}".format(p[0], p[1])

def yesnobird(filename):
    image = Image.open(filename)

    #resize the image to a 224x224 with the same strategy as in TM2:
    #resizing the image to be at least 224x224 and then cropping from the center
    size = (224, 224)
    image = ImageOps.fit(image, size, Image.ANTIALIAS)
    image_array = np.asarray(image)
    normalized_image_array = (image_array.astype(np.float32) / 127.0) - 1
    data[0] = normalized_image_array
    prediction = model.predict(data).flatten()
    print(prediction)
    return prediction


