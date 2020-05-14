from imageatm.components import DataPrep
from imageatm.components import Training


dp = DataPrep(
    image_dir = 'images/',
    samples_file = 'data-yn.json',
    job_dir = 'jobdir-yn'
)

dp.run(resize=False)

trainer = Training(
     dp.image_dir, dp.job_dir, epochs_train_dense=3, epochs_train_all=1, batch_size=64,
)

trainer.run()

