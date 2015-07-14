function boxes_nms = DetectionWRotation( ...
                        model, im, nms_threshold, min_level, ...
                        rotation_range, rotation_step)

if(~exist('min_level', 'var'))
	min_level = 1;
end
if(~exist('rotation_range','var'))
	rotation_range = 0;
	rotation_step = 10;
end

tic
all_boxes = [];
cent = [size(im,1)/2, size(im,2)/2];
rots = -rotation_range : rotation_step : rotation_range;
parfor r  = 1 : length(rots)
	fprintf('rotation: %.2f\n', rots(r));
	rot_angle = rots(r);
	im_rot = RotateAround(im, cent(2), cent(1), rot_angle);
	rot_boxes = DetectDetect(im_rot, model, min_level);
	
	if ~isempty(rot_boxes)
		for j = 1:length(rot_boxes)

			rot_boxes(j).cxy = [mean(rot_boxes(j).xy(:,[1 3]), 2) mean(rot_boxes(j).xy(:, [2 4]), 2)];
			numpart = size(rot_boxes(j).xy, 1);
			if numpart == 1
				x1 = rot_boxes(j).xy(1);
				y1 = rot_boxes(j).xy(2);
				x2 = rot_boxes(j).xy(3);
				y2 = rot_boxes(j).xy(4);
			else
				x1 = min(rot_boxes(j).cxy(:, 1));
				y1 = min(rot_boxes(j).cxy(:, 2));
				x2 = max(rot_boxes(j).cxy(:, 1));
				y2 = max(rot_boxes(j).cxy(:, 2));
			end
			rect = [x1 y1; x1 y2; x2 y2; x2 y1];
			rot_boxes(j).area = abs(x1 - x2) * abs(y1 - y2);
			rot_boxes(j).rect = RotatePoints(rect, cent, rot_angle);

			rot_boxes(j).ang = rot_angle;
			rot_boxes(j).rot_cent = cent;

			rot_boxes(j).xy(:, [1 2])  = RotatePoints(rot_boxes(j).xy(:, [1 2]), cent, rot_angle);
			rot_boxes(j).xy(:, [3 4])  = RotatePoints(rot_boxes(j).xy(:, [3 4]), cent, rot_angle);
			rot_boxes(j).cxy = RotatePoints(rot_boxes(j).cxy, cent, rot_angle);
		end
		all_boxes = [all_boxes rot_boxes];
	end
end

boxes_nms = NmsFaceWRotation(all_boxes, nms_threshold);
fprintf('Number of boxes after nms (with threshold %.2f) is %d (out of %d).\n',  ... 
		nms_threshold, length(boxes_nms), length(all_boxes));
image_id = 0;%warning
boxes_nms = BoxesInfo(boxes_nms, model, [0 0], false);
for j = 1 : length(boxes_nms)
	boxes_nms(j).id = image_id;
end
toc

