function changeAlpha(model, test, test_name, options)
compare_eval = 'cache/changealpha/';
if(~exist(compare_eval,'dir'))
    mkdir(compare_eval);
end


testres_filenames = cell(1,0);
legend_names      = cell(1,0);

modelo = model;
pvalues = ([-.6:0.1:0.3]);
for occ_bias_inc = pvalues
    options.occ_bias_inc = occ_bias_inc;
    filename = BoxesFilename(options);
	fprintf('%s\n', filename);
    save_eval_res = [compare_eval filename(7:end) '_forplot'];

	testres_filenames{end+1} = save_eval_res;
    legend_names{end+1} = ['alpha:' sprintf(' .2%f', options.occ_bias_inc)];

    try
		load(save_eval_res);
	catch 
    	model = ChangeBiasOfOccKeypoints(modelo, options.occ_bias_inc);
		boxes = LocalizationsWRotation(test, model, options);

		for i = 1 : length(boxes)
			if ~isempty(boxes{i})
				[boxes{i}.det_sim_29, boxes{i}.occ29] = ...
					Mapping68kToCofw29(boxes{i}.det68, boxes{i}.occ68);
				boxes{i}.det29 = ApplyRegression(boxes{i}, model.c68to29);
			end
		end

		% Evaluation
		[errors, precision, recall] = LandmarkLocalizationEval( ...
			boxes, 'det29', 'occ29', test, options.left_eye_inds, ...
			options.right_eye_inds);
		% Prints results.
		ave_errors = nanmean(errors);
		failure_rate = sum(errors > 0.1) / length(errors) * 100;
		fprintf('Average Error: %.3f, Failure rate: %.2f%%\n', ave_errors, ...
			failure_rate);
		fprintf('recall: %.3f precision %.3f\n', recall, precision);
		fprintf('number of nan: %d\n', sum(isnan(errors)));
		
		% Saves result for plotting results for different parameters
		save(save_eval_res,'precision','recall','errors');
	end
end
PlotGraphs(testres_filenames,legend_names, pvalues, 'alpha', ...
           [compare_eval test_name '_changealpha'], 'cache/res/');
