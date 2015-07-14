## Occlusion Coherence: Detecting and Localizing Occluded Faces
This is the code for the method described in:

[Golnaz Ghiasi, Charless Fowlkes, "Occlusion Coherence: Detecting and Localizing Occluded Faces" , Technical Report, June 2015, arXiv:1506.08347](http://arxiv.org/pdf/1506.08347.pdf)

[Golnaz Ghiasi, Charless Fowlkes, "Occlusion Coherence: Localizing Occluded Faces with a Hierarchical Deformable Part Model" , (CVPR) 2014](http://www.ics.uci.edu/~gghiasi/papers/gf-cvpr14.pdf)


This library is written in Matlab, and is based on the following two works:

* [Face Detection, Pose Estimation and Landmark Localization in the Wild](http://www.ics.uci.edu/~xzhu/face/)


* [Articluated Pose Estimation with Flexible Mixtures of Parts](http://www.ics.uci.edu/~yyang8/research/pose/index.html)


---- 

## Quick start guide

This code is tested on Linux. Pre-compiled Mex files for linux are inlcuded.

### Download and compile
``` sh
 cd PATH
 git clone git://github.com/golnazghiasi/hpm-detection-code.git
 cd hpm-detection-code/
 matlab
>> compile
```


### Runs face detection using pre-trained model on the images in the photo directory.
``` sh
 cd PATH/hpm-detection-code/
 matlab
>> Demo
```

### Benchmarks landmark localization on the COFW test data.
Download COFW data:
``` sh
 cd PATH
 mkdir databases/
 cd databases/
 wget http://www.vision.caltech.edu/xpburgos/ICCV13/Data/COFW.zip
 unzip COFW.zip
 mv common/xpburgos/behavior/code/pose/COFW_test.mat .
 mv common/xpburgos/behavior/code/pose/COFW_train.mat .
```

``` sh
 cd PATH/hpm-detection-code/
 matlab
>> DemoCofw
```
This will load the pre-computed results. To run the detection code on the COFW test dataset,
remove or rename the following files:
``` sh
 PATH/hpm-detection-code/cache/HPM_cofw_*
 PATH/hpm-detection-code/cache/changealpha/*
```

### Benchmarks face detection on the UCI-OFD test data.
``` sh
 cd PATH/hpm-detection-code/
 matlab
>> DemoOfd
```
This will load the pre-computed results. To run the detection code on the UCI-OFD dataset,
remove or rename the following file:
``` sh
 PATH/hpm-detection-code/cache/HPM_OFD_*
```

### Benchmarks landmark localization on LFW test data.
Note: our model is trained on the front view training data, while this dataset 
has many side view faces.

Download LFW data:
``` sh
 cd PATH/databases/
 wget http://www.vision.ee.ethz.ch/~mdantone/datasets/lfw_ffd_ann.txt
 wget http://vis-www.cs.umass.edu/lfw/lfw.tgz
 tar zxvf lfw.tgz
```

``` sh
 cd PATH/hpm-detection-code/
 matlab
>> DemoLFW
```

This will load the pre-computed results. To run the detection code on the LFW test dataset,
remove or rename the following files:
``` sh
 PATH/hpm-detection-code/cache/HPM_lfw_*
```

----

### Issues, Questions, Congratulations, etc

Please contact "gghiasi @ ics.uci.edu"

--- -
**Copyright (C) 2015 Golnaz Ghiasi, Charless Fowlkes**

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

