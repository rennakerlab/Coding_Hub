function compareAnesTC

%Load the f32 data file
[file1,path] = uigetfile('*.f32', 'Load the First Tuning Curve.');
cd(path);
temp = [file1(1:3) '*.f32'];
file2 = uigetfile(temp, 'Load the Second Tuning Curve');
file3 = uigetfile(temp, 'Load the Third Tuning Curve');
file4 = uigetfile(temp, 'Load the PostPost IsoTC');

data1 = spikedataf(file1);

numreps = length(data1(1).sweep);
freqs = [];
ints = [];
for i = 1:length(data1);
    if isempty(find(freqs==data1(i).stim(1)));
        freqs = [freqs; data1(i).stim(1)];
    end
    if isempty(find(ints==data1(i).stim(2)));
        ints = [ints; data1(i).stim(2)];
    end
end
numfreq = length(freqs);
numint = length(ints);

for i = 1:length(data1);
    x = find(data1(i).stim(1)==freqs);
    z = find(data1(i).stim(2)==ints);
    temp1 = [];
    for r = 1:numreps;
        try;
            temp2 = histc(data1(i).sweep(r).spikes,[0:1:data1(i).sweeplength]);
        catch;
            temp2 = zeros(1,data1(i).sweeplength + 1);
        end;
        temp1 = [temp1; temp2];
        for y = 1:length(temp2);
            tc(x,y,z,r,1) = temp2(y)/0.001;
        end
    end
    data1(i).spikerate = temp1/0.001;
end

data2 = spikedataf(file2);

for i = 1:length(data2);
    x = find(data2(i).stim(1)==freqs);
    z = find(data2(i).stim(2)==ints);
    temp1 = [];
    for r = 1:numreps;
        try;
            temp2 = histc(data2(i).sweep(r).spikes,[0:1:data2(i).sweeplength]);
        catch;
            temp2 = zeros(1,data2(i).sweeplength + 1);
        end;
        temp1 = [temp1; temp2];
        for y = 1:length(temp2);
            tc(x,y,z,r,2) = temp2(y)/0.001;
        end
    end
    data2(i).spikerate = temp1/0.001;
end

data3 = spikedataf(file3);

for i = 1:length(data3);
    x = find(data3(i).stim(1)==freqs);
    z = find(data3(i).stim(2)==ints);
    temp1 = [];
    for r = 1:numreps;
        try;
            temp2 = histc(data3(i).sweep(r).spikes,[0:1:data3(i).sweeplength]);
        catch;
            temp2 = zeros(1,data3(i).sweeplength + 1);
        end;
        temp1 = [temp1; temp2];
        for y = 1:length(temp2);
            tc(x,y,z,r,3) = temp2(y)/0.001;
        end
    end
    data3(i).spikerate = temp1/0.001;
end

data4 = spikedataf(file4);

numreps = length(data4(1).sweep);
temp = zeros(length(data4(1).sweep),data4(1).sweeplength+1);
for i = 1:numfreq;
    for j = 1:numreps;
        try;
            temp(j,:) = histc(data4(i).sweep(j).spikes,[0:data4(i).sweeplength]);
        catch;
            temp(j,:) = zeros(1,data4(i).sweeplength+1);
        end;
    end;
   data4(i).spikerate = temp/(0.001);
end;
temp = zeros(numfreq,data4(1).sweeplength+1);
for i = 1:numfreq;
    temp(i,:)=mean(data4(i).spikerate);
