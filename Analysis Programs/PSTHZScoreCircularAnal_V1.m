function [PSTH]=PSTHZScoreCircularAnal_V1(PSTH,Catch,Bins,isi,NClicks,SpDelay,NReps,fname)
%Created 07262004 By: Rob Rennaker
%Plots the PSTH for each RRTF file 
%Calculates circular statistics for 500 us Bins
scale=2; %Determines number of bins 1=1ms 2= 500 uS; 4 = 250 uS etc
figure; hold on; Bins=round(Bins); Step=10; AllSponBin=[];
Nstim=length(isi);
%Calculates spontaneous rates for all stimuli
for i=1:Nstim
    y=hist(PSTH(Catch).Stim(i).CellSpikes,Bins*scale);%Counts number of spikes in each time bin
    SponBins=y(1:SpDelay*scale);%First 35ms The 1st 'N' bins
    AllSponBin=[AllSponBin,SponBins];
end

MeanSpon=mean(AllSponBin); StdSpon=std(AllSponBin);
%--------------------------------------------------------------------------
%-
for i=1:Nstim%Number of stimuli
    y=hist(PSTH(Catch).Stim(i).CellSpikes,Bins*scale);%Counts number of spikes in each time bin
%     if i==1
%         ystep=hist(PSTH(Catch).Stim(length(isi)).CellSpikes,Bins*scale)
%         step=ceil(max(ystep)*1.01);
%     end
    PSTH(Catch).Stim(i).Bins=y; 
    ZBins=(y-MeanSpon)./StdSpon; 
    PSTH(Catch).Stim(i).CircularZBins=ZBins;
    ZBins(find(ZBins<1.96))=0; %99% Single Tail:  2.326  --> 95% 1.645
    SigBins=ZBins;    
    %Calculates Theta for Circular analysis
    SigTime=find(ZBins>0);
    SigTheta=2*pi*((SigTime-SpDelay*scale)./(isi(i)*scale));
    PSTH(Catch).Stim(i).SigTheta=SigTheta;    
    X=sum(cos(SigTheta));
    Y=sum(sin(SigTheta));
    PSTH(Catch).Stim(i).MeanVector=sqrt(X^2+Y^2)/length(SigTheta);
    PSTH(Catch).Stim(i).VectorAngle=atan2(Y,X);
    PSTH(Catch).Stim(i).SigZVector=2*length(SigTheta)*(PSTH(Catch).Stim(i).MeanVector)^2;% calculate Rayleigh statistic  2n(R^2)if 2n(R^2) > 13.8 then p<0.001
    %----------------------------------------------------------------------
    %neural delay "Latency"
    %Spontaneous Duration
    win=5*scale;%Analysis window in ms
    Astart=5; %analysis window delay after tone
    %----------Spikes is the number of spikes for each presentation----#stimuli x #Repititions x #Tones-------------------
    AllMaxZ=[]; ClickCount=0;
    Height=((i-1)*Step);
    for k=1:NClicks%Counts number of spikes in each windows for the slow rates
        Ast=(((k-1)*isi(i))+SpDelay+Astart)*scale;%Window Start Time
        Tst=(((k-1)*isi(i))+SpDelay)*scale;%Tone Start Time
        ClickCount=ClickCount+1;
        if (ClickCount*isi(i)>Bins)|(ClickCount>100)
        else
            if (Ast+win)>Bins*scale
                LastBin=Bins*scale;
            else
                LastBin=Ast+win;
            end
            MaxZVal=max(ZBins(Ast:LastBin));%-----Grabs max value in window---------.................
            AllMaxZ=[AllMaxZ,MaxZVal];%--------    ----------------------------
            plot([Ast,LastBin],[Height-2.5,Height-2.5], 'k','linewidth', 1);
            plot([Tst,Tst+3],[Height-2,Height-2], 'r','linewidth', 3);
        end%Plot markers
     end
    PSTH(i).CircularZMax=AllMaxZ;%All Spikes after Start of tone zeroed
    %-------------------------------plots ZScores-------------------------------
    x=1:1:Bins*scale;
    plot(x,SigBins+Height,'LineWidth',1);
    if (NClicks*isi(i)+SpDelay)>Bins
        ClickCount=(Bins-SpDelay)/(isi(i));
    else
        ClickCount=NClicks;
    end    
end
rates=round(1000./isi);
axis([0,Bins,-5,Nstim*Step]);
set(gca, 'ylim', [0 Step*25], 'ytick', [.1:Step:Step*25]);
set(gca, 'xlim', [0 Bins*scale], 'xtick', [.1:Bins*scale/10:Bins*scale+1]);
set(gca,'YTickLabel',rates);
set(gca,'XTickLabel',[0:Bins/10:Bins]);
xlabel('Time (ms)','fontsize',14);

title([fname(1:20),'ZBins (', num2str(1000/scale), ' uS)'],'fontsize',14);
ylabel('Repetition Rate (Hz.)','fontsize',14);
saveas(gcf,[fname(1:20),'ZBins',num2str(Catch)],'tif');
saveas(gcf,[fname(1:20),'ZBins',num2str(Catch)],'m');
    
figure;
PValue=[];
PValue=[PSTH(Catch).Stim(:).SigZVector];%PValue(find([data(:).Sig]>13.816))=20;
PSTH(Catch).ZCircSig=PValue;
plot([1000./isi(:)],PValue,'*');
hold on;
plot([1000./isi(:)],PValue);
plot([0,250],[13.8,13.8],'--r')
disp('Select Cutoff');
[x,y]=ginput(1);
CutOff=x;
plot(CutOff,13.8,'kp');%Replot Cutoff
plot(95,30,'kp'); 
text(100,30,['Cutoff: ', num2str(CutOff), ' Hz']);
PSTH(Catch).Cutoff=CutOff;
xlabel('Repetition Rate (Hz)','fontsize',14);
title([fname(1:20),'Rayleigh Stats (', num2str(1000/scale), ' uS)'],'fontsize',14);
%title(filename,'fontsize',14);
ylabel('Rayleigh Statistic','fontsize',14);    
saveas(gcf,[fname(1:20),'ZCirc a 05',num2str(Catch)],'tif');
saveas(gcf,[fname(1:20),'ZCirc a 05',num2str(Catch)],'m');    