%{

  Demo for Fast Sinkhorn Filter - a fast, accurate and bijective pointwise functional-map conversion - CVPR 2021

%}
%%
clc; close all; clear all;
addpath(genpath('utils/'));
addpath('func_main/');
mesh_dir = 'data/';
addpath(mesh_dir);

s1_name = 'Man0';
s2_name = 'Man1';

%% Read the mesh and compute the LB basis
disp('reading shapes ...');
S1 = MESH.MESH_IO.read_shape([mesh_dir, s1_name]);S1 = MESH.compute_LaplacianBasis(S1, 100);S1.cor = 1:S1.nv;
S2 = MESH.MESH_IO.read_shape([mesh_dir, s2_name]);S2 = MESH.compute_LaplacianBasis(S2, 100);S2.cor = 1:S2.nv;
disp('done ...');

%% Pointwise Map Conversion - Compare between Nearest Neighbor and Fast Sinkhorn Filter using various metrics

disp('Compare pointwise conversion of F-Map using NN and Sinkhorn (Figure 1) ...');

numbasis = 10:10:90; 

time_nn = zeros(length(numbasis),1); time_sinkhorn = time_nn;
errs_nn = zeros(length(numbasis),1); errs_sinkhorn = errs_nn;
bijectivity_nn = zeros(length(numbasis),1); bijectivity_sinkhorn = zeros(length(numbasis),1);
smoothness_nn = zeros(length(numbasis),1); smoothness_sinkhorn = zeros(length(numbasis),1);
coverage_nn = zeros(length(numbasis),1); coverage_sinkhorn = zeros(length(numbasis),1);
chamfer_nn = zeros(length(numbasis),1); chamfer_sinkhorn = zeros(length(numbasis),1);

for i = 1:length(numbasis)
    
    SrcLaplaceBasis = S1.evecs(:,1:numbasis(i)); TarLaplaceBasis = S2.evecs(:,1:numbasis(i)); % choose number of basis functions    
    A = TarLaplaceBasis' * pinv(SrcLaplaceBasis)';% Ground truth - Adjoint Map (gt: FAUST original) 
    
    KSrc = SrcLaplaceBasis*A';KTar = TarLaplaceBasis; % Align the basis with Adjoint Operator 
    
    tic;
    nn12 = knnsearch(KTar,KSrc);nn21 = knnsearch(KSrc,KTar);% Nearest Neighbor
    time_nn(i) = toc;  
    
    tic;
    [~,sinkhorn12,sinkhorn21] = fast_sinkhorn_filter(KTar,KSrc); % Fast Sinkhorn Filter 
    time_sinkhorn(i) = toc; 
    
    %% Geometric Metrics
    geo_metrics_nn = measure_geometric_metrics(S1,S2,nn12,nn21);
    geo_metrics_sinkhorn = measure_geometric_metrics(S1,S2,sinkhorn12,sinkhorn21);
    
    % Functional Metrics
    func_metrics_nn = measure_functional_metrics(S1,S2,nn12);
    func_metrics_sinkhorn = measure_functional_metrics(S1,S2,sinkhorn12);
    
    errs_nn(i) = geo_metrics_nn.gt_error; errs_sinkhorn(i) = geo_metrics_sinkhorn.gt_error;
    bijectivity_nn(i) = geo_metrics_nn.bijectivity; bijectivity_sinkhorn(i) = geo_metrics_sinkhorn.bijectivity;
    smoothness_nn(i) = geo_metrics_nn.smoothness; smoothness_sinkhorn(i) = geo_metrics_sinkhorn.smoothness;
    coverage_nn(i) = geo_metrics_nn.coverage; coverage_sinkhorn(i) = geo_metrics_sinkhorn.coverage;
    chamfer_nn(i) = func_metrics_nn.chamfer; chamfer_sinkhorn(i) = func_metrics_sinkhorn.chamfer;

end

%% Plot the map-metrics as a function of basis size 

h = figure(1);set(h,'position',[500,500,900,700])
fs = 15;

