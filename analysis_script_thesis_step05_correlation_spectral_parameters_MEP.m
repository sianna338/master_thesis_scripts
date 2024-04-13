%%%% spectral analysis of pre-TMS time window to get spindle characteristics
%%%% get: spindle frequency, sigma power, sigma amplitude, duration and 1/f level
%%%% and then correlate with trial-by-trial variations in MEP amplitude

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
condition_names = {condition_peak, condition_trough, condition_rising, ...
    condition_falling, condition_sp_free}

%% load the cleaned and segmented data
for isub=1:numel(subjects)
    load([datapath, filesep, subjects{isub}, filesep, 'data_', subjects{isub}, '_', 'all_ses', '_TMS_clean_demean'])
    % need to do demeaining to get rid of non-zero DC component in time
    % domain data to not have the TF plot look weird
    data_tms_clean_copy = data_tms_clean 
    % replace the post TMS period with zeros
    for itrial=1:length(data_tms_clean_copy.trial)
        data_tms_clean_copy.trial{itrial}(:, ((2.5-0.004)*sf):end) = 0
    end 
    % time-frequency analysis
    cfg              = [];
    cfg.output       = 'pow';
    cfg.method       = 'mtmconvol';
    cfg.taper        = 'hanning'; % unsure whether hanning or gaussian taper
    cfg.foi          = 1:0.5:35;
    cfg.t_ftimwin    = 5./cfg.foi;  
    cfg.toi          = -1.004:0.02:-0.004; % 1.5 to 1s pre TMS
    cfg.keeptrials='yes' % get frequency estimate for every trial
    TFRhann5_all_conds= ft_freqanalysis(cfg, data_tms_clean_copy);  

    cfg              = [];
    cfg.parameter    = 'powspctrm'
    % cfg.baseline     = [-0.5 -0.4] % remove 1/f component from the data 
    cfg.baselinetype = 'absolute';
    cfg.maskstyle    = 'saturation';
    cfg.zlim         = [0 50];
    % cfg.ylim         = [TFRhann5{1}.freq(1,3) TFRhann5{1}.freq(1,end)]
    cfg.channel      = 'C4';
    cfg.interactive  = 'no';
    figure
    ft_singleplotTFR(cfg, TFRhann5_all_conds);
    xlabel('time'); 
    ylabel('frequency');
    title(['time-frequency plot before TMS pulse'])

    % check topolplot whether activity in sigma range in really spindle
    % activity 
    cfg = [];
    cfg.zlim = [0 50];
    cfg.xlim = [-1.5 1]; 
    cfg.ylim = [12 16];
    % cfg.baseline = [-0.5 -0.4];
    cfg.baselinetype = 'absolute';
    cfg.layout = 'acticap-64ch-standard2';
    figure; ft_topoplotTFR(cfg,TFRhann5_all_conds); colorbar
    title(['topoplot before TMS pulse'])
end 

%% get sigma power
for isub=1:numel(subjects)
    for itrial=1:length(data_tms_clean_copy.trial)
    % find the max power peak in the spindle frequency range 
        [max_sigma(itrial), idx_max_sigma(itrial)] = max([TFRhann5_all_conds.powspctrm(itrial, 6, 23:31, :)], [], 'all')
    end 
end 

%% get spindle frequency
for itrial=1:length(data_tms_clean_copy.trial)
    [I1(itrial),I2(itrial), I3(itrial), I4(itrial)] = ind2sub([1 1 9 51],idx_max_sigma(itrial))
end 

sigma_freqs = TFRhann5_all_conds.freq(23:31)
max_sigma_freqs = sigma_freqs(I3)

%% get sigma amplitude
sigma_amplitude = rms(max_sigma, 1) % rms value for power val associated with peak freq on each trial

%% get 1/f level
%% how to extract spindle duration??

%% correlate spindle characteristics with trial-by-trial variations in MEP amplitude 
for isub=1:numel(subjects)
    load([datapath, filesep, subjects{isub}, filesep,'data_', subjects{isub}, '_all_ses_MEP_trialwise'])
end 

% sigma peak freq
[r_freq, p_freq] = corrcoef(max_sigma_freqs, data_MEPs_conds(:,3)')
% sigma power
[r_pow, p_pow] = corrcoef(max_sigma, data_MEPs_conds(:,3)')
% sigma amplitude
[r_amp, p_amp] = corrcoef(sigma_amplitude, data_MEPs_conds(:,3)')
