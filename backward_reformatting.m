%% 
% backward projection from the VAE reconstruction to the cortex

%% Configuration
batchsize = 25;
addpath('./durak');
addpath('./CIFTI_read_save');
% recon_path = './result/recon/';
inverse_transformation_path = '.\result\';
data_path_after=['D:\fmri\rsfMRI_VAE\demo\result\recon\recon_nii'];
data_path_right_left = ['D:\fmri\rsfMRI_VAE\demo\result\'];
data_path_before = ['D:\7T_rest\7T_rest_174\'];
path_inner_before = 'MNINonLinear\Results\rfMRI_REST2_7T_AP\rfMRI_REST2_7T_AP_Atlas_MSMAll_hp2000_clean.dtseries.nii';
sub_names_before=dir(data_path_before);
sub_vec_before = {sub_names_before(3:(end),1).name};
n_before = length(sub_vec_before);
sub_names_right_left=dir(data_path_right_left);
sub_vec_right_left = {sub_names_right_left(3:(end),1).name};
n_right_left = length(sub_vec_right_left)-2;
j=1;
for i=1:3:n_right_left
%% load the inverse transformation matrix

% load the inverse transformation matrix of geometric reformatting, as in JH's Recon_fMRI_Generator.m
load([inverse_transformation_path sub_vec_right_left{i} ], 'inverse_transformation');
Left_inverse_transformation = inverse_transformation;
load([inverse_transformation_path sub_vec_right_left{i+2} ], 'inverse_transformation');
Right_inverse_transformation = inverse_transformation;

%% backward projection
recon_dtseries = zeros(59412, 900);
for idx = 1:10
    load(['D:\fmri\rsfMRI_VAE\demo\result\recon\img_path\' sub_vec_before{1} '_img' num2str(idx-1) '.mat'], 'recon_L', 'recon_R');
    corticalrecon_L = Left_inverse_transformation * double(reshape(permute(recon_L,[1,2,4,3]),batchsize, [])');
    corticalrecon_R = Right_inverse_transformation * double(reshape(permute(recon_R,[1,2,4,3]),batchsize, [])');
    recon_dtseries(:, (idx-1)*batchsize+1:idx*batchsize) = [corticalrecon_L; corticalrecon_R];
end

%% save the reconstruction back into cifti file
% read in original data with fieldtrip toolbox
% loaded in as a struc
cii_template_filepath = fullfile(data_path_before,sub_vec_before{j}, path_inner_before);
cii_output_filepath = strcat(fullfile(data_path_after,sub_vec_before{j}),'_rfMRI_REST1_LR_Atlas_MSMAll_hp2000_clean_reconstruction');
cii = ft_read_cifti(cii_template_filepath);

% extract time-series data from left and right cortex (regions 1,2)
cortex_dtseries = cii.dtseries((cii.brainstructure == 1 | cii.brainstructure == 2), :);

% fill the normalized data into the correct index of the cifti data
cortex_dtseries(~isnan(cortex_dtseries(:,1)), :) = recon_dtseries;
cii.dtseries((cii.brainstructure == 1 | cii.brainstructure == 2), :) = cortex_dtseries;

% save the preprocessed data
ft_write_cifti(cii_output_filepath, cii, 'parameter', 'dtseries');
j=j+1;
end