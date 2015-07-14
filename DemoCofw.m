%%%%% Note: for more info about some of the parameters, check the comments
%%%%% of Demo.m file.

function DemoCofw()
init;

% Loads pre-trained HPM model for localization.
load('cache/HPM_final.mat');

% Visualizes the model
disp('Model visualization ...');
VisualizeModel(model);

options = [];
options.occ_bias_inc = 0;

options.interval = 5;
model.interval = options.interval;;

model.feature_map_padding = 0;

options.cachedir = 'cache/';
options.figdir = 'cache/figdir/';
options.experiment_name = 'HPM';

% index of eyes keypoints in the ground-truth for computing
% the distance between centers of eyes.
options.left_eye_inds = 17;
options.right_eye_inds = 18;

% Highest score configuration with at least options.overlap_threshold
% with the gound-truth bounding box will be returned as a solution.
options.overlap_threshold = 0.7;
% The overlap of bounding box of options.keypoint_subset keypoints with the ground truth bbox
% will be computed and the best solution with at least overlap_threshold will be returned.
% since COFW bounding boxes are tight bounding boxes around its 29 keypoints,
% the bounding box of non-jaw keypoints should be used.
options.keypoint_subset = 1 : 52;

% Minimum level of feature pyramid that the model is run. Since, running the 
% model on the low level of feature pyramid (corresponding to upsampled image) 
% is computationaly expensive,  we can restrict the minimum level.
options.min_level = 1;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf('Landmark localization on the validation data (COFW train data) ...\n');
% Runs the model on the validation data and use the 68 landmark localization
% resutls to learn a mapping from 68 keypoints to 29 (COFW) keypoints.
% Also in landmark localization problem we are given the boundig box of 
% keypoints, so we know the rough scale of the face. Therefore, we don't need
% to run the model on all the levels of the feature pyramid.
% We can run the model on validation data for all or most of the levels and
% learns the range of boundig box sizes on the fired levels. (bounding boxes
% of validation data and test data should be similar)

% We rotate the validation data to be vertical, so we don't need to 
% run the model for different rotations of them.
options.rotation_range = 0;
options.rotation_step = 1;

% Images will be cropped bye option.pad_ratio padding around the bounding boxes,
% and algorithm will be run on the cropped images.
options.pad_ratio = 0.1;

% Runs the model on all the levels for the validation data.
options.limited_level = false;

options.cofw_train_data_file = '../databases/COFW_train.mat';
options.cofw_train_images_dir = '../databases/cofw_train/';

validation_data_name = 'cofw_train';
options.test_name = validation_data_name;

try
	load([options.cachedir validation_data_name]);
catch
	validation = CofwData(options.cofw_train_data_file, ...
                          options.cofw_train_images_dir, 1);
	save([options.cachedir validation_data_name], 'validation');
end
%VisualizeData(validation);

% Runs model on the validation data
validation_boxes = LocalizationsWORotation(validation, model, options);
%VisualizeLocalizationRes(validation_boxes, 'det68', 'occ68', validation, 'cofw_train', options.figdir, 1, 1, 1);

% Sets the minimum and maximum size of the ground-truth boxes on the
% levels that model is fired, based on the validation data.
[model.min_bbox, model.max_bbox, model.min_bbox68, model.max_bbox68] = ...
    ComputeReqLevels(validation, validation_boxes, model.interval);
save('cache/HPM_final_bbox.mat', 'model');

% Computes 29 keypoints locations using nearest keypoint(s).
for i = 1 : length(validation_boxes)
	[validation_boxes{i}.det_sim_29, validation_boxes{i}.occ29] = ...
        Mapping68kToCofw29(validation_boxes{i}.det68, ...
						   validation_boxes{i}.occ68);
end

[errors, precision, recall] = LandmarkLocalizationEval( ...
    validation_boxes, 'det_sim_29', 'occ29', validation, ...
    options.left_eye_inds, options.right_eye_inds);
%VisualizeLocalizationRes(validation_boxes, 'det_sim_29', 'occ29', validation, 'cofw_train', options.figdir, 1, 1, 1);

% Learns mapping from 68 keypoints to 29 keypoints.
mapping_2_hpm_parts = CofwKeypointsToHpmParts();
save_c68_to_29_add = 'cache/c68to29';
try
	load(save_c68_to_29_add, 'c68to29');
catch
	c68to29 = LearnRegression(validation, validation_boxes, errors, ...
					            model, mapping_2_hpm_parts);
	save(save_c68_to_29_add, 'c68to29');
end
model.c68to29 = c68to29;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Benchmarks the model on the COFW test data.
fprintf('Landmark localization on the COFW test data ...\n');
options.test_name = 'cofw_test';
options.limited_level = true;
options.rotation_step = 6;
options.rotation_range = 30;
options.pad_ratio = 0.2;
model.feature_map_padding = 0;

options.cofw_test_data_file = '../databases/COFW_test.mat';
options.cofw_test_images_dir = '../databases/cofw_test/';
test_data_name = 'cofw_test';
try
	load([options.cachedir test_data_name]);
catch
	test = CofwData(options.cofw_test_data_file, ...
                    options.cofw_test_images_dir, 0);
	save([options.cachedir test_data_name], 'test');
end
%VisualizeData(test);

options.occ_bias_inc = -0.1;
modelo = model;
model = ChangeBiasOfOccKeypoints(model, options.occ_bias_inc);

%profile on;
boxes = LocalizationsWRotation(test, model, options);
%p = profile('info');
%profsave(p, [options.cachedir 'profile_test_cofw']);
%VisualizeLocalizationRes(boxes, 'det68', 'occ68', test, 'cofw_test', options.figdir, 1, 1, 0);

% computes 29 keypoints locations using nearest keypoint(s).
for i = 1 : length(boxes)
    if ~isempty(boxes{i})
		[boxes{i}.det_sim_29, boxes{i}.occ29] = ...
            Mapping68kToCofw29(boxes{i}.det68, boxes{i}.occ68);
        boxes{i}.det29 = ApplyRegression(boxes{i}, model.c68to29);
    end
end

[errors, precision, recall] = LandmarkLocalizationEval( ...
    boxes, 'det29', 'occ29', test, options.left_eye_inds, ...
    options.right_eye_inds);
% Prints results.
ave_errors = nanmean(errors);
failure_rate = sum(errors > 0.1) / length(errors) * 100;
fprintf('Average Error: %.3f, Failure rate(at the thresh 0.1): %.2f%% ', ave_errors, failure_rate);
fprintf('(normalized by the distance between the centers of eyes)\n');
fprintf('recall: %.3f precision %.3f\n', recall, precision);
fprintf('number of nan: %d\n', sum(isnan(errors)));

max_to_show = 5;
crop_images = 0; 
show_groundtruth = 0; 
show_keypoint_num = 0;
%VisualizeLocalizationRes(boxes, 'det29', 'occ29', test, 'cofw_test', ...
%             			 options.figdir, crop_images, show_groundtruth, ...
%						 show_keypoint_num, errors, max_to_show);
VisualizeLocalizationRes(boxes, 'det68', 'occ68', test, 'cofw_test', ...
             			 options.figdir, crop_images, show_groundtruth, ...
						 show_keypoint_num, errors, max_to_show);

fprintf(['Press any key to change the alpha parameter and compute' ...
		' precision/recall curve for occlusion prediction.\n']);
pause;

ChangeAlpha(modelo, test, options.test_name, options);
