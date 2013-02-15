function Cluster_Main(handles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Main Program for clustering the DATA
%Program by Shazafar Khaja (Shahzafar@gmail.com)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear
plotOpt=1;
load PCscore;
figure
% clusterNum=input('Enter the Number of Clusters the Data has to be Clustered into ======>');
% Num_Prin_comps=input('Enter the number of Principal Components you want to use (Upto a maximum of 4) ========>');
% fprintf('Select from following list a method to pick the  Initial Cluster Centers ...\n');
%  fprintf('      Method 1: Randomly pick clusterNum data points as cluster centers \n');
%  fprintf('      Method 2: Choose clusterNum data points closest to mean vector\n');
%  fprintf('      Method 3: Choose clusterNum data points furthest to the mean vector\n');
%  fprintf('      Method 4: Choose clusterNum as cluster center\n');
%  method=input(' Enter Method Selection =======>');
switch Num_Prin_comps
    case 1
        data=[PCscore(:,1)]';%The first Principal Component Score
    case 2
        data=[PCscore(:,1) PCscore(:,2)]';% The first and second PC scores.
    case 3
        data=[PCscore(:,1) PCscore(:,2) PCscore(:,3)]';% 3 PC scores.
    case 4
        data=[PCscore(:,1) PCscore(:,2) PCscore(:,3) PCscore(:,4)]';% 4 PC scores.
end

[center, U, obj_fcn] = Spike_Kmeans(data, clusterNum, plotOpt);

