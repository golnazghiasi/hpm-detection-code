function bs = TestLocalization( ...
                  model, im, bbox, keypoint_subset, min_overlap, ...
                  limited_level, min_level, rotation_step, ...
                  min_rotation_range, max_rotation_range, pad_ratio, ...
                  rot_center)

tic

[im_crop, bbcrop, offset] = croppos(im, bbox, pad_ratio);
rots = min_rotation_range : rotation_step : max_rotation_range;
if(~exist('rot_center', 'var'))
	cent = [size(im_crop, 1) / 2, size(im_crop, 2) / 2];
else
	% For the validation data we pre computed the rotation of the image and
	% the center of the rotation.
	cent = rot_center - offset;
end
% Finds best detection for different rotation of the image.
for min_overlap_ = [min_overlap, 0.5, 0.1 0.05]
	all_boxes = cell(1, length(rots));

	if(length(rots) == 1)
		rot_ang = rots;
		fprintf('rotation angle : %.3f\n', rot_ang);
		im_rotated = RotateAround(im_crop, cent(2), cent(1), rot_ang);
	
		rot = struct('cent', cent, 'ang', rot_ang);
		bs = DetectGivendet(im_rotated, model, bbcrop, min_overlap_, ...
							keypoint_subset, rot, limited_level, ...
                            min_level);
		if(~isempty(bs))
			[bs.ang] = deal(rot_ang);
			[bs.rot_cent] = deal(cent);
			all_boxes{1} = bs;
		end
	else

		parfor r  = 1 : length(rots)
			rot_ang = rots(r);
			fprintf('%d : rotation angle : %.3f\n', r, rot_ang);
			im_rotated = RotateAround(im_crop, cent(2), cent(1), rot_ang);
			
			rot = struct('cent', cent, 'ang', rot_ang);
			bs = DetectGivendet(im_rotated, model, bbcrop, min_overlap_, ...
								keypoint_subset, rot, limited_level);
			if(~isempty(bs))
				[bs.ang] = deal(rot_ang);
				[bs.rot_cent] = deal(cent);
				all_boxes{r} = bs;
			end
		end
	end

	all_boxes = [all_boxes{:}];
	bs = [];
	if(~isempty(all_boxes))
		% keeps the highest scoring one.
		s = [all_boxes.s];
		[~, I] = sort(s);
		all_boxes = all_boxes(fliplr(I));
		bs = all_boxes(1);

		bs = BoxesInfo(bs, model, offset);	
		bs = clipboxes(im, bs);

		% We have found a detection with overlap of min_overlap_. 
		% So we don't need to test lower overlaps.
		break;
	end
end

toc


function boxes = clipboxes(im, boxes)
% Clips boxes to image boundary.
imy = size(im, 1);
imx = size(im, 2);
for i = 1 : length(boxes),
    b = boxes(i).xy;
    b(:, 1) = max(b(:, 1), 1);
    b(:, 2) = max(b(:, 2), 1);
    b(:, 3) = min(b(:, 3), imx);
    b(:, 4) = min(b(:, 4), imy);
    boxes(i).xy = b;
    if(isfield(boxes(i), 'xy68'))
        b = boxes(i).xy68;
        b(:, 1) = max(b(:, 1), 1);
        b(:, 2) = max(b(:, 2), 1);
        b(:, 3) = min(b(:, 3), imx);
        b(:, 4) = min(b(:, 4), imy);
        boxes(i).xy68 = b;
    end
end

function [im, box, offset] = croppos(im, box, pad_ratio)
% Crops image around bounding box.
pad = pad_ratio * ((box(3) - box(1) + 1) + (box(4) - box(2) + 1));
x1 = max(1, round(box(1) - pad));
y1 = max(1, round(box(2) - pad));
x2 = min(size(im, 2), round(box(3) + pad));
y2 = min(size(im, 1), round(box(4) + pad));

im = im(y1 : y2, x1 : x2, :);
box([1 3]) = box([1 3]) - x1 + 1;
box([2 4]) = box([2 4]) - y1 + 1;

offset(1) = x1 - 1;
offset(2) = y1 - 1;
