function pOnsets = getPOnsets(saliency,thresh,div1,sampleDur,tShift)
% pOnsets = getPOnsets(saliency,thresh,div1,sampleDur)
%
% Extracts discrete perceptual onsets from the continuous saliency trace
% using an adaptive threshold.
%
% Inputs
%   saliency    a continuous trace of the transients in the summed output
%               of the cortical filters 
%   thresh      initial threshold for event detection
%   div1        divisor for use in threshold adaptation
%   sampleDur   the sample duration of the saliency vector (s)
%   tShift      the duration of the window used to calculate the saliency
%               vector (s); used to correct for the event onset time.
%
% Output
%   pOnsets     the detected perceptual onsets, return as a matrix with
%               column 1 containing the times and column 2 the amplitudes
%               of the detected events, 1 row per event.
%
% SD EmCAP January 2008
%
%..........................................................................

% Process
iOn = 0;
for i = 3:length(saliency)
    if saliency(i-1) > thresh
        tOn = (i*sampleDur-tShift);  
        vOn = saliency(i-1);
        if (vOn > saliency(i-2)) & (vOn > saliency(i))
            if ~iOn
                iOn = 1;
                pOnsets(iOn,:) = [tOn vOn];
                thresh = vOn/div1;
            else
                if (tOn-pOnsets(iOn,1)) <= 0.120
                    if pOnsets(iOn,2)< vOn
                        % Replace else keep previous
                        pOnsets(iOn,:) = [tOn vOn];
                    end
                else
                    iOn = iOn + 1;
                    pOnsets(iOn,:) = [tOn vOn];
                    if vOn>10*thresh, thresh = vOn/div1;end
                end
            end
        end
    end
end
