% This method computes Precision-Recall curves of face detection on (a) all the faces,
% (b) ovisible subset, (c) ccluded subset and (d) significant occluded subset.
% This method computes Precsion-Recall curves for all faces, visible
% faces, occluded faces and significant occluded faces subsets of the dataset.
% It is based on the detection evaluation of Pascal VOC toolbox.
% http://pascallin.ecs.soton.ac.uk/challenges/VOC/voc2011/VOCdevkit_25-May-2011.tar

function [rec, prec, ap, rec_o, prec_o, ap_o, rec_so, prec_so, ap_so, rec_v, prec_v, ap_v, confidence] = Evaluate(gt, gtids, BB, ids, confidence, min_overlap)
[~, si] = sort(-confidence);
ids = ids(si);
BB = BB(:, si);

nd = length(confidence);
% True positive
tp = zeros(nd, 1);
% False positive
fp = zeros(nd, 1);
% True positive for an occluded face
tp_o = zeros(nd, 1);
% True positive for a visible face
tp_v = zeros(nd, 1);
% True positive for a significantly occluded face
tp_so = zeros(nd, 1);

for d = 1 : nd
    % Finds ground truth image.
	i = [];
    for j = 1 : length(gtids)
        if strcmp(gtids{j}, ids{d})
            i = j;
            break;
        end
    end
    if isempty(i)
        error('Unrecognized image "%s"', ids{d});
    elseif length(i)>1
        error('Multiple image with id: "%s"', ids{d});
    end
    
    % Assigns detection to ground truth object if any.
    bb=BB(:, d);
    ovmax = -inf;
    for j = 1 : size(gt(i).BB, 2)
        bbgt = gt(i).BB(:, j);
        bi = [max(bb(1), bbgt(1)) ; max(bb(2), bbgt(2)) ; min(bb(3), bbgt(3)) ; min(bb(4), bbgt(4))];
        iw = bi(3) - bi(1) + 1;
        ih = bi(4) - bi(2) + 1;
        if iw > 0 && ih > 0
            % Computes overlap as area of intersection / area of union.
            ua = (bb(3) - bb(1) + 1) * (bb(4) - bb(2) + 1) + ...
                (bbgt(3) - bbgt(1) + 1) * (bbgt(4) - bbgt(2) + 1) -...
                iw * ih;
            ov = iw * ih / ua;
            if ov > ovmax
                ovmax = ov;
                jmax = j;
            end
        end
    end
    % Assigns detection as true positive/don't care/false positive.
    if ovmax >= min_overlap
		if ~gt(i).det(jmax)
			% True positive
			tp(d) = 1;
			gt(i).det(jmax) = true;
			if(gt(i).occ(jmax) > 0)
			% True positive for an occluded face
				tp_o(d) = 1;
			end
			if(gt(i).occ(jmax) > 1) 
			% True positive for a significantly occluded face
				tp_so(d) = 1;
			end
			% True positive for a visible face
			if(gt(i).occ(jmax) == 0)
				tp_v(d) = 1;
			end
		else
			% False positive (multiple detection)
			fp(d) = 1;
		end
    else
	% False positive
        fp(d) = 1;
    end
end

npos_v = 0;
npos_so = 0;
npos_o = 0;
npos = 0;
for i = 1 : length(gtids)
	npos_v = npos_v + sum(gt(i).occ == 0);
	npos_o = npos_o + sum(gt(i).occ > 0);
	npos_so = npos_so + sum(gt(i).occ > 1);
	npos = npos + length(gt(i).occ);
end

[rec_v, prec_v, ap_v] = ComputePrecRec(fp, tp_v, npos_v);
[rec_so, prec_so, ap_so] = ComputePrecRec(fp, tp_so, npos_so);
[rec_o, prec_o, ap_o] = ComputePrecRec(fp, tp_o, npos_o);
[rec, prec, ap] = ComputePrecRec(fp, tp, npos);

function [rec, prec, ap] = ComputePrecRec(fp, tp, npos)
% Computes precision/recall.
fp = cumsum(fp);
tp = cumsum(tp);
rec = tp / npos;
prec = tp ./ (fp + tp);

% Computes average precision.
ap = 0;
for t = 0 : 0.01 : 1
    p = max(prec(rec >= t));
    if isempty(p)
        p = 0;
    end
	ap = ap + p / 101;
end
