%%%%% Note: for more info about some of the parameters, check the comments
%%%%% of Demo.m and DemoCofw.m files.

function demo_lfw()
init;

% Loads pre-trained HPM model for localization.
load('cache/HPM_final');

% Visualizes the model
disp('Model visualization ...');
VisualizeModel(model);

options = [];
options.occ_bias_inc = 0;
model = ChangeBiasOfOccKeypoints(model, options.occ_bias_inc);

options.interval = 5;
model.interval = options.interval;;

model.feature_map_padding = 0;

options.cachedir = 'cache/';
options.figdir = 'cache/figdir/';
options.experiment_name = 'HPM';

options.limited_level = false;
options.rotation_range = 10;
options.rotation_step = 5;
options.overlap_threshold = 0.2;

options.keypoint_subset = 1 : 68;
options.pad_ratio = 0;
options.lfw_file_add = '../databases/lfw_ffd_ann.txt';
options.lfw_dir = '../databases/lfw/';

options.left_eye_inds = 1 : 2;
options.right_eye_inds = 7 : 8;

% ---------------------------------------------------------------------------
% Runs HPM on the validation data (subset of LFW images which starts with M!).
options.test_name = 'lfw_val_M';
options.min_level = ceil(model.interval / 2);
try
	load([options.cachedir options.test_name]);
catch
	validation_data = LfwData(options.lfw_file_add, options.lfw_dir, 'M');
	save([options.cachedir options.test_name], 'validation_data');
end

validation_boxes = LocalizationsWORotation(validation_data, model, options);
assert(length(validation_data) == length(validation_boxes));
%VisualizeLocalizationRes(validation_boxes, 'det68', 'occ68', validation_data, 'lfw_M', options.figdir, 1, 1, 0);

% Based on ground truth bounding boxes finds subset of levels that
% we need to run the model based on the size of bounding box
[model.min_bbox, model.max_bbox] = ComputeReqLevels( ...
    validation_data, validation_boxes, model.interval);

% ---------------------------------------------------------------------------
% Runs HPM on the validation data (subset of LFW images which starts with A or B!).
options.test_name = 'lfw_A_B';
filename = BoxesFilename(options);

options.limited_level = true;
options.rotation_step = 6;
options.rotation_range = 30;
options.min_level = 1;

try
	load([options.cachedir options.test_name]);
catch
	test = LfwData(options.lfw_file_add, options.lfw_dir, 'AB');
	save([options.cachedir options.test_name], 'test');
end

fprintf('Landmark localization on the LFW test data ...\n');
boxes = LocalizationsWRotation(test, model, options);

for i = 1 : length(boxes)
    if ~isempty(boxes{i})
        [boxes{i}.det_lfw, boxes{i}.occ_lfw] = Mapping68kToLfw(boxes{i}.det68, boxes{i}.occ68);
    end
end

filename = BoxesFilename(options);
save(filename, 'boxes', 'test');

[errors, precision, recall] = LandmarkLocalizationEval( ...
    boxes, 'det_lfw', 'occ_lfw', test, options.left_eye_inds, ...
	options.right_eye_inds);
% Prints results.
ave_errors = nanmean(errors);
failure_rate = sum(errors > 0.1) / length(errors) * 100;
fprintf('Evaluation %s\n', filename(7 : end));
fprintf('Results on all faces, normalized by the distance between centers of eyes\n');
fprintf('Average Error: %.3f, Failure rate(at thresh 0.1): %.2f%%\n', ave_errors, failure_rate);

% Prints view on frontal view faces.
view_points = [test.headpose];
front_view = [view_points == -1 | view_points == 0 | view_points == 1];
errors_fv = errors(front_view);
ave_errors = nanmean(errors_fv);
failure_rate = sum(errors_fv > 0.1) / length(errors_fv) * 100;

fprintf('------------------------------\n');
fprintf('Results on front view faces, normalized by the distance between centers of eyes\n');
fprintf('Average Error: %.3f, Failure rate(at thresh 0.1): %.2f%%\n', ave_errors, failure_rate);

max_to_show = 5;
crop_images = 0; 
show_groundtruth = 0; 
show_keypoint_num = 0;

VisualizeLocalizationRes(boxes, 'det_lfw', 'occ_lfw', test, 'cofw_test', ...
             			 options.figdir, crop_images, show_groundtruth, ...
						 show_keypoint_num, errors, max_to_show);
%VisualizeLocalizationRes(boxes, 'det68', 'occ68', test, 'cofw_test', ...
%             			 options.figdir, crop_images, show_groundtruth, ...
%						 show_keypoint_num, errors, max_to_show);

