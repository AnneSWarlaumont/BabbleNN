function [y,ty] = skv(x,cf,fs,nPeriods,minPeriod,binSize)
% y = skv(x,cf,nPeriods,minPeriod,fs,binSize)
%
% This is the latest SKV variant which takes as input a 'cochlear' energy
% representation and returns an output in the form of a transient
% (onset/offset) representation based on the skewness of energy
% distribution in overlapping, sliding time windows, where the duration of
% each window is dependent on the centre frequency of the channel:
%   dur(i) = nPeriods * period(i)
%   period(i) = max([1/CF minPeriod])
%
% Inputs
%   x           a matrix containing the result of cochlear processing
%   cf          the centre frequency in Hz for each frequency channel, from
%               low to high
%   fs          stimulus sampling rate
%   nPeriods    the number of periods of the channel centre frequency to
%               use in the skewness calculation. Default is 8.
%   minPeriod   the minimum period in milliseconds, any channels where the
%               period is less than this will be fixed to minPeriod.
%               Wiegrebe suggested 1.25ms from his perceptual experiments.
%   
% Outputs
%   y           the transient respresentation of the stimulus
%
% 
% MC, SD	ALAVLSI, EmCAP 19/12/05
%
%..........................................................................

% Initialise
if nargin<5, minPeriod = 1.25; end
if nargin<4, nPeriods = 8; end

% Pad x to avoid false transients
[nr,nc] = size(x);
y = zeros(nr, nc);

% Get min period
period = 1./cf;
period(find(period<minPeriod/1000)) = minPeriod/1000;
cFreq = round(1./period);

% For each frequency channel(row)
for i = 1:nr
    clear r
    % downsample
    nWind = round(fs/cFreq(i));
    if nWind>1
        k = 0;
        for j = 1:nWind:(nc-nWind)
            k = k+1;
            range = j-nWind:j+nWind;
            range(find(range<=0))=[];
            r(k) = mean(x(i,range));
        end
        downSamp = 1;
    else
        r = x(i,:);
        downSamp = 0;
    end
    % pad start and end
    r = [ones(1,nPeriods)*r(1) r ones(1,nPeriods)*r(end)];

    % reshape into matrix form
    n = length(r)-nPeriods+1;
    z = zeros(nPeriods,n);
    for j = 1:n
        z(:,j) = r(j:(j+nPeriods-1))';
    end
    % calculate skewness
    z = d_normalize(z);
    r = d_skewness(z);
    
    %############################
    % calculate skewness
%     [z,dFac] = d_normalize(z);
%     r = d_skewness(z);
%     r = r.*dFac;
    %############################

    % only upsample if downsampled
    if downSamp
        %rx = resample(r,fs,cFreq(i));
        rr = zeros(1,length(r)*nWind);
        for j = 1:length(r)
            range = (j-1)*nWind+[1:nWind];
            rr(range) = r(j);
        end
        r = smooth(rr,nWind);
    end
    % trim
    trimVal = ceil(nWind*(nPeriods/2));
    r(end-trimVal+1:end)=[];
    r(1:trimVal+1)=[];
    % save 
    rLen = length(r);
    if rLen>nc
        y(i,:) = r(1:nc);
    elseif rLen<nc
        y(i,1:rLen) = r;
    else
        y(i,:) = r;
    end
end
 
% Reverse the sign so onsets are positive
y = -y;

% Resample
fy = round(1000/binSize);
y = resample(y',fy,fs)';
ty = 0:binSize:(size(y,2)-1)*binSize;