end;
STRF.Mean = temp;
STRF.Smooth = smoothts(smoothts(STRF.Mean)')';

[a,b,c,d,e] = size(tc);
for i = 1:a
    for j = 1:b
        for k = 1:c
            for n = 1:e
                Ds(i,j,k,n)=mean(tc(i,j,k,1:d,n));
            end
        end
    end
end

for k = 1:c
    Ds(:,:,k,1)=smoothts(smoothts(Ds(:,:,k,1)')');
    Ds(:,:,k,2)=smoothts(smoothts(Ds(:,:,k,2)')');
    Ds(:,:,k,3)=smoothts(smoothts(Ds(:,:,k,3)')');
    graphmax(k) = max(max(max(max(Ds(:,:,k,:)))));
    graphmin(k) = min(min(min(min(Ds(:,:,k,:)))));
end



scrnsize = get(0,'ScreenSize');
pos = [1 scrnsize(4)/16 scrnsize(3) 14*scrnsize(4)/16];
disp('Plotting temporal receptive fields for each intensity...');
%close all;
for i = 1:numint
    h = figure(i);
    set(h,'Position',pos);
    
    %**********************************************************************
    %**********************************************************************
    %PRE VS. ANES *********************************************************
    subplot(4,4,1);
    surf(Ds(:,:,i,1),'EdgeColor', 'none');
    view(0,90);
    set(gca,'XLim',[1 data1(1).sweeplength],'YLim', [1 numfreq]);
    if numfreq<20
        set(gca,'YTick', [1:numfreq],'YTickLabel', round(freqs(2:5:numfreq)/100)/10);
    else
        set(gca,'YTick', [2.5:5:numfreq],'YTickLabel', round(freqs(2:5:numfreq)/100)/10);
    end
    %zlim([graphmin(i) graphmax(i)]);
    %set(gca,'CLim',[graphmin(i) graphmax(i)]);
    ylabel('frequency (kHz)','FontWeight','Bold');
    set(gca,'XTick',[]);
    line([35 35],[1 numfreq],[graphmax(i) graphmax(i)],'Color','w','LineStyle', '--');
    colorbar;
    text(data1(1).sweeplength,numfreq,10000,'Pre ','HorizontalAlignment','right','VerticalAlignment','top','FontWeight','bold','Color','w');
    

    subplot(4,4,2);
    surf(Ds(:,:,i,2),'EdgeColor', 'none');
    view(0,90);
    set(gca,'XLim',[1 data2(1).sweeplength],'YLim', [1 numfreq]);
    %zlim([graphmin(i) graphmax(i)]);
    %set(gca,'CLim',[graphmin(i) graphmax(i)]);
    %ylabel('frequency (Hz)','FontWeight','Bold');
    set(gca,'YTick',[]);
    set(gca,'XTick',[]);
    line([35 35],[1 numfreq],[graphmax(i) graphmax(i)],'Color','w','LineStyle', '--');
    colorbar;
    text(data1(1).sweeplength,numfreq,10000,'Anes ','HorizontalAlignment','right','VerticalAlignment','top','FontWeight','bold','Color','w');
    

    subplot(4,4,3);
    surf(Ds(:,:,i,2)-Ds(:,:,i,1),'EdgeColor', 'none');
    view(0,90);
    set(gca,'XLim',[1 data2(1).sweeplength],'YLim', [1 numfreq]);
    %set(gca,'CLim',[graphmin graphmax]);
    set(gca,'YTick',[]);
    set(gca,'XTick',[]);
    %ylabel('frequency (Hz)','FontWeight','Bold');
    line([35 35],[1 numfreq],[graphmax(i) graphmax(i)],'Color','w','LineStyle', '--');
    colorbar;
    text(data1(1).sweeplength,numfreq,10000,'Diff ','HorizontalAlignment','right','VerticalAlignment','top','FontWeight','bold','Color','w');
    

    
    
    %**********************************************************************
    %**********************************************************************
    %Post VS. ANES ********************************************************
    subplot(4,4,5);
    surf(Ds(:,:,i,3),'EdgeColor', 'none');
    view(0,90);
    set(gca,'XLim',[1 data1(1).sweeplength],'YLim', [1 numfreq]);
    if numfreq<20
        set(gca,'YTick', [1:numfreq],'YTickLabel', round(freqs(2:5:numfreq)/100)/10);
    else
        set(gca,'YTick', [2.5:5:numfreq],'YTickLabel', round(freqs(2:5:numfreq)/100)/10);
    end
    %zlim([graphmin(i) graphmax(i)]);
    %set(gca,'CLim',[graphmin(i) graphmax(i)]);
    ylabel('frequency (kHz)','FontWeight','Bold');
    set(gca,'XTick',[]);
    line([35 35],[1 numfreq],[graphmax(i) graphmax(i)],'Color','w','LineStyle', '--');
    colorbar;
    text(data1(1).sweeplength,numfreq,10000,'Post ','HorizontalAlignment','right','VerticalAlignment','top','FontWeight','bold','Color','w');
    

    subplot(4,4,6);
    surf(Ds(:,:,i,2),'EdgeColor', 'none');
    view(0,90);
    set(gca,'XLim',[1 data2(1).sweeplength],'YLim', [1 numfreq]);
    %zlim([graphmin(i) graphmax(i)]);
    %set(gca,'CLim',[graphmin(i) graphmax(i)]);
    set(gca,'YTick',[]);
    set(gca,'XTick',[]);
    line([35 35],[1 numfreq],[graphmax(i) graphmax(i)],'Color','w','LineStyle', '--');
    colorbar;
    text(data1(1).sweeplength,numfreq,10000,'Anes ','HorizontalAlignment','right','VerticalAlignment','top','FontWeight','bold','Color','w');
    

    subplot(4,4,7);
    surf(Ds(:,:,i,2)-Ds(:,:,i,3),'EdgeColor', 'none');
    view(0,90);
    set(gca,'XLim',[1 data2(1).sweeplength],'YLim', [1 numfreq]);
    %set(gca,'CLim',[graphmin graphmax]);
    set(gca,'YTick',[]);
    set(gca,'XTick',[]);
    line([35 35],[1 numfreq],[graphmax(i) graphmax(i)],'Color','w','LineStyle', '--');
    colorbar;
    text(data1(1).sweeplength,numfreq,10000,'Diff ','HorizontalAlignment','right','VerticalAlignment','top','FontWeight','bold','Color','w');
    
    
    
    
    %**********************************************************************
    %**********************************************************************
    %PRE VS. POST *********************************************************
    subplot(4,4,9);
    surf(Ds(:,:,i,1),'EdgeColor', 'none');
    view(0,90);
    set(gca,'XLim',[1 data1(1).sweeplength],'YLim', [1 numfreq]);
    if numfreq<20
        set(gca,'YTick', [1:numfreq],'YTickLabel', round(freqs(2:5:numfreq)/100)/10);
    else
        set(gca,'YTick', [2.5:5:numfreq],'YTickLabel', round(freqs(2:5:numfreq)/100)/10);
    end
    %zlim([graphmin(i) graphmax(i)]);
    %set(gca,'CLim',[graphmin(i) graphmax(i)]);
    ylabel('frequency (kHz)','FontWeight','Bold');
    xlabel('time (ms)','FontWeight','Bold');
    set(gca,'XTick', [35:50:data2(1).sweeplength],'XTickLabel',[0:50:(data2(1).sweeplength-35)]);
    line([35 35],[1 numfreq],[graphmax(i) graphmax(i)],'Color','w','LineStyle', '--');
    colorbar;
    text(data1(1).sweeplength,numfreq,10000,'Pre ','HorizontalAlignment','right','VerticalAlignment','top','FontWeight','bold','Color','w');
    

    subplot(4,4,10);
    surf(Ds(:,:,i,3),'EdgeColor', 'none');
    view(0,90);
    set(gca,'XLim',[1 data2(1).sweeplength],'YLim', [1 numfreq]);
    %zlim([graphmin(i) graphmax(i)]);
    %set(gca,'CLim',[graphmin(i) graphmax(i)]);
    set(gca,'YTick',[]);
    xlabel('time (ms)','FontWeight','Bold');
    set(gca,'XTick', [35:50:data3(1).sweeplength],'XTickLabel',[0:50:(data3(1).sweeplength-35)]);
    line([35 35],[1 numfreq],[graphmax(i) graphmax(i)],'Color','w','LineStyle', '--');
    colorbar;
    text(data1(1).sweeplength,numfreq,10000,'Post ','HorizontalAlignment','right','VerticalAlignment','top','FontWeight','bold','Color','w');
    

    subplot(4,4,11);
    surf(Ds(:,:,i,3)-Ds(:,:,i,1),'EdgeColor', 'none');
    view(0,90);
    set(gca,'XLim',[1 data2(1).sweeplength],'YLim', [1 numfreq]);
    %set(gca,'CLim',[graphmin graphmax]);
    set(gca,'YTick',[]);
    xlabel('time (ms)','FontWeight','Bold');
    set(gca,'XTick', [35:50:data3(1).sweeplength],'XTickLabel',[0:50:(data3(1).sweeplength-35)]);
    %ylabel('frequency (Hz)','FontWeight','Bold');
    line([35 35],[1 numfreq],[graphmax(i) graphmax(i)],'Color','w','LineStyle', '--');
    colorbar;
    text(data1(1).sweeplength,numfreq,10000,'Diff ','HorizontalAlignment','right','VerticalAlignment','top','FontWeight','bold','Color','w');
    
    
    
    %**********************************************************************
    %**********************************************************************
    %PRE VS. POSTPOST *********************************************************
    subplot(4,4,13);
    surf(Ds(:,:,i,1),'EdgeColor', 'none');
    view(0,90);
    set(gca,'XLim',[1 data1(1).sweeplength],'YLim', [1 numfreq]);
    if numfreq<20
        set(gca,'YTick', [1:numfreq],'YTickLabel', round(freqs(2:5:numfreq)/100)/10);
    else
        set(gca,'YTick', [2.5:5:numfreq],'YTickLabel', round(freqs(2:5:numfreq)/100)/10);
    end
    %zlim([graphmin(i) graphmax(i)]);
    %set(gca,'CLim',[graphmin(i) graphmax(i)]);
    ylabel('frequency (kHz)','FontWeight','Bold');
    xlabel('time (ms)','FontWeight','Bold');
    set(gca,'XTick', [35:50:data2(1).sweeplength],'XTickLabel',[0:50:(data2(1).sweeplength-35)]);
    line([35 35],[1 numfreq],[graphmax(i) graphmax(i)],'Color','w','LineStyle', '--');
    colorbar;
    text(data1(1).sweeplength,numfreq,10000,'Pre ','HorizontalAlignment','right','VerticalAlignment','top','FontWeight','bold','Color','w');
    

    subplot(4,4,14);
    surf(STRF.Smooth,'EdgeColor', 'none');
    view(0,90);
    set(gca,'XLim',[1 data2(1).sweeplength],'YLim', [1 numfreq]);
    %zlim([graphmin(i) graphmax(i)]);
    %set(gca,'CLim',[graphmin(i) graphmax(i)]);
    set(gca,'YTick',[]);
    xlabel('time (ms)','FontWeight','Bold');
    set(gca,'XTick', [35:50:data3(1).sweeplength],'XTickLabel',[0:50:(data3(1).sweeplength-35)]);
    line([35 35],[1 numfreq],[graphmax(i) graphmax(i)],'Color','w','LineStyle', '--');
    colorbar;
    text(data1(1).sweeplength,numfreq,10000,'48 Hr Post ','HorizontalAlignment','right','VerticalAlignment','top','FontWeight','bold','Color','w');
    

    subplot(4,4,15);
    surf(STRF.Smooth-Ds(:,:,i,1),'EdgeColor', 'none');
    view(0,90);
    set(gca,'XLim',[1 data2(1).sweeplength],'YLim', [1 numfreq]);
    %set(gca,'CLim',[graphmin graphmax]);
    set(gca,'YTick',[]);
    xlabel('time (ms)','FontWeight','Bold');
    set(gca,'XTick', [35:50:data3(1).sweeplength],'XTickLabel',[0:50:(data3(1).sweeplength-35)]);
    %ylabel('frequency (Hz)','FontWeight','Bold');
    line([35 35],[1 numfreq],[graphmax(i) graphmax(i)],'Color','w','LineStyle', '--');
    colorbar;
    text(data1(1).sweeplength,numfreq,10000,'Diff ','HorizontalAlignment','right','VerticalAlignment','top','FontWeight','bold','Color','w');
end


temp = questdlg('Do signficance tests?','Compute:','Yes','No','Yes');
pause(1);
if temp(1) == 'Y'
    testmap = [0 0 1; 1 1 1; 1 0 0];
    [a,b,c,d,e] = size(tc);
    for i = 1:a
        for k = 1:c
            for l = 1:d
                for j = 1:(b-9)
                    for n = 1:e
                        S(i,j,k,l,n)=mean(tc(i,j:(j+9),k,l,n));
                    end
                end
            end
        end
    end
    
    [a,b,c,d,e] = size(S);
    for i = 1:a
        for j = 1:b
            for k = 1:c

                if std([S(i,j,k,1:d,1)]) ~= 0 | std([S(i,j,k,1:d,2)]) ~= 0
                    temp = ttest2([S(i,j,k,1:d,1)],[S(i,j,k,1:d,2)],0.1);
                else
                    temp = 0;
                end
                if temp == 1 & (mean([S(i,j,k,1:d,2)])-mean([S(i,j,k,1:d,1)])) > 0
                    Sig(i,j,k,1) = 1;
                elseif  temp == 1 & (mean([S(i,j,k,1:d,2)])-mean([S(i,j,k,1:d,1)])) < 0
                    Sig(i,j,k,1) = -1;
                else
                    Sig(i,j,k,1) = 0;
                end

                if std([S(i,j,k,1:d,2)]) ~= 0 | std([S(i,j,k,1:d,3)]) ~= 0
                    temp = ttest2([S(i,j,k,1:d,2)],[S(i,j,k,1:d,3)],0.1);
                else
                    temp = 0;
                end
                if temp == 1 & (mean([S(i,j,k,1:d,2)])-mean([S(i,j,k,1:d,3)])) > 0
                    Sig(i,j,k,2) = 1;
                elseif  temp == 1 & (mean([S(i,j,k,1:d,2)])-mean([S(i,j,k,1:d,3)])) < 0
                    Sig(i,j,k,2) = -1;
                else
                    Sig(i,j,k,2) = 0;
                end

                if std([S(i,j,k,1:d,1)]) ~= 0 | std([S(i,j,k,1:d,3)]) ~= 0
                    temp = ttest2([S(i,j,k,1:d,1)],[S(i,j,k,1:d,3)],0.1);
                else
                    temp = 0;
                end
                if temp == 1 & (mean([S(i,j,k,1:d,3)])-mean([S(i,j,k,1:d,1)])) > 0
                    Sig(i,j,k,3) = 1;
                elseif  temp == 1 & (mean([S(i,j,k,1:d,3)])-mean([S(i,j,k,1:d,1)])) < 0
                    Sig(i,j,k,3) = -1;
                else
                    Sig(i,j,k,3) = 0;
                end
            end
        end
    end
    
    temp = [];
    for i = 1:numfreq
        for k = 1:length(data4(i).spikerate);
            temp(i,k,:) = data4(i).spikerate(:,k);
        end
    end
    
    [a,b,c] = size(temp);
    for i = 1:a
        for k = 1:c
            for j = 1:(b-9)
                Iso(i,j,k)=mean(temp(i,j:(j+9),k));
            end
        end
    end
    
    [a,b,c] = size(S);
    for i = 1:a
        for j = 1:b

                if std([S(i,j,8,:,1)]) ~= 0 | std([Iso(i,j,:)]) ~= 0
                    temp = ttest2([S(i,j,8,:,1)],[Iso(i,j,:)],0.05);
                else
                    temp = 0;
                end
                if temp == 1 & (mean([Iso(i,j,:)])-mean([S(i,j,8,:,1)])) > 0
                    Sig(i,j,1,4) = 1;
                elseif  temp == 1 & (mean([Iso(i,j,:)])-mean([S(i,j,8,:,1)])) < 0
                    Sig(i,j,1,4) = -1;
                else
                    Sig(i,j,1,4) = 0;
                end

            end
        end
    end
    
    for i = 1:numint
        h = figure(i);
        set(h,'Position',pos);

        %**********************************************************************
        %**********************************************************************
        %PRE VS. ANES *********************************************************
        subplot(4,4,4);
        surf(Sig(:,:,i,1),'EdgeColor', 'none');
        view(0,90);
        set(gca,'XLim',[1 length(S)],'YLim', [1 numfreq]);
        set(gca,'YTick',[]);
        set(gca,'CLim',[-1 1]);
        set(gca,'XTick',[]);
        line([35 35],[1 numfreq],[graphmax(i) graphmax(i)],'Color','w','LineStyle', '--');
        %title(['Significant Differences, ' num2str(ints(i)) ' dB'],'FontWeight','Bold','FontSize',10);
        colorbar;
        text(data1(1).sweeplength,numfreq,10000,'Sig ','HorizontalAlignment','right','VerticalAlignment','top','FontWeight','bold','Color','w');
        colormap(testmap);
        



        %**********************************************************************
        %**********************************************************************
        %Post VS. ANES ********************************************************
        subplot(4,4,8);
        surf(Sig(:,:,i,2),'EdgeColor', 'none');
        view(0,90);
        set(gca,'XLim',[1 length(S)],'YLim', [1 numfreq]);
        set(gca,'YTick',[]);
        set(gca,'CLim',[-1 1]);
        set(gca,'XTick',[]);
        line([35 35],[1 numfreq],[graphmax(i) graphmax(i)],'Color','w','LineStyle', '--');
        %title(['Significant Differences, ' num2str(ints(i)) ' dB'],'FontWeight','Bold','FontSize',10);
        colorbar;
        text(data1(1).sweeplength,numfreq,10000,'Sig ','HorizontalAlignment','right','VerticalAlignment','top','FontWeight','bold','Color','w');
        colormap(testmap);
        



        %**********************************************************************
        %**********************************************************************
        %PRE VS. POST *********************************************************
        subplot(4,4,12);
        surf(Sig(:,:,i,3),'EdgeColor', 'none');
        view(0,90);
        set(gca,'XLim',[1 length(S)],'YLim', [1 numfreq]);
        set(gca,'YTick',[]);
        set(gca,'CLim',[-1 1]);
        xlabel('time (ms)','FontWeight','Bold');
        set(gca,'XTick', [35:50:data3(1).sweeplength],'XTickLabel',[0:50:(data3(1).sweeplength-35)]);
        line([35 35],[1 numfreq],[graphmax(i) graphmax(i)],'Color','w','LineStyle', '--');
        %title(['Significant Differences, ' num2str(ints(i)) ' dB'],'FontWeight','Bold','FontSize',10);
        colorbar;
        text(data1(1).sweeplength,numfreq,10000,'Sig ','HorizontalAlignment','right','VerticalAlignment','top','FontWeight','bold','Color','w');
        colormap(testmap);
        
        
        %**********************************************************************
        %**********************************************************************
        %PRE VS. POST *********************************************************
        subplot(4,4,16);
        surf(Sig(:,:,1,4),'EdgeColor', 'none');
        view(0,90);
        set(gca,'XLim',[1 length(S)],'YLim', [1 numfreq]);
        set(gca,'YTick',[]);
        set(gca,'CLim',[-1 1]);
        xlabel('time (ms)','FontWeight','Bold');
        set(gca,'XTick', [35:50:data3(1).sweeplength],'XTickLabel',[0:50:(data3(1).sweeplength-35)]);
        line([35 35],[1 numfreq],[graphmax(i) graphmax(i)],'Color','w','LineStyle', '--');
        %title(['Significant Differences, ' num2str(ints(i)) ' dB'],'FontWeight','Bold','FontSize',10);
        colorbar;
        text(data1(1).sweeplength,numfreq,10000,'Sig ','HorizontalAlignment','right','VerticalAlignment','top','FontWeight','bold','Color','w');
        colormap(testmap);
        
    end
end


figure;
%**********************************************************************
%**********************************************************************
%PRE ******************************************************************
subplot(4,3,1);
temp1 = [];
temp2 = [];
error1 = [];
error2 = [];
for i = 1:20;
    temp = [];
    for j = 1:10
        temp = [temp; mean(tc(i,45:60,8,j,1))];
    end
    [h,sig,ci] = ttest(temp);
    error1 = [error1, ci(2) - mean(temp)];
    temp1 = [temp1; mean(temp)];
    temp = [];
    for j = 1:10
        temp = [temp; mean(tc(i,60:80,8,j,1))];
    end
    [h,sig,ci] = ttest(temp);
    error2 = [error2, ci(2) - mean(temp)];
    temp2 = [temp2; mean(temp)];
end
spont = mean(mean(mean(tc(:,1:30,:,1))));
temp1 = temp1 - spont;
temp2 = temp2 - spont;
errorbar(temp1,error1','b');
hold;
a = errorbar(temp2,error2');
set(a,'Color',[0 0.5 0]);
line([0,21],[0,0],'Color','k','LineStyle',':');
xlim([0,21]);
ylabel('Spike Rate (sp/s)','FontWeight','bold','FontSize',10);
% set(gca,'XTick', [2:5:numfreq],'XTickLabel', round(freqs(2:5:numfreq)/100)/10,'FontWeight','bold');
axis tight;
set(gca,'XTick',[],'FontWeight','bold');
a = get(gca,'YLim');
ylim(1.1*a);
title('Window Analysis','FontWeight','bold','FontSize',12);
text(5,450,'Onset','HorizontalAlignment','left','VerticalAlignment','middle','FontWeight','bold','FontSize',10,'Color','b');
line([1,4],[450,450],'Color','b','LineStyle','-');
text(5,325,'Late-Phase','HorizontalAlignment','left','VerticalAlignment','middle','FontWeight','bold','FontSize',10,'Color',[0 0.5 0]);
line([1,4],[325,325],'Color',[0 0.5 0],'LineStyle','-');

subplot(4,3,[2 3]);
surf(Ds(:,:,8,1)-spont,'EdgeColor', 'none');
view(0,90);
set(gca,'XLim',[1 data1(1).sweeplength],'YLim', [1 numfreq],'FontWeight','bold');
if numfreq<20
    set(gca,'YTick', [1:numfreq],'YTickLabel', round(freqs(2:5:numfreq)/100)/10);
else
    set(gca,'YTick', [2.5:5:numfreq],'YTickLabel', round(freqs(2:5:numfreq)/100)/10);
end
ylabel('frequency (kHz)','FontWeight','Bold');
set(gca,'XTick',[]);
line([35 35],[1 numfreq],[10000 10000],'Color','w','LineStyle', '--','LineWidth',2);
line([45 45],[1 numfreq],[10000 10000],'Color',[0.5,0.5,1],'LineStyle', '--','LineWidth',1.5);
line([60 60],[1 numfreq],[10000 10000],'Color',[0.5,0.5,1],'LineStyle', '--','LineWidth',1.5);
line([61 61],[1 numfreq],[10000 10000],'Color','g','LineStyle', '--','LineWidth',1.5);
line([80 80],[1 numfreq],[10000 10000],'Color','g','LineStyle', '--','LineWidth',1.5);
text(data1(1).sweeplength,numfreq,10000,'Pre ','HorizontalAlignment','right','VerticalAlignment','top','FontWeight','bold','Color','w','FontSize',16);
title('Temporal Analysis','FontWeight','bold','FontSize',12);
a = colorbar;
set(a,'FontWeight','bold');
y = get(a,'YTick');
temp = {};
for i = 1:length(y);
    temp(i) = mat2cell([' ' num2str(y(i))]);
end
set(a,'YTickLabel',temp);
colormap('hot');
text(49,2,10000,'Onset \rightarrow','HorizontalAlignment','Right','VerticalAlignment','bottom','FontWeight','bold','FontSize',14,'Color',[0.5,0.5,1]);
text(76,2,10000,'\leftarrow Late-Phase','HorizontalAlignment','Left','VerticalAlignment','bottom','FontWeight','bold','FontSize',14,'Color','g');

%**********************************************************************
%**********************************************************************
%ANES ******************************************************************
subplot(4,3,4);
temp1 = [];
temp2 = [];
error1 = [];
error2 = [];
for i = 1:20;
    temp = [];
    for j = 1:10
        temp = [temp; mean(tc(i,45:60,8,j,2))];
    end
    [h,sig,ci] = ttest(temp);
    error1 = [error1, ci(2) - mean(temp)];
    temp1 = [temp1; mean(temp)];
    temp = [];
    for j = 1:10
        temp = [temp; mean(tc(i,60:80,8,j,2))];
    end
    [h,sig,ci] = ttest(temp);
    error2 = [error2, ci(2) - mean(temp)];
    temp2 = [temp2; mean(temp)];
end
spont = mean(mean(mean(tc(:,1:30,:,1))));
temp1 = temp1 - spont;
temp2 = temp2 - spont;
errorbar(temp1,error1','b');
hold;
a = errorbar(temp2,error2');
set(a,'Color',[0 0.5 0]);
line([0,21],[0,0],'Color','k','LineStyle',':');
xlim([0,21]);
ylabel('Spike Rate (sp/s)','FontWeight','bold','FontSize',10);
% set(gca,'XTick', [2:5:numfreq],'XTickLabel', round(freqs(2:5:numfreq)/100)/10,'FontWeight','bold');
axis tight;
set(gca,'XTick',[],'FontWeight','bold');
a = get(gca,'YLim');
ylim(1.1*a);

subplot(4,3,[5 6]);
surf(Ds(:,:,8,2)-spont,'EdgeColor', 'none');
view(0,90);
set(gca,'XLim',[1 data1(1).sweeplength],'YLim', [1 numfreq],'FontWeight','bold');
if numfreq<20
    set(gca,'YTick', [1:numfreq],'YTickLabel', round(freqs(2:5:numfreq)/100)/10);
else
    set(gca,'YTick', [2.5:5:numfreq],'YTickLabel', round(freqs(2:5:numfreq)/100)/10);
end
ylabel('frequency (kHz)','FontWeight','Bold');
set(gca,'XTick',[]);
line([35 35],[1 numfreq],[10000 10000],'Color','w','LineStyle', '--','LineWidth',1.5);
line([45 45],[1 numfreq],[10000 10000],'Color',[0.5,0.5,1],'LineStyle', '--','LineWidth',1.5);
line([60 60],[1 numfreq],[10000 10000],'Color',[0.5,0.5,1],'LineStyle', '--','LineWidth',1.5);
line([61 61],[1 numfreq],[10000 10000],'Color','g','LineStyle', '--','LineWidth',1.5);
line([80 80],[1 numfreq],[10000 10000],'Color','g','LineStyle', '--','LineWidth',1.5);
text(data1(1).sweeplength,numfreq,10000,'Anes ','HorizontalAlignment','right','VerticalAlignment','top','FontWeight','bold','Color','w','FontSize',16);
a = colorbar;
set(a,'FontWeight','bold');
y = get(a,'YTick');
temp = {};
for i = 1:length(y);
    temp(i) = mat2cell([' ' num2str(y(i))]);
end
set(a,'YTickLabel',temp);
colormap('hot');


%**********************************************************************
%**********************************************************************
%POST *****************************************************************
subplot(4,3,7);
temp1 = [];
temp2 = [];
error1 = [];
error2 = [];
for i = 1:20;
    temp = [];
    for j = 1:10
        temp = [temp; mean(tc(i,45:60,8,j,3))];
    end
    [h,sig,ci] = ttest(temp);
    error1 = [error1, ci(2) - mean(temp)];
    temp1 = [temp1; mean(temp)];
    temp = [];
    for j = 1:10
        temp = [temp; mean(tc(i,60:80,8,j,3))];
    end
    [h,sig,ci] = ttest(temp);
    error2 = [error2, ci(2) - mean(temp)];
    temp2 = [temp2; mean(temp)];
end
spont = mean(mean(mean(tc(:,1:30,:,1))));
temp1 = temp1 - spont;
temp2 = temp2 - spont;
errorbar(temp1,error1','b');
hold;
a = errorbar(temp2,error2');
set(a,'Color',[0 0.5 0]);
line([0,21],[0,0],'Color','k','LineStyle',':');
xlim([0,21]);
ylabel('Spike Rate (sp/s)','FontWeight','bold','FontSize',10);
set(gca,'XTick',[],'FontWeight','bold');
axis tight;
a = get(gca,'YLim');
ylim(1.1*a);

subplot(4,3,[8 9]);
surf(Ds(:,:,8,3)-spont,'EdgeColor', 'none');
view(0,90);
set(gca,'XLim',[1 data1(1).sweeplength],'YLim', [1 numfreq],'FontWeight','bold');
if numfreq<20
    set(gca,'YTick', [1:numfreq],'YTickLabel', round(freqs(2:5:numfreq)/100)/10);
else
    set(gca,'YTick', [2.5:5:numfreq],'YTickLabel', round(freqs(2:5:numfreq)/100)/10);
end
ylabel('frequency (kHz)','FontWeight','Bold');
set(gca,'XTick',[]);
line([35 35],[1 numfreq],[10000 10000],'Color','w','LineStyle', '--','LineWidth',2);
line([45 45],[1 numfreq],[10000 10000],'Color',[0.5,0.5,1],'LineStyle', '--','LineWidth',1.5);
line([60 60],[1 numfreq],[10000 10000],'Color',[0.5,0.5,1],'LineStyle', '--','LineWidth',1.5);
line([61 61],[1 numfreq],[10000 10000],'Color','g','LineStyle', '--','LineWidth',1.5);
line([80 80],[1 numfreq],[10000 10000],'Color','g','LineStyle', '--','LineWidth',1.5);
text(data1(1).sweeplength,numfreq,10000,'4 Hr Post ','HorizontalAlignment','right','VerticalAlignment','top','FontWeight','bold','Color','w','FontSize',16);
a = colorbar;
set(a,'FontWeight','bold');
y = get(a,'YTick');
temp = {};
for i = 1:length(y);
    temp(i) = mat2cell([' ' num2str(y(i))]);
end
set(a,'YTickLabel',temp);
colormap('hot');



%**********************************************************************
%**********************************************************************
%POSTPOST *************************************************************
subplot(4,3,10);
temp1 = [];
temp2 = [];
error1 = [];
error2 = [];
spont = [];
for i = 1:20;
    [h,sig,ci] = ttest(mean(data4(i).spikerate(:,45:60)')');
    error1 = [error1, ci(2) - mean(mean(data4(i).spikerate(:,45:60)')')];
    temp1 = [temp1; mean(mean(data4(i).spikerate(:,45:60)')')];
    [h,sig,ci] = ttest(mean(data4(i).spikerate(:,60:80)')');
    error2 = [error2, ci(2) - mean(mean(data4(i).spikerate(:,60:80)')')];
    temp2 = [temp2; mean(mean(data4(i).spikerate(:,60:80)')')];
    spont = [spont; mean(mean(data4(i).spikerate(:,1:30)))];
end
spont = mean(spont);
temp1 = temp1 - spont;
temp2 = temp2 - spont;
errorbar(temp1,error1','b');
hold;
a = errorbar(temp2,error2');
set(a,'Color',[0 0.5 0]);
line([0,21],[0,0],'Color','k','LineStyle',':');
xlim([0,21]);
ylabel('Spike Rate (sp/s)','FontWeight','bold','FontSize',10);
xlabel('Frequency (kHz)','FontWeight','bold','FontSize',10);
set(gca,'XTick', [2:5:numfreq],'XTickLabel', round(freqs(2:5:numfreq)/100)/10,'FontWeight','bold');
axis tight;
a = get(gca,'YLim');
ylim(1.1*a);

subplot(4,3,[11 12]);
surf(STRF.Smooth-spont,'EdgeColor', 'none');
view(0,90);
set(gca,'XLim',[1 data1(1).sweeplength],'YLim', [1 numfreq],'FontWeight','bold');
if numfreq<20
    set(gca,'YTick', [1:numfreq],'YTickLabel', round(freqs(2:5:numfreq)/100)/10);
else
    set(gca,'YTick', [2.5:5:numfreq],'YTickLabel', round(freqs(2:5:numfreq)/100)/10);
end
ylabel('frequency (kHz)','FontWeight','Bold');
xlabel('Time (ms)','FontWeight','bold','FontSize',10);
set(gca,'XTick', [35:50:data3(1).sweeplength],'XTickLabel',[0:50:(data3(1).sweeplength-35)]);
line([35 35],[1 numfreq],[10000 10000],'Color','w','LineStyle', '--','LineWidth',1.5);
line([45 45],[1 numfreq],[10000 10000],'Color',[0.5,0.5,1],'LineStyle', '--','LineWidth',1.5);
line([60 60],[1 numfreq],[10000 10000],'Color',[0.5,0.5,1],'LineStyle', '--','LineWidth',1.5);
line([61 61],[1 numfreq],[10000 10000],'Color','g','LineStyle', '--','LineWidth',1.5);
line([80 80],[1 numfreq],[10000 10000],'Color','g','LineStyle', '--','LineWidth',1.5);
text(data1(1).sweeplength,numfreq,10000,'48 Hr Post ','HorizontalAlignment','right','VerticalAlignment','top','FontWeight','bold','Color','w','FontSize',16);
a = colorbar;
set(a,'FontWeight','bold');
y = get(a,'YTick');
temp = {};
for i = 1:length(y);
    temp(i) = mat2cell([' ' num2str(y(i))]);
end
set(a,'YTickLabel',temp);
colormap('hot');
text(33,5,10000,'Tone \rightarrow','HorizontalAlignment','Right','VerticalAlignment','bottom','FontWeight','bold','FontSize',12,'Color','w');
text(33,2,10000,'Start     ','HorizontalAlignment','Right','VerticalAlignment','bottom','FontWeight','bold','FontSize',12,'Color','w');