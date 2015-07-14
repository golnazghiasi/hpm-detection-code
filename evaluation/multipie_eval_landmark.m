function [err] = multipie_eval_landmark(boxes,test)

% number of test images
N = length(test);

% mean error
err = nan(N,1);

for i = 1:N % loop over all test images
    % ground truth
    pts = test(i).pts;
    
    % face size
    w = test(i).bbox(3) - test(i).bbox(1);
    h = test(i).bbox(4) - test(i).bbox(2);
    siz = (w+h)/2;
    
    % detection is empty
    if isempty(boxes{i})
        % Missed detection has infinite localization error
        err(i) = nan;
        continue;
    end
    
    b = boxes{i}(1);
    % detection
    det = b.det_afw;
    
    % the numbers of parts are different
    if(size(det,1)~=size(pts,1))
        err(i) = nan;
        continue;
    end
    
    dif = pts-det;
    e = (dif(:,1).^2+dif(:,2).^2).^0.5;
    err_in_pixel = nanmean(e);
    err(i) = err_in_pixel/siz;
end




function ov = testoverlap(box,pts,thresh)
boxc = [mean(box(:,[1 3]),2) mean(box(:,[2 4]),2)];

b1 = [min(boxc(:,1)) min(boxc(:,2)) max(boxc(:,1)) max(boxc(:,2))];
b2 = [min(pts(:,1)) min(pts(:,2)) max(pts(:,1)) max(pts(:,2))];

bi=[max(b1(1),b2(1)) ; max(b1(2),b2(2)) ; min(b1(3),b2(3)) ; ...
    min(b1(4),b2(4))];
iw=bi(3)-bi(1)+1;
ih=bi(4)-bi(2)+1;
if iw>0 && ih>0
    % compute overlap as area of intersection / area of union
    ua=(b1(3)-b1(1)+1)*(b1(4)-b1(2)+1)+...
        (b2(3)-b2(1)+1)*(b2(4)-b2(2)+1)-...
        iw*ih;
    ov=iw*ih/ua;
end
ov = (ov>thresh);

