function test = AfwTestData(afw_dir)
disp('Reading AFW test data ...');

load([afw_dir 'anno.mat']);
test = [];
for i = 1 : length(anno)
    for j = 1 : length(anno{i, 2})
        if(isempty(test))
            test(1).im = [afw_dir anno{i, 1}];
        else
            test(end+1).im = [afw_dir anno{i, 1}];
        end
        test(end).pts = anno{i, 4}{j};
        test(end).headpose = anno{i, 3}{j}(1);
        test(end).bbox = anno{i, 2}{j};
        test(end).bbox = [test(end).bbox(1, :) test(end).bbox(2, :)];
        test(end).id = num2str(length(test));
        test(end).image_num = i;
		test(end).face_num = j;
    end
end
