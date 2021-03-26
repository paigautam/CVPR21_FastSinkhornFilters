# Fast-Sinkhorn-Filters

This is a sample demo-code for our CVPR 2021 paper: Fast Sinkhorn Filters - Using Matrix Scaling for Non-Rigid Shape Correspondence with Functional Maps, by [Gautam Pai](https://sites.google.com/view/paigautam/home), [Jing Ren](https://ren-jing.com/), [Simone Melzi](https://sites.google.com/site/melzismn/), [Peter Wonka](http://peterwonka.net/) and [Maks Ovsjanikov](http://www.lix.polytechnique.fr/~maks/)

![Alt text](Figures/Teaser_Sinkhorn.png?raw=true)
## Main Functions

```
[S,T12,T21] = fast_sinkhorn_filter(KTar,KSrc,options)

%{
***Input***
(1.) KSrc -- a M X K Matrix of Features/Aligned Basis/Embedding in Source Shape with M Points and
K Features
(2.) KTar -- a N X K Matrix of Features/Aligned Basis/Embedding in Target Shape with N Points and
K Features
(3.) (optional) options struct - see below

***Output*** 
(1.) S -- The M X N doubly stochastic matrix after matrix scaling 
(2.) T12 -- pointwise forward map, i.e. Source(Src) to Target(Tar) 
(3.) T21 -- pointwise backward map, i.e. Target(Tar) to Source(Src)

***Parameters***
An options struct with the following
(1.) p -- (power of the distance for assignment matrix) - default set to 1
(2.) knn -- number of nearest neighbors for sparsifying kernel - default set to 50
(3.) distmax -- factor for choosing lambda, default value 500 as per https://marcocuturi.net/SI.html
(4.) maxiter -- number of matrix scaling iterations desired (~ 10-50)
(5.) kernel_type -- 'full' or 'sparse' (default) depending on nature of kernel desired. Choose 'sparse' for faster mode. 

***Additional Comments*** 
You can replace the knnsearch in this script with a possibly faster
k-nearest neighbor implementation for improved performance
%}
```

## Comments

The script ```demo.m``` runs our Fast Sinkhorn Filter with 2 experiments:
  
 1. A pointwise conversion using a ground-truth *Adjoint Map* operator (which we prove in the paper to be optimal for transferring delta functions in order to establish a pointwise correspondence from a functional representation) using the nearest neighbor and the proposed fast sinkhorn filter. We evaluate various geometric and functional metrics like: gt-error, bijectivity, spectral chamfer distance etc. as a function of the spectral basis size.
<img src="Figures/metric.png" width="900">
  
 2. Comparing the original and *Sinkhornized* versions of **ICP** and [**Zoomout**](https://github.com/llorz/SGA19_zoomOut) refinement algorithms. We show the ground truth error curves and also visualize the error map on ths source surface:
   <img src="Figures/map_err.png" width="900">
 

[![License: CC BY-NC 4.0](https://img.shields.io/badge/License-CC%20BY--NC%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by-nc/4.0/)

This work is licensed under a [Creative Commons Attribution-NonCommercial 4.0 International License](http://creativecommons.org/licenses/by-nc/4.0/). For any commercial uses or derivatives, please contact us (gautamppai89@gmail.com, jing.ren@kaust.edu.sa, melzismn@gmail.com , peter.wonka@kaust.edu.sa, maks@lix.polytechnique.fr).

