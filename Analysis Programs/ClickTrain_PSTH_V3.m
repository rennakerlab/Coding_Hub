function [PSTH,SpDelay,Bins]=ClickTrain_PSTH_V3(data,PSTH,Catch,SpDelay,Bins,isi,isiindex)
%Created By: Rob Rennaker 6/18/2004 - Modified: 07182004
SponSpikes=[];
%--------------------------------------------------------------------------------------------------------------------%
%----------Spikes is the number of spikes for each presentation----#stimuli x #Repititions x #Tones-------------------
% if length(isi)==27%ignores first and last stimulus due to changes in siggen files.
%     start=2;stop=26;
%     isi=isi(2:26);%Gets rid of isi's from old siggen files
% else
%     start=1;stop=25;
% end
stop=length(isi);
start=1;
Count=0; %Tracks stimulus number %Catch tracks file number
CellSpikes=[];%The total number of spikes for each stimulus for each file
for i=start:stop%Number of stimulus sets
    Count=Count+1;%Advance stimulus set number
   if Catch==1 %Initializes first file else
        AllSpikes=[]; SpikeCount=[];
   else  %Places previous results in common array for group analysis
        AllSpikes=PSTH(Count).AllSpikes; 
        SpikeCount=PSTH(Count).NSpikes;
   end    
   for j=1:length(data(i).sweep)%Number of Sweeps
      Spikes=data(i).sweep(j).spikes';%Places spike times from the current file in Spikes for each stimulus and sweep
      NSpikes=length(Spikes);%Counts total number of spikes
      Spon=Spikes(find((Spikes>0)&(Spikes<SpDelay)));%Counts number of spikes in first 35 ms
      if isempty(Spikes)%NO SPIKES IN THIS SWEEP
          disp('Empty data: ');  Spikes=0; NSpikes=0; Spon=-1;
      end
      AllSpikes=[AllSpikes;Spikes];%Places all spikes in a single structure.
      SpikeCount=[SpikeCount;NSpikes];
      SponSpikes=[SponSpikes;Spon];%Number of SponSpikes for entire file
      CellSpikes=[CellSpikes;Spikes];
  end
  PSTH(Count).AllSpikes=AllSpikes;%Saves all spikes from all files
  PSTH(Count).NSpikes=SpikeCount;%Saves all spike counts from all files
  PSTH(Catch).Stim(Count).CellSpikes=CellSpikes;%Saves all spikes for all files
  PSTH(Catch).Stim(Count).Spon=Spon;%Saves number of spontaneous spikes for each sweep
  CellSpikes=[];%Clear CellSpikes
end
PSTH(Catch).SponSpikes=SponSpikes;
[H,P,CI,Stats]=ttest(PSTH(Catch).SponSpikes,2,.001,0);
PSTH(Catch).SponCI=CI(2);