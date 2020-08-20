import tensorflow as tf
import tensorflow as tf
import tensorflow_hub as hub
import PIL
import numpy as np
import matplotlib.pyplot as plt
import sys, json, csv, math

from flask import Flask, request
app = Flask(__name__)

S224 = (224, 224)

np.set_printoptions(suppress=True)

cd = json.load(open('coco_labels.json'))

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

def bird(img):
    im = img.resize(S224)
    im = np.array(im)/255.0
    p = model_species.predict(im[np.newaxis, ...])[0]
    i = np.argmax(p)
    return {'id':i, 'p':p[i], 'name':birds_dict[i]}

def detect_objects(image_filename):
    o = PIL.Image.open(image_filename)
    im = o.resize((320,320))

    image = np.asarray(im)
    input_tensor = tf.convert_to_tensor(image)
    input_tensor = input_tensor[tf.newaxis,...]

    results = ssd(input_tensor)

    result = {key:value.numpy() for key,value in results.items()}

    ret = []

    i=0
    for cls in result['detection_classes'][0]:
        ds = result['detection_scores'][0][i]
        y1, x1, y2, x2 = result['detection_boxes'][0][i]
        db = [x1, y1, x2, y2]
        if ds > 0.5:
            label = cd[str(int(cls))]
            oc = o.crop((np.multiply(db, [*o.size, *o.size])))
            ret.append({'ds':ds, 'db':db, 'label':label, 'oc':oc, 'bird':bird(oc)})
        i = i+1
    return ret

def find_birds(original_image, plt_image):
    detections = detect_objects(original_image)
    plt.figure(figsize=(9, 16))
    l = len(detections)
    i=0
    for d in detections:
        #print(d)
        plt.subplot(math.ceil(l/2), 2, i+1)
        title = "{0} {1:.4g}".format(d['bird']['name'], d['bird']['p'])
        plt.title(title)
        plt.imshow(d['oc'])
        i += 1
    plt.savefig(plt_image)


    return json.dumps(detections, cls=NumpyEncoder)

@app.route('/yesnobird1', methods=['POST'])
def yesno1():
    i = tf.keras.preprocessing.image.load_img(request.form['filename'], target_size = (224, 224))
    ia = tf.keras.preprocessing.image.img_to_array(i)
    iae = tf.expand_dims(ia, 0)
    p = model_yn1.predict(iae)[0][0]
    return "{0:.4g}".format(p)

@app.route('/find_birds', methods=['POST'])
def fb():
    return find_birds(request.form['filename'], request.form['plt_filename'])
