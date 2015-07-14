function ShowPoints(im, boxes)
clf;
imagesc(im);
axis equal;
axis off;
grid off;
hold on;
for b = boxes,
    plot(b.det(b.occ==1, 1), b.det(b.occ == 1, 2), '.r', 'MarkerSize', 4);
    plot(b.det(b.occ==0, 1), b.det(b.occ == 0, 2), '.g', 'MarkerSize', 4);
end
drawnow;
