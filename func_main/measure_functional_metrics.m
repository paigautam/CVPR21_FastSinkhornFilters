function metrics = measure_functional_metrics(Src,Tar,map)

Pt_Src = Src.evecs(:,1:100);
Pt_Tar = Tar.evecs(:,1:100);

C12 = pinv(Pt_Src)*Pt_Tar(map,:);

chamfer = Chamfer_Distance(Pt_Src*C12, Pt_Tar);

zoomout_energy = zoomOut_energy(C12);

lapl_comm = laplacian_commutativity(Src,Tar,C12);

orth = norm(C12'*C12 - eye(size(C12)));

metrics = struct('chamfer', chamfer, 'zoomout_energy', zoomout_energy,'comm',lapl_comm, 'orth',orth);

end

%% Zoomout Energy

function err = zoomOut_energy(C)
func_ortho_err = @(C) norm(C'*C - eye(size(C)), 'fro');
C12_test = C;
err = 0;
for k = 1:size(C12_test,1)
    err = err + func_ortho_err(C12_test(1:k, 1:k))/k;
end

end
%% Chamfer Distance

function distance = Chamfer_Distance(Pt_Src, Pt_Tar)

[~,d_12] = knnsearch(Pt_Tar,Pt_Src);
[~,d_21] = knnsearch(Pt_Src,Pt_Tar);

distance = sum(d_12) + sum(d_21);

end


%% Laplacian Commutativity

function err = laplacian_commutativity(Src,Tar,C)

k = size(C,1);

SrcEval = diag(Src.evals(1:k)); TarEval = diag(Tar.evals(1:k));

err = norm((SrcEval*C - C*TarEval))/norm(C);

end
