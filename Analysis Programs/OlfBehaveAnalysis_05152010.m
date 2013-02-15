function OlfBehaveAnalysis_05152010
close all;
fclose('all');
clear all;
cd(uigetdir);
files = dir('*.smr'); 
NFiles=length(files);
for i=1:NFiles
    %% Initialize Variables
    fid = fopen(files(i).name);
    k = 0;NVCI=[];
    
    %Reads in keyboard strokes from channel 31
    Key = SONGetChannel(fid,31);
    EventTimes = (Key.timings);%Pulls out times for each event
    Codes = char(Key.markers(:,1));%Pulls out codes corresponding to behavioral performanc and stimulus
    TrialInd = find(Codes=='V'|Codes=='C'|Codes=='l'|Codes=='z');%Finds all trials with a measured resposne V=Miss, l=Hit, C=False Alarm, z=Correct rejection
    OdorInd = find(Codes=='1'|Codes=='2'|Codes=='3'|Codes=='4'|Codes=='5');%Finds all odor presentations
    VCI = intersect(TrialInd-2,OdorInd)+2;
    OdorIndicies = VCI-2;%List of odors indicies on valid trials

  %Pulls out manual feeding from CSMinus
    %CSMinus = unique(str2num(Codes(VCI(find(Codes(VCI)=='C'|Codes(VCI)=='z'))-2)));%Pulls out CSMinus Odors
    CSMinus = [2,3,4,5];
    %Pulls out manual feeding from CSPlus
    %CSPlus = unique(str2num(Codes(VCI(find(Codes(VCI)=='l'|Codes(VCI)=='V'))-2)));%Pulls out CSPlus Indicies
    CSPlus = 1;
      
    Odors = str2num(Codes(OdorIndicies));
    OdorSet = unique(Odors);
    NOdors = length(OdorSet);
    ResponseIndicies = VCI-1;%Indicies for withdrawl from poke on valid trials.
    Session(i).ResponseTime = EventTimes(ResponseIndicies)-EventTimes(OdorIndicies);%Time from leaving poke to water port for valid trials
    
%%  Count number of events for the CS+
    try% Misses
        NMisses = length(find(Codes(VCI)=='V'));
        if NMisses == 0
            NMisses = 0.005;
        end
    catch
        NMisses = 0.005;
    end
    try% Hits
        NHits = length(find(Codes(VCI) == 'l'));
        if NHits == 0 
            NHits = 0.005;
        end
    catch
        NHits = 0.005;
    end
    Session(i).Odor(CSPlus).Misses = NMisses;
    Session(i).Odor(CSPlus).Hits = NHits;
    Session(i).Odor(CSPlus).FA = 0.005;
    Session(i).Odor(CSPlus).CR = 0.005;
    Session(i).Odor(CSPlus).PC = NHits/(NHits+NMisses);
        
%%  Count number of events for each CS-
    for j = 1:length(CSMinus)
        %% Correct Rejections for Odor 
        NCR = length(find(Codes(VCI)=='z'& Odors==CSMinus(j)));
        if NCR == 0
            NCR = 0.005;
        end
        NFA = length(find(Codes(VCI)=='C'& Odors==CSMinus(j)));
        if NFA == 0
            NFA = 0.005;
        end
        Session(i).Odor(CSMinus(j)).CR = NCR;
        disp(NCR);
        disp(NFA);
        Session(i).Odor(CSMinus(j)).FA = NFA;
        Session(i).Odor(CSMinus(j)).PC = NCR/(NCR+NFA);
        if isempty(Session(i).Odor(CSMinus(j)).PC )
            Session(i).Odor(CSMinus(j)).PC = 0;
        end
    end    
%% Sensitivity, Bias and Percent Correct Functions
    Session(i).DPrime = norminv(Session(i).Odor(CSPlus).Hits /(Session(i).Odor(CSPlus).Hits +Session(i).Odor(CSPlus).Misses ))-norminv(sum([Session(i).Odor(:).FA])/(sum([Session(i).Odor(CSMinus).FA])+sum([Session(i).Odor(CSMinus).CR])));
    Session(i).Bias =  norminv(Session(i).Odor(CSPlus).Hits /(Session(i).Odor(CSPlus).Hits +Session(i).Odor(CSPlus).Misses ))+norminv(sum([Session(i).Odor(:).FA])/(sum([Session(i).Odor(CSMinus).FA])+sum([Session(i).Odor(CSMinus).CR])));
    if isempty(Session(i).Odor(CSPlus).PC)
        Session(i).Odor(CSPlus).PC = 0;
    end
end

%If you have any hit rates of 1.0 or false alarm rates of 0, you need to do a standard correction. 
%Let's say that N is the maximum number of false alarms 
%Not counting zero, the smallest false alarm rate you have is 1/N. 
%If you have a measured false alarm rate of 0, you know that the true false alarm rate falls somewhere between 0 and 1/N, 
%so the usual strategy is to just use 1/(2N) instead of zero . 
%The same reasoning applies to a hit rate of 1.0. 
%Instead of using 1.0, use 1 - 1/(2N), where N is now the number of targets.

%% Plotting Functions
NFigures=5+3;
NRows=ceil(round(NFigures/4));

odor = cd;
odor = odor(findstr(cd,'Odor'):findstr(cd,'Odor')+5);
NameInd=findstr(files(1).name,'_');
FigName=files(1).name(1:NameInd-1);
a = figure(1);
set(a,'position',[50,50,1250,1050])
Name=files(i).name;
NCol=ceil((NOdors+2)/2);

%% Plots D' for all sessions
subplot(4,NRows,1);
bar([1:length([Session(:).DPrime])],[Session(:).DPrime]);
title([FigName,' D-Prime: ' odor]);
hold on;
line(get(gca,'xlim'),[1.96, 1.96],'color','r','linestyle','--');
% set(gca,'xlim',[0.5,20.5]);
xlabel('Day');

%% Plots C for all sessions;
subplot(4,NRows,2);
bar([1:length([Session(:).Bias])],[Session(:).Bias]);
title([FigName,'Bias: C']);
set(gca,'ylim',[-1,1]);
xlabel('Day');

%% Plots Percent Correct for all sessions and Odors;

for i = 1:NFiles
    subplot(4,NRows,i+2);
    bar(100*[Session(i).Odor(:).PC]);
    title([FigName,'% Correct: ' odor,num2str(j)]);
    hold on;
    line(get(gca,'xlim'),[80, 80],'color','r','linestyle','--');
    set(gca,'ylim',[10,110]);
    xlabel('Odor');
end
%saveas(gcf,[FigName,'_PC_Stage2_' odor],'bmp');


%% Plots Percent Correct for all sessions and Odors;

% for i = 1:NOdors
%     subplot(4,NRows,i+2,'title',files(i).name);
%     bar([Session(i).Odor(:).PC]);
%     title([FigName,'% Correct: ' odor,num2str(j)]);
%     hold on;
%     line(get(gca,'xlim'),[80, 80],'color','r','linestyle','--');
%     set(gca,'ylim',[10,110]);
%     xlabel('Odor');
% end
