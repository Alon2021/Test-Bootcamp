%% 
% preprocess fMRI data for the VAE

%% Configuration
addpath('./durak');
addpath('.\CIFTI_read_save');
data_path = ['D:\7T_rest\7T_rest_174\'];
path_inner = 'MNINonLinear\Results\rfMRI_REST2_7T_AP\rfMRI_REST2_7T_AP_Atlas_MSMAll_hp2000_clean.dtseries.nii';
output_dir = 'C:\Users\Alon\Desktop\fmri\rsfMRI_VAE\demo\data\datamix';
output_file_suffix='preprocesed';
sub_names=dir(data_path);
sub_vec = {sub_names(3:(end),1).name};
n = length(sub_vec);
for i=1:174
cii_input_filepath = fullfile(data_path,sub_vec{i}, path_inner);
cii_output_filepath = [output_dir '\' sub_vec{i} output_file_suffix];
%% Preprocess
% sampling frequency of HCP fMRI data
Fs = 1/0.72; 

% read in original data with fieldtrip toolbox
% loaded in as a struc
cii = ft_read_cifti(cii_input_filepath);

% extract time-series data from left and right cortex (regions 1,2)
cortex_dtseries = cii.dtseries((cii.brainstructure == 1 | cii.brainstructure == 2), :);
cortex_nonan_dtseries = cortex_dtseries(~isnan(cortex_dtseries(:,1)), :); % 59412 dimensional

% detrend and filter the data
Normalized_cortex_nonan_dtseries = Detrend_Filter(cortex_nonan_dtseries,Fs);

% fill the normalized data into the correct index of the cifti data
cortex_dtseries(~isnan(cortex_dtseries(:,1)), :) = Normalized_cortex_nonan_dtseries;
cii.dtseries((cii.brainstructure == 1 | cii.brainstructure == 2), :) = cortex_dtseries;

% save the preprocessed data
ft_write_cifti(cii_output_filepath, cii, 'parameter', 'dtseries');
end
