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

// matlab entry point
// [score, Ix, Iy, Im] = dt(scorep, Ixp, Iyp, defid, occfilter, leaf, b, localdefid, K, L, Ny, Nx)
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
	int leaf = (int)mxGetScalar(prhs[5]);
	double *b = (double *)mxGetPr(prhs[6]);
	double *localdefid = (double *)mxGetPr(prhs[7]);
	int K = (int)mxGetScalar(prhs[8]);
	int L = (int)mxGetScalar(prhs[9]);
	int Ny = (int)mxGetScalar(prhs[10]);
	int Nx = (int)mxGetScalar(prhs[11]);

	mwSize ndim = 3;
	mwSize dims[3] = {Ny, Nx, L};
	mxArray *mxScore = mxCreateNumericArray(ndim, dims, mxDOUBLE_CLASS, mxREAL);
	mxArray *mxIy = mxCreateNumericArray(ndim, dims, mxINT32_CLASS, mxREAL);
	mxArray *mxIx = mxCreateNumericArray(ndim, dims, mxINT32_CLASS, mxREAL);
	mxArray *mxIm = mxCreateNumericArray(ndim, dims, mxINT32_CLASS, mxREAL);
	double *score = (double *)mxGetPr(mxScore);
	int *Iy = (int *)mxGetPr(mxIy);
	int *Ix = (int *)mxGetPr(mxIx);
	int *Im = (int *)mxGetPr(mxIm);

	double init_value[20];
	int init_im[20];

	for(int l=0; l<L; l++) //loop over parent mixtures
	{
		init_value[l] = -INF;
		init_im[l] = 0;
	}
	if(leaf)
	{
		for(int l=0; l<L; l++) //loop over parent mixtures
		{
			for(int k=0; k<K; k++)
				if(occfilter[k] && gv2(defid,L,l,k)>0 && gv2(b,L,l,k)>init_value[l])
				{
					init_value[l] = gv2(b,L,l,k);
					init_im[l] = k+1;
				}
		}
	}
	int * Im_ind = Im;
	double *score_ind = score;
	for(int l=0; l<L; l++)
		for(int j=0; j<Nx; j++)
			for(int i=0; i<Ny; i++)
			{
				*score_ind = init_value[l];
				*Im_ind = init_im[l];
				Im_ind++;
				score_ind++;
			}

	int ind_2d = 0;
	for(int k=0; k<K; k++) // loop over child mixtures
	{
		score_ind = score;
		Im_ind = Im;
		int * Ix_ind = Ix;
		int * Iy_ind = Iy;
		for(int l=0; l<L; l++) // loop over parent mixtures
		{
			if(defid[ind_2d] > 0 && (occfilter[k]==0 || leaf==0))
			{
				double bias = b[ind_2d];
				int lid = localdefid[ind_2d] - 1; // 0-base
				double * scorep_ind = scorep + lid*Ny*Nx;
				int * Ixp_ind = Ixp + lid*Ny*Nx;
				int * Iyp_ind = Iyp + lid*Ny*Nx;
				for(int j=0; j<Nx; j++) // loop over the location
				{
					for(int i=0; i<Ny; i++) // loop over the location
					{
						double score0 = *scorep_ind + bias;
						if(score0 > *score_ind) // Computes the max
						{
							*score_ind = score0;
							*Ix_ind = *Ixp_ind;
							*Iy_ind = *Iyp_ind;
							*Im_ind = k+1;
						}
						scorep_ind++;
						Ixp_ind++;
						Iyp_ind++;

						score_ind++;
						Im_ind++;
						Ix_ind++;
						Iy_ind++;
					}
				}
			}
			else
			{
				score_ind += Ny*Nx;
				Im_ind += Ny*Nx;
				Ix_ind += Ny*Nx;
				Iy_ind += Ny*Nx;
			}
			ind_2d++;
		}
	}

	plhs[0] = mxScore;
	plhs[1] = mxIx;
	plhs[2] = mxIy;
	plhs[3] = mxIm;
}
