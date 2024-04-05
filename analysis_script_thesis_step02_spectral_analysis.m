%% preliminaries

clc 
clear all; 
close all; 

% fieldtrip
path_ft   = 'C:\Users\siann\Downloads\fieldtrip-20231113\fieldtrip-20231113';
addpath(path_ft);
ft_defaults;

datapath = 'C:\Users\siann\Data\spindle_ppTMS\EEG'
subjects = {'sub-02'}
sf = 5000; 

% define conditions
condition_peak = 'S155'
condition_trough = 'S156'
condition_rising = 'S157'
condition_falling = 'S158'
condition_sp_free = 'S159'
conditions = {condition_peak, condition_trough, condition_rising, ...
    condition_falling, condition_sp_free}
%% 
% load the cleaned data
for isub=1:numel(subjects)
    load([datapath, filesep, subjects{isub}, filesep, 'data_', subjects{isub}, '_', 'all_ses', '_TMS_clean'])
    % need to do demeaining to get rid of non-zero DC component in time
    % domain data to not have the TF plot look weird
    cfg = []
    cfg.demean = 'yes'
    cfg.baseline     = [-0.5 -0.4];
    data_tms_clean = ft_preprocessing(cfg, data_tms_clean);
    data_tms_clean_copy = data_tms_clean 
    % replace the post TMS period with zeros
    for itrial=1:length(data_tms_clean_copy.trial)
        data_tms_clean_copy.trial{itrial}(:, ((2.5-0.004)*sf):end) = 0
    end 
    % select data for different conditions
    for icond = 1:numel(conditions)
        cfg = []
        cfg.trials = data_tms_clean_copy.trialinfo == str2double(conditions{icond}(2:end));
        data_all{icond} = ft_redefinetrial(cfg, data_tms_clean_copy);
    end 
    % TFA, frequency dependent window length (5 cycles)
    % multitaper convolution method
    conditions = {'peak stimulation', 'trough stimulation', 'rising stimulation', 'falling stimulation', 'spindle-free'}
    for icond = 1:numel(conditions)
        cfg              = [];
        cfg.output       = 'pow';
        cfg.channel      = 'C4';
        cfg.method       = 'mtmconvol';
        cfg.taper        = 'hanning'; % unsure whether hanning or gaussian taper
        cfg.foi          = 1:0.5:35;
        cfg.t_ftimwin    = 5./cfg.foi;  
        cfg.toi          = -1.5:0.02:-1; % 1.5 to 1s pre TMS
        TFRhann5{icond} = ft_freqanalysis(cfg, data_all{icond}); 
        % TFRhann5{icond}.freq = round(TFRhann5{icond}.freq*100)/100
        cfg              = [];
        cfg.parameter    = 'powspctrm'
        cfg.baselinetype = 'absolute';
        cfg.maskstyle    = 'saturation';
        cfg.zlim         = [0 10];
        % cfg.ylim         = [TFRhann5{1}.freq(1,3) TFRhann5{1}.freq(1,end)]
        cfg.channel      = 'C4';
        cfg.interactive  = 'no';
        figure
        ft_singleplotTFR(cfg, TFRhann5{icond});
        xlabel('time'); 
        ylabel('frequency');
        title(['time-frequency plot before TMS pulse for channel C4, condition: ' conditions{icond}])
    end 
    for icond = 1:numel(conditions)
        % plot using imagesc to see whether it looks nicer
        figure; 
        imagesc(TFRhann5{icond}.time,TFRhann5{icond}.freq,squeeze(TFRhann5{icond}.powspctrm(1,:,:)));axis xy; caxis([0 10]);
        xlabel('time'); 
        ylabel('frequency');
        title(['time-frequency plot before TMS pulse for channel C4, condition: ' conditions{icond}])
    end 
end 
