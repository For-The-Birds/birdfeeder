import tensorflow as tf
import tensorflow as tf
import tensorflow_hub as hub
import PIL
import numpy as np
import matplotlib.pyplot as plt
import os, sys, json, csv, math

from flask import Flask, request

S224 = (224, 224)

np.set_printoptions(suppress=True)

coco_labels = json.load(open('coco_labels.json'))

reader = csv.reader(open('aiy_birds_V1_labelmap.csv'))
next(reader, None) # skip header
birds_dict = dict((int(rows[0]),rows[1]) for rows in reader)

class NumpyEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, np.integer):
            return int(obj)
        elif isinstance(obj, np.floating):
            return float(obj)
        elif isinstance(obj, np.ndarray):
            return obj.tolist()
        elif isinstance(obj, float):
            return str(obj)
        elif isinstance(obj, PIL.Image.Image):
            return str(obj.size)
        return json.JSONEncoder.default(self, obj)

ssd = hub.load("https://tfhub.dev/tensorflow/ssd_mobilenet_v2/fpnlite_320x320/1")

birds_V1 = 'https://tfhub.dev/google/aiy/vision/classifier/birds_V1/1'
model_species = tf.keras.Sequential([
        hub.KerasLayer(birds_V1, input_shape=S224+(3,))
        ])

model_yn1 = tf.keras.models.load_model('yn1_model.h5')
model_eye = tf.keras.models.load_model('eye_crop_model.h5')

app = Flask(__name__)

def sharpness(img):
    im = img.convert('L') # to grayscale
    array = np.asarray(im, dtype=np.int32)

    gy, gx = np.gradient(array)
    gnorm = np.sqrt(gx**2 + gy**2)
    return np.average(gnorm)

def bird_eye(oc):
    ia = tf.keras.preprocessing.image.img_to_array(oc)
    iae = tf.expand_dims(ia, 0)
    return model_eye.predict(iae)[0][0]

def bird(im):
    #im = img.resize(S224)
    im = np.array(im)/255.0
    p = model_species.predict(im[np.newaxis, ...])[0]
    i = np.argmax(p)
    return {'id':i, 'p':p[i], 'name':birds_dict[i]}

def detect_objects(image_filename):
    o = PIL.Image.open(image_filename)
    im320 = o.resize((320,320))
    input_tensor = tf.convert_to_tensor(np.asarray(im320))
    input_tensor = input_tensor[tf.newaxis,...]

    results = ssd(input_tensor)
    result = {key:value.numpy() for key,value in results.items()}

    ret = []
    r = zip(result['detection_classes'][0], result['detection_scores'][0], result['detection_boxes'][0])
    for cls, ds, db_wtf in r:
        if ds < 0.5:
            continue
        icls = int(cls)
        if icls != 16:
            continue
        label = coco_labels[str(icls)]
        y1, x1, y2, x2 = db_wtf
        db = [x1, y1, x2, y2]
        oc = o.crop((np.multiply(db, [*o.size, *o.size])))
        oc224 = oc.resize(S224)
        ret.append({
            'dc':cls,
            'ds':ds,
            'db':db,
            'label':label,
            'oc':oc,
            'sharpness':sharpness(oc224),
            'eye':bird_eye(oc224),
            'bird':bird(oc224)})
    return ret

def find_birds(original_image, plt_image):
    detections = detect_objects(original_image)
    if plt_image is not None:
        plt.figure(figsize=(9, 16))
        l = len(detections)
        i=0
        for d in detections:
            #print(d)
            plt.subplot(l, 1, i+1)
            title = "{0} {1:.4g}".format(d['bird']['name'], d['bird']['p'])
            plt.title(title)
            plt.imshow(d['oc'])
            i += 1
        plt.savefig(plt_image)
        plt.close()

    #max_eye = np.max([ d['eye'] for d in detections ])
    return detections

@app.route('/yesnobird1', methods=['POST'])
def yesno1():
    i = tf.keras.preprocessing.image.load_img(request.form['filename'], target_size = (224, 224))
    ia = tf.keras.preprocessing.image.img_to_array(i)
    iae = tf.expand_dims(ia, 0)
    p = model_yn1.predict(iae)[0][0]
    return "{0:.4g}".format(p)

@app.route('/find_birds', methods=['POST'])
def fb():
    ret = find_birds(request.form['filename'], request.form.get('plt_filename'))
    if 'save_crop' in request.form:
        i=0
        for d in ret:
            ocfn = "{}/{:04.02f}-{:04.02f}-{}-{}.jpg".format(
                    request.form['save_crop'],
                    d['eye'],
                    d['sharpness'],
                    os.path.basename(request.form['filename'])[:-4],
                    i)
            d['crop_filename'] = ocfn
            d['oc'].save(ocfn)
            i += 1
    return json.dumps(ret, cls=NumpyEncoder)

