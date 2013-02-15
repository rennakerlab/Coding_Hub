function [center, U, distortion] = Spike_Kmeans(data, clusterNum, plotOpt)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%K-Means clustering of the spike DATA. 
%Program by Shazafar Khaja (Shahzafar@gmail.com)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

load PCscore;
CI = kmeans(PCscore,clusterNum);
save 'Cluster_IDs.mat' CI;
figure
maxLoopCount = 100;				% Max. iteration
distortion = zeros(maxLoopCount, 1);		% Array for objective function
if length(clusterNum)==1
	center = initCenter(clusterNum, data, 4);	% Initial cluster centers
else
	center = clusterNum;				% The passed argument is a matrix of cluster centers
end

if plotOpt & size(data,1)>=2
	plot(data(1,:), data(2,:), 'b.');
	centerH=line(center(1,:), center(2,:), 'color', 'r', 'marker', 'o', 'linestyle', 'none', 'linewidth', 2);
	axis image
end;

% Main loop
for i = 1:maxLoopCount,
	[center, distortion(i), U] = Spike_UpdateCenter(center, data);
	fprintf('Iteration count = %d, distortion = %f\n', i, distortion(i));
	if plotOpt & size(data,1)>=2 
		set(centerH, 'xdata', center(1,:), 'ydata', center(2,:));
		drawnow;
	end
	% check termination condition
	if i > 1,
		if abs(distortion(i-1) - distortion(i))/distortion(i-1) < eps, break; end,
	end
end
loopCount = i;	% Actual number of iterations 
distortion(loopCount+1:maxLoopCount) = [];
if plotOpt & size(data,1)>=2, Spike_Kmeans_PlotResult(data, center, U); end

% ========== subfunctions ==========
% ====== Find the initial centers
function center = initCenter(clusterNum, data, method)
switch method
	case 1
		% ====== Method 1: Randomly pick clusterNum data points as cluster centers
		dataNum = size(data, 2);
		tmp = randperm(dataNum);
		center = data(:, tmp(1:clusterNum));
	case 2
		% ====== Method 2: Choose clusterNum data points closest to mean vector
		meanVec = mean(data, 2);
		distMat = vecdist(meanVec', data');
		[a,b] = sort(distMat);
		center = data(:, b(1:clusterNum));
	case 3
		% ====== Method 3: Choose clusterNum data points furthest to the mean vector
		meanVec = mean(data, 2);
		distMat = vecdist(meanVec', data');
		[a,b] = sort(-distMat);
		center = data(:, b(1:clusterNum));
	case 4
		% ====== Method 4: Choose clusterNum as cluster center
		center = data(:, 1:clusterNum);
	otherwise
		error('Unknown method!');
end

% ====== Update centers
function [center, distortion, U] = Spike_UpdateCenter(center, data)
dim = size(data, 1);
dataNum = size(data, 2);
centerNum = size(center, 2);
% ====== Compute distance matrix
distMat=vecdist(center', data');
% ====== Find the U (partition matrix)
[a,b] = min(distMat);
index = b+centerNum*(0:dataNum-1);
U = zeros(size(distMat));
U(index) = ones(size(index));
distortion = sum(sum((distMat.^2).*U));		% objective function
% ====== Check if there is an empty group (and delete them)
index=find(sum(U,2)==0);
emptyGroupNum=length(index);
if emptyGroupNum~=0,
	fprintf('Found %d empty group(s)!\n', emptyGroupNum);
	U(index,:)=[];
	distMat(index,:)=[];
