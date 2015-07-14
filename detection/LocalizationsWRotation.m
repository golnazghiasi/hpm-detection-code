function boxes = LocalizationsWRotation(test, model, options)
filename = BoxesFilename(options);

try 
	load(filename);
catch
	save_boxes_add = [options.cachedir 'boxes_' filename(7 : end) '/'];
	if(~exist(save_boxes_add, 'dir'))
		mkdir(save_boxes_add);
	end

	startmatlabpool();
	for i = 1: length(test)
    	fprintf('testing on (%d/%d) : %s\n', i, length(test), test(i).id);
		box_filename = [save_boxes_add 'box_' test(i).id];
		try
			lb = load(box_filename);
			boxes{i} = lb.bs;
			fprintf('Saved result loaded.\n');
		catch
			I = imread(test(i).im);
			bs = TestLocalization( ...
                    model, I, test(i).bbox, options.keypoint_subset,...
                    options.overlap_threshold, options.limited_level, ...
                    1, options.rotation_step, ...
                    -options.rotation_range, options.rotation_range, ...
                    options.pad_ratio);
            boxes{i} = bs;
			parforsave(box_filename, bs);

			figure(1); clf; imagesc(I); axis off; axis image; 
            hold on; drawnow;
			if(size(I, 3) == 1)
				colormap(gray);
			end
			if ~isempty(bs)
				pts = bs.det68;
				occ = bs.occ68;
				plot(pts(occ == 0, 1), pts(occ == 0, 2), '.g', ...
					 'MarkerSize', 10);
				plot(pts(occ == 1, 1), pts(occ == 1, 2), '.r', ...
					 'MarkerSize', 10);
				drawnow;
			end
		end
	end
	closematlabpool();
	save(filename, 'boxes', 'test');
	rmdir(save_boxes_add, 's');
end

function parforsave(filename, bs)
save(filename, 'bs');
