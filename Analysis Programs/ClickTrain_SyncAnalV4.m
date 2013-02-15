function [spikes,MeanNormResp,NormStdErr,NormSpon,rates,PVal,RespRatesInit,RespRatesFinal,CutOff,Latency,StdErrLate,AllN]=ClickTrain_SyncAnalV4(fname,tdur,win,NClicks,data,SpDelay,isi,isiindex,Bins)
%Created By: Mike Kilgard- Updated: Rob Rennaker 4/19/2004

if isempty(NClicks)
    NClicks=100;
end
nd=5; %neural delay "Latency"
tdur=2;%Tone Duration
sd=SpDelay; %Spontaneous Duration
space=1/(length(data(1).sweep));%Space between rates on histogram figure
height=1; %Y location of space
%win=5;%Analysis window in ms
Astart=nd; %analysis window delay after tone
NReps=length(data(1).sweep);%Number of repeats
NStim=length(isi);
spikes=nan*zeros(length(isi), length(data(1).sweep)*NClicks);%Creates storage array Size: "n" stimuli x Nsweeps x NClicks
RespRatesInit=zeros(length(isi), length(data(1).sweep));%Storage array for 
RespRatesFinal=zeros(length(isi), length(data(1).sweep));%Storage array for 
Latency=[];
WinSpikes=nan*ones(NStim,NReps*NClicks);
%--------------------------------------------------------------------------------------------------------------------%
%----------Spikes is the number of spikes for each presentation----#stimuli x #Repititions x #Tones-------------------
NTrials=0;
scrsz = get(0,'ScreenSize');
figure('Position',[25 scrsz(4)/10 scrsz(3)/2 scrsz(4)/2]);
plot(0,0);
hold on;
for i=1:NStim%Runs through isi indicies Number of stimulus sets
   AllSpikes=[]; ClickCount=0; AllFirst=[];%Initialize Variables for next loop
   for j=1:NReps%Number of Sweeps
      height=height+space;%Increments location of scatter plot
      plot(data(i).sweep(j).spikes, ones(size(data(i).sweep(j).spikes))*height, 'r.', 'markersize', 1);%plots a dot for each spike time at height
      RawSp=data(i).sweep(j).spikes;%Gets all spike times for this stimulus and sweep
      for k=1:NClicks%Counts number of spikes in each window
            Ast=((k-1)*isi(i))+SpDelay+Astart;%Window Start Time
            if Ast>Bins%IF tone start time is greater than the number of ms recorded place a nan in the data
                WinSpikes(i,k)=nan;
            else
                Ast=((k-1)*isi(i))+sd+Astart;%Window Start Time
                Tst=((k-1)*isi(i))+sd;%Tone Start Time
                ClickCount=ClickCount+1;%Counts number of clicks in the record for each rate NSweeps x NClicks
                if k==1%Collects Responses to first tone for all rates
                First=length(find((RawSp>=SpDelay+nd) & (RawSp<=SpDelay+Astart+win)));%Gets spikes in first window
                AllFirst=[AllFirst,First];%Combines spike counts into a single variable for the first click
                spon(i,j)=length(find(RawSp>=2 & RawSp<=win+5));%Combines spike counts into a single variable for spontaneous period
                end
                %-------------Spike data used for latency plots only------------------
                Spikes=RawSp(find((RawSp>=Tst) & (RawSp<=Ast+win*1.5)))-Tst;%Grabs Spikes and Zeros%---------
                AllSpikes=[AllSpikes,Spikes];%Combines spike into a single variable for All spikes
                %--------------  RRTF Window Analysis -------------------------------------------------------
                WinSpikes(i,ClickCount)=length(find((RawSp>=Tst+nd)&(RawSp<=Ast+win)));%Counts # of spikes in window
                %Plot click and analysis window markers
                if j==1, plot([Tst Tst+tdur], [height-space*3 height-space*3], 'k','linewidth', 2),end %Plots Black line Marking Tone
                if j==1, plot([Ast Ast+win], [height-space*1 height-space*1], 'b','linewidth', 1), end %Plots Blue line Marking Analysis Window
            end
        end
   end
   Latency(i).Spikes=AllSpikes;%All Spikes after Start of tone zeroed
   Latency(i).NumClicks=ClickCount;
   Latency(i).AllFirst=AllFirst;%Number of spikes in response to first tone.
   height=height+space*4;%Provides two spaces between each Data Set on raster plot
