function compareTC

%Load the f32 data file
[file1,path] = uigetfile('*.f32', 'Load the First Tuning Curve.');
cd(path);
temp = [file1(1:3) '*.f32'];
file2 = uigetfile(temp, 'Load the Second Tuning Curve');

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

spont1 = [];
for i = 1:length(data1);
    spont1 = [spont1; mean(mean(data1(i).spikerate(:,1:30))')];
end

spont2 = [];
for i = 1:length(data2);
    spont2 = [spont2; mean(mean(data2(i).spikerate(:,1:30))')];
end

[a,b,c,d,e] = size(tc);
for i = 1:a
    for j = 1:b
        for k = 1:c
            for n = 1:e
                Ds(i,j,k,n)=mean(tc(i,j,k,1:d,n));
            end
            if std([tc(i,j,k,1:d,1)]) ~= 0 | std([tc(i,j,k,1:d,2)])
                temp = ttest2([tc(i,j,k,1:d,1)],[tc(i,j,k,1:d,2)],0.1);
            else
                temp = 0;
            end
            if temp == 1 & (mean([tc(i,j,k,1:d,2)])-mean([tc(i,j,k,1:d,1)])) > 0
                Sig(i,j,k) = 1;
            elseif  temp == 1 & (mean([tc(i,j,k,1:d,2)])-mean([tc(i,j,k,1:d,1)])) < 0
                Sig(i,j,k) = -1;
            else
                Sig(i,j,k) = 0;
            end
        end
    end
end

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
            if std([S(i,j,k,1:d,1)]) ~= 0 | std([S(i,j,k,1:d,2)])
                temp = ttest2([S(i,j,k,1:d,1)],[S(i,j,k,1:d,2)],0.1);
            else
                temp = 0;
            end
            if temp == 1 & (mean([S(i,j,k,1:d,2)])-mean([S(i,j,k,1:d,1)])) > 0
                Sig(i,j,k) = 1;
            elseif  temp == 1 & (mean([S(i,j,k,1:d,2)])-mean([S(i,j,k,1:d,1)])) < 0
                Sig(i,j,k) = -1;
            else
                Sig(i,j,k) = 0;
            end
        end
    end
end

for k = 1:c
    Ds(:,:,k,1)=smoothts(smoothts(Ds(:,:,k,1)')');
    Ds(:,:,k,2)=smoothts(smoothts(Ds(:,:,k,2)')');
end

graphmax = max(max(max(max(Ds))));
graphmin = min(min(min(min(Ds))));

scrnsize = get(0,'ScreenSize');
pos = [1 scrnsize(4)/16 scrnsize(3) 14*scrnsize(4)/16];
disp('Plotting temporal receptive fields for each intensity...');
close all;
counter = 3;
for i = 1:numint
    if counter == 3;
        figure('Position',pos);
        counter = 1;
    else
        counter = counter + 1;
    end
    
    subplot(3,4,4*(counter-1)+1);
    temp = Ds(:,:,i,1);
    temp = [temp; zeros(1,length(temp))];
    surf(temp,'EdgeColor', 'none');
    view(0,90);
    set(gca,'XLim',[1 data1(1).sweeplength],'YLim', [1 numfreq]);
    if numfreq<20
        set(gca,'YTick', [1:numfreq],'YTickLabel', round(freqs(2:5:numfreq)/100)/10);
    else
        set(gca,'YTick', [2.5:5:numfreq],'YTickLabel', round(freqs(2:5:numfreq)/100)/10);
    end
    zlim([graphmin graphmax]);
    set(gca,'CLim',[graphmin graphmax]);
    ylabel('frequency (kHz)','FontWeight','Bold');
    if counter == 3
        xlabel('time (ms)','FontWeight','Bold');
        set(gca,'XTick', [35:50:data2(1).sweeplength],'XTickLabel',[0:50:(data2(1).sweeplength-35)]);
    else
        set(gca,'XTick',[]);
    end
    line([35 35],[1 numfreq],[graphmax graphmax],'Color','w','LineStyle', '--');
    [a,b,c,d,e] = size(tc);
	test_data = [];
	for x = 1:a
        rows = [];
        for y = 5:5:b
            obs = [];
            for r = 1:d
                obs = [obs; mean(tc(x,(y-4):y,i,r,1))];
            end
            rows = [rows, obs];
        end
        test_data = [test_data; rows];
	end
	p = anova2(test_data,d,'off');
    title(['TC 1, ' num2str(ints(i)) ' dB, p = ' num2str(round(1000*p(3))/1000)],'FontWeight','Bold','FontSize',10);
    colorbar;
    
    subplot(3,4,4*(counter-1)+2);
    temp = Ds(:,:,i,2);
    temp = [temp; zeros(1,length(temp))];
    surf(temp,'EdgeColor', 'none');
    view(0,90);
    set(gca,'XLim',[1 data2(1).sweeplength],'YLim', [1 numfreq]);
%     if numfreq<20
%         set(gca,'YTick', [1:numfreq],'YTickLabel', round(freqs(2:5:numfreq)/100)/10);
%     else
%         set(gca,'YTick', [2.5:5:numfreq],'YTickLabel', round(freqs(2:5:numfreq)/100)/10);
%     end
    zlim([graphmin graphmax]);
    set(gca,'CLim',[graphmin graphmax]);
    %ylabel('frequency (Hz)','FontWeight','Bold');
    set(gca,'YTick',[]);
    if counter == 3
        xlabel('time (ms)','FontWeight','Bold');
        set(gca,'XTick', [35:50:data2(1).sweeplength],'XTickLabel',[0:50:(data2(1).sweeplength-35)]);
    else
        set(gca,'XTick',[]);
    end
    line([35 35],[1 numfreq],[graphmax graphmax],'Color','w','LineStyle', '--');
    [a,b,c,d,e] = size(tc);
	test_data = [];
	for x = 1:a
        rows = [];
        for y = 5:5:b
            obs = [];
            for r = 1:d
                obs = [obs; mean(tc(x,(y-4):y,i,r,2))];
            end
            rows = [rows, obs];
        end
        test_data = [test_data; rows];
	end
	p = anova2(test_data,d,'off');
    title(['TC 2, ' num2str(ints(i)) ' dB, p = ' num2str(round(1000*p(3))/1000)],'FontWeight','Bold','FontSize',10);
    colorbar;
    
    subplot(3,4,4*(counter-1)+3);
    temp = Ds(:,:,i,2)-Ds(:,:,i,1);
    temp = [temp; zeros(1,length(temp))];
    surf(temp,'EdgeColor', 'none');
    view(0,90);
    set(gca,'XLim',[1 data2(1).sweeplength],'YLim', [1 numfreq]);
%     if numfreq<20
%         set(gca,'YTick', [1:numfreq],'YTickLabel', round(freqs(2:5:numfreq)/100)/10);
%     else
%         set(gca,'YTick', [2.5:5:numfreq],'YTickLabel', round(freqs(2:5:numfreq)/100)/10);
%     end
    %set(gca,'CLim',[graphmin graphmax]);
    set(gca,'YTick',[]);
    if counter == 3
        xlabel('time (ms)','FontWeight','Bold');
        set(gca,'XTick', [35:50:data2(1).sweeplength],'XTickLabel',[0:50:(data2(1).sweeplength-35)]);
    else
        set(gca,'XTick',[]);
    end
    %ylabel('frequency (Hz)','FontWeight','Bold');
    line([35 35],[1 numfreq],[graphmax graphmax],'Color','w','LineStyle', '--');
    [a,b,c,d,e] = size(tc);
	test_data = [];
	for x = 1:a
        rows = [];
        for y = 5:5:b
            obs = [];
            for r = 1:d
                obs = [obs; mean(tc(x,(y-4):y,i,r,2))-mean(tc(x,(y-4):y,i,r,1))];
            end
            rows = [rows, obs];
        end
        test_data = [test_data; rows];
	end
	p = anova2(test_data,d,'off');
    title(['Difference, ' num2str(ints(i)) ' dB, p = ' num2str(round(1000*p(3))/1000)],'FontWeight','Bold','FontSize',10);
    colorbar;
    
    subplot(3,4,4*(counter-1)+4);
    temp = Sig(:,:,i);
    temp = [temp; zeros(1,length(temp))];
    surf(temp,'EdgeColor', 'none');
    view(0,90);
    set(gca,'XLim',[1 length(S)],'YLim', [1 numfreq]);
%     if numfreq<20
%         set(gca,'YTick', [1:numfreq],'YTickLabel', round(freqs(2:5:numfreq)/100)/10);
%     else
%         set(gca,'YTick', [2.5:5:numfreq],'YTickLabel', round(freqs(2:5:numfreq)/100)/10);
%     end
    set(gca,'YTick',[]);
    set(gca,'CLim',[-1 1]);
    if counter == 3
        xlabel('time (ms)','FontWeight','Bold');
        set(gca,'XTick', [35:50:data2(1).sweeplength],'XTickLabel',[0:50:(data2(1).sweeplength-35)]);
    else
        set(gca,'XTick',[]);
    end
%     if counter == 1
%         ylabel('frequency (Hz)','FontWeight','Bold');
%     end
    line([35 35],[1 numfreq],[graphmax graphmax],'Color','w','LineStyle', '--');
	p = anova2(test_data,d,'off');
    title(['Significant Differences, ' num2str(ints(i)) ' dB'],'FontWeight','Bold','FontSize',10);
    colorbar;
end

figure('Position',pos);
[a,b,c,d,e] = size(tc);
subplot(2,2,1);
fig1 = zeros(c,a);
for i = 1:a
    for j = 1:c
        fig1(j,i) = mean(mean(tc(i,44:58,j,:,1)));
    end
end
fig1 = fig1 - mean(spont1);
fig1 = [fig1;zeros(1,a)];
surf(fig1,'EdgeColor','none');
view(0,90);
axis tight;
colorbar;
subplot(2,2,2);
fig2 = zeros(c,a);
for i = 1:a
    for j = 1:c
        fig2(j,i) = mean(mean(tc(i,44:58,j,:,2)));
    end
end
fig2 = fig2 - mean(spont1);
fig2 = [fig2 ;zeros(1,a)];
surf(fig2,'EdgeColor','none');
view(0,90);
axis tight;
colorbar;
subplot(2,2,3);
temp = fig2-fig1;
surf(temp,'EdgeColor','none');
view(0,90);
axis tight;
colorbar;
subplot(2,2,4);
fig1 = fig1/(max(max(fig1)));
fig2 = fig2/(max(max(fig2)));
temp = fig2-fig1;
surf(temp,'EdgeColor','none');
view(0,90);
axis tight;
colorbar;

figure('Position',pos);
[a,b,c,d,e] = size(tc);
subplot(2,2,1);
fig1 = zeros(c,a);
for i = 1:a
    for j = 1:c
        temp = [];
        for k = 1:d
            temp = [temp; mean(tc(i,44:58,j,k,1))];
        end
        temp = temp - mean(spont1);
        [h,sig,ci] = ttest(temp,0,0.05);
        if mean(temp) > 0
            fig1(j,i) = sig;
        else
            fig1(j,i) = -sig;
        end
    end;
end
pplot(fig1);
subplot(2,2,2);
fig2 = zeros(c,a);
for i = 1:a
    for j = 1:c
        temp = [];
        for k = 1:d
            temp = [temp; mean(tc(i,44:58,j,k,2))];
        end
        temp = temp - mean(spont2);
        [h,sig,ci] = ttest(temp,0,0.05);
        if mean(temp) > 0
            fig2(j,i) = sig;
        else
            fig2(j,i) = -sig;
        end
    end;
end
pplot(fig2);
subplot(2,2,3);
fig1 = zeros(c,a);
for i = 1:a
    for j = 1:c
        temp = [];
        for k = 1:d
            temp = [temp; (mean(tc(i,44:58,j,k,2))-mean(spont2))-(mean(tc(i,44:58,j,k,1))-mean(spont1))];
        end
        [h,sig,ci] = ttest(temp,0,0.05);
        if mean(temp) > 0
            fig1(j,i) = sig;
        else
            fig1(j,i) = -sig;
        end
    end;
end
pplot(fig1);
subplot(2,2,4);
fig1 = zeros(c,a);
for i = 1:a
    for j = 1:c
        fig1(j,i) = mean(mean(tc(i,44:58,j,:,1)))-mean(spont1);
    end
end
fig2 = zeros(c,a);
for i = 1:a
    for j = 1:c
        fig2(j,i) = mean(mean(tc(i,44:58,j,:,2)))-mean(spont2);
    end
end
fig3 = zeros(c,a);
for i = 1:a
    for j = 1:c
        temp = [];
        for k = 1:d
            temp = [temp; (mean(tc(i,44:58,j,k,2))-mean(spont2))/(max(max(fig2)))-(mean(tc(i,44:58,j,k,1))-mean(spont1))/(max(max(fig1)))];
        end
        [h,sig,ci] = ttest(temp,0,0.05);
        if mean(temp) > 0
            fig3(j,i) = sig;
        else
            fig3(j,i) = -sig;
        end
    end;
end
pplot(fig3);












figure('Position',pos);
[a,b,c,d,e] = size(tc);
subplot(2,2,1);
fig1 = zeros(c,a);
for i = 1:a
    for j = 1:c
        fig1(j,i) = mean(mean(tc(i,59:92,j,:,1)));
    end
end
fig1 = fig1 - mean(spont1);
fig1 = [fig1;zeros(1,a)];
surf(fig1,'EdgeColor','none');
view(0,90);
axis tight;
colorbar;
subplot(2,2,2);
fig2 = zeros(c,a);
for i = 1:a
    for j = 1:c
        fig2(j,i) = mean(mean(tc(i,59:92,j,:,2)));
    end
end
fig2 = fig2 - mean(spont1);
fig2 = [fig2 ;zeros(1,a)];
surf(fig2,'EdgeColor','none');
view(0,90);
axis tight;
colorbar;
subplot(2,2,3);
temp = fig2-fig1;
surf(temp,'EdgeColor','none');
view(0,90);
axis tight;
colorbar;
subplot(2,2,4);
fig1 = fig1/(max(max(fig1)));
fig2 = fig2/(max(max(fig2)));
temp = fig2-fig1;
surf(temp,'EdgeColor','none');
view(0,90);
axis tight;
colorbar;

figure('Position',pos);
[a,b,c,d,e] = size(tc);
subplot(2,2,1);
fig1 = zeros(c,a);
for i = 1:a
    for j = 1:c
        temp = [];
        for k = 1:d
            temp = [temp; mean(tc(i,59:92,j,k,1))];
        end
        temp = temp - mean(spont1);
        [h,sig,ci] = ttest(temp,0,0.05);
        if mean(temp) > 0
            fig1(j,i) = sig;
        else
            fig1(j,i) = -sig;
        end
    end;
end
pplot(fig1);
subplot(2,2,2);
fig2 = zeros(c,a);
for i = 1:a
    for j = 1:c
        temp = [];
        for k = 1:d
            temp = [temp; mean(tc(i,59:92,j,k,2))];
        end
        temp = temp - mean(spont2);
        [h,sig,ci] = ttest(temp,0,0.05);
        if mean(temp) > 0
            fig2(j,i) = sig;
        else
            fig2(j,i) = -sig;
        end
    end;
end
pplot(fig2);
subplot(2,2,3);
fig1 = zeros(c,a);
for i = 1:a
    for j = 1:c
        temp = [];
        for k = 1:d
            temp = [temp; (mean(tc(i,59:92,j,k,2))-mean(spont2))-(mean(tc(i,59:92,j,k,1))-mean(spont1))];
        end
        [h,sig,ci] = ttest(temp,0,0.05);
        if mean(temp) > 0
            fig1(j,i) = sig;
        else
            fig1(j,i) = -sig;
        end
    end;
end
pplot(fig1);
subplot(2,2,4);
fig1 = zeros(c,a);
for i = 1:a
    for j = 1:c
        fig1(j,i) = mean(mean(tc(i,59:92,j,:,1)))-mean(spont1);
    end
end
fig2 = zeros(c,a);
for i = 1:a
    for j = 1:c
        fig2(j,i) = mean(mean(tc(i,59:92,j,:,2)))-mean(spont2);
    end
end
fig3 = zeros(c,a);
for i = 1:a
    for j = 1:c
        temp = [];
        for k = 1:d
            temp = [temp; (mean(tc(i,59:92,j,k,2))-mean(spont2))/(max(max(fig2)))-(mean(tc(i,59:92,j,k,1))-mean(spont1))/(max(max(fig1)))];
        end
        [h,sig,ci] = ttest(temp,0,0.05);
        if mean(temp) > 0
            fig3(j,i) = sig;
        else
            fig3(j,i) = -sig;
        end
    end;
end
pplot(fig3);