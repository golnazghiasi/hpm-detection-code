function [map_pts, map_occ] = Mapping68kToAfw(pts, occ)
% Maps keypoints based on the nearest keypoint(s).

T{1} = 37 : 42;
T{2} = 43 : 48;
T{3} = 31;
T{4} = [49, 61];
T{4} = [61];
T{5} = 49 : 68;
T{6} = [55, 65];

map_pts = zeros(length(T), 2);
map_occ = zeros(1, length(T));
for i = 1 : size(map_pts, 1)
    map_pts(i, :) = mean(pts(T{i}, :), 1);
    map_occ(i) = max(occ(T{i}));
end
