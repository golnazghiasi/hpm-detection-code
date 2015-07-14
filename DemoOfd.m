%%%%% Note: for more info about some of the parameters, check the comments
%%%%% of Demo.m file.

init;

% Loads pre-trained multi-resolution HPM model.
load('cache/HPM_multi_res_final.mat');

% Visualizes the model
disp('Model visualization ...');
VisualizeModel(model);

options = [];
options.occ_bias_inc = 0;
model = ChangeBiasOfOccKeypoints(model, options.occ_bias_inc);

options.rotation_range = 20;
options.rotation_step = 10;

model.feature_map_padding = 0;

options.nms_threshold = 0.4;

options.cachedir = 'cache/';
options.figdir = 'cache/figdir/';
options.experiment_name = 'HPM';
options.test_name = 'OFD';

options.interval = 5;
model.interval = options.interval;;

for i = 1 : 3
	model.min_scale(i) = -1; 
	model.max_scale(i) = 1;  
end
for i = 4 : length(model.components)
	model.min_scale(i) = 60/100; 
	model.max_scale(i) = 1;
end

model.thresh = -0.5;

filename = BoxesFilename(options);
try
    load(filename);
catch
    save_boxes_add = [options.cachedir 'boxes_' filename(7 : end) '/'];
    if(~exist(save_boxes_add, 'dir'))
        mkdir(save_boxes_add);
    end

	ims = dir('UCI_OFD/OFD/*.jpg');
	startmatlabpool();
	gt = [];
	for i = 1 : length(ims)
		gt(i).im = ['UCI_OFD/OFD/' ims(i).name];
		gt(i).id = ims(i).name(1:end-4);
	end
	%profile on;
	for i = 1 : length(ims)
    	fprintf('testing on (%d/%d) : %s\n', i, length(ims), ims(i).name);
		I = imread(gt(i).im);
		box_filename = [save_boxes_add 'box_' gt(i).id];
        try
			load(box_filename, 'bs');
			fprintf('Saved result loaded.\n');
        catch
			siz = size(I);
			fprintf('image size is %d %d %d\n', siz(1), siz(2), siz(3));
            bs = DetectionWRotation( ...
            		model, I, options.nms_threshold, 1, ...
                    options.rotation_range, options.rotation_step);
			save(box_filename, 'bs');
        end
		boxes{i} = bs;
		for j = 1 : length(boxes{i})
			boxes{i}(j).id = ims(i).name(1:end-4);
		end
        % Visualizes the detections.
        clf; imagesc(I); axis image; axis off; drawnow; hold on;
        if(size(I, 3) == 1)
            colormap(gray);
        end

        for b = boxes{i}
            plot(b.det(b.occ == 1, 1), b.det(b.occ == 1, 2), ...
                '.r', 'MarkerSize', 10);
            plot(b.det(b.occ == 0, 1), b.det(b.occ == 0, 2), ...
                '.g', 'MarkerSize', 10);
            drawnow;
        end
	end
	%p = profile('info');
	%profsave(p, [options.cachedir 'profile_test_ofd']);

	save(filename, 'boxes', 'gt');
    rmdir(save_boxes_add, 's');
end

confidence = [];
BB = zeros(4, 0);
ids = cell(0, 1);
for i = 1 : length(boxes)
	for j = 1 : length(boxes{i})
		xy = boxes{i}(j).xy;
		if(size(xy, 1) == 1)
			BB(:, end+1) = xy;
		elseif(size(xy, 1) == 7)
			bb = [min(xy(:, 1)), min(xy(:, 2)), ...
					 max(xy(:, 3)), max(xy(:, 4))];
			sc = bb(3) - bb(1) + bb(4) - bb(2);
			bb(1) = bb(1) + sc/15;
			bb(2) = bb(2) + sc/20;
			bb(3) = bb(3) - sc/15;
			bb(4) = bb(4) - sc/20;
			BB(:, end+1) = bb;
		else
			BB(:, end+1) = [min(xy(:, 1)), min(xy(:, 2)), ...
					 max(xy(:, 3)), max(xy(:, 4))];
		end
		confidence(end+1) = boxes{i}(j).s;
		ids{end + 1} = boxes{i}(j).id;
		boxes{i}(j).BB = BB(:, end);
	end
end
   
save_res_add =  'cache/HPM_multi_res_HELEN68_PASCAL_OFD.txt';
PrintDetectionResToFile(BB', ids, confidence, save_res_add);

cur_dir = pwd;
cd 'UCI_OFD'
Main([cur_dir '/'  save_res_add], '*Multi-resolution HPM');
cd(cur_dir);

if 1
    fprintf('Visualizing the detection results ...\n');
    save_vis_res = [options.figdir options.experiment_name '_' ...
                    options.test_name  '/'];
	max_to_show = 5;
	figure;
    VisualizeDetectionRes(gt, boxes, save_vis_res, -0.3, max_to_show);
end
