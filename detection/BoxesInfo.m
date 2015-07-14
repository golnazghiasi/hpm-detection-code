function bs = BoxesInfo(bs, model, offset, rotate_points)
if(~exist('offset', 'var'))
    offset = [0 0];
end
if(~exist('rotate_points', 'var'))
    rotate_points = true;
end

if ~isempty(bs)
    for j = 1:length(bs)
		if(rotate_points && bs(j).ang ~= 0)
			bs(j).xy(:, [1, 2]) = RotatePoints(bs(j).xy(:, [1, 2]), ...
											   bs(j).rot_cent, bs(j).ang);
			bs(j).xy(:, [3, 4]) = RotatePoints(bs(j).xy(:, [3, 4]), ...
											   bs(j).rot_cent, bs(j).ang);
		end

        bs(j).xy(:,[1 3]) = bs(j).xy(:,[1 3]) + offset(1);
        bs(j).xy(:,[2 4]) = bs(j).xy(:,[2 4]) + offset(2);
		bs(j).rot_cent = bs(j).rot_cent + offset;
        
        bs(j).xy_all = bs(j).xy;
        bs(j).m_all  = bs(j).m;
		% Removes parts.
        bs(j).xy(model.opts.mixture(bs(j).c).part_level == 2,:) = [];
        bs(j).m(model.opts.mixture(bs(j).c).part_level == 2) = [];
        
        model_parts = model.components{bs(j).c};
        model_parts(model.opts.mixture(bs(j).c).part_level == 2) = [];
        
        % Sets occlusion flags.
        is_occ = zeros(1,length(model_parts));
        for it = 1 : length(model_parts)
            is_occ(it) = model_parts(it).occfilter(bs(j).m(it));
        end
        bs(j).occ = is_occ;
        
        bs(j).det = [mean(bs(j).xy(:, [1, 3]), 2), ...
                     mean(bs(j).xy(:, [2, 4]), 2)];
		if size(bs(j).det, 1) == 68
			bs(j).det = inv(model.opts.mixture(1).anno2treeorder) * ...
                            bs(j).det;
			bs(j).occ = (inv(model.opts.mixture(1).anno2treeorder) * ...
                         bs(j).occ')';
			bs(j).m = inv(model.opts.mixture(1).anno2treeorder) * ...
                          bs(j).m;
			bs(j).xy = inv(model.opts.mixture(1).anno2treeorder) * ...
                           bs(j).xy;
			bs(j).det68 = bs(j).det;
			bs(j).occ68 = bs(j).occ;
		end
    end
end
