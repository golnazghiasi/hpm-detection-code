function reg_coef = LearnRegression(test, boxes, errors, model, ...
                                    mapping_2_hpm_parts)
% errors: some estimation of the errors (e.g. errors for a simple mapping).
% mapping_2_hpm_parts: a matrix that shows the corresponding hpm part number
% (e.g. nose, eye, upper lip) for each keypoing of the target mapping.
% reg_coef: learned coeficient for linear regression.

fprintf('learning linear regression to map 68 landmarks to %d landmarks.\n', ...
		length(mapping_2_hpm_parts));

X1 = [];
X2 = [];
y1 = [];
y2 = [];

for i = 1 : length(test)
    % Uses only examples with small prediction errors for learning linear 
	% regression.
    if isempty(boxes{i}) || errors(i) > 0.1
        continue;
    end

    gt_pts = test(i).pts;
    b = boxes{i}(1);
    det68 = b.det68;
	if(isfield(boxes{i}, 'ang'))
	% Learns the regression with the assumption that faces are vertical.
    	gt_pts = RotatePoints(gt_pts, boxes{i}.rot_cent, -boxes{i}.ang);
    	det68 = RotatePoints(det68, boxes{i}.rot_cent, -boxes{i}.ang);
    end
    
    X1 = [X1 ; det68(:, 1)'];
    X2 = [X2 ; det68(:, 2)'];
    y1 = [y1 ; gt_pts(:, 1)'];
    y2 = [y2 ; gt_pts(:, 2)'];
end

reg_coef = LearnRegressionCoef(model.opts, X1, X2, y1, y2, ...
                               mapping_2_hpm_parts);

%debugging(boxes, test, left_eye_inds, right_eye_inds, reg_coef, ...
%          errors, model, mapping_2_hpm_parts);

function coef = LearnRegressionCoef(opts, X1,X2,y1,y2, mapping_2_hpm_parts)
x_num_elements = size(X1, 2);
y_num_elements = size(y1, 2);

for i = 1 : size(X1, 1)
    h = max(X1(i, :)) - min(X1(i, :));
    w = max(X2(i, :)) - min(X2(i, :));
    r = (h + w) / 2;
    X1(i, :) = X1(i, :) / r;
    X2(i, :) = X2(i, :) / r;
    y1(i, :) = y1(i, :) / r;
    y2(i, :) = y2(i, :) / r;
end

X = [X1, X2];
X = [ones(size(X, 1), 1), X];
y = [y1, y2];

level_2_parts = opts.mixture(1).level_2_parts;
for i = 1 : length(level_2_parts)
    x_part_num(level_2_parts(i).children) = i;
end
x_part_num(x_part_num == 0) = [];
x_part_num = inv(opts.mixture(1).anno2treeorder)*(x_part_num');
x_part_num = [0 x_part_num' x_part_num'];

y_num_elements = length(mapping_2_hpm_parts);
y_part_num = [mapping_2_hpm_parts mapping_2_hpm_parts];

coef = zeros(x_num_elements * 2 + 1, y_num_elements * 2);

% To prevent overfeating, learns a separate regression for the keypoints
% of each part (eg. nose, eye, eyebrow)
for i = 1 : length(level_2_parts)
    x_sub_parts = find(x_part_num == i) ;
    y_sub_parts = find(y_part_num == i);
    xi = X(:, [1 x_sub_parts]);
    yi = y(:, y_sub_parts);
    
    xx = xi' * xi;
    a = eye(size(xx, 1)); a(1, 1) = 0;
    %A = inv(xx + a * 0.02) * xi' * yi;
    A = inv(xx + a * 0.02) * xi' * yi;
    coef([1, x_sub_parts], y_sub_parts) = A;
end


function debugging(boxes, test, left_eye_inds, right_eye_inds, ...
                   reg_coef, errors, model, mapping_2_hpm_parts)
% Updates the 29 keypoints prediction.
% TODO check it later when the center of rotation are saved correctly!
for i = 1 : length(boxes)
    if ~isempty(boxes{i})
        boxes{i}.det29 = ApplyRegression(boxes{i}, reg_coef);
    end
end

aft_errors = LandmarkLocalizationEval( ...
                boxes, 'det29', 'occ29', test, left_eye_inds, ...
                right_eye_inds);
disp(mean(errors));
disp(mean(aft_errors));
if 1
	for i = 1 : length(boxes)
		%errors(i)
		figure(1); clf;
		I = imread(test(i).im);
		imagesc(I); axis 'equal'; hold on; colormap('gray');
		pts = boxes{i}.det_sim_29;
		plot(pts(:, 1), pts(:, 2), '.g', 'MarkerSize', 10);
		pts = boxes{i}.det29;
		plot(pts(:, 1), pts(:, 2), '.b', 'MarkerSize', 10);
		pts = test(i).pts;
		plot(pts(:, 1), pts(:, 2), '.c', 'MarkerSize', 10);
		if 1
			level_2_parts = model.opts.mixture(1).level_2_parts;
			x_part_num = zeros( ...
                1, sum(model.opts.mixture(1).part_level == 1) * 2 + 1);
			for j=1:length(level_2_parts)
				x_part_num(level_2_parts(j).children) = j;
			end
			x_part_num(x_part_num == 0) = [];
			x_part_num = inv(model.opts.mixture(1).anno2treeorder) * ...
                         (x_part_num');

			for j = 1 : length(level_2_parts)
				y_sub = find(mapping_2_hpm_parts == j);
				x_sub = find(x_part_num == j);

				clf; imagesc(I); axis 'equal'; hold on;
				pts10 = boxes{i}.det_sim_29;
				pts68 = boxes{i}.det68;
				plot(pts68(x_sub, 1), pts68(x_sub, 2), '.g', ...
                     'MarkerSize', 10);
				plot(pts10(y_sub, 1), pts10(y_sub, 2), '.b', ...
                     'MarkerSize', 10);

				pause;
			end
		end
		pause;
	end
end
