function test = LfwData(lfw_anno, lfw_dir, first_char)

fprintf('Reading lfw data starting with %c ...\n', first_char);

file_id = fopen(lfw_anno,'r');
linedata = textscan(file_id,'%s','delimiter','\n','whitespace','');
linedata = linedata{1};

% Removes initial lines.
linedata(1 : 6) = [];

test = [];
for i = 1 : length(linedata)
	s = linedata{i};
	if all(s(1) ~= first_char)
		continue;
	end

	ind = min(find(s == ' '));
	name = s(1 : ind - 1);
	test(end+1).im = [lfw_dir name];

	nums = sscanf(s(ind + 1 : end), '%d ');
	test(end).bbox = [nums(1), nums(2), ...
			nums(1) + nums(3), nums(2) + nums(4)];

	test(end).headpose = nums(5);

	test(end).pts = [nums(7:2:end) + nums(1) + 1, ...
                     nums(8:2:end) + nums(2) + 1];
	id = name(find(name == '/') + 1 : end - 4);
	test(end).id = id;
end

if 0 
    % Visualizes ground-truth.
	for i = 1 : length(linedata)
		I = imread(test(i).im);
		imagesc(I); axis('equal'); hold on;

		bb = test(i).bbox;
		rectangle('Position', ...
                  [bb(1), bb(2), bb(3) - bb(1), bb(4) - bb(2)], ...
                  'EdgeColor', 'b');

		pts = test(i).pts;	
		plot(pts(:, 1), pts(:, 2), '.r');

		pause;
	end
end
