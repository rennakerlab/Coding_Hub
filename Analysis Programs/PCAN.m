function data=PCAN(handles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Principal Component Analysis of the Data.
%Program by Shazafar Khaja (shahzafar@gmail.com)
%Program will perform PCA on the spike values read from the 'TEXT' file.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% this is the read back function for the binary spike files
finame = 'int.bin';
Q=[];
fbin = fopen(finame, 'r', 'n');
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
Q;
% finding and deleting the spike waveforms which are causing saturation. 
[x,y]=find(max(Q'==127));
Q(y,:)=0;
[x,y]=find(max(Q'==-127));
Q(y,:)=0;

save 'Data.mat' Q;
X=Q;
[n m]=size(Q);
Xm=mean(X);%Calculating the mean spike waveform for all the spikes in the data.
plot(Xm);
legend('Mean Spike Waveform Shape');
figure;
Xc=X-repmat(Xm,n,1);%Centering the data.
[PC, PCscore, PCvar] = princomp(Xc);
SD=sqrt(PCvar);
plot(SD/2,'+');% Normalising the Standard deviation and its plot.
figure
plot3(PCscore(:,1),PCscore(:,2),PCscore(:,3),'+')
xlabel('1st Principal Component');
ylabel('2nd Principal Component');
zlabel('3rd Principal Component');
figure
scatter3(PCscore(:,1),PCscore(:,2),PCscore(:,3),'+')
xlabel('1st Principal Component');
ylabel('2nd Principal Component');
zlabel('3rd Principal Component');
figure
plot(PCscore(:,1),PCscore(:,2),'+')
xlabel('1st Principal Component');
ylabel('2nd Principal Component');
save 'PCscore.mat' PCscore;
save 'PC.mat' PC;
save 'Mean_spike.mat' Xm;