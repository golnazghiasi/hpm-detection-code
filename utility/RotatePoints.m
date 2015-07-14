function pts = RotatePoints(pts, cent, theta)
% Rotates points (pts) around center (cent) theta degrees.

theta = degtorad(theta);
if abs(theta)<eps
	return;
end
R = [cos(theta), -sin(theta); sin(theta), cos(theta)];

pts(:, 1) = pts(:, 1) - cent(1);
pts(:, 2) = pts(:, 2) - cent(2);
pts = (R * pts')';
pts(:, 1) = pts(:, 1) + cent(1);
pts(:, 2) = pts(:, 2) + cent(2);

