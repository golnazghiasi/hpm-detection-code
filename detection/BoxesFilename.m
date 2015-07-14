function filename = BoxesFilename(options)
% Returns a filename based on the options.

filename = [options.cachedir options.experiment_name '_' options.test_name ...
			'_boxes' '_interval' num2str(options.interval) '_incOB'];
if(options.occ_bias_inc<0)
    filename = [filename 'n'];
end
filename = [filename num2str(abs(options.occ_bias_inc) * 100)];
if isfield(options,'overlap_threshold')
    filename = [filename '_ov' num2str(floor(options.overlap_threshold * 10))];
end
filename = [filename '_rot'  num2str(floor(options.rotation_range)) '_'  ...
			num2str(floor(options.rotation_step))];
