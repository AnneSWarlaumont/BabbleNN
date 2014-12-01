function [] = babble_daspnet_reservoir(id,newT,reinforcer,outInd,muscscale,yoke,plotOn)
% BABBLE_DASPNET_RESERVOIR Neural network model of the development of reduplicated canonical babbling in human infancy.
%
%   Modification of Izhikevich's (2007 Cerebral Cortex) daspnet.m and of a previous model described in Warlaumont (2012, 2013 ICDL-EpiRob).
% 
%   Estimates of auditory salience calucated from a modified version of
%   Coath et. al. (2009) auditory salience algorithms.
%
%   For further reading:
%
%       Warlaumont A.S. (2012) Salience-based reinforcement of a spiking neural network leads to increased syllable production. 
%       Proceedings of the 2013 IEEE Third Joint International Conference on Development and Learning and Epigenetic Robotics (ICDL). doi: 10.1109/DevLrn.2013.6652547
%
%       Izhikevich E.M. (2007) Solving the Distal Reward Problem through Linkage of STDP and Dopamine Signaling. Cerebral Cortex. doi: 10.1093/cercor/bhl152
%
%       The auditory salience estimator and auditory event detector used in salience-reinforced versions:
%           http://emcap.iua.upf.edu/downloads/content_final/auditory_saliency_model.html
%           http://www.mcg.uva.nl/papers/Coath-et-al-2007.pdf
%   
%   Description of Input Arguments:
%       id          % Unique identifier for this simulation. Must not contain white space.
%       newT        % Time experiment is to run in seconds. Can specify new times (longer or shorter) 
%                      for experimental runs by changing this value when a simulation is restarted.
%       reinforcer  % Type of reinforcement. Can be 'human', 'relhisal', or 'range'.
%       outInd      % Index of reservoir neurons that project to motor neurons. Length of this vector must be even. Recommended vector is 1:100
%       muscscale   % Scales activation sent to Praat. Recommended value is 4
%       yoke        % Indicates whether to run an experiment or yoked control simulation. Set to 'false' to run a regular simulation. 
%                      Set to 'true' to run a yoked control. There must alread have been a simulation of the same name run with its 
%                      data on the MATLAB path for the simulation to yoke to.
%       plotOn      % Enables plots of several simulation parameters. Set to 0 to disable plots, and 1 to enable.
%
%   Example of Use:
%       babble_daspnet_reservoir('Mortimer',7200,'relhisal',1:100,4,'false',0);
%
% Authors: Anne S. Warlaumont and Megan K. Finnegan
% Cognitive and Information Sciences
% University of California, Merced
% email: awarlaumont2@ucmerced.edu or anne.warlaumont@gmail.com or 
% Website: http://www.annewarlaumont.org/lab/
% December 2014
% For updates, see https://github.com/AnneSWarlaumont/BabbleNN

%INITIALIZATIONS AND LOADING%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
rng shuffle;

% Initialization.
salthresh = 4.5;            % Initial salience value for reward (used in 'relhisal' reinforcment).
DAinc = 1;                  % Amount of dopamine given during reward.
sm = 4;                     % Maximum synaptic weight.
testint = 1;                % Number of seconds between vocalizations.

% Directory names for data.
wavdir = [id, '_Wave'];
firingsdir = [id, '_Firings'];
workspacedir = [id, '_Workspace'];
yokeworkspacedir = [id, '_YokedWorkspace'];

% Error Checking.
if(any(isspace(id)))
    disp('Please choose an id without spaces.');
    return
end

% Creating data directories.
if ~exist(wavdir, 'dir')
    mkdir(wavdir);
else
    addpath(wavdir);
end
if ~exist(firingsdir, 'dir')
    mkdir(firingsdir);
else
    addpath(firingsdir);
end
if ~exist(workspacedir, 'dir')
    mkdir(workspacedir);
else
    addpath(workspacedir);
end
if strcmp(yoke, 'true')
    if ~exist(yokeworkspacedir, 'dir')
        mkdir(yokeworkspacedir);
    else
        addpath(yokeworkspacedir);
    end
end

% Creating workspace names.
if strcmp(yoke,'false')
    workspaceFilename=[workspacedir,'/babble_daspnet_reservoir_',id,'.mat'];
elseif strcmp(yoke,'true')
    % Where to put the yoked control simulation data.
    workspaceFilename=[yokeworkspacedir,'/babble_daspnet_reservoir_',id,'_yoke.mat'];
    % Where to find the original simulation data.
    yokeSourceFilename=[workspacedir,'/babble_daspnet_reservoir_',id,'.mat'];