subplot(2,3,1);
plot(numbasis,errs_nn,'LineWidth',2); hold on; 
plot(numbasis,errs_sinkhorn,'LineWidth',2); hold off;
xlabel('Spectral Basis Size','FontSize',fs); ylabel('Mean GT Error','FontSize',fs); 
legend(' NN',' Sinkhorn','FontSize',fs); 
axis([0 max(numbasis) 0 0.05]);axis vis3d; 
title('Gt-Error','FontSize',fs); 


subplot(2,3,6);
plot(numbasis,time_nn,'LineWidth',2); hold on; 
plot(numbasis,time_sinkhorn,'LineWidth',2); hold off;
xlabel('Spectral Basis Size','FontSize',fs); ylabel('Runtime (sec)','FontSize',fs); 
legend(' NN',' Sinkhorn','FontSize',fs);
axis([0 max(numbasis) 0 5]); axis vis3d; 
title('Runtime','FontSize',fs);


subplot(2,3,2);
plot(numbasis,bijectivity_nn,'LineWidth',2); hold on; 
plot(numbasis,bijectivity_sinkhorn,'LineWidth',2); hold off;
xlabel('Spectral Basis Size','FontSize',fs); ylabel('Bijection error','FontSize',fs); 
legend(' NN',' Sinkhorn','FontSize',fs);
axis([0 max(numbasis) 0 0.05]); axis vis3d; 
title('Bijectivity','FontSize',fs);

subplot(2,3,4);
plot(numbasis,coverage_nn,'LineWidth',2); hold on; 
plot(numbasis,coverage_sinkhorn,'LineWidth',2); hold off;
xlabel('Spectral Basis Size','FontSize',fs); ylabel('Coverage(%)','FontSize',fs); 
legend(' NN',' Sinkhorn','FontSize',fs);
axis([0 max(numbasis) 0 1]); axis vis3d; 
title('Coverage','FontSize',fs);

subplot(2,3,5);
plot(numbasis,smoothness_nn,'LineWidth',2); hold on; 
plot(numbasis,smoothness_sinkhorn,'LineWidth',2); hold off;
xlabel('Spectral Basis Size','FontSize',fs); ylabel('Dirichlet-Energy','FontSize',fs); 
legend(' NN',' Sinkhorn','FontSize',fs);
axis([0 max(numbasis) 0 70]); axis vis3d; 
title('Smoothness','FontSize',fs);

subplot(2,3,3);
plot(numbasis,chamfer_nn,'LineWidth',2); hold on; 
plot(numbasis,chamfer_sinkhorn,'LineWidth',2); hold off;
xlabel('Spectral Basis Size','FontSize',fs); ylabel('Chamfer-Dist','FontSize',fs); 
legend(' NN',' Sinkhorn','FontSize',fs);
axis([0 max(numbasis) 0 5e4]); axis vis3d; 
title('Spectral-Chamfer Distance','FontSize',fs);

sgtitle('Pointwise Map Conversion','FontSize',20) ;

drawnow; disp('done ... ');

%% Compare between Original and Sinkhornized versions of ICP and Zoomout

disp('Compare between Original and Sinkhornized versions of ICP and Zoomout....');

ini = dlmread('Man0_Man1.map'); % Initial Noisy Map 

%% ICP
numIter = 5;
[map_icp_nn,~] = icp_refine(S1.evecs, S2.evecs, ini, numIter, 'nn');
[map_icp_sinkhorn,~] = icp_refine(S1.evecs, S2.evecs, ini, numIter, 'sinkhorn');
disp('icp done ...');

%% Zoomout
[map_zoomout_nn,~] = zoomout_refine(S1.evecs, S2.evecs, ini, numIter, 'nn');
[map_zoomout_sinkhorn,~] = zoomout_refine(S1.evecs, S2.evecs, ini, numIter, 'sinkhorn');
disp('zoomout done ...');

%% Evaluate Errors

