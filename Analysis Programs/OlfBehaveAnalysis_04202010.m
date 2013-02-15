function OlfBehaveStage2
clear all;
close all;
cd(uigetdir);
files = dir('*.smr'); 
NFiles=length(files);
for i=1:NFiles
    
    fid=fopen(files(i).name);
    %Reads in keyboard strokes from channel 31
    Key=SONGetChannel(fid,31);
    Event.Codes=char(Key.markers(:,1));%Pulls out codes corresponding to behavioral performanc and stimulus
    Codes=vertcat(Event.Codes);
    Event.Timing=(Key.timings);
    CodeTime=vertcat(Event.Timing);
    HitTime=[];CRTime=[];FATime=[];MissTime=[];
    Hit=0;Miss=0;FA=0;CR=0;
    ResponseIndicies=find(Codes=='V'|Codes=='C'|Codes=='l'|Codes=='z'|Codes=='x');%Finds all trials with a measured resposne V=Miss, l=Hit, C=False Alarm, z=Correct rejection, x=exit poke

    for j=2:length(ResponseIndicies)
    ResponseTime(j)=CodeTime(ResponseIndicies(j))-CodeTime(ResponseIndicies(j)-1);   
       switch Codes(ResponseIndicies(j))
           case 'V'%Miss
                Miss=Miss+1;
                MissTime(Miss)=ResponseTime(j);
                ResponseCode(j)=4;
           case 'C' %False Alarm
                FA=FA+1;
                FATime(FA)=ResponseTime(j);
                ResponseCode(j)=3;
           case 'l'%Hit
               Hit=Hit+1;
                HitTime(Hit)=ResponseTime(j);
                ResponseCode(j)=1;
           case 'z'%Correct Rejection
               CR=CR+1;
               CRTime(CR)=ResponseTime(j);
               ResponseCode(j)=2;
           case 'x'%Exit poke
               ResponseCode(j)=0;
       end
    end
    if Miss==0
        Miss=1/(2*Hit);
    end
    if Hit==0
        Hit=1/(2*Miss);
    end
    if CR==0
        CR=1/(2*FA);
    end
    if FA==0
        FA=1/(2*CR);
    end
    AllHit(i)=Hit;
    AllMiss(i)=Miss;
    AllFA(i)=FA;
    AllCR(i)=CR;
    All(i).HitTime=HitTime;
    All(i).MissTime=MissTime;
    All(i).FATime=FATime;
    All(i).CRTime=CRTime;
    All(i).Responses=ResponseCode;
end

for i=1:NFiles
    %Plots d-prime and c as a funciton of time (30 trial moving window)
    D=0;C=0;window=50;
    ResponseCode=[All(:).Responses];
    if ResponseCode<100 
        window=25;
    end
    for j=1:length(ResponseCode)-window
        HC=length(find(ResponseCode(j:j+window-1)==1));
        MC=length(find(ResponseCode(j:j+window-1)==4));
        CRC=length(find(ResponseCode(j:j+window-1)==2));
        FAC=length(find(ResponseCode(j:j+window-1)==3));
        if MC==0
            MC=1/(2*HC);
        end
        if HC==0
            HC=1/(2*MC);
        end
        if CRC==0
            CRC=1/(2*FAC);
        end
        if FAC==0
            FAC=1/(2*CRC);
        end
        D(j)=norminv(HC/(HC+MC))-norminv(FAC/(FAC+CRC));
        C(j)=(norminv(HC/(HC+MC))+norminv(FAC/(FAC+CRC)))/2;
        
    end
end

