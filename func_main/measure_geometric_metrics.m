function metrics = measure_geometric_metrics(Src,Tar,map12,map21)

bijectivity = mean(measure_bijectivity(Src,Tar,map12,map21));

coverage = coverage_map(Src,Tar, map12);

smoothness = smoothness_map(Src,Tar,map12);

gt_error = mean(fMAP.eval_pMap(Src, Tar, map12, [Src.cor' Tar.cor'], 'euclidean'));

metrics = struct('bijectivity', bijectivity, 'coverage' , coverage, 'smoothness', smoothness,'gt_error',gt_error);

end

%% Bijectivity
function error = measure_bijectivity(Src,Tar,map12,map21)

map_11  = map21(map12);

gt_corres = [(1:Src.nv)' (1:Src.nv)'];

error = fMAP.eval_pMap(Tar, Src, map_11, gt_corres, 'euclidean');

end

%% Coverage
function coverage = coverage_map(Src,Tar, matches)

matches_unique = unique(matches);

coverage = sum(Tar.area(matches_unique))/(Tar.sqrt_area.^2);

end
%% Smoothness

function smoothness = smoothness_map(Src,Tar,matches) 

N = struct('VERT',[Src.surface.X Src.surface.Y Src.surface.Z],'STIFFNESS',Src.W);

M = struct('VERT',[Tar.surface.X Tar.surface.Y Tar.surface.Z],'n',Tar.nv);

f = (M.VERT - min(M.VERT))./repmat((max(M.VERT)-min(M.VERT)),M.n,1);
smoothness = mean(diag(f(matches,:)'*N.STIFFNESS*f(matches,:)));

end

