function VisualizeDetectionRes(gt, boxes, save_vis_res, thresh, max_to_show, ...
								   draw_rectangle, show_score_size)

if(~exist('max_to_show', 'var'))
	max_to_show = length(gt);
end

if(~exist('draw_rectangle', 'var'))
	draw_rectangle = false;
end
if(~exist('show_score_size', 'var'))
	show_score_size = false;
end
if(~exist(save_vis_res,'dir'))
    mkdir(save_vis_res);
end

fprintf(['Visualizing detection result of first %d images ...\n'], max_to_show);

for i = 1 : max_to_show
    im = imread(gt(i).im);
    boxes_out = boxes{i};
    sc = [boxes_out.s];
    boxes_out = boxes_out(sc > thresh);
    ShowPoints(im, boxes_out);
    hold on;
    for j = 1:length(boxes_out)
        c = boxes_out(j).c;
		bb = boxes_out(j).BB;
		x = bb(1);
		y = bb(2);
		x_r = bb(3) - bb(1);
		y_r = bb(4) - bb(2);
		if show_score_size
			text(x - 5, y - 5, sprintf('%.2f',boxes_out(j).s), ...
				 'color', 'b', 'fontsize', 4);
			text(x - 20, y - 5, sprintf('%.1f', x_r), ...
				 'color', 'r', 'fontsize', 4);
		end
		if draw_rectangle
        	rectangle('Position',[x, y, x_r, y_r], ...
                  'edgecolor', 'g', 'linewidth', 0.5);
		end
    end
	pause(2);
	if 0
		name = boxes{i}(1).id;
		if(length(name) > 3 && name(end - 3) == '.')
			name = name(1 : end - 4);
		end
		export_fig([save_vis_res name '_' num2str(abs(thresh)*100)], '-pdf');
	end
end