end
%axis tight; height; length(data);
set(gca, 'ylim', [(1-space*3) height], 'ytick', [1:space*(length(data(1).sweep)+4):height-space]);
set(gca,'YTickLabel',round(1000./isi));
xlabel('Time (ms)','fontsize',14);
title(fname,'fontsize',14);
ylabel('Repetition Rate (Hz.)','fontsize',14);
dot=find(fname=='.');
saveas(gcf,['Raster', fname(1:dot-1)],'tif');
%------------------------------------Plots the  RRTF-----
rates=1000./isi;%
%------------------------------------First Tone Mean---------------------------------------
MeanDrivenFirst=nanmean([Latency(:).AllFirst]);%Mean Response Count to first tone
StdDrivenFirst=nanstd([Latency(:).AllFirst]);%Std Response Count to first tone
%---------Calculates Mean & StdError of the spike rates for tones 2 - NClicks -----------------
NormResp=(WinSpikes')./MeanDrivenFirst;%Normalized Response to following tones.
MeanNormResp=nanmean(NormResp);%Mean Response Rate to following tones
StdNormResp=nanstd(NormResp);%Std Response Rate to following tones
%----------------------------------Spontaneous Mean Rate-------------------------------
[Row,Col]=size(spon);
Spon=reshape(spon,1,Row*Col); 
NormSpon=Spon/MeanDrivenFirst;
MNormSpon=nanmean(NormSpon');
%----------Counts number of clicks--------------------------
ClickCount=length(WinSpikes)-sum(isnan(WinSpikes'));
%-------------------------------Response Normalized by first response--------------------
figure;
NormStdErr=StdNormResp./sqrt(ClickCount);
rates=1000./isi;%convert intervals to seconds
errorbar(rates(1:length(rates)),MeanNormResp,NormStdErr,NormStdErr);
hold on;
axis([0,max(1000./isi)+1, 0,1.2]);
text(50,.9,['1st Tone (Spike Rate- Hz): ',num2str(MeanDrivenFirst)]); 
text(50,.8,['PVal: <.001']),plot(130,.8,'r*'); 
text(50,.7,['PVal: <.01']),plot(130,.7,'gd'); 
text(50,.6,['PVal: <.05']),plot(130,.6,'bp'); 
xlabel('Repetition Rate (Hz)','fontsize',14);
title(fname,'fontsize',14);
ylabel('Norm. Spike Count (Sp/Stimulus)','fontsize',14);
title(fname);
plot(rates(1:length(rates))',MNormSpon*ones(1,length(rates)),'--k');
rates=rates(1:length(rates));
PVal=[];
%---------- Paired (1:length(data)ttest----------------------
if mean(Spon)==0
else
    Ints=isi;
    for  i=1:NStim
        RawRate=NormResp(:,i);
        try
            [h,sig,ci] = ttest(RawRate,MNormSpon,.001,1);
        catch
            disp('0 found')
            h=0; sig=.99; ci=10;PVal(i)=1;
        end
        if sig<.001
            PVal(i)=sig; plot(1000/isi(i),.02,'r*');
        elseif sig<.01
            PVal(i)=sig; plot(1000/isi(i),.02,'gd');
        elseif sig<.05;
            PVal(i)=sig; plot(1000/isi(i),0.02,'bp');
        else
            PVal(i)=sig;
        end
    end
end

try
    CutOff=fix(1000/isi(min(find(PVal<.05))));
    CutOff=CutOff(1);
catch
    CutOff=0;
end

%--------------Allows user to change Cutoff-------------------
plot(CutOff,MNormSpon(1),'rh');
Keep=questdlg('Keep Cutoff ? ');
if strcmp(Keep,'No')
    disp('Select Cutoff');
    [x,y]=ginput(1);
    CutOff=x;
    plot(CutOff,MNormSpon(1),'kp');
end
text(50,.5,['Cutoff: ', num2str(CutOff), ' Hz']),plot(130,.5,'rh'); 
dot=find(fname=='.');
saveas(gcf,['RRTF', fname(1:dot-1)],'tif');
%-----------------------------------Driven?---------
Driven=questdlg('Is this Cell Driven ?');

%----------------------------------Latency Measures--------------------
 scrsz = get(0,'ScreenSize');
 SpHist=[];
%----------------Calculates Spontaneous level
 for i=7:length(rates)
    [N,X]=hist(Latency(i).Spikes,10*round(win*1.5));
    [N]=Data_Smooth(N,25);%Uses a moving window to smooth the data 
    SpHist=horzcat(SpHist,N(1:50));
end
%-------------------Find Latency, Peak Value and Time, End of Peak------
for i=1:length(rates)%finds latency
    [N,X]=hist(Latency(i).Spikes,10*round(win*1.5));
    [N]=Data_Smooth(N,25);%Uses a moving window to smooth the data    
    AllN(i,1:length(N))=N/Latency(i).NumClicks;
    Binms=[0:.1:round(win*1.5)-.1];
    figure('Position',[25 scrsz(4)/10 scrsz(3)/3 scrsz(4)/3]);
    plot(Binms,N);hold on;
    [H,P,CI,STATS] = ttest(N(1:60),2,.001,-1);
    plot([0,25],[CI(2),CI(2)],'r');
    Keep='No';
    if i<8|strcmp(Driven,'No')
        Latency(i).Time_ms=nan; PeakVal=nan;PeakTime=nan;
        Latency(i).PeakVal=nan; Latency(i).PeakTime_ms=nan;
        Latency(i).EndTime_ms=nan; Late=nan;
        EndLate=nan; Latency(i).Rate=nan; Sig=nan;
        Keep='Yes';
    else
    %------------AutoDetect Histogram Measures-------------------
        try
            Thresh=CI(2)*1.1;
            StatSigInd=find((N)>Thresh);% Finds sig responses
            %Looks at on Sig bins greater than 5 ms.
            PossSigInd=StatSigInd(find(StatSigInd>40));
            Late=(min(PossSigInd))/10;
            EndLate=(max(StatSigInd))/10;
            Peak=max(N(StatSigInd)); PeakVal=Peak(1);
            PeakTime=find(N==Peak)/10; PeakTime=PeakTime(1);
            plot(Late,Thresh,'r*'); plot(PeakTime,Peak,'r*'); plot(EndLate,Thresh,'r*');
            Keep=questdlg('Keep these measures?');
            Latency(i).Time_ms=Late; Latency(i).PeakVal=Peak/Latency(i).NumClicks; Latency(i).PeakTime_ms=PeakTime;
            Latency(i).EndTime_ms=EndLate; Latency(i).Rate=sum(N(Late*10:Late*10+100));
            Rate=Latency(i).Rate,
        catch
            Keep='No';    
        end
      
    %-------------------------------
    end
    if strcmp(Keep,'No')
        Sig=CI(2);
        x=[];;y=[];
        [x,y]=ginput(3);
        figure('Position',[25 scrsz(4)/10 scrsz(3)/3 scrsz(4)/3]);
        plot(Binms,N);hold on;
        [H,P,CI,STATS] = ttest(N(1:60),2,.001,-1);
        plot([0,25],[CI(2)*1.1,CI(2)*1.1],'r');
        plot(x(1),y(1),'r*'); plot(x(2),y(2),'r*'); plot(x(3),y(3),'r*');
        pause(2);
        close all;
        Latency(i).Time_ms=x(1);
        PeakVal=y(2);PeakTime=x(2);
        Latency(i).PeakVal=PeakVal/Latency(i).NumClicks;
        Latency(i).PeakTime_ms=PeakTime;
        Latency(i).EndTime_ms=x(3);
        Late=x(1);
        EndLate=x(3);
        Latency(i).Rate=sum(N(Late*10:Late*10+100));
        Rate=Latency(i).Rate,
        close all;
    end
    if strcmp(Keep,'Cancel')
        Latency(i).Time_ms=nan; PeakVal=nan;PeakTime=nan;
        Latency(i).PeakVal=nan; Latency(i).PeakTime_ms=nan;
        Latency(i).EndTime_ms=nan; Late=nan;
        EndLate=nan; Latency(i).Rate=nan; Sig=nan;
    end
    AllN(i,length(N)+2)=Latency(i).Time_ms;
    AllN(i,length(N)+3)=PeakVal/Latency(i).NumClicks;
    AllN(i,length(N)+4)=Latency(i).PeakTime_ms;
    AllN(i,length(N)+5)=Latency(i).EndTime_ms;    
    
end
Latency(1).MeanLatency=nanmean([Latency(:).Time_ms]);
Latency(1).StdErrLate=nanstd([Latency(:).Time_ms])/sqrt(length([Latency(:).Time_ms]));
Latency(i).MeanPeakVal=nanmean([Latency(:).PeakVal]);
Latency(i).MeanPeakTime=nanmean([Latency(:).PeakTime_ms]);
Latency(i).MeanEndPeak=nanmean([Latency(:).EndTime_ms]);
StdErrLate=Latency(1).StdErrLate;
Latency(i).MeanRate=nanmean([Latency(:).Rate]);

%-------------Plots Latency Data-------------------------------------
figure;
plot(rates',[Latency(:).Time_ms],'*k');
freqCut=rates(min(find([Latency(:).Time_ms]>0)));
if isempty(freqCut) freqCut=250; end
axis([0,freqCut+10,0,25])
xlabel('Repetition Rate (Hz)','fontsize',14);
title(fname,'fontsize',14);
ylabel('Latency (ms)','fontsize',14);
title(fname,'fontsize',14);
dot=find(fname=='.');

saveas(gcf,['Late', fname(1:dot-1)],'tif');
%------------------Plots Peak Val Data-------------------------------------
figure;
plot(rates',[Latency(:).PeakVal],'*k');
if isempty(freqCut) freqCut=250; end
axis([0,freqCut+10,0,1000])
xlabel('Repetition Rate (Hz)','fontsize',14);
title(fname,'fontsize',14);
ylabel('Mean Peak Value (sp/100 us)','fontsize',14);
title(fname,'fontsize',14);
dot=find(fname=='.');

saveas(gcf,['PeakVals', fname(1:dot-1)],'tif');

%------------------Plots Latency Data-------------------------------------
figure;
plot(rates',[Latency(:).PeakTime_ms],'*k');

if isempty(freqCut) freqCut=250; end
axis([0,freqCut+10,0,25])
xlabel('Repetition Rate (Hz)','fontsize',14);
title(fname,'fontsize',14);
ylabel('PeakTime (ms)','fontsize',14);
title(fname,'fontsize',14);
dot=find(fname=='.');

saveas(gcf,['PeakTime', fname(1:dot-1)],'tif');
%------------------Plots Latency Data-------------------------------------
figure;
plot(rates',[Latency(:).EndTime_ms],'*k');
if isempty(freqCut) freqCut=250; end
axis([0,freqCut+10,0,25])
xlabel('Repetition Rate (Hz)','fontsize',14);
title(fname,'fontsize',14);
ylabel('End of Latency (ms)','fontsize',14);
title(fname,'fontsize',14);
dot=find(fname=='.');

saveas(gcf,['EndLate', fname(1:dot-1)],'tif');