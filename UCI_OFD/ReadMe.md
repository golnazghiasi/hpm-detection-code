This directory contains UCI-OFD dataset which is introduced in the following paper:

[Golnaz Ghiasi, Charless Fowlkes, 
"Occlusion Coherence: Detecting and Localizing Occluded Faces", 
Technical Report, June 2015] [arXiv:1506.08347](http://arxiv.org/pdf/1506.08347.pdf)

"OFD" directory contains dataset images and the annotations are stored in 
"OFD/annotations.mat". For each image, this file has bounding boxes of the
faces and labels that indicate the level of occlusion of faces (0 -> visible, 
1-> occluded, 2-> at least one of the inner parts of the face is occluded by
something other than glass!). ShowAnnotation.m visualizes the annotations.

To evaluate your model, generate a file that contains the detections info and
specify its address and name in Main.m.
Each line of the file should contain image id, bounding box coordinates and
detection score for one face.
image_id bbox_x1 bbox_y1 bbox_x2 bbox_y2 score


