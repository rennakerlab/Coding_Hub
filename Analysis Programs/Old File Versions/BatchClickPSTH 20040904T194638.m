function [PSTH,Group]=BatchClickPSTH
dd=dir('*.f32');
PSTH=struct([]);
Catch=0;
NClicks=100;
SpDelay=35; 
SR=[];
tdur=2;
win=15;
NFiles=length(dd);
GroupData=zeros(NFiles,55);
for i=1:length(dd)
    fname=dd(i).name;
    data=spikedataf(fname);
    isiindex=find([data(:).stim]>0);%removes zeros from the stim
    isi=[data(isiindex).stim];
    isi=union(isi,isi);
    Bins=data(1).sweeplength%The Bin size for histograms
    NReps=length(data(1).sweep);
    Catch=Catch+1;
    [spikes, NormRRTF,NormStdErr,NormSpon,rates,PVal,RespRatesInit,RespRatesFinal,WinCutOff,Latency,StdErrLate,AllN]=ClickTrain_SyncAnalV4(fname,tdur,win,NClicks,data,SpDelay,isi,isiindex,Bins);
    [data,CutOff,MNonSync1,NonSync2,PValue,Spon]=clickVectorAnalysis_V1(fname,NClicks,data,SpDelay,isi);
    [PSTH,SpDelay,Bins]=ClickTrain_PSTH_V3(data,PSTH,Catch,SpDelay,Bins,isi,isiindex);
    [PSTH]=PSTHZScoreCircularAnal_V1(PSTH,Catch,Bins,isi,NClicks,SpDelay,NReps,fname);
    
    if length(isi)==27
        Rows=2:1:26;
        LastCol=26;
    else
        Rows=1:1:25;
        LastCol=25;
    end
%   Group(Catch).Data(3)=PSTH(Catch).Cutoff;
    Group(Catch).fname=fname;
    Group(Catch).PSTHZCirc=PSTH(Catch).ZCircSig(Rows);
    Group(Catch).NormRRTF=NormRRTF(Rows);
    Group(Catch).StdErr=NormStdErr(Rows);
    Group(Catch).Latency=[Latency(Rows).Time_ms];
    Group(Catch).PeakTime=[Latency(Rows).PeakTime_ms];
    Group(Catch).EndLate=[Latency(Rows).EndTime_ms];
    Group(Catch).PeakVal=[Latency(Rows).PeakVal];
    Group(Catch).Rate=[Latency(Rows).Rate];
    Group(Catch).PValue=PValue(Rows);
    Group(Catch).Data=[WinCutOff,CutOff,PSTH(Catch).Cutoff,Latency(LastCol).Time_ms,Latency(LastCol).PeakTime_ms,Latency(LastCol).EndTime_ms,Latency(LastCol).PeakVal,Latency(LastCol).Rate];
    close all;
end
save RRTF_08192004
 