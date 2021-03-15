# Fast-Sinkhorn-Filters

This is a sample demo-code for Fast Sinkhorn Filters - Using Matrix Scaling for Non-Rigid Shape Correspondence with Functional Maps from CVPR 2021. 

![Alt text](Figures/Teaser_Sinkhorn.png?raw=true)

```
[S,T12,T21] = fast_sinkhorn_filter(KTar,KSrc,options)

%{
***Input***

(1.) KSrc -- a N X K Matrix of Features/Aligned Basis/Embedding in Source Shape with M Points and
K Features
(2.) KTar -- a M X K Matrix of Features/Aligned Basis/Embedding in Target Shape with N Points and
K Features
(3.) iter -- number of matrix scaling iterations desired (~ 10-50)

***Output*** 

(1.) S -- The M X N doubly stochastic matrix after matrix scaling 
(2.) T12 -- pointwise forward map, i.e. Source(Src) to Target(Tar) 
(3.) T21 -- pointwise backward map, i.e. Target(Tar) to Source(Src)

***Parameters***

An options struct with the following

(1.) p -- (power of the distance for assignment matrix) - default set to 1
(2.) knn -- number of nearest neighbors for sparsifying kernel
(3.) distmax -- factor for choosing lambda, default value 200 as per https://marcocuturi.net/SI.html
(4.) maxiter -- number of sinkhorn iterations desired
(5.) kernel_type -- 'full' or 'sparse' depending on nature of kernel
desired. Choose 'sparse' for fastest mode
%}
```
