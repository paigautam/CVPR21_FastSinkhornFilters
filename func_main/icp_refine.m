%{

ICP Algorithm with different options for pointwise conversion

Inputs: 

ini: Initial map from Source to Target
L1: Source Basis functions (number of points x number of eigenvectors)
L2: Target Basis Function  (number of points x number of eigenvectors)
numIter: number of ICP iterations 
type: 'nn' or 'sinkhorn'

Outputs:
T12: p2p from Source to Target
T21: p2p from Target to Source

%}

function [T12,T21] = icp_refine(L1, L2, ini, numIter, type)
    
    n1 = size(L1,2);
    n2 = size(L2,2);
    
    C = pinv(L1)*L2(ini,:);
        
    for k=1:numIter
        
        Vs = (L1*C)/size(L1,1);
        Vt = (L2)/size(L2,1);
        
        switch type
            
            case 'nn'
                
                T12 = knnsearch(Vt, Vs);
                T21 = knnsearch(Vs, Vt);
                
            case 'sinkhorn'
                
                [~,T12,T21] = fast_sinkhorn_filter(Vt,Vs);
        end
                
        W = pinv(L1)*L2(T12,:);
        [s,~,d] = svd(W);
        C = s*eye(n2,n1)*d';
        
        
    end
    
    
end