type = 'euclidean';
errs_ini = fMAP.eval_pMap(S1, S2, ini, [(1:S1.nv)' (1:S2.nv)'],type);
errs_icp_nn = fMAP.eval_pMap(S1, S2, map_icp_nn, [(1:S1.nv)' (1:S2.nv)'],type);
errs_icp_sinkhorn = fMAP.eval_pMap(S1, S2, map_icp_sinkhorn, [(1:S1.nv)' (1:S2.nv)'],type);

errs_zoomout_nn = fMAP.eval_pMap(S1, S2, map_zoomout_nn, [(1:S1.nv)' (1:S2.nv)'],type);
errs_zoomout_sinkhorn = fMAP.eval_pMap(S1, S2, map_zoomout_sinkhorn, [(1:S1.nv)' (1:S2.nv)'],type);

%% Plot Errors 

figure(2);fs = 15;
h2 = figure(2);set(h2,'position',[500,500,600,500]);
plot(sort(errs_ini), linspace(0,1,length(errs_ini)),'LineWidth',2);hold on;
plot(sort(errs_icp_nn), linspace(0,1,length(errs_icp_nn)),'LineWidth',2);
plot(sort(errs_icp_sinkhorn), linspace(0,1,length(errs_icp_sinkhorn)),'LineWidth',2);

plot(sort(errs_zoomout_nn), linspace(0,1,length(errs_zoomout_nn)),'LineWidth',2);
plot(sort(errs_zoomout_sinkhorn), linspace(0,1,length(errs_zoomout_sinkhorn)),'LineWidth',2);

xlabel('Distance error threshold','FontSize',fs);
ylabel('Fraction of correspondences','FontSize',fs);
title('Point-to-point map reconstruction error','FontSize',fs);
legend(' Initial',' ICP-NN',' ICP-Sink','Zm-NN','Zm-Sink','FontSize',fs);
axis([0 0.1 0 1]); 

%% Visualize Errors

disp('Visualizing Map errors in Figure (3) ...');

h3 = figure(3);set(h3,'position',[500,500,500,700]);
fs = 15; cmax = 0.08;
subplot(2,3,1);
trimesh(S2.surface.TRIV, S2.surface.X, S2.surface.Y, S2.surface.Z,ones(S2.nv,1),'FaceColor','interp', 'EdgeColor', 'k');
title('Target','FontSize',fs);axis equal;axis off;caxis([0,cmax]);view(0,90);

subplot(2,3,2);
trimesh(S1.surface.TRIV, S1.surface.X, S1.surface.Y, S1.surface.Z,errs_ini,'FaceColor','interp', 'EdgeColor', 'none');
title('Initial Map','FontSize',fs);axis equal;axis off;caxis([0,cmax]);view(0,90);

subplot(2,3,3);
trimesh(S1.surface.TRIV, S1.surface.X, S1.surface.Y, S1.surface.Z,errs_icp_nn,'FaceColor','interp', 'EdgeColor', 'none');
title('ICP-NN','FontSize',fs);axis equal;axis off;caxis([0,cmax]);view(0,90);

subplot(2,3,4);
trimesh(S1.surface.TRIV, S1.surface.X, S1.surface.Y, S1.surface.Z,errs_icp_sinkhorn,'FaceColor','interp', 'EdgeColor', 'none');
title('ICP-Sink','FontSize',fs);axis equal;axis off;caxis([0,cmax]);view(0,90);

subplot(2,3,5);
trimesh(S1.surface.TRIV, S1.surface.X, S1.surface.Y, S1.surface.Z,errs_zoomout_nn,'FaceColor','interp', 'EdgeColor', 'none');
title('ZM-NN','FontSize',fs);axis equal;axis off;caxis([0,cmax]);view(0,90);

subplot(2,3,6);
trimesh(S1.surface.TRIV, S1.surface.X, S1.surface.Y, S1.surface.Z,errs_zoomout_sinkhorn,'FaceColor','interp', 'EdgeColor', 'none');
title('ZM-Sink','FontSize',fs);axis equal;axis off;caxis([0,cmax]);view(0,90);
disp('done...');
sgtitle('Ground Truth Map Errors','FontSize',20) ;







