function [min_bbox, max_bbox, min_bbox68, max_bbox68] = ComputeReqLevels(test, boxes, interval)

% In the landmark localization we have the sizes of bounding boxes.
% So if the training and testing data have similar bounding boxes,
% we can use thsese sizes and avoid to run the model on the levels of the
% feature pyramid that the ground-truth bounding box is very large or very
% small.
% This method computes the minimum and maximum size of the ground-truth 
% boxes on the levels that model is fired.

% test : ground truth
% boxes: Results of running of the model on all the levels for vericication
% data. We need the level which the model was fired.

levels = [];
box_sizes = [];
box_sizes_68 = [];
for i = 1 : length(test)
    bs = boxes{i};
    if(isempty(bs))
        continue;
    end
	bbox = test(i).bbox;
    bbox68 = [min(bs.det68(:, 1)), min(bs.det68(:, 2)), ...                          
              max(bs.det68(:, 1)), max(bs.det68(:, 2))];  

    if(isfield(bs, 'level'))
        levels = [levels, bs.level];
		box_sizes = [box_sizes, (bbox(3) - bbox(1) + bbox(4) - bbox(2)) / 2];
        box_sizes_68 = [box_sizes_68, ...                                            
                    ((bbox68(3) - bbox68(1)) + (bbox68(4) - bbox68(2))) / 2];  
    end
end

sc = 2 ^ (1 / interval);
x = 2 ./ (sc .^ [0 : 60]);
sizes = x(levels) .* box_sizes;
min_bbox = min(sizes) - 10;
max_bbox = max(sizes) + 10;

% Computes the min and max of the sizes of the 68 keypoints boundig boxes. 
sizes = x(levels) .* box_sizes_68;
min_bbox68 = min(sizes) - 10;
max_bbox68 = max(sizes) + 10;

