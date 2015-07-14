function PlotCurves(precision, recall, ap, method_names, title_name)

figure; hold on; grid on;
colors = VaryColor(length(method_names));
for i = 1 : length(method_names) 
	plot(precision{i}, recall{i}, 'color', colors(i, :), 'linewidth', 2);
	method_names{i} = [method_names{i} sprintf(', AP: %.2f%%', ap{i} * 100)];
end

xlabel('Recall', 'fontsize', 20);
ylabel('Precision', 'fontsize', 20);
set(gca,'fontsize', 20);
set(gcf,'color', 'w') 
legend(method_names, 'Location', 'SouthWest', 'FontSize', 15);
title(title_name);
axis tight

%if(~exist('plots','dir'))
%	mkdir('plots');
%end
%addpath /extra/titansc0/gghiasi/Matlab_tools/export_fig/
%export_fig(['plots/' title_name], '-pdf');
