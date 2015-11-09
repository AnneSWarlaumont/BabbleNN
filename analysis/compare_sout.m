% Anne S. Warlaumont

diary('~/IVOC-NN-Learning/DataTables/compare_sout.txt')

% Navigate to the directory containing the simulation workspaces
cd ~/IVOC-NN-Learning/BabbleNNPreGit/PresentationsAndPublications/WarlaumontAndFinnegan4PLOSONE/Submission1/SupportingInformation/Workspaces/

Nruns = 5;

real_sout_ratios = NaN(Nruns,1);
yoke_sout_ratios = NaN(Nruns,1);
real_sout_sds = NaN(Nruns,1);
yoke_sout_sds = NaN(Nruns,1);

for nrun = 1:Nruns
    
    vars_real = load(strcat('babble_daspnet_reservoir_NandScExtended_2_1_',num2str(nrun),'_7200.mat'),'sout');
    vars_yoke = load(strcat('babble_daspnet_reservoir_NandScExtended_2_1_',num2str(nrun),'_yoke_7200.mat'),'sout');
    
    real_sout_ratios(nrun,1) = mean(mean(vars_real.sout(:,1:size(vars_real.sout,2)/2)))/mean(mean(vars_real.sout(:,size(vars_real.sout,2)/2+1:size(vars_real.sout,2))));
    yoke_sout_ratios(nrun,1) = mean(mean(vars_yoke.sout(:,1:size(vars_yoke.sout,2)/2)))/mean(mean(vars_yoke.sout(:,size(vars_yoke.sout,2)/2+1:size(vars_yoke.sout,2))));
    
    real_sout_sds(nrun,1) = std2(vars_real.sout);
    yoke_sout_sds(nrun,1) = std2(vars_yoke.sout);
    
end

datatable = table(real_sout_ratios, yoke_sout_ratios, real_sout_sds, yoke_sout_sds);
writetable(datatable, '~/IVOC-NN-Learning/DataTables/sout_ratios_sds.csv')

real_sout_ratios
mean(real_sout_ratios)
yoke_sout_ratios
mean(yoke_sout_ratios)
[h,p,ci,stats] = ttest(real_sout_ratios,yoke_sout_ratios)

real_sout_sds
mean(real_sout_sds)
yoke_sout_sds
mean(yoke_sout_sds)
[h,p,ci,stats] = ttest(real_sout_sds,yoke_sout_sds)

diary off