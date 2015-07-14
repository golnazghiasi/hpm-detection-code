function test = CofwData(data_file_add, data_dir, read_train_data)
% data_file_add: address to the COFW train data.
% data_dir: directory to save cofw images.
% read_train_data: read train or test COFW test data, 1->train, 0->test

if read_train_data
	fprintf('Reading COFW train data ...\n');
else
	fprintf('Reading COFW test data ...\n');
end

if read_train_data
	load(data_file_add, 'phisTr','IsTr','bboxesTr');
else
	% Reads cofw test data.
	load(data_file_add, 'phisT','IsT','bboxesT');
	phisTr = phisT;
	IsTr = IsT;
	bboxesTr = bboxesT;
end

if(~exist(data_dir, 'dir'))
	mkdir(data_dir);
end
for i = 1 : length(IsTr)
	im_add = [data_dir '/im_' num2str(i) '.png'];
	try
		imread(im_add);
	catch
		I = IsTr{i};
		imwrite(I, im_add);
	end
	try
		load(im_add(1 : end - 4), 'pts', 'occ');
	catch
		pts = [phisTr(i, 1 : 29)' phisTr(i, 30 : 58)'];
		occ = phisTr(i, 59 : end);
		save(im_add(1 : end - 4), 'pts', 'occ');
	end
	test(i).id = num2str(i);
	test(i).im = im_add;
	test(i).pts = pts;
	test(i).occ = occ;
	if read_train_data
	% Sets the COFW training boundig boxes to be same as the COFW testing
	% bounding boxes! (Original training bouding boxes have more variation)
		test(i).bbox = round([min(pts(:, 1)) - 10, min(pts(:, 2)) - 10, ...
                             max(pts(:,1)) + 10,  max(pts(:, 2)) + 10]);	
	else
    % For the experiments in the papers, these bounding boxes are set to be
    % the tight bounding boxes around the keypoints and the detection with 
    % highest score and minimum 80% overlap is returned as the solution.
    % However, We can get same results when the bounding boxes are set same as the
    % COFW ground-truth bounding boxes and the minimum overlap is 70% (as here).
		bb = bboxesTr(i,:);
		test(i).bbox = [bb(1), bb(2), bb(3) + bb(1), bb(4) + bb(2)];
	end
end
