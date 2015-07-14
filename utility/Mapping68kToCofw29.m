function [map_pts, map_occ] = Mapping68kToCofw29(pts, occ)
% Maps keypoints based on the nearest keypoint(s).

T{1} = 18;
T{2} = 27;
T{3} = 22;
T{4} = 23;
T{5} = 20;
T{6} = [18, 22];
T{7} = 25;
T{8} = [23, 27];
T{9} = 37;
T{10} = 46;
T{11} = 40;
T{12} = 43;
T{13} = 38 : 39;
T{14} = 41 : 42;
T{15} = 44 : 45;
T{16} = 47 : 48;
T{17} = 37 : 42;
T{18} = 43 : 48;
T{19} = 32;
T{20} = 36;
T{21} = 31;
T{22} = 34;
T{23} = [49, 61];
T{24} = [55, 65];
T{25} = 51 : 53;
T{26} = 63;
T{27} = 67;
T{28} = 57 : 59;
T{29} = 8 : 10;


map_pts = zeros(length(T), 2);
map_occ = zeros(1, length(T));
for i = 1 : size(map_pts, 1)
    map_pts(i, :) = mean(pts(T{i}, :), 1);
    map_occ(i) = max(occ(T{i}));
end
