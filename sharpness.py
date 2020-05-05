from PIL import Image
import numpy as np
import sys

im = Image.open(sys.argv[1]).convert('L') # to grayscale
array = np.asarray(im, dtype=np.int32)

gy, gx = np.gradient(array)
gnorm = np.sqrt(gx**2 + gy**2)
sharpness = np.average(gnorm)
print(sharpness)


#A similar number can be computed with the simpler numpy.diff instead of numpy.gradient. The resulting array sizes need to be adapted there:
#
#dx = np.diff(array)[1:,:] # remove the first row
#dy = np.diff(array, axis=0)[:,1:] # remove the first column
#dnorm = np.sqrt(dx**2 + dy**2)
#sharpness = np.average(dnorm)
