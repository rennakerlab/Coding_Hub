function OlfBehaveAnalysis_05152010
close all;
fclose('all');
clear all;
cd(uigetdir);
files = dir('*.smr'); 
NFiles=length(files);
NOdors = 5;
CSPlus = 1,
CSMinus = [2,3,4,5];

for i=1:NFiles
    %% Initialize Variables
    fid = fopen(files(i).name);
    k = 0;NVCI=[];
    
    %Reads in keyboard strokes from channel 31
    Key = SONGetChannel(fid,31);
    EventTimes = (Key.timings);%Pulls out times for each event
    Codes = char(Key.markers(:,1))';%Pulls out codes corresponding to behavioral performanc and stimulus
    
    %Finds all possible combinations of
    Session(i).Odor(1).Hit = length(strfind(Codes,'1xl'));%Hit
    Session(i).Odor(1).Miss = length(strfind(Codes,'1xV'));%Miss
    Session(i).Odor(1).NTrials = length(strfind(Codes,'1'));
    Session(i).Odor(1).PC = Session(i).Odor(1).Hit/(Session(i).Odor(1).Hit+Session(i).Odor(1).Miss);
    Session(i).Odor(1).PResp = (Session(i).Odor(1).Miss+Session(i).Odor(1).Hit)/(Session(i).Odor(1).Hit+Session(i).Odor(1).Miss+Session(i).Odor(1).NTrials);
    
    %Finds all Correct Rejections and False Alarms
    Session(i).Odor(2).CR = length(strfind(Codes,'2xz'));
    Session(i).Odor(2).FA = length(strfind(Codes,'2xC'));
    Session(i).Odor(2).NTrials = length(strfind(Codes,'2'));
    Session(i).Odor(2).PC = Session(i).Odor(2).CR/(Session(i).Odor(2).CR+Session(i).Odor(2).FA);
    Session(i).Odor(2).PResp = (Session(i).Odor(2).CR+Session(i).Odor(2).FA)/(Session(i).Odor(2).CR+Session(i).Odor(2).FA+Session(i).Odor(2).NTrials);
    
    Session(i).Odor(3).CR = length(strfind(Codes,'3xz'));
    Session(i).Odor(3).FA = length(strfind(Codes,'3xC'));
    Session(i).Odor(3).NTrials = length(strfind(Codes,'3'));
    Session(i).Odor(3).PC = Session(i).Odor(3).CR/(Session(i).Odor(3).CR+Session(i).Odor(3).FA);
    Session(i).Odor(3).PResp = (Session(i).Odor(3).CR+Session(i).Odor(3).FA)/(Session(i).Odor(3).CR+Session(i).Odor(3).FA+Session(i).Odor(3).NTrials);
    
    Session(i).Odor(4).CR = length(strfind(Codes,'4xz'));
    Session(i).Odor(4).FA = length(strfind(Codes,'4xC'));
    Session(i).Odor(4).NTrials = length(strfind(Codes,'4'));
    Session(i).Odor(4).PC = Session(i).Odor(4).CR/(Session(i).Odor(4).CR+Session(i).Odor(4).FA);
    Session(i).Odor(4).PResp = (Session(i).Odor(4).CR+Session(i).Odor(4).FA)/nansum([Session(i).Odor(4).CR, Session(i).Odor(4).FA, Session(i).Odor(4).NTrials]);
    
    Session(i).Odor(5).CR = length(strfind(Codes,'5xz'));
    Session(i).Odor(5).FA = length(strfind(Codes,'5xC'));
    Session(i).Odor(5).NTrials = length(strfind(Codes,'5'));
    Session(i).Odor(5).PC = Session(i).Odor(5).CR/(Session(i).Odor(5).CR+Session(i).Odor(5).FA);
    Session(i).Odor(5).PResp = (Session(i).Odor(5).CR+Session(i).Odor(5).FA)/(Session(i).Odor(5).CR+Session(i).Odor(5).FA+Session(i).Odor(5).NTrials);
         
%%  Count number of events for each CS-
NFA = nansum([Session(i).Odor(2).FA,Session(i).Odor(3).FA,Session(i).Odor(4).FA,Session(i).Odor(5).FA]);
NCR = nansum([Session(i).Odor(2).CR,Session(i).Odor(3).CR,Session(i).Odor(4).CR,Session(i).Odor(5).CR]);
Session(i).NFA = NFA;
Session(i).NCR = NCR;



%% Sensitivity, Bias and Percent Correct Functions
    Session(i).DPrime = norminv(Session(i).Odor(1).Hit /(Session(i).Odor(1).Hit +Session(i).Odor(1).Miss )) - norminv(NFA/(NFA+NCR));
    Session(i).Bias =  norminv(Session(i).Odor(1).Hit /(Session(i).Odor(1).Hit +Session(i).Odor(1).Miss )) + norminv(NFA/(NFA+NCR));

end

%If you have any hit rates of 1.0 or false alarm rates of 0, you need to do a standard correction. 
%Let's say that N is the maximum number of false alarms 
%Not counting zero, the smallest false alarm rate you have is 1/N. 
%If you have a measured false alarm rate of 0, you know that the true false alarm rate falls somewhere between 0 and 1/N, 
%so the usual strategy is to just use 1/(2N) instead of zero . 
%The same reasoning applies to a hit rate of 1.0. 
%Instead of using 1.0, use 1 - 1/(2N), where N is now the number of targets.

%% Plotting Functions
NFigures=NFiles+3;
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

temp = strfind(files(1).name,'_');
save([files(1).name(1:temp-1),'.mat']);



