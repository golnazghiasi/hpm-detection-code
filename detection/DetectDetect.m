function boxes = DetectDetect(input, model, min_level)

if(~exist('min_level', 'var'))
    min_level = 1;
end
if(size(input,3) == 1)
    input = repmat(input, [1 1 3]);
end

BOXCACHESIZE = 100000;
cnt = 0;
boxes.s  = 0;
boxes.c  = 0;
boxes.xy = 0;
boxes.level = 0;
boxes.m = 0;
boxes(BOXCACHESIZE) = boxes;

% Computes the feature pyramid.
pyra_or  = featpyramid(input,model);

% Computes fliped image and its feature pyramid for the
% components which share their parameters with their flipped components.
input_fl = input(:, end : -1 : 1, :);
pyra_fl  = featpyramid(input_fl,model);

% If faces are big enough that we don't need to run the model on the
% low levels of the pyramid. Levels 1 to interval corresponding to the
% images larger with a scale larger than 1.
% (corresponding image of level 1 has scale of 2)
levels   = min_level : length(pyra_or.feat);

levels = levels(randperm(length(levels)));
[components,filters,resp] = modelComponents(model, pyra_or);

resp_fl = resp;
resp_or = resp;
% Finds filter set for the fliped components.
filterid_fl_list = false(1, length(filters));
for c = 1 : length(model.flip_image)
    if(model.flip_image(c))
        parts = components{c};
        for i = 1 : length(parts)
            filterid_fl_list(parts(i).filterid(parts(i).filterid > 0)) = true;
        end
    end
end

% Computes the corresponding scale of the image for each level of the feature pyramid.
pyramid_scales = model.sbin ./ pyra_or.scale;
% Iterates over random permutation of scales and components,
for rlevel = levels,
    for c  = randperm(length(model.components))
        
        min_s = model.min_scale(c);
        max_s = model.max_scale(c);
        if(min_s ~= -1 && pyramid_scales(rlevel) < min_s || ...
           max_s ~= -1 && pyramid_scales(rlevel) > max_s)
            continue;
        end
        
        parts    = components{c};
        num_parts = length(parts);
       
		% Calculates size of a response map for a filter of the component and current level
		% parts(end) is a leaf and it has a filter.
		filterids = parts(end).filterid;
		non_zero_filterid = filterids(find(filterids, 1, 'first'));
        % Local part scores
        for k = 1 : num_parts,
            f = parts(k).filterid;
            level = rlevel - parts(k).scale * model.interval;
            
            if ~model.flip_image(c)
                if isempty(resp_or{level}),
                    resp_or{level} = fconv(pyra_or.feat{level}, ...
                                     filters, 1, length(model.filters));
                end
                resp{level} = resp_or{level};
            else
                if isempty(resp_fl{level}),
                    filters_fl = filters(filterid_fl_list);
                    resp_fl{level}(filterid_fl_list) = ...
                        fconv(pyra_fl.feat{level}, filters_fl, ...
                        1, length(filters_fl));
                end
                resp{level} = resp_fl{level};
            end
			score_size = size(resp{level}{non_zero_filterid});

            parts(k).score = zeros(score_size(1), score_size(2), length(f));
            for fi = 1 : length(f)
                if(f(fi) ~= 0)
                    parts(k).score(:, :, fi) = resp{level}{f(fi)};
                end
            end
            parts(k).level = level;
        end
        
        % Walks from leaves to root of tree, passing message to parent.
        for k = num_parts : -1 : 2,
            par = parts(k).parent;
            [msg, parts(k).Ix, parts(k).Iy, parts(k).Im] = ...
                passmsg(parts(k),parts(par));
            parts(par).score = parts(par).score + msg;
        end
        
        % Adds bias to root score.
        parts(1).score = parts(1).score + parts(1).b;
        [rscore, Im] = max(parts(1).score, [], 3);
        [Y, X] = find(rscore >= model.thresh);
        if ~isempty(X)
            I = (X - 1) * size(rscore, 1) + Y;
            XY = backtrack(X, Y, Im(I), parts, pyra_or);
        end
        
        % Walks back down tree following pointers.
        for i = 1 : length(X)
            x = X(i);
            y = Y(i);
            
            bb = XY(i, :, :);
            if(size(bb, 3) > 1)
                bb = squeeze(bb)';
            end
            xy = [mean(bb(:, [1, 3]), 2) mean(bb(:, [2, 4]), 2)];
            xy(model.opts.mixture(c).part_level == 2, :) = [];
            
            if 0
                if cnt == BOXCACHESIZE
                    nboxes = nmsFace(boxes, 0.95);
                    boxes = [];
                    cnt = 0;
                    boxes.s  = 0;
                    boxes.c  = 0;
                    boxes.xy = 0;
                    boxes.level = 0;
                    boxes.m = 0;
                    boxes(BOXCACHESIZE) = boxes;
                    cnt = length(nboxes);
                    boxes(1 : cnt) = nboxes;
                    fprintf('Number of boxes reached to the maximum number of boxes and after nms number of boxes is %d.\n',cnt);
                end
            end
            
            cnt = cnt + 1;
            boxes(cnt).c = c;
            boxes(cnt).s = rscore(y,x);
            boxes(cnt).level = rlevel;
            boxes(cnt).xy = bb(:,1:4);
            boxes(cnt).m = bb(:,5);
        end
    end
