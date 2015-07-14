function [failure_rate_p1, precs, recalls] = PlotGraphs( ...
    model_names, legend_names, params, x_label, ...
    experiment_save_plot_res, experiment_save_res)

failure_rate_p1 = [];
precs = [];
recalls = [];
ave_errors = [];

clf;
cnt = 0;
cols = distinguishable_colors(length(legend_names));
for mn = 1 : length(model_names)
    try
        load(model_names{mn});
    catch
        fprintf('%s not loaded.\n', model_names{mn});
        continue;
    end
    cnt = cnt + 1;

	failure_rate_p1 = [failure_rate_p1 sum(errors > 0.1) / ...
                       length(errors) * 100];
	ave_error = nanmean(errors);
    ave_errors = [ave_errors, ave_error];

    if(exist('precision', 'var'))
        precs = [precs, precision];
        recalls = [recalls, recall];
        clear precision recall
    end
end
fprintf('failure rate :'); disp(failure_rate_p1);
fprintf('ave error    :'); disp(ave_errors);
fprintf('precision    :'); disp(precs);
fprintf('recall       :'); disp(recalls);
fprintf('alpha        :'); disp(params);



disp(experiment_save_res);
if ~exist(experiment_save_res, 'dir')
	mkdir(experiment_save_res);
end
save([experiment_save_res 'changealpha'], 'params', 'failure_rate_p1', ...
      'x_label', 'ave_errors', 'precs', 'recalls');

figure;
plot(recalls, precs);
grid on;
ylabel('Precision', 'fontsize',14);
xlabel('Recall','fontsize', 14);
set(gcf, 'color', 'w');

figure;
plot(recalls, ave_errors);
grid on;
ylabel('Average localization error', 'fontsize',14);
xlabel('Recall','fontsize', 14);
set(gcf, 'color', 'w');

figure;
plot(recalls, failure_rate_p1);
grid on;
ylabel('Failure rate', 'fontsize',14);
xlabel('Recall','fontsize', 14);
set(gcf, 'color', 'w')

%export_fig([experiment_save_plot_res '_comp'], '-pdf');
