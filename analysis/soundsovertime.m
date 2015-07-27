% This code concatenates sampled wave files produced during a simulation into one wave file.
% Megan K. Finnegan & Anne S. Warlaumont

smplint = 120; % Sampling interval. i.e. How many .wav files to skip.
totalsec = 7200; % Total number of seconds of simulation time to include in the concatenated sound file.
skipmissing = 0;

% Names/ID Numbers of simulations, separated on reinforcement type. All
% yoked controls MUST be placed in the "_yoke" sim types!
simnames = {'NandScExtended_2_1_1','NandScExtended_2_1_1'}
simwavpaths = {'/chroot/lab/BabbleNN/Extended_Neuron_and_Scaling_Tests/NandScExtended_2_1_1_Wave/',...
               '/chroot/lab/BabbleNN/Extended_Neuron_and_Scaling_Tests/NandScExtended_2_1_1_Wave/'};
newsoundfiles = {'/chroot/lab/BabbleNN/Extended_Neuron_and_Scaling_Tests/reports/SoundsOverTime/SoundsOverTime_200n_2m_sim1.wav',...
                 '/chroot/lab/BabbleNN/Extended_Neuron_and_Scaling_Tests/reports/SoundsOverTime/SoundsOverTime_200n_2m_sim1_yoked.wav'};
yoked = [0,1];

% Keeps track of whether the simulation type is a yoked control or not.
% Needed to specify the right workspace filename.
isityoked = [0,1]; 

% Making reservoir songs.
for trial=1:length(simwavpaths_real) % Looking at every simulation
        
        if(isityoked(trial))
            wavfilebase = strcat('synth_', simnames{trial}, '_yoke_');
        else
            wavfilebase = strcat('synth_', simnames{trial});
        end
        
        % Making the reservoir .wav file
        for currSec = 1:(testint*smplint):totalsec % Looping through all the wave files I want to concatenate.
            if verLessThan('matlab', '8.1.0') % This if-statement is for backward compatibility. wavread is being phased out, but older versions of MATLAB use it.
                [mstrwav, fs, bits] = wavread(strcat(wavfilebase, num2str(currSec), '.wav')); % Reading the first .wav file
            else
                [mstrwav, fs] = audioread(strcat(wavfilebase, num2str(currSec), '.wav')); % Reading the first .wav file
            end
        end
        
        % Writing the master wave file.
        if verLessThan('matlab', '8.1.0')
            wavwrite(mstrwav, fs, bits, newsoundfiles{trial});
        else
            audiowrite(newsoundfiles{trial}, mstrwav, fs);
        end
end
