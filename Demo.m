init;

% Loads pre-trained HPM multi resolution model.
load('cache/HPM_multi_res_final.mat');

% Visualizes the model
%disp('Model visualization ...');
%VisualizeModel(model);

options = [];
% Sets the parameter alpha to change the bias of the model toward occlusion 
% prediction.
% larger value for this parameter --> higher recall of occlusion
options.occ_bias_inc = 0;
model = ChangeBiasOfOccKeypoints(model, options.occ_bias_inc);

options.cachedir = 'cache/';
options.figdir = 'cache/figdir/';
options.experiment_name = 'demo_det';
options.limited_level = true;

% Runs the model on 3 rotations (-14, 0, 14) of the test image to
% detect rotated faces.
% More rotations better results, but slower model.
options.rotation_range = 14;
options.rotation_step = 14;

% Number of HoG cells to be padded to the test image. It is helpful for finding the
% cropped faces. But, larger value will increase the running time.
model.feature_map_padding = 0;

% nms threshold
options.nms_threshold = 0.4;

% The scale between the images of two consecutive level of the feature pyramid
% is 2^(1/model.interval). larger values --> more level in feature pyramid --> 
% searches over more scales of the image and the results look better
% --> but increasing running time.
options.interval = 5;
model.interval = options.interval;;

% Based on the size of the faces that we want our model to detect, sets the 
% min_scale and max_scale parameters:

% Sets the high resolution components should be run on which scales of the image
% (or which levels of the the feature pyramid).
% High resolution components are about 100 pixels tall.
for i = 1 : 3
	model.min_scale(i) = -1; 
	% --> no restriction on the maximum face height
	model.max_scale(i) = 1;  
	% --> minimum face height of about 100 pixels.
end
% Sets the low resolution components should be run on which scales of the image.
% (or which levels of the feature pyramid).
% Low resolution components are about 60 pixels tall.
for i = 4 : length(model.components)
	model.min_scale(i) = 60/100; 
	% --> image scale >= 0.6 --> model scale <= 100/60 --> maximum face height = 100/60 * 60 = 100 pixels. 
	model.max_scale(i) = 1;
	% --> image scale <= 1 --> model scale >= 1 --> minimum face height = 60
	% With this setting low resolution components detect faces between 60
	% to 100 pixels high (eyebrow to chin) (They can detect a little smaller or 
	% larger faces because of the deformation).
end
% To detect smaller faces we can increase the max_scale parameter up to 2. But,
% it will increase the running time of the model.

% lower thresh --> higher recall of face detection, also increasing running time!
model.thresh = -0.25;

% Runs the model in the images in photos directory.
ims = dir('photos/*.jpg');
ims = [ims; dir('photos/*.png')];

startmatlabpool();
for i = 1 : length(ims)
    fprintf('testing on (%d/%d) : %s\n', i, length(ims), ims(i).name);
    I = imread(['photos/' ims(i).name]);
	siz = size(I);
	fprintf('image size is %d %d %d\n', siz(1), siz(2), siz(3));
    clf; imagesc(I); axis image; axis off; drawnow; hold on; 
    if(size(I, 3) == 1)
        colormap(gray);
    end
    
    boxes = DetectionWRotation(model, I, options.nms_threshold, 1, ...
        options.rotation_range, ...
        options.rotation_step);
    for b = boxes,
        plot(b.det(b.occ == 1, 1), b.det(b.occ == 1, 2), '.r', ...
            'MarkerSize', 10);
        plot(b.det(b.occ == 0, 1), b.det(b.occ == 0, 2), '.g', ...
            'MarkerSize', 10);
    end
	fprintf('Press any key to continue\n');
    pause;
end
closematlabpool();
