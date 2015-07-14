load('OFD/annotations');
for i = 1: length(ground_truth)
    figure(1); clf;
    imshow(imread(ground_truth(i).im)); hold on;
    
    bb = ground_truth(i).BB;
    for j = 1 : size(bb, 2)
        x = bb([1 1 3 3 1], j);
        y = bb([2 4 4 2 2], j);
        if(ground_truth(i).occ(j) == 2)
            col = 'm';
        elseif(ground_truth(i).occ(j) == 1)
            col = 'r';
        else
            col = 'g';
        end
        plot(x, y, col, 'linewidth', 2);
    end
    fprintf('Press any key to show next image\n');
    pause;
end

