function [BB, ids, confidence] = ReadDetectionResults(filename)

fid = fopen(filename, 'r');
ids = [];
confidence = [];
BB = [];
while ~feof(fid)
    nextline = fgets(fid);
    imageid = sscanf(nextline, '%s', 1);
    nextline = nextline(length(imageid) + 1 : end); 
    tbox = sscanf(nextline, '%f');
    tBB(1, 1) = tbox(1);
    tBB(2, 1) = tbox(2);
    tBB(3, 1) = tbox(3);
    tBB(4, 1) = tbox(4);
    
    BB = [BB tBB];
    confidence = [confidence; tbox(5)];
    ids{end + 1, 1} = imageid;
end
fclose(fid);
