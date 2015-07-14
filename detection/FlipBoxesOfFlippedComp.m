function boxes = FlipBoxesOfFlippedComp(boxes, flip_component, size_im, opts)
% Flips the detection results of the components that their parameters
% are shared with the component with their flip viewpoint.
flipmaps = cell(1,0);
for i = 1 : length(opts.mixture)
	flipmap = [];
	if length(opts.mixture(i).pa) == 78
		num_level2_parts = sum(opts.mixture(i).part_level == 2);
		if num_level2_parts == 10
			fmap = FlipMapTreeOrder(opts);
			orig = 1 : length(fmap);
			flipmap = 1 : (length(fmap) + num_level2_parts);
			flipmap(orig + num_level2_parts) = fmap + num_level2_parts;

			assert(length(flipmap) == 78);
			assert(all(flipmap <= 78));
		end
	elseif length(opts.mixture(i).pa) == 7
		flipmap = FlipMap7Parts();
	end
	flipmaps{i} = flipmap;
end

for i = 1 : length(boxes)
    if flip_component(boxes(i).c)
        xy = boxes(i).xy;
        x1 = xy(:, 1);
        x3 = xy(:, 3);
        xy(:, 1) = size_im(2) + 1 - x3;
        xy(:, 3) = size_im(2) + 1 - x1;
		flipmap = flipmaps{boxes(i).c};
		if ~isempty(flipmap)
        	xy(1 : end, :) = xy(flipmap, :);
        	boxes(i).m = boxes(i).m(flipmap);
		end
        boxes(i).xy = xy;
    end
end

function flipmap = FlipMap7Parts()
flipmap = zeros(1,7);
flipmap(1) = 1;
flipmap(2) = 3;
flipmap(3) = 2;
flipmap(4) = 4;
flipmap(5) = 5;
flipmap(6) = 7;
flipmap(7) = 6;

function fmap = FlipMapTreeOrder(opts)
flip_map = zeros(1, 68);
flip_map(1) = 17;
flip_map(2) = 16;
flip_map(3) = 15;
flip_map(4) = 14;
flip_map(5) = 13;
flip_map(6) = 12;
flip_map(7) = 11;
flip_map(8) = 10;
flip_map(9) = 9;
flip_map(10) = 8;
flip_map(11) = 7;
flip_map(12) = 6;
flip_map(13) = 5;
flip_map(14) = 4;
flip_map(15) = 3;
flip_map(16) = 2;
flip_map(17) = 1;
flip_map(18) = 27;
flip_map(19) = 26;
flip_map(20) = 25;
flip_map(21) = 24;
flip_map(22) = 23;
flip_map(23) = 22;
flip_map(24) = 21;
flip_map(25) = 20;
flip_map(26) = 19;
flip_map(27) = 18;
flip_map(28) = 28;
flip_map(29) = 29;
flip_map(30) = 30;
flip_map(31) = 31;
flip_map(32) = 36;
flip_map(33) = 35;
flip_map(34) = 34;
flip_map(35) = 33;
flip_map(36) = 32;
flip_map(37) = 46;
flip_map(38) = 45;
flip_map(39) = 44;
flip_map(40) = 43;
flip_map(41) = 48;
flip_map(42) = 47;
flip_map(43) = 40;
flip_map(44) = 39;
flip_map(45) = 38;
flip_map(46) = 37;
flip_map(47) = 42;
flip_map(48) = 41;
flip_map(49) = 55;
flip_map(50) = 54;
flip_map(51) = 53;
flip_map(52) = 52;
flip_map(53) = 51;
flip_map(54) = 50;
flip_map(55) = 49;
flip_map(56) = 60;
flip_map(57) = 59;
flip_map(58) = 58;
flip_map(59) = 57;
flip_map(60) = 56;
flip_map(61) = 65;
flip_map(62) = 64;
flip_map(63) = 63;
flip_map(64) = 62;
flip_map(65) = 61;
flip_map(66) = 68;
flip_map(67) = 67;
flip_map(68) = 66;

tree_2_orig = (opts.mixture(1).anno2treeorder * (1 : 68)')';
orig_2_tree(tree_2_orig) = 1 : 68;

fmap(orig_2_tree(1 : 68)) = orig_2_tree(flip_map);
