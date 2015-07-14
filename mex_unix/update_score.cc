#define INF 1E20
#include <math.h>
#include <assert.h>
#include <sys/types.h>
#include "mex.h"

/*
 * updatescore.cc
 * A helper function for message passing.
 * This function performs second step of message passing which is explained in section
 * 3.2 of our "Occlusion Coherence: Detecting and Localizing Occluded Faces" paper.
 */
#define gv2(A,dim1,i,j) A[(i)+(j)*dim1]
#define gv3(A,dim1,dim2,i,j,k) A[(i)+((j)+(k)*dim2)*dim1]

#define sv2(A,dim1,i,j,v) A[(i)+(j)*dim1] = v
#define sv3(A,dim1,dim2,i,j,k,v) A[(i)+((j)+(k)*dim2)*dim1] = v

// matlab entry point
// [score, Ix, Iy, Im] = dt(scorep, Ixp, Iyp, defid, occfilter, b, localdefid, K, L, Ny, Nx)
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) { 
  if (nrhs != 12)
    mexErrMsgTxt("Wrong number of inputs"); 
  if (nlhs != 4)
    mexErrMsgTxt("Wrong number of outputs");
  if (mxGetClassID(prhs[0]) != mxDOUBLE_CLASS)
    mexErrMsgTxt("Invalid input");

  // Read in ...
  double *scorep = (double *)mxGetPr(prhs[0]);
  int32_t *Ixp = (int32_t *)mxGetPr(prhs[1]);
  int32_t *Iyp = (int32_t *)mxGetPr(prhs[2]);
  double *defid = (double *)mxGetPr(prhs[3]);
  mxLogical *occfilter = (mxLogical *)mxGetLogicals(prhs[4]);
  int leaf  = (int)mxGetScalar(prhs[5]);
  double *b = (double *)mxGetPr(prhs[6]);
  double *localdefid = (double *)mxGetPr(prhs[7]);
  int K  = (int)mxGetScalar(prhs[8]);
  int L  = (int)mxGetScalar(prhs[9]);
  int Ny  = (int)mxGetScalar(prhs[10]);
  int Nx  = (int)mxGetScalar(prhs[11]);

  mwSize ndim = 3;
  mwSize dims[3] = {Ny, Nx, L};
  mxArray  *mxScore = mxCreateNumericArray(ndim, dims, mxDOUBLE_CLASS, mxREAL );
  mxArray  *mxIy    = mxCreateNumericArray(ndim, dims, mxINT32_CLASS, mxREAL );
  mxArray  *mxIx    = mxCreateNumericArray(ndim, dims, mxINT32_CLASS, mxREAL );
  mxArray  *mxIm    = mxCreateNumericArray(ndim, dims, mxINT32_CLASS, mxREAL );
  double   *score = (double *)mxGetPr(mxScore);
  int *Iy = (int *)mxGetPr(mxIy);
  int *Ix = (int *)mxGetPr(mxIx);
  int *Im = (int *)mxGetPr(mxIm);

  for(int l = 0; l<L; l++)
    for(int j=0;j<Nx;j++)
      for(int i=0; i<Ny; i++)
		sv3(score,Ny,Nx,i,j,l, -1000000);


  for(int l = 0; l<L; l++)
  {
    for(int k = 0; k<K; k++)
	{
	  double bias = gv3(b,1,L,0,l,k);
      if(gv2(defid,L,l,k) > 0)
	  {
		if(occfilter[k]==1 && leaf==1)
		{
			for(int j=0; j<Nx; j++)
			  for(int i=0; i<Ny; i++)
			  {
				if(gv3(score,Ny,Nx,i,j,l)<bias)
				{
					sv3(score,Ny,Nx,i,j,l,bias);
					sv3(Im,Ny,Nx,i,j,l,k+1);
				}
			  }
		}
		else
		{
			int lid = gv2(localdefid,L,l,k)-1; // 0-base
			for(int j=0;j<Nx;j++)
			  for(int i=0;i<Ny;i++)
			  {
				double score0 = gv3(scorep,Ny,Nx,i,j,lid) + bias;
				if(score0>gv3(score,Ny,Nx,i,j,l))
				{
					sv3(score,Ny,Nx,i,j,l,score0);
					sv3(Ix,Ny,Nx,i,j,l,(int)gv3(Ixp,Ny,Nx,i,j,lid));
					sv3(Iy,Ny,Nx,i,j,l,(int)gv3(Iyp,Ny,Nx,i,j,lid));
					sv3(Im,Ny,Nx,i,j,l,k+1);
				}
			  }
		}
	  }	
	}
  }

  plhs[0] = mxScore;
  plhs[1] = mxIx;
  plhs[2] = mxIy;
  plhs[3] = mxIm;
}
