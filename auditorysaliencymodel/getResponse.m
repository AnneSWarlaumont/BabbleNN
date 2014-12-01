function [z] = getResponse(skvRep,ensSet,convType)
% z = getResponse(skvRep,ensSet,convType)
%
% Get the response of the fragment ensemble to the current stimulus, using
% the convolution method specified
% Note, if divisive normalisation is specified, then the correlation
% weights will have to have been previously calculated using the
% corresponding convolution type.
%
% Inputs
%   skvRep  the skv representation of the current stimulus
%   ensSet  the fragment set 
%   convType    the convolution type as described below:
%               type 1 - fragments and skvRep are in the range -1:1, and
%                   the convolution is simple multiplicative
%               type 2 - fragments and skvRep are in the range -1:1, and
%                   the convolution is simple multiplicative, and divisive
%                   normalisation is included
%
% Output
%   z       the ensemble response    
%
%   SD ALAVLSI June 2005
%
%..........................................................................

% Initialise
load(ensSet)
nColsFrag = size(strfs{1},2);
nColsFrag2 = ceil(nColsFrag/2);
n = length(strfs);
[nRows,nCols] = size(skvRep);
skvRep = [zeros(nRows,nColsFrag) skvRep zeros(nRows,nColsFrag)];
z = zeros(n,nCols+nColsFrag);
       
% Convolve with the strf ensemble
for j = 1:n
    fDen = sum(sum(abs(strfs{j}))); % dividing by this evens up the power across fragments
    for k = 1:nCols+nColsFrag
        r = k-1+[1:nColsFrag];
        z(j,k) = sum(sum(skvRep(:,r).*strfs{j}))/fDen;
    end
end

% Divisive normalisation
if convType == 2
    z = divNorm(z,'strfDivNormWeights');
end

% z(:,(size(z,2)-nColsFrag2+1):size(z,2)) = [];
% z(:,1:nColsFrag2) = [];

z(:,(size(z,2)-nColsFrag2+1 - 1):size(z,2)) = [];
z(:,1:(nColsFrag2-1)) = [];

%z(:,(size(z,2)-nColsFrag+1):size(z,2)) = [];

%z(:,1:20) = randn(n,20).*repmat(mean(z(:,20:25)')',[1 20]); % to get rid of transient to stimulus DC offset

