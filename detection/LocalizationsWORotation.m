function boxes = LocalizationsWORotation(test, model, options)
% This method uses the ground-truth locations (validation data) of the 
% eyes to find the rotation of the face and rotates the image so that the 
% face be vertical. Then, it performs the landmark localization.

filename = BoxesFilename(options);

try
	load(filename)
catch
	save_boxes_add = [options.cachedir 'boxes_' filename(7 : end) '/'];
	if(~exist(save_boxes_add, 'dir'))
		mkdir(save_boxes_add);
	end

	startmatlabpool();
	parfor i = 1 : length(test)
    	fprintf('testing on (%d/%d) : %s\n', i, length(test), test(i).id);
		box_filename = [save_boxes_add 'box_' test(i).id];
		try
			lb = load(box_filename);
			boxes{i} = lb.bs;
			fprintf('Saved result loaded.\n');
		catch
			I = imread(test(i).im);
			bbox = test(i).bbox;

			% Finds the rotation of the face.
			[rot_ang, I_ver, pts_ver, rot_cent]= RotateFace( ...
                I, test(i).pts, options.left_eye_inds, options.right_eye_inds);
			bs = TestLocalization(...
                    model, I, bbox, options.keypoint_subset,...
					options.overlap_threshold, options.limited_level, ...
					options.min_level, 2, rot_ang, rot_ang, ...
                    options.pad_ratio, rot_cent);
			parforsave(box_filename, bs);
			boxes{i} = bs;
		end

	end
	closematlabpool();
	save(filename, 'boxes');
	rmdir(save_boxes_add, 's');
end

function parforsave(filename, bs)
save(filename, 'bs');
