from imageatm.components import DataPrep
from imageatm.components import Training

import sys


dp = DataPrep(
    image_dir = 'images224/',
    samples_file = 'data-%s.json' % sys.argv[1],
    job_dir = 'jobdir-%s' % sys.argv[1]
)

dp.run(resize=False)

"""
https://github.com/idealo/imageatm/blob/master/imageatm/components/training.py

Builds model and runs training.
The following pretrained CNNs from Keras can be used for transfer learning:
- Xception
- VGG16
- VGG19
- ResNet50, ResNet101, ResNet152
- ResNet50V2, ResNet101V2, ResNet152V2
- ResNeXt50, ResNeXt101
- InceptionV3
- InceptionResNetV2
- MobileNet
- MobileNetV2
- DenseNet121, DenseNet169, DenseNet201
- NASNetLarge, NASNetMobile
Training is split into two phases, at first only the last dense layer gets
trained, and then all layers are trained. The maximum number of epochs for
each phase is set by *epochs_train_dense* (default: 100) and
*epochs_train_all* (default: 100), respectively. Similarly,
*learning_rate_dense* (default: 0.001) and *learning_rate_all*
(default: 0.0003) can be set.
For each phase the learning rate is reduced after a patience period if no
improvement in validation accuracy has been observed. The patience period
depends on the average number of samples per class:
- if n_per_class < 200: patience = 5 epochs
- if n_per_class >= 200 and < 500: patience = 4 epochs
- if n_per_class >= 500: patience = 2 epochs
The training is stopped early after a patience period that is three times
the learning rate patience to allow for two learning rate adjustments
with no validation accuracy improvement before stopping training.
Attributes:
    image_dir: Directory with images used for training.
    job_dir: Directory with train_samples.json, val_samples.json,
                and class_mapping.json.
    epochs_train_dense: Maximum number of epochs to train dense layers (default 100).
    epochs_train_all: Maximum number of epochs to train all layers (default 100).
    learning_rate_dense: Learning rate for dense training phase (default 0.001).
    learning_rate_all: Learning rate for all training phase (default 0.0003).
    batch_size: Number of images per batch (default 64).
    dropout_rate: Fraction of nodes before output layer set to random value (default 0.75).
    base_model_name: Name of pretrained CNN (default MobileNet).
"""

trainer = Training(
     dp.image_dir,
     dp.job_dir,
     epochs_train_dense=5,
     epochs_train_all=2,
     batch_size=64,
)

trainer.run()