end

% Directory for Coath et. al. Saliency Detector.
addpath('auditorysaliencymodel'); 


if exist(workspaceFilename) > 0
    load(workspaceFilename);
else
    
    M=100;                 % number of synapses per neuron
    D=1;                   % maximal conduction delay
    % excitatory neurons   % inhibitory neurons      % total number
    Ne=800;                Ni=200;                   N=Ne+Ni;
    Nout = length(outInd);
    Nmot=Nout; % Number of motor neurons that the output neurons in the reservoir connect to.
    a=[0.02*ones(Ne,1);    0.1*ones(Ni,1)];     % Sets time scales of membrane recovery variable.
    d=[   8*ones(Ne,1);    2*ones(Ni,1)];       % Membrane recovery variable after-spike shift. 
    a_mot=.02*ones(Nmot,1);
    d_mot=8*ones(Nmot,1);
    post=ceil([N*rand(Ne,M);Ne*rand(Ni,M)]); % Assign the postsynaptic neurons for each neuron's synapse in the reservoir.
    post_mot=repmat(1:Nmot,Nout,1); % All output neurons connect to all motor neurons.

    s=[rand(Ne,M);-rand(Ni,M)];         % Synaptic weights in the reservoir.
    sout=rand(Nout,Nmot); % Synaptic weights from the reservoir output neurons to the motor neurons.

    % Normalizing the synaptic weights.
    sout=sout./(mean(mean(sout)));
    
    sd=zeros(Nout,Nmot); % The change to be made to sout.
    
    for i=1:N
        delays{i,1}=1:M;
    end
    for i=1:Nout
        delays_mot{i,1}=1:Nmot;
    end
    STDP = zeros(Nout,1001+D);
    v = -65*ones(N,1);          % Membrane potentials.
    v_mot = -65*ones(Nmot,1);
    u = 0.2.*v;                 % Membrane recovery variable.
    u_mot = 0.2.*v_mot;
    firings=[-D 0];     % All reservoir neuron firings for the current second.
    outFirings=[-D 0];  % Output neuron spike timings.
    motFirings=[-D 0];  % Motor neuron spike timings.
    
    DA=0; % Level of dopamine above the baseline.
    
    muscsmooth=100; % Spike train data sent to Praat is smoothed by doing a 100 ms moving average.
    sec=0;
    
    rewcount=0; 
    rew=[];
    
    % History variables.
    v_mot_hist={};
    sout_hist={};
    
    % Initializing reward policy variables.
    if strcmp(reinforcer,'relhisal')
        temprewhist=zeros(1,10); % Keeps track of rewards given at a threshold value for up to 10 previous sounds.
    end

    if strcmp(reinforcer, 'range')
        temprewhist=zeros(1,10);
        range_hist = NaN(newT, 1); % Keeps a record of the range over the entire simulation run time.
        rangethresh = 0.75; % Starting threshold for reward. 
        Ranginc = .05; % How much to increase the threshold by.
    end
    
    % Variables for saving data.
    vlstsec = 0; % Record of when v_mot_hist was last saved.
    switch reinforcer  % Sets how often to save data.
        case 'human'
            SAVINTV = 10;
        otherwise
            SAVINTV = 100;
    end
    
end

T=newT;
clearvars newT;

% Absolute path where Praat can be found.
praatPathpc = 'c:/users/lab/praatcon';
praatPathmac = '/Applications/Praat.app/Contents/MacOS/Praat';

% Special initializations for a yoked control.
if strcmp(yoke,'true')
    load(yokeSourceFilename,'rew', 'yokedruntime');
    if(T > yokedruntime)
        T = yokedruntime;
    end
end