end
boxes = boxes(1 : cnt);
boxes = FlipBoxesOfFlippedComp(boxes, model.flip_image, size(input_fl), ...
                               model.opts);
%fprintf('Number of boxes is %d.\n', length(boxes));

% Backtrack through DP msgs to collect ptrs to part locations
function box = backtrack(x, y, mix, parts, pyra)
num_x = length(x);
num_parts = length(parts);

xptr = zeros(num_x, num_parts);
yptr = zeros(num_x, num_parts);
mptr = zeros(num_x, num_parts);
box  = zeros(num_x, 5, num_parts);

for k = 1 : num_parts,
    p = parts(k);
    if k == 1,
        xptr(:, k) = x;
        yptr(:, k) = y;
        mptr(:, k) = mix;
    else
        par = p.parent;
        [h, w, ~] = size(p.Ix);
        I = (mptr(:, par) - 1) * h * w + (xptr(:, par) - 1) * h + ...
            yptr(:, par);
        xptr(:, k) = p.Ix(I);
        yptr(:, k) = p.Iy(I);
        mptr(:, k) = p.Im(I);
        
        % Sets the location of occluded leaves at their rest location.
        if(p.leaf)
            occleaves = find(p.occfilter(mptr(:,k))==1);
            for i = 1 : length(occleaves)
                ic = occleaves(i);
                
                pm  = mptr(ic,par);
                chm = mptr(ic,k);
                px = xptr(ic,par);
                py = yptr(ic,par);
                
                probex = ((px - 1) * p.step + p.startx(pm, chm));
                probey = ((py - 1) * p.step + p.starty(pm, chm));
                
                xptr(ic, k) = probex;
                yptr(ic, k) = probey;
            end
        end
    end
    scale = pyra.scale(p.level);
    x1 = (xptr(:, k) - 1 - pyra.padx) * scale + 1;
    y1 = (yptr(:, k) - 1 - pyra.pady) * scale + 1;
    x2 = x1 + p.sizx(mptr(:, k)) * scale - 1;
    y2 = y1 + p.sizy(mptr(:, k)) * scale - 1;
    box(:, :, k) = [x1, y1, x2, y2, mptr(:, k)];
end

% Given a 2D array of filter scores 'child',
% (1) Apply distance transform
% (2) Shift by anchor position of part wrt parent
function [score, Ix, Iy, Im] = passmsg(child, parent)

n_y = size(parent.score, 1);
n_x = size(parent.score, 2);

num_req_dt = length(child.share_dt_computation);
K   = length(child.filterid);
L   = length(parent.filterid);

dim1 = size(child.score, 1);
dim2 = size(child.score, 2);

scorep = zeros(dim1, dim2, num_req_dt);
Ixp  = int32(zeros(dim1, dim2, num_req_dt));
Iyp  = int32(zeros(dim1, dim2, num_req_dt));

