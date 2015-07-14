function Main(file_name, method_name)
close all;

load('OFD/annotations.mat');
min_overlap = 0.5;
file_names = cell(1, 0);
method_names = cell(1, 0);

file_names{end+1} = 'DetectionResults/HPM_no_occ_HELEN68.txt';
method_names{end+1} = 'HPM-occ(HELEN68)';

file_names{end+1} = 'DetectionResults/HPM_HELEN68.txt';
method_names{end+1} = 'HPM(HELEN68)';

% Multi-resolution HPM without rotation at test
%file_names{end+1} = 'DetectionResults/HPM_multi_res_worot_HELEN68.txt';
%method_names{end+1} = 'Multi-resolution HPM(HELEN68)';

% Multi-resolution HPM wtih rotation at test
file_names{end+1} = 'DetectionResults/HPM_multi_res_wrot_HELEN68.txt';
method_names{end+1} = 'Multi-resolution HPM(HELEN68)';

% Add other methods here.
% file_names{end+1} = 'address of the detection info file';
% method_names{end+1} = 'name of the method';

% Adds the results of the input.
if(exist('file_name', 'var'))
	file_names{end+1} = file_name;
	method_names{end+1} = method_name;
end

for i = 1 : length(file_names)
	fprintf('Reading detection results of "%s" from "%s".\n', ...
			method_names{i}, file_names{i});
	[BB, ids, confidence] = ReadDetectionResults(file_names{i});
	fprintf('Evaluating ...\n');
	[rec{i}, prec{i}, ap{i}, rec_o{i}, prec_o{i}, ap_o{i}, rec_so{i}, ...
			prec_so{i}, ap_so{i}, rec_v{i}, prec_v{i}, ap_v{i}] = ...
			Evaluate(ground_truth, gt_ids, BB, ids, confidence, min_overlap);
end

fprintf('Plotting precision-recall curves ...\n');
PlotCurves(rec, prec, ap, method_names, 'all faces');
PlotCurves(rec_v, prec_v, ap_v, method_names, 'visible faces');
PlotCurves(rec_o, prec_o, ap_o, method_names, 'occluded faces');
PlotCurves(rec_so, prec_so, ap_so, method_names, 'significant occluded faces');