%RUNNING THE SIMULATION%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for sec=(sec+1):T % T is the duration of the simulation in seconds.
    
    display('********************************************');
    display(['Second ',num2str(sec),' of ',num2str(T)]);
    
    v_mot_hist{sec}=[]; % Record of all the membrane voltages of the motor neurons.
    
    % How long a yoked control could be run. Assumes rewards are
    % assigned for the current second only.
    yokedruntime = sec;
    
    for t=1:1000                            % Millisecond timesteps
        
        %Random Thalamic Input.
        I=13*(rand(N,1)-0.5);
        I_mot=13*(rand(Nmot,1)-0.5);
            
        fired = find(v>=30);                % Indices of fired neurons
        fired_out = find(v(outInd)>=30);
        fired_mot = find(v_mot>=30);
        v(fired)=-65;                       % Reset the voltages for those neurons that fired
        v_mot(fired_mot)=-65;
        u(fired)=u(fired)+d(fired);         % Individual neuronal dynamics
        u_mot(fired_mot)=u_mot(fired_mot)+d_mot(fired_mot);
                
        % Spike-timing dependent plasticity computations:
        STDP(fired_out,t+D)=0.1; % Keep a record of when the output neurons spiked.
        for k=1:length(fired_mot)
            sd(:,fired_mot(k))=sd(:,fired_mot(k))+STDP(:,t); % Adjusting sd for synapses eligible for potentiation.
        end
        firings=[firings;t*ones(length(fired),1),fired];                % Update the record of when neuronal firings occurred.
        outFirings=[outFirings;t*ones(length(fired_out),1),fired_out];
        motFirings=[motFirings;t*ones(length(fired_mot),1),fired_mot];
        % For any presynaptic neuron that just fired, calculate the current to add
        % as proportional to the synaptic strengths from its postsynaptic neurons.
        k=size(firings,1);
        while firings(k,1)>t-D
            del=delays{firings(k,2),t-firings(k,1)+1};
            ind = post(firings(k,2),del);
            I(ind)=I(ind)+s(firings(k,2), del)';
            k=k-1;
        end;
        % Calculating currents to add for motor neurons. 
        k=size(outFirings,1);
        while outFirings(k,1)>t-D
            del_mot=delays_mot{outFirings(k,2),t-outFirings(k,1)+1};
            ind_mot = post_mot(outFirings(k,2),del_mot);
            I_mot(ind_mot)=I_mot(ind_mot)+2*sout(outFirings(k,2), del_mot)';
            k=k-1;
        end;
        
        % Individual neuronal dynamics computations:
        v=v+0.5*((0.04*v+5).*v+140-u+I);                            % for numerical
        v=v+0.5*((0.04*v+5).*v+140-u+I);                            % stability time
        v_mot=v_mot+0.5*((0.04*v_mot+5).*v_mot+140-u_mot+I_mot);    % step is 0.5 ms
        v_mot=v_mot+0.5*((0.04*v_mot+5).*v_mot+140-u_mot+I_mot);
        v_mot_hist{sec}=[v_mot_hist{sec},v_mot];
        u=u+a.*(0.2*v-u);                   
        u_mot=u_mot+a_mot.*(0.2*v_mot-u_mot);
        STDP(:,t+D+1)=0.95*STDP(:,t+D);                             % tau = 20 ms
        
        DA=DA*0.995; % Decrease in dopamine concentration over time.
        
        % Modify synaptic weights.
        if (mod(t,10)==0)
            sout=max(0,min(sm,sout+DA*sd));

            % Normalizing the synaptic weights.
            sout=sout./(mean(mean(sout)));
            
            sd=0.99*sd; % Decrease in synapse's eligibility to change over time.
        end;
        
        
        
        % Every testint seconds, use the motor neuron spikes to generate a sound.
        if (mod(sec,testint)==0) 
            
            firedmusc1pos=find(v_mot(1:Nmot/2)>=30); % Find out which of the jaw/lip motor neurons fired.
            firedmusc1neg=find(v_mot(Nmot/2+1:end)>=30);
            summusc1posspikes(t)=size(firedmusc1pos,1); % Sum the spikes at each timestep across the set of motor neurons.
            summusc1negspikes(t)=size(firedmusc1neg,1);
            
            if t==1000 % Based on the 1 s timeseries of smoothed summed motor neuron spikes, generate a sound.
                 
                % Create a moving average of the summed spikes.
                for smootht=muscsmooth:1000
                    smoothmuscpos(smootht,sec)=mean(summusc1posspikes((smootht-muscsmooth+1):smootht));
                    smoothmuscneg(smootht,sec)=mean(summusc1negspikes((smootht-muscsmooth+1):smootht));
                    smoothmusc(smootht,sec)=muscscale*(smoothmuscpos(smootht,sec)-smoothmuscneg(smootht,sec));
                end
                
                % History of total motor neuron spikes for each second.
                summusc1posspikeshist(sec)=sum(summusc1posspikes);
                summusc1negspikeshist(sec)=sum(summusc1negspikes);
                
                if ~strcmp(reinforcer,'range')
                    % Write the Praat script:
                    if strcmp(yoke,'false')
                        fid = fopen([wavdir,'/ressynth_',id,'.praat'],'w');
                    elseif strcmp(yoke,'true')
                        fid = fopen([wavdir,'/ressynth_',id,'_yoke.praat'],'w');
                    end
                    fprintf(fid,'Create Speaker... speaker Female 2\n');
                    fprintf(fid,['Create Artword... babble ' num2str((1000-muscsmooth)/1000,'%.3f') '\n']);
                    fprintf(fid,'select Artword babble\n');
                    fprintf(fid,['Set target... ' num2str((0)/1000,'%.3f') ' ' num2str(0.1,'%.3f') ' Lungs\n']);
                    fprintf(fid,['Set target... ' num2str(0.02,'%.3f') ' ' num2str(0.1,'%.3f') ' Lungs\n']);
                    fprintf(fid,['Set target... ' num2str(0.05,'%.3f') ' ' num2str(0,'%.3f') ' Lungs\n']);
                    fprintf(fid,['Set target... ' num2str((1000-muscsmooth)/1000,'%.3f') ' ' num2str(0,'%.3f') ' Lungs\n']);
                    fprintf(fid,['Set target... ' num2str((0)/1000,'%.3f') ' ' num2str(0.5,'%.3f') ' Interarytenoid\n']);
                    fprintf(fid,['Set target... ' num2str((1000-muscsmooth)/1000,'%.3f') ' ' num2str(0.5,'%.3f') ' Interarytenoid\n']);
                    fprintf(fid,['Set target... ' num2str((0)/1000,'%.3f') ' ' num2str(0.4,'%.3f') ' ' ' Hyoglossus\n']);
                    fprintf(fid,['Set target... ' num2str((1000-muscsmooth)/1000,'%.3f') ' ' num2str(0.4,'%.3f') ' Hyoglossus\n']);
                    for praatt=0:(1000-muscsmooth)
                        fprintf(fid,['Set target... ' num2str((praatt)/1000,'%.3f') ' ' num2str(smoothmusc(praatt+muscsmooth,sec),'%.3f') ' Masseter\n']);
                        fprintf(fid,['Set target... ' num2str((praatt)/1000,'%.3f') ' ' num2str(smoothmusc(praatt+muscsmooth,sec),'%.3f') ' OrbicularisOris\n']);
                    end
                    fprintf(fid,'select Speaker speaker\n');
                    fprintf(fid,'plus Artword babble\n');
                    fprintf(fid,'To Sound... 22050 25 0 0 0 0 0 0 0 0 0\n');
                    fprintf(fid,'\tselect Sound babble_speaker\n');
                    if strcmp(yoke,'false')
                        fprintf(fid,['\tWrite to WAV file... synth_',id,'_',num2str(sec),'.wav\n']);
                    elseif strcmp(yoke,'true')
                        fprintf(fid,['\tWrite to WAV file... synth_',id,'_yoke_',num2str(sec),'.wav\n']);
                    end
                    
                    fclose(fid);
                    
                    % Execute the Praat script -- produces a wave file:
                    if ismac
                        if strcmp(yoke,'false')
                            system([praatPathmac, ' ', wavdir,'/ressynth_',id,'.praat']);
                        elseif strcmp(yoke,'true')
                            system([praatPathmac, ' ', wavdir,'/ressynth_',id,'_yoke.praat']);
                        end
                    elseif ispc
                        if strcmp(yoke,'false')
                            system([praatPathpc, ' ', wavdir,'/ressynth_',id,'.praat']);
                        elseif strcmp(yoke,'true')
                            system([praatPathpc, ' ', wavdir,'/ressynth_',id,'_yoke.praat']);
                        end
                    end
                    
                    % Housekeeping.
                    if  strcmp(yoke,'false')
                        delete([wavdir,'/ressynth_',id,'.praat']);
                    elseif strcmp(yoke,'true')
                        delete([wavdir,'/ressynth_',id,'_yoke.praat']);
                    end
                    
                    % Find the auditory salience of the sound:
                    if strcmp(yoke,'false')
                        salienceResults = auditorySalience([wavdir,'/synth_',id,'_',num2str(sec),'.wav'],0);
                    elseif strcmp(yoke,'true')
                        display([wavdir,'/synth_',id,'_yoke_',num2str(sec),'.wav']);
                        salienceResults = auditorySalience([wavdir,'/synth_',id,'_yoke_',num2str(sec),'.wav'],0);
                    end
                    salience = sum(abs(salienceResults.saliency(31:180))); % Summing over salience trace to produce a single value.
                    salhist(sec,1) = salience; % History of salience over entire simulation.
          
                    if ~(strcmp(reinforcer,'human') && strcmp(yoke, 'false'))
                        display(['salience = ',num2str(salience)]);
                    end
                end
                                
                % Assign Reward.
                if strcmp(yoke,'true')
                    % Yoked controls use reward assigned from the
                    % experiment they are yoked to.
                    if any(rew==sec*1000+t)
                        display('rewarded');
                    else
                        display('not rewarded');
                    end
                elseif strcmp(reinforcer,'human')
                    % Asking the human listener to provide or withold reinforcement for this sound.
                    tempInput = input('Press Return/Enter to play the sound.','s');
                    % Read and play the sound file. (maintains backwards compatibility with wavread)
                    if verLessThan('matlab', '8.0.0')
                        [mysound,Fs] = wavread([wavdir,'/synth_',id,'_',num2str(sec),'.wav']);
                    else
                        [mysound,Fs] = audioread([wavdir,'/synth_',id,'_',num2str(sec),'.wav']);
                    end
                    sound(mysound,Fs);
                    % Get listener's reinforcment decision.
                    user_reinforceAmount = '2';
                    while ~max(strcmp(user_reinforceAmount,{'0','1'}))
                        user_reinforceAmount = input('Enter 1 to reinforce this sound. Enter zero to withhold reinforcement.','s');
                    end
                    if strcmp(user_reinforceAmount,'1')
                        rew=[rew,sec*1000+t];
                    end
                elseif strcmp(reinforcer,'relhisal')
                    display(['salthresh: ',num2str(salthresh)]);
                    temprewhist(1:9)=temprewhist(2:10);
                    % Reward if the salience of the sound is above
                    % threshold value.
                    if salience>salthresh
                        display('rewarded');
                        rew=[rew,sec*1000+t];
                        rewcount=rewcount+1;
                        temprewhist(10)=1;
                        % If at least 3 of the last 10 sounds were above
                        % threshold, raise the threshold value and reset the count.
                        if mean(temprewhist)>=.3
                            salthresh=salthresh+.1;
                            temprewhist=zeros(1,10);
                        end
                    else
                        display('not rewarded');
                        temprewhist(10)=0;
                    end
                    display(['temprewhist: ',num2str(temprewhist)]);
                    display(['mean(temprewhist): ',num2str(mean(temprewhist))]);
                elseif strcmp(reinforcer, 'range')
                    muscrange = range(smoothmusc(:,sec)); % Range of motor neuron activation during this second.
                    range_hist(sec) = muscrange;
                    display(['Current Range: ', num2str(muscrange)]);
                    temprewhist(1:9)=temprewhist(2:10);
                    % Reward if the range of the muscle activation is above
                    % threshold value.
                    if muscrange>rangethresh
                        display('rewarded');
                        rew=[rew,sec*1000+t];
                        rewcount=rewcount+1;
                        temprewhist(10)=1;
                        % If at least 3 of the last 10 sounds were above
                        % threshold, raise the threshold value and reset the count.
                        if mean(temprewhist)>=.3
                            rangethresh = rangethresh + Ranginc;
                            temprewhist=zeros(1,10);
                        end
                    else
                        display('not rewarded');
                        temprewhist(10)=0;
                    end
                    display(['temprewhist: ',num2str(temprewhist)]);
                    display(['mean(temprewhist): ',num2str(mean(temprewhist))]);
                end
                
                % Display reward count information.
                if strcmp(yoke,'false') && ~strcmp(reinforcer,'human')
                    display(['rewcount: ',num2str(rewcount)]);
                end
                
            end
        end
        
        % If the human listener decided to reinforce (or if the yoked control
        % schedule says to reinforce), increase the dopamine concentration.
        if any(rew==sec*1000+t)
            DA=DA+DAinc;
        end
    end
    
    % Writing reservoir neuron firings for this second to a text file.
    if mod(sec,SAVINTV*testint)==0 || sec==T        
        if strcmp(yoke,'false')
            firings_fid = fopen([firingsdir,'/babble_daspnet_firings_',id,'_',num2str(sec),'.txt'],'w');
        elseif strcmp(yoke,'true')
            firings_fid = fopen([firingsdir,'/babble_daspnet_firings_',id,'_yoke_',num2str(sec),'.txt'],'w');
        end
        for firingsrow = 1:size(firings,1)
            fprintf(firings_fid,'%i\t',sec);
            fprintf(firings_fid,'%i\t%i',firings(firingsrow,:));
            fprintf(firings_fid,'\n');
        end
        fclose(firings_fid);
    end
    
    % Make axis labels and titles for plots that are being kept.
    % ---- plot -------
    if plotOn
        hNeural = figure(103);
        set(hNeural, 'name', ['Neural Spiking for Second: ', num2str(sec)], 'numbertitle','off');
        subplot(4,1,1)
        plot(firings(:,1),firings(:,2),'.'); % Plot all the neurons' spikes
        title('Reservoir Firings', 'fontweight','bold');
        axis([0 1000 0 N]);
        subplot(4,1,2)
        plot(outFirings(:,1),outFirings(:,2),'.'); % Plot the output neurons' spikes
        title('Output Nueron Firings', 'fontweight','bold');
        axis([0 1000 0 Nout]);
        subplot(4,1,3)
        plot(motFirings(:,1),motFirings(:,2),'.'); % Plot the motor neurons' spikes
        title('Motor Neuron Firings', 'fontweight','bold');
        axis([0 1000 0 Nmot]);
        subplot(4,1,4);
        plot(smoothmusc(muscsmooth:1000,sec)); ylim([-.5,.5]); xlim([-100,900]); % Plot the smoothed sum of motor neuron spikes 1 s timeseries
        title('Sum of Agonist/Antagonist Motor Neuron Activation', 'fontweight','bold');
        
        drawnow;
        
        hSyn = figure(113);
        set(hSyn, 'name', ['Synaptic Strengths for Second: ', num2str(sec)], 'numbertitle','off');
        imagesc(sout)
        set(gca,'YDir','normal')
        colorbar;
        title('Synapse Strength between Output Neurons and Motor Nuerons', 'fontweight','bold');
        xlabel('postsynaptic motor neruon index', 'fontweight','bold');
        ylabel('presynaptic output neuron index', 'fontweight','bold');
        
    end
    % ---- end plot ------
    
    sout_hist{sec}=sout;
    
    % Preparing STDP and firings for the following 1000 ms.
    STDP(:,1:D+1)=STDP(:,1001:1001+D);
    ind = find(firings(:,1) > 1001-D);
    firings=[-D 0;firings(ind,1)-1000,firings(ind,2)];
    ind_out = find(outFirings(:,1) > 1001-D);
    outFirings=[-D 0;outFirings(ind_out,1)-1000,outFirings(ind_out,2)];
    ind_mot = find(motFirings(:,1) > 1001-D);
    motFirings=[-D 0;motFirings(ind_mot,1)-1000,motFirings(ind_mot,2)];
    
    
    
    % Every so often, save the workspace in case the simulation is interupted all data is not lost.
    if mod(sec,SAVINTV*testint)==0 || sec==T
        display('Data Saving..... Do not exit program.');
        save(workspaceFilename, '-regexp', '^(?!(v_mot_hist)$).');
    end
    
    
    % Writing motor neuron membrane potentials to a single large text file.
    if mod(sec,SAVINTV*testint)==0 || sec==T
        if strcmp(yoke, 'false')
            vmhist_fid = fopen([workspacedir,'/v_mot_hist_',id,'.txt'],'a');
        elseif strcmp(yoke, 'true')
            vmhist_fid = fopen([yokeworkspacedir,'/v_mot_hist_',id,'_yoke.txt'],'a');
        end
        if(vlstsec == 0)
            fprintf(vmhist_fid, 'History of Motor Neuron Membrane Potentials:\n');
        end
        for sindx = (vlstsec+1):sec % Going through all the seconds needed data saved for.
            % Information formated to make data more human readable.
            fprintf(vmhist_fid, '\nSecond: %i\n',sindx);
            fprintf(vmhist_fid, 'Millisecond:\n\t\t');
            fprintf(vmhist_fid, '%f\t\t%f\t\t', 1:1000);
            fprintf(vmhist_fid, '\n');
            fprintf(vmhist_fid, 'Neuron: \n');
            % Appending new voltage data.
            for nrow = 1:size(v_mot_hist{sindx},1)
               fprintf(vmhist_fid, '%i\t\t', nrow);
               fprintf(vmhist_fid, '%f\t\t%f\t\t', v_mot_hist{sindx}(nrow, :));
               fprintf(vmhist_fid, '\n');
            end
            fprintf(vmhist_fid, '\n');
        end
        
        fclose(vmhist_fid);
        vlstsec = sec; % Latest second of saving.
        save(workspaceFilename, 'vlstsec', '-append'); % Saving the value of the last written second in case the simulation is terminated and restarted.
        display('Data Saved.');
    end
    

end
