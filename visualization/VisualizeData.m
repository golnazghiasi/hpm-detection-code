function VisualizeData(test, show_num)

if ~exist('show_num', 'var')
	show_num = 0;
end

for i = 1 : length(test)
    I = imread(test(i).im);
    clf; imagesc(I); hold on; axis('equal');
	if size(I, 3) == 1
		colormap('gray');
	end
    pts = test(i).pts;
	if isfield(test(i), 'occ')
		occ = test(i).occ;
	else
		occ = zeros(1, size(pts, 1));
	end
    plot(pts(occ == 0, 1), pts(occ == 0, 2), '.g');
    plot(pts(occ == 1, 1), pts(occ == 1, 2), '.r');

    bbox = test(i).bbox;
    rectangle('Position', ...
              [bbox(1) bbox(2) bbox(3)-bbox(1) bbox(4)-bbox(2)]);
  
	if show_num 
		for j = 1 : size(pts, 1)
			text(pts(j, 1), pts(j, 2), num2str(j));
		end 
	end

    pause;
end


