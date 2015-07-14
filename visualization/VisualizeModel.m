function VisualizeModel(model, num_instances)

if nargin < 2
    num_instances = 1;
end

for compid = 1 : length(model.components)
	if(model.flip_image(compid))
		% This component shares its parameters with the component for opposite viewpoint.
		continue;
	end
    c = model.components{compid};
    numparts = length(c);
    
    % Samples part mixtures to show.
    m = zeros(numparts, num_instances);
    for i = 1 : num_instances
        m(1, i) = randi(length(c(1).filterid));
        for k = 2 : numparts
            pa = c(k).parent;
            I = find(c(k).defid(m(pa, i), :) > 0);
            m(k, i) = I(randi(length(I)));
        end
    end
    
    for i = 1 : num_instances
		% Visualizes HOG templates.
        figure;
        VisualizeComponentFilters(model, compid, m(:, i)); axis on;
       
		% Visualizes skeleton.
        figure;
        VisualizeComponentSkeleton(model, compid, m(:, i), model.opts);
    end
end

function VisualizeComponentFilters(model, compid, mix)

pad = 2;
bs = 20;

c = model.components{compid};
num_parts = length(c);
k = 1;
part = c(1);

fids = [model.components{compid}.filterid];
non_zero_fid = fids(find(fids, 1));
zero_w = zeros(size(model.filters(non_zero_fid).w));

% Part filter
if(part.filterid(mix(k)) ~= 0)
    w = model.filters(part.filterid(mix(k))).w;
    w = foldHOG(w);
    scale = max(abs(w(:)));
else
    fids = [model.components{compid}.filterid];
    w = foldHOG(zero_w);
    scale = 1;
end
p = HOGpicture(w, bs);
p = padarray(p, [pad, pad], 0);
p = uint8(p * (255 / scale));
% border
p(:, 1 : 2 * pad) = 128;
p(:, end - 2 * pad + 1 : end) = 128;
p(1 : 2 * pad, :) = 128;
p(end - 2 * pad + 1 : end, :) = 128;
im = p;
startpoint = zeros(num_parts, 2);
startpoint(1,:) = [0, 0];

partsize = zeros(num_parts, 1);
partsize(1) = size(p, 1);

for k = 2 : num_parts
    part = c(k);
    parent = c(k).parent;
    % part filter
    if(part.filterid(mix(k)) ~= 0)
        w = model.filters(part.filterid(mix(k))).w;
        w = foldHOG(w);
        scale = max(abs(w(:)));
    else
        w = foldHOG(zero_w);
        scale = 1;
    end
    p = HOGpicture(w, bs);
    p = padarray(p, [pad, pad], 0);
    p = uint8(p * (255 / scale));
    % border
    p(:, 1 : 2 * pad) = 128;
    p(:, end - 2 * pad + 1 : end) = 128;
    p(1 : 2 * pad, :) = 128;
    p(end - 2 * pad + 1 : end, :) = 128;
    
    % paste into root
    def = model.defs(part.defid(mix(parent), mix(k)));
    
    x1 = (def.anchor(1) - 1) * bs + 1 + startpoint(parent, 1);
    y1 = (def.anchor(2) - 1) * bs + 1 + startpoint(parent, 2);
    
    [H W] = size(im);
    imnew = zeros(H + max(0, 1 - y1), W + max(0, 1 - x1));
    imnew(1 + max(0, 1 - y1) : H + max(0, 1 - y1), ...
		  1 + max(0, 1 - x1) : W + max(0, 1 - x1)) = im;
    im = imnew;
    
    startpoint = startpoint + repmat([max(0, 1 - x1), ...
									  max(0, 1 - y1)], [num_parts, 1]);
    
    x1 = max(1, x1);
    y1 = max(1, y1);
    x2 = x1 + size(p, 2) - 1;
    y2 = y1 + size(p, 1) - 1;
    
    startpoint(k, 1) = x1 - 1;
    startpoint(k, 2) = y1 - 1;
    
    im(y1 : y2, x1 : x2) = p;
    partsize(k) = size(p, 1);
end

