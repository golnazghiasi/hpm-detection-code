function [rot_deg, Ir, ptsr, rot_cent] = RotateFace( ...
                     I, pts, left_eye_ind, right_eye_ind)
% Rotates face to be vertical using the locations of eyes' centers.

if(~exist('left_eye_ind', 'var'))
	if(size(pts, 1) == 68)
		left_eye_ind  = 37:42;
		right_eye_ind = 43:48;
	else
		assert(size(pts, 1) == 29);
		left_eye_ind = 17;
		right_eye_ind = 18;
	end
end
left_eye_loc = mean(pts(left_eye_ind, :), 1);
right_eye_loc = mean(pts(right_eye_ind, :), 1);

% Calculates amount of rotation in the given face using the locations of eyes 
% centers.
rot_cent = (left_eye_loc + right_eye_loc) / 2;
rot_rad = atan2(right_eye_loc(1,2) - rot_cent(1,2), ...
                right_eye_loc(1,1) - rot_cent(1,1));
rot_deg = radtodeg(rot_rad);

Ir(:, :, 1) = RotateAround(I(: ,: ,1), rot_cent(1, 2), ...
                           rot_cent(1, 1), rot_deg);
if(size(I, 3) > 1)
    Ir(:, :, 2) = RotateAround(I(:, :, 2), rot_cent(1, 2), ...
                               rot_cent(1, 1), rot_deg);
    Ir(:, :, 3) = RotateAround(I(:, :, 3), rot_cent(1, 2), ...
                               rot_cent(1, 1), rot_deg);
end
ptsr = RotatePoints(pts, rot_cent, -rot_deg);

if 0
	figure(199); clf; imagesc(I); axis 'equal'; hold on;
	plot(pts(:, 1), pts(:, 2), '.g');
	plot(left_eye_loc(1), left_eye_loc(2), '*b');
	plot(right_eye_loc(1), right_eye_loc(2), '*b');
	figure(200); clf; imagesc(Ir); axis 'equal'; hold on;
	plot(ptsr(:, 1), ptsr(:, 2), '.g');
	plot(left_eye_loc(1), left_eye_loc(2), '*b');
	plot(right_eye_loc(1), right_eye_loc(2), '*b');
end