end
% ====== Find the new centers
%center = (U*data')./(sum(U,2)*ones(1,dim));
center = (data*U')./(ones(dim,1)*sum(U,2)');
% ====== Add new centers for the deleted group
if emptyGroupNum~=0
	distortionByGroup=sum(((distMat.^2).*U)');
	[junk, index]=sort(-distortionByGroup);   % Find the indices of the centers to be split
	index=index(1:emptyGroupNum);
	temp=center; temp(:, index)=[];
	center=[temp, center(:,index)-eps, center(:,index)+eps];
	distMat = vecdist(center', data');
	[a,b] = min(distMat);
	index = b+centerNum*(0:dataNum-1);
	U = zeros(size(distMat));
	U(index) = ones(size(index));
%	center = (U*data')./(sum(U,2)*ones(1,dim));
	center = (data*U')./(ones(dim,1)*sum(U,2)');
	distMat = vecdist(center', data');
end
% ====== Function for computing Distance Matrix
function distmat = vecdist(mat1, mat2)
if nargin == 1,
	mat2 = mat1;
end

[m1, n1] = size(mat1);
[m2, n2] = size(mat2);

if n1 ~= n2,
	error('Matrices mismatch!');
end

distmat = zeros(m1, m2);

if n1 == 1,
	distmat = abs(mat1*ones(1,m2)-ones(m1,1)*mat2');
elseif m2 >= m1,
	for i = 1:m1,
		distmat(i,:) = sqrt(sum(((ones(m2,1)*mat1(i,:)-mat2)').^2));
	end
else 
	for i = 1:m2,
		distmat(:,i) = sqrt(sum(((mat1-ones(m1,1)*mat2(i,:))').^2))';
    end
end
% ====== Plot results
function Spike_Kmeans_PlotResult(data, center, U)
if size(data, 1)<2; return; end
color = {'r', 'g', 'c', 'y', 'm', 'b', 'k'};
figure
plot(data(1,:), data(2,:), 'o');
maxU = max(U);
clusterNum = size(center,2);
for i=1:clusterNum
	index = find(U(i, :) == maxU);
    colorIndex = rem(i, length(color))+1;
	fprintf('\n\nSize of group %d = %d \n', i,length(index));
 	line(data(1,index), data(2,index), 'linestyle', 'none', 'marker', '*', 'color', color{colorIndex});
	line(center(1,i), center(2,i), 'color', 'r', 'marker', 'o', 'linestyle', 'none', 'linewidth', 2);
groupcolor=color(colorIndex)
groupcenter=[center(1,i),center(2,i)];
end
pcw=center
save 'princomp_weights.mat' pcw;
axis image;
[pcs,numclusters]=size(pcw);
load PC;
load Mean_spike;
shp(1:numclusters,length(PC))=zeros;
for i=1:numclusters
    for j=1:pcs
        shp(i,:)=pcw(j,i)*PC(:,j)'+shp(i,:);
    end
    shp(i,:)=shp(i,:)+Xm;
end
save 'Spike_Shapes.mat' shp;

%Sorting the Spike Times based on the Cluster ID's.
load SpikeTimes_Marked.mat;
load Cluster_IDs.mat;
A=timestamps_marker;
A1(:,1)=A;
A1(:,2)=zeros(1,length(A));
w=find(A1(:,1)==-2);%Finding the -2's
A1(w,2)=-2;
x=find(A1(:,1)==-4);%Finding the -4's
A1(x,2)=-4;
y=find(A1(:,1)==-1);%Finding the -1's
A1(y,2)=-1;
z=find(A1(:,2)==0);
A1(z,2)=CI;
for i=1:clusterNum
l=find(A1(:,2)==-2|A1(:,2)==-1|A1(:,2)==-4|A1(:,2)==i);
MSS{i}=A1(l,1);%Creating a structure with individual cells holding the spike times of the sorted clusters.
end
% Extracting the data from F32 file and then inserting it into the
% structure.
load f32data;
s=0;
for i=1:length(data)
    s=s+1;
    r1(s)=data(i).sweeplength;
    s=s+1;
    r1(s)=length(data(i).stim);
    r1(s+1:s+r1(s))=data(i).stim;
    s=s+r1(s);
end
R=r1';
for i=1:clusterNum
   t=find(MSS{i}==-4);
   MSS{i}(t)=R;
end

save 'Marked_Sorted_SpikeTimes.mat' MSS;
    
Time_Stamps = importdata('float.txt');
int_binary_file='int.bin'
fbin = fopen(int_binary_file, 'r', 'n');
q = fread(fbin, inf, 'integer*4');
fclose(fbin);
s=length(q);
temp=0;
for i=1:s/27
    for j=1:27
        temp=temp+1;
        Q(i,j)=q(temp);
    end
end
G=CI;
[r1 c1]=size(Q);
temp1=0;
temp2=0;
n=clusterNum;
k=0;
for i=1:n
    k=k+1;
    temp=0;
    for j=1:r1
        if G(j)==i
            temp=temp+1;
            SS{k}(temp,:)=Q(j,:);
        end
    end
end
save 'Sorted_Spikes.mat' SS;
