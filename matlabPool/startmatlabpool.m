function startmatlabpool(max_workers)

if (verLessThan('matlab', '8.3.0'))
    if matlabpool('size') > 0
        return
    end
else
    if ~isempty(gcp('nocreate'))
        return
    end
end

found = false;
for i = 1 : 1000
    fname = sprintf('~/.matlab/local_pools/pool.%d', i);
    if ~isdir(fname)
        found = true;
        break;
    end
end
if (~found)
    error('Couldn''t find an empty MATLAB pool to use.')
end
mkdir(fname);
disp(fname)
if (verLessThan('matlab', '8.3.0'))
    schd = findResource('scheduler', 'configuration', defaultParallelConfig);
    schd.DataLocation = fname;
    if(exist('max_workers', 'var'))
        matlabpool(schd, max_workers);
	else
    	matlabpool(schd);
	end
else
    schd = parcluster(parallel.defaultClusterProfile);
    set(schd, 'JobStorageLocation', fname);
    if(exist('max_workers', 'var'))
        parpool(schd, max_workers);
    else
        parpool(schd);
    end
end


