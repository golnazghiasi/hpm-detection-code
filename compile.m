% =============
% Learning code
%cd learning;
%mex -O -largeArrayDims qp_one_sparse.cc
%mex -O -largeArrayDims score.cc
%mex -O -largeArrayDims lincomb.cc
%cd ..;

% =============
% Detection code
if isunix()
    cd mex_unix
    % use one of the following depending on your setup
    % 1 is fastest, 3 is slowest
    % 1) multithreaded convolution using blas
    mex -O fconvblas_gcc445.cc -lmwblas -output fconv
    % 2) mulththreaded convolution without blas
    % mex -O fconvMT.cc -o fconv
    % 3) basic convolution, very compatible
    % mex -O fconv.cc -o fconv
elseif ispc()
    cd mex_pc;
    mex -O fconv.cc
end

mex -O resize.cc
mex -O reduce.cc
mex -O shiftdt.cc
mex -O fast_bounded_shifdt.cc
mex -O features.cc
mex -O fast_update_score.cc

cd ..;
