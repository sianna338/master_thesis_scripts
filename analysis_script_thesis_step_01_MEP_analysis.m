%% preliminaries 
addpath('C:\Users\siann\Downloads\fieldtrip-20231113\fieldtrip-20231113')
ft_defaults

datapath = 'C:\Users\siann\Data\spindle_ppTMS\EEG'
subjects = {'sub-02'}
session = {'ses-exp_01', 'ses-exp_02', 'ses-exp_03'}
% define conditions
condition_peak = 'S155'
condition_trough = 'S156'
condition_rising = 'S157'
condition_falling = 'S158'
condition_sp_free = 'S159'

%% 
% look at markers in dataset and segment based on markers
for isub=1:length(subjects)
    for ises=1:length(session)
        cfg = [];
        cfg.datafile = [datapath, filesep, subjects{isub}, filesep, session{ises}, filesep, 'spindle-ppTMS_', subjects{isub}, '_', session{ises}, '.eeg']
        cfg.continous = 'yes';
        cfg.channel = {'FDIr'};
        cfg.trialdef.prestim = 0.05; 
        cfg.trialdef.poststim = 0.1; 
        cfg.trialdef.eventtype = 'Stimulus';
        cfg.trialdef.eventvalue = {condition_peak, condition_trough, condition_falling,...
            condition_rising, condition_sp_free}
        cfg = ft_definetrial(cfg);
        trial_matrix = cfg.trl
   

        % read-in data
        % cfg = []; 
        cfg.headerfile = [datapath, filesep, subjects{isub}, filesep, session{ises}, filesep, 'spindle-ppTMS_', subjects{isub}, '_', session{ises}, '.vhdr']
        cfg.channel = {'FDIr'};
        cfg.demean = 'yes'
        cfg.baselinewindow = [-0.05 -0.005]
        data_raw= ft_preprocessing(cfg);   

        % extract min and max points for for the time window from 0.015-0.05 after
        % TMS pulse
        cfg=[];
        cfg.latency=[0.015 0.05];
        cfg.channel = {'FDIr'};
        data_MEPs = ft_selectdata(cfg, data_raw)
        for i = 1:numel(data_MEPs.trial)
            plot(data_MEPs.trial{i}(1,:))
            min_val = min(data_MEPs.trial{i}(1,:));
            max_val = max(data_MEPs.trial{i}(1,:));
            data_MEPs.mep(i,1) = abs(min_val) + abs(max_val);
        end
        save([datapath, filesep, subjects{isub}, filesep, session{ises}, filesep,'data_', subjects{isub}, '_', session{ises}], 'data_MEPs', '-v7.3');
    end
end

    
%%
data_MEPs_conds = []
for isub = 1:numel(subjects)
    MEPs_one_subject = []
    conditions_one_subject = []
    for ises = 1:numel(session)
        load([datapath, filesep, subjects{isub}, filesep, session{ises}, filesep,'data_', subjects{isub}, '_', session{ises}]);
        conditions_one_subject = [conditions_one_subject; data_MEPs.trialinfo]
        MEPs_one_subject = [MEPs_one_subject; data_MEPs.mep]
    end  
    data_MEPs_conds = [MEPs_one_subject, conditions_one_subject]  

    % calculate z-scores and remove outliers if needed
    data_MEPs_conds(:,3) = zscore(data_MEPs_conds(:,1));
    threshold = 1.5
    ; 
    non_outliers = (abs(data_MEPs_conds(:,3)) < threshold)
    data_MEPs_conds = data_MEPs_conds(non_outliers,:) 

    % Count how many times each condition occurs and then get mean MEP amplitude for each ITI
    % [condition_num, ~, idx] = unique(data_MEPs_conds(:,2));
    [conditions_counts,condition_num] = groupcounts(data_MEPs_conds(:,2)) 
    average_MEP = groupsummary(data_MEPs_conds(:,1),data_MEPs_conds(:,2),"mean")
    SD_MEP = groupsummary(data_MEPs_conds(:,1),data_MEPs_conds(:,2),"std")

    MEP_avg = struct('Condition', condition_num, 'Count', conditions_counts, 'Average_MEP', average_MEP);

end 


% Plot
figure; 
plot(MEP_avg.Condition, MEP_avg.Average_MEP, 'ok', 'MarkerFaceColor','k','MarkerSize', 8)
errorbar(MEP_avg.Condition, MEP_avg.Average_MEP, SD_MEP, 'ok', 'MarkerFaceColor', 'k', 'LineWidth', 1, 'Color', [0.5 0.5 0.5]);
title([subjects(isub),' MEP amplitudes'], 'FontWeight', 'bold');
xlabel('conditions', 'FontWeight', 'bold');
ylabel('MEP amplitude (microvolt)', 'FontWeight', 'bold');
xticks([155, 156, 157, 158, 159])
xticklabels({'peak', 'trough', 'rising', 'falling', 'post'})
set(gca, 'FontSize', 12, 'FontName', 'Arial');
grid on; 
set(gca, 'GridLineStyle', '--', 'GridColor', [0.6 0.6 0.6], 'GridAlpha', 0.7);
pbaspect([1.5 1 1]); 
box on;
colormap(jet)



