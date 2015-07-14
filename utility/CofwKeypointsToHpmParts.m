function cofw_to_hpm_part = CofwKeypointsToHpmParts()

% Number of keypoints of lfw annotations.
num_keypoints = 29;

cofw_to_hpm_part = zeros(1, num_keypoints);

% nose
cofw_to_hpm_part([19, 20, 21, 22]) = 1;

% right eye
cofw_to_hpm_part([9, 11, 13, 14, 17]) = 2;

% right eyebrow
cofw_to_hpm_part([1, 3, 5, 6]) = 3;

% left eye
cofw_to_hpm_part([10, 12, 15, 16, 18]) = 4;

% left eyebrow
cofw_to_hpm_part([2, 4, 7, 8]) = 5;

% upper lip
cofw_to_hpm_part([23, 24, 25, 26]) = 6;

% lower lip
cofw_to_hpm_part([27, 28]) = 7;

% lower jaw
cofw_to_hpm_part(29) = 8;
