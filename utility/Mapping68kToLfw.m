function [map_pts, map_occ] = Mapping68kToLfw9k(pts, occ)
% Maps keypoints based on the nearest keypoint(s).

T{1} = 37;
T{2} = 40;
T{3} = [49, 61];
T{4} = [55, 65];
T{5} = [57, 58, 59];
T{6} = [51, 52, 53];
T{7} = 43;
T{8} = 46;
T{9} = 32;
T{10} = 36;

map_pts = zeros(length(T), 2);
map_occ = zeros(1, length(T));
for i = 1 : size(map_pts, 1)
    map_pts(i, :) = mean(pts(T{i}, :), 1);
    map_occ(i) = max(occ(T{i}));
end
