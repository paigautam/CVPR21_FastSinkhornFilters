%{

  Demo for Fast Sinkhorn Filter - a fast, accurate and bijective pointwise functional-map conversion - CVPR 2021

%}
%%
clc; close all; clear;
addpath(genpath('utils/'));
addpath('func_main/');
mesh_dir = 'data/';
addpath(mesh_dir);

s1_name = 'Man0';
s2_name = 'Man1';

%% Read the mesh and compute the LB basis
disp('reading shapes ...');
S1 = MESH.MESH_IO.read_shape([mesh_dir, s1_name]);
S2 = MESH.MESH_IO.read_shape([mesh_dir, s2_name]);

S1 = MESH.compute_LaplacianBasis(S1, 100);
S2 = MESH.compute_LaplacianBasis(S2, 100);

disp('done ...');
% load('tr_reg_004.mat'); S1.Gamma = D; D = [];
% load('tr_reg_009.mat'); S2.Gamma = D; D = [];

%% Pointwise Map Conversion - Compare between Nearest Neighbor and Fast Sinkhorn Filter 

disp('Compare pointwise conversion of F-Map using NN and Sinkhorn (Figure 1) ...');

numbasis = 10:10:90; 

time_nn = zeros(length(numbasis),1); time_sinkhorn = time_nn;
errs_nn = zeros(length(numbasis),1); errs_sinkhorn = errs_nn;

for i = 1:length(numbasis)
    
    SrcLaplaceBasis = S1.evecs(:,1:numbasis(i)); TarLaplaceBasis = S2.evecs(:,1:numbasis(i)); % choose number of basis functions    
    A = TarLaplaceBasis' * pinv(SrcLaplaceBasis)';% Ground truth - Adjoint Map (gt: FAUST original) 
    
    KSrc = SrcLaplaceBasis*A';KTar = TarLaplaceBasis; % Align the basis with Adjoint Operator 
    
    tic;
    nn = knnsearch(KTar,KSrc);% Nearest Neighbor
    time_nn(i) = toc;  
    
    tic;
    [~,sinkhorn,~] = fast_sinkhorn_filter(KTar,KSrc); % Fast Sinkhorn Filter 
    time_sinkhorn(i) = toc; 
    
    % Evaluate Errors
    type = 'euclidean';
    errs_nn(i) = mean(fMAP.eval_pMap(S1, S2, nn, [(1:S1.nv)' (1:S2.nv)'],type));
    errs_sinkhorn(i) = mean(fMAP.eval_pMap(S1, S2, sinkhorn, [(1:S1.nv)' (1:S2.nv)'],type));
    
end

% Plot the errors and times as a function of basis size 
figure(1);
fs = 15;

subplot(1,2,1);
plot(numbasis,errs_nn,'LineWidth',2); hold on; 
plot(numbasis,errs_sinkhorn,'LineWidth',2); hold off;
xlabel('Spectral Basis Size','FontSize',fs); 
ylabel('Mean GT Error','FontSize',fs); 
legend(' NN',' Sinkhorn','FontSize',fs); 
axis([0 max(numbasis) 0 0.05]);
axis vis3d; 
title('Error','FontSize',fs); 


subplot(1,2,2);
plot(numbasis,time_nn,'LineWidth',2); hold on; 
plot(numbasis,time_sinkhorn,'LineWidth',2); hold off;
xlabel('Spectral Basis Size','FontSize',fs); 
ylabel('Runtime (sec)','FontSize',fs); 
legend(' NN',' Sinkhorn','FontSize',fs);
axis([0 max(numbasis) 0 5]);
title('Runtime','FontSize',fs); 
axis vis3d; 

sgtitle('Pointwise Map Conversion','FontSize',20) ;

drawnow;

disp('done ... ');

%% Compare between Original and Sinkhornized versions of ICP and Zoomout

disp('Compare between Original and Sinkhornized versions of ICP and Zoomout....');

ini = dlmread('Man0_Man1.map'); % Initial Noisy Map 

numIter = 5;
[map_icp_nn,~] = icp_refine(S1.evecs, S2.evecs, ini, numIter, 'nn');
[map_icp_sinkhorn,~] = icp_refine(S1.evecs, S2.evecs, ini, numIter, 'sinkhorn');
disp('icp done ...');

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

figure(3);
fs = 10; cmax = 0.08;
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


x0=500;
y0=500;
width=550;
height=800;
set(gcf,'position',[x0,y0,width,height])




