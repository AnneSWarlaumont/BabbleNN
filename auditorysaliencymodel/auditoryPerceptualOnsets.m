function results = auditoryPerceptualOnsets(fName,thresh0,div1,doDisplay)
% results = auditoryPerceptualOnsets(fName,thresh0,div1,doDisplay)
%
% Auditory Perceptual Onsets model: batch version - processes the
% stimulus contained in the sound file <fName> using a causal model of
% auditory processing which includes the following stages: cochlear
% filtering, halfwave rectification, parallel transient and energy
% extraction, convolution with cortical filters, event detection.
%
% The results file contains the detected event times in seconds together
% with the final model output, and soundtrack with detected events
% superimposed on the original sound track.
%
% Note: the current model includes an adaptive decision threshold for event
% detection which allows for the change in saliency which typically occurs;
% the first event is generally far more salient than later ones. The
% algorithm is very simple though and could undoubtedly be improved. At
% this stage, following the first detected event (detected using thresh0),
% the threshold is then set to the saliency amplitude of each event,
% divided by div1. Increasing div1 increases the number of small saliency
% events detected, decreasing it, decreases the number of detected events.
%
%
% Inputs
%   fName           name of the sound file containing the stimulus 
%                   (.wav or .au) 
%   thresh0         initial threshold for event detection; default = 1.
%   div1            divisor for use in threshold adaptation (should be
%                   >=1); default = 2. 
%   doDisplay       flag set for a plot of the saliency trace and detected
%                   events and a soundtrack with the original stimulus
%                   superimposed on the detected event track; default 0.
%
% Outputs
%   results data structure in which the peripheral model responses are
%           returned:
%       .stim       .sOrig (stimulus)
%                   .sDet  (detected event track)
%                   .fs    (sampling rate)
%       .saliency   continuous saliency trace
%       .pOnsets    discrete perceptual onsets extracted from the saliency
%                   using an adaptive decision threshold; stored as a
%                   matrix with column 1 containing event times in seconds,
%                   and column 2 a measure of event saliency; each row
%                   corresponds to a detected event.
%       .eResp      energy response - half-wave rectified output of the
%                   cochlear model 
%       .tResp      transient response - onsets extracted by the transient
%                   model  
%       .cortResp   cortical response - output of the cortical filters
% 
% SD	EmCAP January 2008
%
%..........................................................................

% Set processing parameters     
if nargin < 4, doDisplay = 0; end
if nargin < 3, div1 = 2; end
if nargin < 2, thresh0 = 1; end
div1 = max([div1 1]); 
thresh = thresh0;
if doDisplay, fPos = [631    33   644   919]; end

% Note: Cochlear channel CFs are fixed by the cortical filters which have
% been previously derived. So if the sampling rate of the stimulus files is
% less than cFS, then it is resampled to cFS.
cFS = 16000;        % minimum stimulus sampling rate (Hz)
nChannels = 30;     % number of cochlear channels
lowF = 100;         % lowest channel centre frequency (Hz)
highF = 8000;       % highest channel centre frequency (Hz)
xFloor = 0.35;      % non-zero floor for calculating transient response
cochlearFS = 1000;  % sampling rate for cochlear response (Hz)
saliencyFS = 200;   % sampling rate for saliency response (Hz)
%doNormalise = 1;
nPeriods = 8;       % Frequency dependent time window for transient    
                    % analysis = nPeriods/cf
minPeriod = 1.25;   % minimum time window for transient analysis in ms

cfCort = 100;
nCortPeriods = 4;
minCortPeriod = 1;

% ................................................................ Stimulus
if findstr(fName,'.au') 
    [s,fs] = auread(fName);
elseif findstr(fName,'.wav') 
    [s,fs] = wavread(fName);
else
    disp('** Not a valid sound file')
    return
end

% Ignore stereo
s = s(:,1);

% Resample if necessary
if fs < cFS
    s = resample(s,cFS,fs);
    fs = cFS;
end
% if doNormalise, s = s/max(abs(s)); end

% Get sampling times
ns = length(s);
dt = 1/fs;
ts = [0:dt:(ns-1)*dt];

% ......................................................Cochlear Processing
[eResp,fx,cf,tx] = scm(s,fs,[nChannels lowF highF],1000/cochlearFS);

% .............................................................. Transients
[y,ty] = skv(eResp,cf,fx,nPeriods,minPeriod,1000/saliencyFS);
tResp = y.*(y>0);


%............................................................ STRF response
cortResp = getResponse(tResp,'strfsSorted200',1);

%........................................................ Perceptual Onsets
saliency = skv(sum(cortResp)+xFloor,cfCort,saliencyFS,nCortPeriods, ...
    minCortPeriod,1000/saliencyFS);
tShift = nCortPeriods/saliencyFS;
pOnsets = getPOnsets(saliency,thresh,div1,1/saliencyFS,tShift);

% Make event track
sDet = getEventTrack(ts,pOnsets(:,1));

%.................................................................. Display
% Display results
if doDisplay
    figure,set(gcf,'pos',fPos,'color',[1 1 1])
    subplot(311),imagesc(eResp),axis xy,colorbar,title('Cochlear response')
    v = sum(eResp); v = v - min(v); v = nChannels*v/max(v);
    hold on,plot(v,'w')
    subplot(312),imagesc(tResp),axis xy,colorbar,title('Onset transients')
    v = sum(tResp); v = nChannels*v/max(v);
    hold on,plot(v,'w')
    subplot(313),imagesc(cortResp),axis xy,colorbar,title('STRF convolution response')
    v = saliency; v = 300*v/max(v);
    hold on,plot(v,'w')

    figure,set(gcf,'pos',fPos,'color',[1 1 1])
    t = [0:(length(saliency)-1)]/saliencyFS;
    plot(ts,s*max(abs(saliency)),'c',t,saliency,'k'),grid,hold on
    stem(pOnsets(:,1),pOnsets(:,2),'filled','color',[1 0 0])
    disp('<return> to hear sound + computed event markers'),pause
    soundsc([s sDet],fs)
end

% Save
results.stim.s = s;
results.stim.fs = fs;
results.stim.sDet = sDet;
results.saliency = saliency;
results.pOnsets = pOnsets;
results.eResp = eResp;
results.tResp = tResp;
results.cortResp = cortResp;
