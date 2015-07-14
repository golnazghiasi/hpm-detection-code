function det = ApplyRegression(box, reg_coef, I)
% Applys linear regression to map 68 keypoint to size(reg_coef, 2) keypoints.

det = [];
if(~isempty(box))
	if exist('I', 'var')
		figure(10);
		clf; imagesc(I); axis 'equal'; hold on;
		plot(box.det68(:,1), box.det68(:,2), '.r');
	end

	% We learn the linear regression for the vertical faces, so we need
	% to ratate faces to be vertical before applying the regression.
	if(isfield(box, 'ang'))
		pts = RotatePoints(box.det68, box.rot_cent, -box.ang);
	else
		pts = box.det68;
	end

	if exist('I', 'var')
		figure(11);
		Ir = RotateAround(I, box.rot_cent(2), box.rot_cent(1), box.ang);
		clf; imagesc(Ir); axis 'equal'; hold on;
		plot(pts(:,1), pts(:,2), '.r');
	end
	
	n_pts = ApplyReg(pts, reg_coef);

	if exist('I', 'var')
		figure(11);
		plot(n_pts(:,1), n_pts(:,2), '.b');
	end
	if(isfield(box, 'ang'))
		n_pts = RotatePoints(n_pts, box.rot_cent, box.ang);
	end
	det = n_pts;
	if(exist('I','var'))
		figure(10);
		plot(det(:,1), det(:,2), '.b');
		pause;
	end
end


function det = ApplyReg(det68, reg_coef)
h = max(det68(:,1)) - min(det68(:,1));
w = max(det68(:,2)) - min(det68(:,2));
r = (h+w)/2;
det68 = det68 /r;
x = [1 det68(:,1)' det68(:,2)'];
det = x* reg_coef;
det = reshape(det, [], 2);
det = det*r;
