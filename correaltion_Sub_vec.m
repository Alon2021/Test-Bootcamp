data_path1 = ['D:\7T_rest\7T_rest_174'];
sub_names1=dir(data_path1);
sub_vec1 = {sub_names1(3:(end),1).name};
n = length(sub_vec1);
correlationmax=cell(174,3);
% for i=1:n
% correlationmax{i,2}=0;
% end
% for i=1:n-1
% correl1=load(strcat(sub_vec1{i},'_save_z0.mat'));
% correlationmax{i,1}=sub_vec1{i};
%   for j=1:n-1
%     if i~=j
%       correl2=load(strcat(sub_vec1{j},'_save_z0.mat'));
%       correlation=corrcoef(correl1.z_distribution(1,:),correl2.z_distribution(1,:));
%         if correlation(1,2)>correlationmax{i,2}
%            correlationmax{i,2}=correlation(1,2);
%            correlationmax{i,3}=sub_vec1{j};
%      
%         end
%     end
%   end
% end
correl2=load(strcat(sub_vec1{1},'_save_z0.mat'));
correl1=load(strcat(sub_vec1{3},'_save_z0.mat'));
men1=[mean(correl2.z_distribution(1,1:256)),std(correl2.z_distribution(1,1:256))]
me21=[mean(correl1.z_distribution(1,1:256)),std(correl1.z_distribution(1,1:256))]
figure(1)
x1 = [-2.5:.1:2.5];
y1 = normpdf(x1,mean(correl2.z_distribution(1,1:256)),std(correl2.z_distribution(1,1:256)));
plot(x1,y1)
x2 =[-2.5:.1:2.5];
y2 = normpdf(x2,mean(correl1.z_distribution(1,1:256)),std(correl1.z_distribution(1,1:256)));
figure(2)
plot(x2,y2)
 
