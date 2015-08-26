% Plot a simulation and its yoked control's synaptic weights from the
% output neurons to the motor neurons, after 2 hours of training.
%
% Anne S. Warlaumont

% Navigate to the directory where the simulation and its yoked control
% workspaces can be found
cd ~/IVOC-NN-Learning/BabbleNNPreGit/PresentationsAndPublications/WarlaumontAndFinnegan4PLOSCB/SupportingInformation/Workspaces/

% Load the simulation's synaptic weights and its yoked control's synaptic
% weights
sout_real = load('babble_daspnet_reservoir_NandScExtended_2_1_1_7200.mat','sout');
sout_yoked = load('babble_daspnet_reservoir_NandScExtended_2_1_1_yoke_7200.mat','sout');
sec = 7200;

% Set the file paths and names where the figures should be saved
realFigFname = '~/IVOC-NN-Learning/BabbleNNPreGit/PresentationsAndPublications/WarlaumontAndFinnegan4PLOSCB/Figures/SynapseFigs/Synapses_200n_2m_sim1_7200s_sypnases.tif';
yokeFigFname = '~/IVOC-NN-Learning/BabbleNNPreGit/PresentationsAndPublications/WarlaumontAndFinnegan4PLOSCB/Figures/SynapseFigs/Synapses_200n_2m_sim1_yoked_7200s_synapses.tif';

% Plot the real simulation's synaptic weights and save to file
figure('PaperPosition', [500, 500, 500, 400],'PaperPositionMode','auto'); 
imagesc(sout_real.sout,[0,4]); colorbar(); 
xlabel('Motor Neuron','FontName','Helvetica','FontSize',10); 
ylabel('Reservoir Output Neuron','FontName','Helvetica','FontSize',10); 
title(sprintf('Salience-Reinforced Simulation %i, Synaptic Weights, %i s', 1, sec),'FontName','Helvetica','FontSize',12,'FontWeight','bold');
print(realFigFname,'-dtiff','-loose','-r300');

% Plot the yoked control simulation's synaptic weights and save to file
figure('PaperPosition', [500, 500, 500, 400],'PaperPositionMode','auto');
imagesc(sout_yoked.sout,[0,4]); colorbar(); 
xlabel('Motor Neuron','FontName','Helvetica','FontSize',10); 
ylabel('Reservoir Output Neuron','FontName','Helvetica','FontSize',10); 
title(sprintf('Yoked Control Simulation %i, Synaptic Weights, %i s', 1, sec),'FontName','Helvetica','FontSize',12,'FontWeight','bold');
print(yokeFigFname,'-dtiff','-loose','-r300');