% plot parts
imagesc(im);
colormap gray; axis equal; axis off; drawnow;

function f = foldHOG(w)
% f = foldHOG(w)
% Condense HOG features into one orientation histogram.
% Used for displaying a feature.

f=max(w(:,:,1:9),0)+max(w(:,:,10:18),0)+max(w(:,:,19:27),0);

function im = HOGpicture(w, bs)
% HOGpicture(w, bs)
% Make picture of positive HOG weights.

% construct a "glyph" for each orientaion
bim1 = zeros(bs, bs);
bim1(:,round(bs/2):round(bs/2)+1) = 1;
bim = zeros([size(bim1) 9]);
bim(:,:,1) = bim1;
for i = 2:9,
    bim(:,:,i) = imrotate(bim1, -(i-1)*20, 'crop');
end

% make pictures of positive weights bs adding up weighted glyphs
s = size(w);
w(w < 0) = 0;
im = zeros(bs*s(1), bs*s(2));
for i = 1:s(1),
    iis = (i-1)*bs+1:i*bs;
    for j = 1:s(2),
        jjs = (j-1)*bs+1:j*bs;
        for k = 1:9,
            im(iis,jjs) = im(iis,jjs) + bim(:,:,k) * w(i,j,k);
        end
    end
end

function VisualizeComponentSkeleton(model, compid, mix, opts)

c = model.components{compid};
numparts = length(c);

bs = 4;

varCol = 'g';
varInvCol = 'r';
hlevelCol = 'k';

point(1, :) = [bs * 5 / 2 + 1, bs * 5 / 2 + 1];
startpoint = zeros(numparts, 2);
startpoint(1, :) = [0 0];
isoc = false(1, numparts);
for k = 2 : numparts
    part = c(k);
    pa = c(k).parent;
    
    if(part.occfilter(mix(k)))
        isoc(k) =true;
    end
    
    % Pastes into root
    def = model.defs(part.defid(mix(pa),mix(k)));
    
    %x1 = (def.anchor(1)-1+round(def.w(2)/def.w(1)/2))*bs+1 + startpoint(pa,1);
    %y1 = (def.anchor(2)-1+round(def.w(4)/def.w(3)/2))*bs+1 + startpoint(pa,2);
    x1 = (def.anchor(1)-1)*bs+1 + startpoint(pa,1);
    y1 = (def.anchor(2)-1)*bs+1 + startpoint(pa,2);
    x2 = x1 + bs*5+1 -1;
    y2 = y1 + bs*5+1 -1;
    
    startpoint(k,1) = x1 - 1;
    startpoint(k,2) = y1 - 1;
    
    point(k,:) = [(x1+x2)/2,(y1+y2)/2];
    
    radius(k,:) = [sqrt(1/2/def.w(1)) sqrt(1/2/def.w(3))];
end

x1 = min(point(:,1));
y1 = min(point(:,2));
x2 = max(point(:,1));
y2 = max(point(:,2));

% Plots anchor points
plot(point(opts.mixture(compid).part_level==1,1), ...
     -point(opts.mixture(compid).part_level==1,2), 'b.', 'markersize', 20);
hold on;
plot(point(opts.mixture(compid).part_level==2,1), ...
     -point(opts.mixture(compid).part_level==2,2), 'k.', 'markersize', 25);

% Plots occlsion
plot(point(isoc,1), -point(isoc,2), 'r.', 'markersize', 20);

% Draw skeletons
for k = 2 : numparts
    pa = c(k).parent;
    line([point(pa,1) point(k,1)], -[point(pa,2) point(k,2)], ...
         'linewidth', 4);
end
% Draw variance of deformations
for k = 1 : numparts
    if(opts.mixture(compid).part_level(k) == 2)
        col = hlevelCol;
    elseif(isoc(k))
        col = varInvCol;
    else
        col = varCol;
    end
    ellipse(radius(k, 1), radius(k, 2), 0, point(k, 1), -point(k, 2), col);
end
axis off; axis equal;
xlim([x1-10, x2+10]); ylim([-y2-10, -y1+10]);
set(gcf, 'Color', 'w');
