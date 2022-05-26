clc;
clear all;
%Geometric reformatting to get the transformation from cortex to grid data
addpath('.\durak');
% Configurations
%set the size of the output image
im_size = 192;
%add filepaths/filenames used
addpath('.\CIFTI_read_save');
data_path1 = ['D:\7T_rest\7T_rest_174'];
sub_names1=dir(data_path1);
sub_vec1 = {sub_names1(3:(end),1).name};
data_path = ['D:\fmri\rsfMRI_VAE\demo\data\datamix'];
sub_names=dir(data_path);
sub_vec = {sub_names(3:(end),1).name};
n = length(sub_vec);
for i=1:174
Preprocessed_fMRI_filepath =  fullfile(data_path,sub_vec{i});
LSphere_filepath = 'D:\fmri\rsfMRI_VAE\demo\template\Q1-Q6_R440.L.sphere.32k_fs_LR.surf.gii';
RSphere_filepath = 'D:\fmri\rsfMRI_VAE\demo\template\Q1-Q6_R440.R.sphere.32k_fs_LR.surf.gii';


% load data
%read in preprocessed data with fieldtrip toolbox
%loaded in as a struc
cii = ft_read_cifti(Preprocessed_fMRI_filepath);

%extract time-series data from left and right visual cortex (regions 1,2)
%fMRI dimensions: num voxels x num time points
fMRI = cii.dtseries((cii.brainstructure == 1 | cii.brainstructure == 2),:);
Left_fMRI = cii.dtseries((cii.brainstructure == 1),:);
Right_fMRI = cii.dtseries((cii.brainstructure == 2),:);

%extract the first time point from fMRI
Sample_Data = fMRI(:,1);
Sample_Data_Left = Left_fMRI(:,1);
Sample_Data_Right = Right_fMRI(:,1);

% get voxels in 59412 space
%create logical vector corresponding to which voxels have nan value
%voxels with nan value are not valid values
voxel_valid = ~isnan(Sample_Data);
voxel_valid_L = ~isnan(Sample_Data_Left);
voxel_valid_R = ~isnan(Sample_Data_Right);

%remove nan values from the sample data
Sample_Data_no_nan = Sample_Data(voxel_valid);
Sample_Data_no_nan_Left = Sample_Data_Left(voxel_valid_L);
Sample_Data_no_nan_Right = Sample_Data_Right(voxel_valid_R);

% save Normalized_fMRI as a mat file
Normalized_fMRI = fMRI(voxel_valid,:);
t='.\data\';
a=strcat(sub_vec{i},'_Fmri.mat');
full_save=fullfile(t,a);
save(full_save,'Normalized_fMRI');

% load coordanite values from spherical templates
%read in left/right hemisphere spherical templates (gifti geometry format)
lb = gifti(LSphere_filepath);
rb = gifti(RSphere_filepath);
%calculate the azimuth and elevation coordinates for each voxel
%do only for the valid voxels with non-nan values
[L_az_nonan, L_el_nonan, R_az_nonan, R_el_nonan] = Dimension_Reduction_Surface(voxel_valid,lb,rb); 

% Mask generation
%initialize mask vectors for left/right cortex
Left_Mask = ones(length(Sample_Data_Left),1);
Right_Mask = ones(length(Sample_Data_Right),1);
%input a zero in rows that correspond to voxels with nan value
Left_Mask(isnan(Sample_Data_Left))=0;
Right_Mask(isnan(Sample_Data_Right))=0;

%create a vector of ones to pass into Dimension_Reduction_Surface
voxel_all = true(length(voxel_valid),1);

%same calculation of azimuth and elevation coordinates for each voxel
%but do for all the voxels (with/wihout nan values)
[L_az, L_el, R_az, R_el] = Dimension_Reduction_Surface(voxel_all,lb,rb); 

%transform angles and create grid (for data with nan values)
[T_L_az, T_L_el, T_R_az, T_R_el, X, Y] = Create_Grid(im_size, L_az, L_el, R_az, R_el);

%generate L/R masks for im_size x im_size grid
[Regular_Grid_Left_Mask, Regular_Grid_Right_Mask] = Mask_Generation(im_size, Left_Mask, Right_Mask, T_L_az, T_L_el, T_R_az, T_R_el, X, Y);

%save the masks for the im_size x im_size grid
t='.\result';
a=strcat(sub_vec{i},'_MSE_Mask.mat');
full_save=fullfile(t,a);
save(full_save,'Regular_Grid_Left_Mask','Regular_Grid_Right_Mask');

% grid mapping
%transform angles and create grid (for data without nan values)
[T_L_az_nonan, T_L_el_nonan, T_R_az_nonan, T_R_el_nonan, X, Y] = Create_Grid(im_size, L_az_nonan, L_el_nonan, R_az_nonan, R_el_nonan);

%generate map for voxel data to 2D grid and its inverse map for L hemi
%save the grid mapping and inverse grid mapping for L hemi
[grid_mapping, inverse_transformation, transformed_gridmap_L, Loss_Rate_L] = Geometric_Reformatting_fMRI2Grid_NN(im_size, T_L_az_nonan, T_L_el_nonan, X,Y, Sample_Data_no_nan_Left);
t='.\result';
a=strcat(sub_vec{i},'_Left_fMRI2Grid_');
full_save=fullfile(t,a);
save([full_save,num2str(im_size),'_by_',num2str(im_size),'_NN.mat'],'grid_mapping','inverse_transformation')

%generate map for voxel data to 2D grid and its inverse map for R hemi
%save the grid mapping and inverse grid mapping for R hemi
[grid_mapping, inverse_transformation, transformed_gridmap_R, Loss_Rate_R] = Geometric_Reformatting_fMRI2Grid_NN(im_size, T_R_az_nonan, T_R_el_nonan, X,Y, Sample_Data_no_nan_Right);
t='.\result';
a=strcat(sub_vec{i},'_Right_fMRI2Grid_');
full_save=fullfile(t,a);
save([full_save,num2str(im_size),'_by_',num2str(im_size),'_NN.mat'],'grid_mapping','inverse_transformation')

% %% visualization
% % for visualization, plot the data for the first time point for L
% figure;
% imagesc(reshape(transformed_gridmap_L,im_size,im_size))
% title('2D image of cortical pattern (L)');
% disp(['Loss rate of reformatting and inverse-reformatting procedures (L) is ',num2str(Loss_Rate_L),'%'])
% 
% % for visualization, plot the data for the first time point for R
% figure;
% imagesc(reshape(transformed_gridmap_R,im_size,im_size))
% title('2D image of cortical pattern (R)');
% disp(['Loss rate of reformatting and inverse-reformatting procedures (R) is ',num2str(Loss_Rate_R),'%'])

% generate hdf5 format for Pytorch dataloader
%data_prep.py driver

s=strcat('D:\fmri\rsfMRI_VAE\demo\data\',sub_vec{i},'_Fmri.mat');
g=strcat('D:\fmri\rsfMRI_VAE\demo\result\',sub_vec{i});
if i<=100
  newname=strcat(sub_vec1{i},'_train.h5');
end
if (i>100)&&(i<140)
   newname=strcat(sub_vec1{i},'_val.h5');
end
if i>140
   newname=strcat(sub_vec1{i},'.h5');    
end
system(char(['python ./durak/data_prep.py --fmri-path '+string(s)+' --trans-path '+string(g)+' --output-path ./data --sub_name '+string(newname)]));
end
