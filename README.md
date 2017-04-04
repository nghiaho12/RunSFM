This is my own packaging of Bundler and CMVS with some modifications made to speed up processing.
I've also tried to simplify the compilation and make things easy as possible.

The modifications I've made include:

- Threaded SIFT key extraction using OpenMP (SiftKey)
- Threaded SIFT key matching using OpenMP (SiftMatcher)
- Uses both Levenberg-Marquardt and GSL Simplex to do patch optimisation in PMVS. I've seen up to 40% speed up in the PMVS process.
- Other minor code optimisation in PMVS

Some changes unrelated to speed optimisation:
- Removed local copies of lapack, blas, gsl. It uses the one installed by the OS.
- Removed massive dataset included by CMVS

### REQUIREMENTS
The following libraries are required, which are probably not installed by default on most Linux systems:

- cmake
- cblas
- lapack
- atlas
- gsl

On Ubuntu 11.04, all these libraries are available in Synaptics. Make sure to install the development package.
 
The following libraries are provided in this package, because I could not find them on Synaptics:

- graclus
- flann
- lmfit

### COMPILING
To compile simply type 'make'. After compilation you will be reminded to copy bundler-v0.4-source/lib/libANN_char.so to /usr/local/lib and type ldconfig. Don't forget to do it!

### RUNNING
Go to the directory containing all your images. Then type:
```
(path to RunSFM)/RunSFM.sh 
```
Grab some coffee ...and that's it!
The 3D model files will be in pmvs/models

RunSFM.sh has optional arguments, which you can pass:
```
RunSFM.sh [IMAGES_PER_CLUSTER=100] [CPU_CORES=8] [MAX_MATCHING_SEQ=-1]
```
IMAGES_PER_CLUSTER is used by CMVS/PMVS2
CPU_CORES is used by CMVS/PMVS2

The default is 100 images and 8 CPU cores. If you have limited RAM then reduce the images per CMVS cluster. 
MAX_MATCHING_SEQ limits the matching of an image to the last N images, useful if the images were captured sequentially eg. video. A value of -1 will do the full permutation and match every image pair possible. This has a time complexity of O(N*N/2), so be careful!

### LICENSE
You are free to do whatever with this package. Each individual software in this package will have their own license. As for mine, you are free to use it as you like. 


### NOTES
I've found that using SiftGPU, specifically BundlerMatcher by Henri Astri (http://www.visual-experiments.com), can sometimes produce less accurate results than David Lowe's binary file. In some cases the results are bad enough to cause Bundle to fail.

I've had a look at using Intel's Math Kernel Library (MKL) but found it slightly slower than using Atlas, at least for my limited test case. I've noticed MKL will use more than 1 CPU core when running Bundler. But I suspect my dataset was too small to benefit from multi-core. When linking Bundler to Atlas, it used only 1 CPU core despite explicitly linking to the multi-threaded version.
