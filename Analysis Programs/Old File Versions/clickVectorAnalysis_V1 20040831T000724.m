function [data,CutOff,MNonSync1,NonSync2,PValue,Spon]=clickVectorAnalysis_V1(fname,NClicks,data,SpDelay,isi)
%Created By: Mike Kilgard- Updated: Rob Rennaker 10/08/2003
% tonetrainana.m calculates the response to trains of tones 
% Spikes is a N sgi x i repetitions x 6 elements matrix of the number of spikes with 25msec of each stimulus.
% Normresponse is the mean response to each sgi normalized to the response to the variable tone in isolation.
% spikes=tonetrainana('en1_035e1.f32')
%data=spikedataf(filename);
%Basic Parameters
NReps=length(data(1).sweep);%Number of repititions
isi;
NStim=length(isi);  %length(ICIs);
%Delay prior to start of first click
disp(['Spontaneous Delay is set at ',num2str(SpDelay),' ms']);
First=[];Spon=[];Count=0;NonSync1=[];NonSync2=[];

for i1=1:NStim
    i1;
    Theta=[];
    Dur=data(i1).sweeplength;
    if isi(i1)*NClicks<Dur
        Last=isi(i1)*NClicks+isi(i1);%Finds the time of the last click
        
        TNClicks(i1)=NClicks;%Number of clicks for each repetition
    else
        Last=NClicks*isi(i1)+20;%The final click in the series
        TNClicks(i1)=round(Dur/isi(i1));%Number of clicks for each repetition
    end
    for i2=1:NReps
        Count=Count+1;
        Spikes=data(i1).sweep(i2).spikes-SpDelay;%Zeros spike times to onset of first click
        Spon=[Spon,length(find(Spikes<0))];%Finds number of spikes prior to the clicks
        NonSync1(i2,i1)=length(find((Spikes<SpDelay+100)&(Spikes>=SpDelay)));
        NonSync2(i2,i1)=length(find((Spikes<235)&(Spikes>=135)));
        Spikes=Spikes(find((Spikes<Last)&(Spikes>=0)));%Gets rid of spikes after end of click train  
        Theta=[Theta,(Spikes)/isi(i1)*2*pi]; %Calculates theta in radians
        First=[First,Theta(find((Theta>=0)&(Theta<=2*pi)))];%Finds spike response to first click only
    end
    data(i1).Theta=Theta;
    NormTheta=Theta-floor(Theta);
    X=sum(cos(Theta));
    Y=sum(sin(Theta));
    data(i1).MeanVector=sqrt(X^2+Y^2)/length(data(i1).Theta);
    data(i1).Sig=2*length(data(i1).Theta)*(data(i1).MeanVector)^2;% calculate Rayleigh statistic  2n(R^2)if 2n(R^2) > 13.8 then p<0.001
end
SpRate=mean(Spon)/length(Spon);     
figure;
PValue=[];
PValue=[data(:).Sig];
%PValue(find([data(:).Sig]>13.816))=20;

plot([1000./isi(:)],PValue);

hold on;
plot([1000./isi(:)],PValue,'*');
plot([0,250],[13.8,13.8],'--r')
xlabel('Repetition Rate (Hz)','fontsize',14);
title(fname,'fontsize',14);
ylabel('Rayleigh Statistic','fontsize',14);
disp('Select Cutoff');
[x,y]=ginput(1);
try
    CutOff=x;
    %fix(1000/ICIs(min(find(PValue>20))));
    plot(CutOff,13.8,'rh');
catch
end

text(150,max([data(:).Sig])/2,['Cutoff: ',num2str(CutOff), ' Hz']),plot(145,max([data(:).Sig])/2,'rh'); 
dot=find(fname=='.');
saveas(gcf,['CircStat', fname(1:dot-1)],'fig');
saveas(gcf,['CircSt', fname(1:dot-1)],'tif');

figure;
[row,col]=size(Spon);
RSpon=reshape(Spon,1,row*col)/.1;
NonSync1=NonSync1./0.1;%Converts Spikes to rate
NonSync2=NonSync2./0.1;%Converts Spikes to rate
MNonSync1=mean(NonSync1);
StdErNonSync1=std(NonSync1)/sqrt(NStim);
MNonSync2=mean(NonSync2);
StdErNonSync2=std(NonSync2)/sqrt(NStim);

try
    errorbar([1000./isi(:)],MNonSync1,StdErNonSync1, StdErNonSync1);
    hold on;
    errorbar([1000./isi(:)],MNonSync2,StdErNonSync2, StdErNonSync2,'r');
    plot([0,250],[mean(RSpon),mean(RSpon)],'k');
catch
end

if mean(Spon)==0
else
    [r1,c1]=size(NonSync1);
    for  i=1:r1
        RawRate1=NonSync1(i,:);
        RawRate2=NonSync2(i,:);
        try
            [h,p1,sig,ci] = ttest2(RawRate1,mean(RSpon),.05,1);
        catch
            disp('0 found')
            h=0;
            p1=1;
            sig=.99;
            ci=10;
        end
        try
            [h2,p2,sig2,ci2] = ttest2(RawRate2,mean(RSpon),.05,1);
        catch
            disp('0 found')
            h2=0;
            p2=1;
            sig2=.99;
            ci2=10;
        end
       Pval=[p1,p2];
       Pval=min(Pval);
       
        if Pval<.05
            plot(1000/isi(i),10,'r*');
        end
    end
end

dot=find(fname=='.');

saveas(gcf,['fr', fname(1:5), fname(dot-15:dot-1)],'tif');