%Sensitivity, Bias and Percent Correct Functions
for A1=1:NFiles
    DPrime(A1)=norminv(AllHit(A1)/(AllHit(A1)+AllMiss(A1)))-norminv(AllFA(A1)/(AllFA(A1)+AllCR(A1)));
    Bias(A1)=((norminv(AllHit(A1)/(AllHit(A1)+AllMiss(A1)))+norminv(AllFA(A1)/(AllFA(A1)+AllCR(A1))))/2);%/DPrime(A1);
    PC(A1)=100*((AllHit(A1)+AllCR(A1))/(AllHit(A1)+AllCR(A1)+AllFA(A1)+AllMiss(A1)));
    CSPlusPC(A1)=100*(AllHit(A1)/(AllHit(A1)+AllMiss(A1)));
    CSMinusPC(A1)=100*(AllCR(A1)/(AllCR(A1)+AllFA(A1)));
end

%If you have any hit rates of 1.0 or false alarm rates of 0, you need to do a standard correction. 
%Let's say that N is the maximum number of false alarms 
%Not counting zero, the smallest false alarm rate you have is 1/N. 
%If you have a measured false alarm rate of 0, you know that the true false alarm rate falls somewhere between 0 and 1/N, 
%so the usual strategy is to just use 1/(2N) instead of zero . 
%The same reasoning applies to a hit rate of 1.0. 
%Instead of using 1.0, use 1 - 1/(2N), where N is now the number of targets.

%Plotting Functions
odor = cd;
odor = odor(findstr(cd,'Odor'):findstr(cd,'Odor')+5);
NameInd=findstr(files(1).name,'_');
FigName=files(1).name(1:NameInd-1);

disp(odor);
disp(DPrime);
disp(PC);
a = figure(1);
set(a,'position',[18,373,1229,441])
Name=files(i).name;

%Plots moving window of D' and C for all sessions selected
subplot(2,3,5);
plot([1:length(D)],D,'.k');
hold on;
plot([1:length(C)],C,'*r');
title([Name,'MoveWin DPrime, CPrime_',num2str(window),'_ms']);
hold on;
line(get(gca,'xlim'),[1.96, 1.96],'color','r','linestyle','--');
xlabel('MovingWindow');
saveas(gcf,[Name,'Dprime'],'fig');

%Plots D' for all sessions
subplot(2,3,1);
bar([1:length(DPrime)],DPrime);
title([FigName,' D-Prime: ' odor]);
hold on;
line(get(gca,'xlim'),[1.96, 1.96],'color','r','linestyle','--');
% set(gca,'xlim',[0.5,20.5]);
xlabel('Day');
% saveas(gcf,[FigName,'D-Prime_Stage2'],'fig');

%Plots C for all sessions;
subplot(2,3,2);
bar([1:length(Bias)],Bias);
title([FigName,'Bias: C']);
  set(gca,'ylim',[-1,1]);
xlabel('Day');
saveas(gcf,[FigName,'Bias_Stage2'],'fig');

%Plots Percent Correct for all sessions;
subplot(2,3,3);
bar([1:length(PC)],PC);
title([FigName,'% Correct: ' odor]);
hold on;
line(get(gca,'xlim'),[80, 80],'color','r','linestyle','--');
set(gca,'ylim',[10,110]);
xlabel('Day');
saveas(gcf,[FigName,'_PC_Stage2_' odor],'bmp');

%Plots CS+ Percent Correct for all Sessions
subplot(2,3,4);
bar([1:length(CSPlusPC)],CSPlusPC);
title([FigName,'CS+ % Correct: ' odor]);
hold on;
line(get(gca,'xlim'),[80, 80],'color','r','linestyle','--');
set(gca,'ylim',[10,110]);
xlabel('Day');
saveas(gcf,[FigName,'_CSPlusPC_' odor],'bmp');

%Plots CS- Percent Correct for all Sessions
subplot(2,3,6);
bar([1:length(CSMinusPC)],CSMinusPC);
title([FigName,'CS- % Correct: ' odor]);
hold on;
line(get(gca,'xlim'),[80, 80],'color','r','linestyle','--');
set(gca,'ylim',[10,110]);
xlabel('Day');
saveas(gcf,[FigName,'_CSMinusPC_' odor],'bmp');

