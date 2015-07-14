function closematlabpool()

if (verLessThan('matlab', '8.3.0'))
    if matlabpool('size') > 0
        return
    end
    matlabpool close
else
    if ~isempty(gcp('nocreate'))
        return
    end
    delete(gcp('nocreate'));
end

% clean up pool folder
dirs = dir('~/.matlab/local_pools');
for d=1:numel(dirs)
    if strcmp(dirs(d).name,'.') || strcmp(dirs(d).name,'..')
        continue;
    end
    files = what(['~/.matlab/local_pools/',dirs(d).name]);
    % delete the leftover metadata mat file
    if numel(files.mat) == 1
        delete(sprintf('%s/%s',files.path,files.mat{1}));
    end
    % delete the directory
    if numel(files.mat) < 2
        rmdir(files.path);
    end
end

