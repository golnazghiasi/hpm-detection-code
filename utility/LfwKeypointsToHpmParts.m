function lfw_to_hpm_part = LfwKeypointsToHpmParts()

% Number of keypoints of lfw annotations.
num_keypoints = 10;

lfw_to_hpm_part = zeros(1, num_keypoints);

% nose
lfw_to_hpm_part([9, 10]) = 1;

% right eye
lfw_to_hpm_part([1, 2]) = 2;

% right eyebrow
%lfw_to_hpm_part() = 3;

% left eye
lfw_to_hpm_part([7, 8]) = 4;

% left eyebrow
%lfw_to_hpm_part() = 5;

% upper lip
lfw_to_hpm_part([6, 3, 4]) = 6;

% lower lip
lfw_to_hpm_part(5) = 7;

% lower jaw
%lfw_to_hpm_part() = 8;
