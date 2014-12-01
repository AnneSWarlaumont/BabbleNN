function [x,fx,cf,tx] = scm(s,fs,chanSpec,binSize,doHPF)
% [x,fx,cf,tx] = scm(s,fs,chanSpec,binSize,doLPF)
%
% Returns x as a NxM matrix of values representing the output of N
% frequency channels over m stimulus samples binned as specified.
%
% Inputs
%   s           the stimulus waveform
%   fs          the sampling rate of the stimulus
%   chanSpec    specification of [nFreqChans lowFreq hiFreq] for
%               the cochlear processing, with centre frequencies spaced
%               evenly on the ERB scale. Typical setting:s [30 100 8000]
%   binSize     bin size of the returned representations in milliseconds
%   doHPF       if set then cochlear output is high pass filtered 
%
% Outputs
%   x           a matrix containing the result of cochlear processing. Each
%               row corresponds to a frequency channel
%   fx          the sampling rate of x
%   cf          the centre frequency in Hz for each frequency channel, from
%               low to high. Note the high frequency is usually less than
%               hiFreq because of the even distribution across the ERB
%               scale (roughly log)
%   tx          sampling times for columns in x (in seconds)
%
% Uses MakeERBFilters and ERBFilterBank from Slaney's auditory toolbox.
% 
% MC, SD	ALAVLSI, EmCAP March, July 2006
%
%..........................................................................

% Initialise
if nargin < 5, doHPF = 0; end

% Constants
xFloor = 0.35; %0.005; % this is to avoid strange behaviour in skewness near zeros
sFac = 20; % scaling factor

% Design and apply filters using Slaney's function
n = chanSpec(1);
[fcoefs cf] = MakeERBFilters(fs,n,chanSpec(2),chanSpec(3));
x = ERBFilterBank(s, fcoefs);

% ........................................................ High pass filter
% From Slaney Auditory toolbox
if doHPF
    for i = 1:size(x,1)
        x(i,:) = filter([1],[1 -0.99],x(i,:));
    end
end

% Half wave rectify (~IHC)
x = x.*(x>0);

% Resample x to binSize
fx = round(1000/binSize);
x = sFac*resample(x',fx,fs)';
%  and add a small DC offset
x = x.*(x>0) + xFloor;

% Scale to roughly 0:1 - assuming a normalised waveform x = x*20;
%x = x*20;

% Rescale to roughly 0:1, and use log amplitude scaling (log scaling is
% commonly used to approximate Weber's law)
%x = log10(x+1);

% Get sampling times
dt = binSize/1000;
tx = [0:dt:(size(x,2)-1)*dt];