for i = 1:num_req_dt
    l = child.share_dt_computation(i).l;
    k = child.share_dt_computation(i).k;
    if(child.occfilter(k) == 0 || child.leaf == 0)
        
        %[scorep(:,:,i), Ixp(:,:,i), Iyp(:,:,i)] = ...
        %  shiftdt(child.score(:, :, k), child.w(1, l, k), child.w(2, l, k), ...
        %		child.w(3,l,k), child.w(4,l,k), child.startx(l, k), ...
        %		child.starty(l, k), n_x, n_y, child.step);
        
        fast_bounded_shifdt(scorep, Ixp, Iyp, (i-1)*dim1*dim2, ...
            child.score(:, :, k), child.w(1, l, k), ....
            child.w(2, l, k), child.w(3,l,k), child.w(4,l,k), ...
            child.startx(l, k), child.starty(l, k), 2);
    end
end

% Second step of pass message method that is explained in the paper.
[score, Ix, Iy, Im] = fast_update_score(scorep, Ixp, Iyp, child.defid, ...
    child.occfilter, child.leaf, child.b, ...
    child.def_id_for_share_dt,K,L,n_y,n_x);

% Caches various statistics from the model data structure for later use.
function [components, filters, resp] = modelComponents(model, pyra)

components = cell(length(model.components), 1);
for c = 1 : length(model.components),
    if(length(model.filters) == 1)
        non_zero_id = 1;
    else
        pids = model.opts.mixture(c).poolid(:);
        non_zero_id = pids(find(pids, 1));
    end
    x = model.filters(non_zero_id);
    filter_size = size(x.w);
    
    for k = 1:length(model.components{c}),
        p = model.components{c}(k);
        [p.w,p.defI,p.starty,p.startx,p.step,p.level,p.Ix,p.Iy] = deal([]);
        [p.scale,p.level,p.Ix,p.Iy] = deal(0);
        
        par = p.parent;
        assert(par < k);
        INF = 1e10;
        p.b = -INF * ones(size(p.biasid));
        p.biasI = zeros(size(p.biasid));
        for fp = 1:size(p.biasid,1)
            for f = 1:size(p.biasid,2)
                if p.biasid(fp,f) == 0, continue, end;
                x = model.bias(p.biasid(fp,f));
                p.b(fp,f) = x.w;
                p.biasI(fp,f) = x.i;
            end
        end
        p.b = reshape(p.b, [1 size(p.biasid)]);
        
        p.sizx  = zeros(length(p.filterid),1);
        p.sizy  = zeros(length(p.filterid),1);
        for f = 1:length(p.filterid)
            if(p.filterid(f)==0)
                p.sizy(f) = filter_size(1);
                p.sizx(f) = filter_size(2);
            else
                x = model.filters(p.filterid(f));
                [p.sizy(f), p.sizx(f), ~] = size(x.w);
            end
        end
        
        for fp = 1:size(p.defid, 1)
            for f = 1:size(p.defid, 2)
                if p.defid(fp,f) == 0, continue, end;
                x = model.defs(p.defid(fp, f));
                p.w(:,fp,f) = x.w';
                p.defI(fp,f) = x.i;
                ax = x.anchor(1);
                ay = x.anchor(2);
                ds = x.anchor(3);
                p.scale = ds + components{c}(par).scale;
                % Amount of (virtual) padding to hallucinate.
                step = 2 ^ ds;
                virtpady = (step - 1) * pyra.pady;
                virtpadx = (step - 1) * pyra.padx;
                % Starting points (simulates additional padding at finer scales)
                p.starty(fp,f) = ay - virtpady;
                p.startx(fp,f) = ax - virtpadx;
                p.step = step;
            end
        end
        components{c}(k) = p;
    end
    
    for k = 1 : length(model.components{c})
        components{c}(k).leaf = 1;
    end
    for k = 1 : length(model.components{c})
        p = model.components{c}(k);
        if(p.parent > 0)
            components{c}(p.parent).leaf = 0;
        end
    end
    
end

resp = cell(length(pyra.feat), 1);
filters = cell(length(model.filters), 1);
for i = 1 : length(filters),
    filters{i} = model.filters(i).w;
end
