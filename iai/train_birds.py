from imageai.Detection.Custom import DetectionModelTrainer

trainer = DetectionModelTrainer()
trainer.setModelTypeAsYOLOv3()
trainer.setDataDirectory(data_directory="birds01")
trainer.setTrainConfig(
        batch_size=4,
        num_experiments=200,
        train_from_pretrained_model="pretrained-yolov3.h5",
        object_names_array=["bird"])
trainer.trainModel()

