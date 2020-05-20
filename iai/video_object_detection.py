from imageai.Detection import VideoObjectDetection
import os, cv2
from PIL import Image

execution_path = os.getcwd()

frame_cache = []
last_bird_frame = -10

camera = cv2.VideoCapture(3)

detector = VideoObjectDetection()
#detector.setModelTypeAsRetinaNet()
#detector.setModelPath( os.path.join(execution_path , "resnet50_coco_best_v2.0.1.h5"))
detector.setModelTypeAsTinyYOLOv3()
detector.setModelPath( os.path.join(execution_path , "yolo-tiny.h5"))
detector.loadModel()
#detector.loadModel(detection_speed="fast")

custom_objects = detector.CustomObjects(bird=True)

def save_cache():
    global last_bird_frame, frame_cache
    for f in frame_cache:
        fname = "frames/bird{0:08d}.jpg".format(f['n'])
        if not os.path.isfile(fname):
            im = Image.fromarray(f['frame'])
            im.save(fname)

def forFrame(frame_number, output_array, output_count, frame):
    global last_bird_frame, frame_cache
    #print("FOR FRAME " , frame_number)
    print("Output for each object : ", output_array)
    print("Output count for unique objects : ", output_count)
    frame_cache.append({'frame':frame, 'n':frame_number})
    if len(frame_cache) > 5:
        frame_cache.pop(0)
    if 'bird' in output_count:
        last_bird_frame = frame_number
        save_cache()
        return
    if frame_number - 5 == last_bird_frame:
        save_cache()



                #output_file_path=os.path.join(execution_path, "birds_custom_detected"),
detector.detectCustomObjectsFromVideo(
    custom_objects=custom_objects,
    camera_input=camera,
    per_frame_function=forFrame,
    return_detected_frame=True,
    save_detected_video=False,
    frames_per_second=5, log_progress=True, minimum_percentage_probability=20)

