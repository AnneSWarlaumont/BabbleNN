function [B,den] = d_normalize(A)
% B = d_normalize(A)
%
% Returns B which has the same dimensions as A in which the values in each
% column have been scaled so the sum of each column is one.
%
% If a column is all zeros then it is considered to contain equal numerical
% values hence: [0 0; 0 0] and [1 1; 1 1] both yield [0.5 0.5; 0.5 0.5]
%
% This function replaces any NAN with (1/rowSize) and any Inf with 1 to
% avoid crashes - but indicates an error so make sure there are none in A.  
% 
% MC, SD	ALAVLSI, EmCAP 19/12/05
%
%..........................................................................

    [r c] = size(A);

% no negatives
    min_vec = min(A);
    min_vec = min_vec .* (min_vec < 0);
    A = A - repmat(min_vec, [r 1]);
% no zeros
    A(find(A==0)) = 10E-13;
    den = sum(A);
% straight calculation    
    A = A ./ repmat(sum(A), [r 1]);
% % replace any NaNs
    A(find(isnan(A))) = 1/r;    
% % replace any Infs
    A(find(isinf(A))) = 1;    
% % return
    B = A;
