function Robs_Compare_FwdMsk

close all;

[file1 path] = uigetfile('*.f32');
cd(path);
temp = [file1(1:10) '*.f32'];
files = dir(temp);

channel = str2num(file1(2:3));  %Identify the channel number for this file.

for index = 1:length(files);
    data = spikedataf(files(index).name);
    if index == 1
        numreps = length(data(1).sweep);
        freqs = [];
        ints = [];
        soas = [];
        for i = 1:length(data);
            if isempty(find(freqs==data(i).stim(1)));
                freqs = [freqs; data(i).stim(1)];
            end
            if isempty(find(ints==data(i).stim(2)));
                ints = [ints; data(i).stim(2)];
            end
            if isempty(find(soas==data(i).stim(3)));
                soas = [soas; data(i).stim(3)];
            end
        end
        soas= soas - 35;
        numfreq = length(freqs);
        numint = length(ints);
        numsoas = length(soas);
        temp = find(files(index).name=='_');      %We'll find information in the filename by dividing it up by the '_' characters.                              
        rat = files(index).name((temp(3)+1):(temp(4)-1));                %Pulls out rat's name.
        daycode = str2num(files(index).name((temp(4)+1):(temp(5)-1)));   %Pulls out the daycode.
        probeint = str2num(files(index).name((temp(6)+1):(temp(6)+2)));  %Pulls out the probe intensity.
        if files(1).name(temp(6)-2)=='e';           %Checks to see if the probe number is two-digit, then pulls out the number.
            temp = str2num(files(index).name(temp(6)-1));
        else
            temp = str2num(files(index).name((temp(6)-2):(temp(6)-1)));
        end
        probenum = temp;
        probefreq = freqs(temp);
        for i = 1:numfreq
            for j = 1:numint
                for k = 1:numsoas
                    fm(1).freq(i).int(j).soa(k).spikerate = [];
                end
            end
        end
    end
    for i = 1:length(data);
        temp = [];
        for j = 1:numreps;
            try
                temp(j,:) = histc(data(i).sweep(j).spikes,[0:1:data(i).sweeplength]);
            catch
                temp(j,:) = zeros(1,data(i).sweeplength + 1);
            end;
        end
        a = find(data(i).stim(1)==freqs);
        b = find(data(i).stim(2)==ints);
        c = find((data(i).stim(3)-35)==soas);
        fm(1).freq(a).int(b).soa(c).spikerate = [fm(1).freq(a).int(b).soa(c).spikerate; temp/0.001];
    end
end

temp = [file1(1:10) '*.f32']; 
[file1 path] = uigetfile(temp);
cd(path);
files = dir(temp);

for index = 1:length(files);
    data = spikedataf(files(index).name);
    if index == 1
        for i = 1:numfreq
            for j = 1:numint
                for k = 1:numsoas
                    fm(2).freq(i).int(j).soa(k).spikerate = [];
                end
            end
        end
    end
    for i = 1:length(data);
        temp = [];
        for j = 1:numreps;
            try;
                temp(j,:) = histc(data(i).sweep(j).spikes,[0:1:data(i).sweeplength]);
            catch;
                temp(j,:) = zeros(1,data(i).sweeplength+1);
            end;
        end
        a = find(data(i).stim(1)==freqs);
        b = find(data(i).stim(2)==ints);
        c = find((data(i).stim(3)-35)==soas);
        fm(2).freq(a).int(b).soa(c).spikerate = [fm(2).freq(a).int(b).soa(c).spikerate; temp/0.001];
    end
end

scrnsize = get(0,'ScreenSize');
pos = [scrnsize(3)/20 scrnsize(4)/16 (scrnsize(3)-2*(scrnsize(3)/20)) (scrnsize(4)-2*(scrnsize(4)/16))];

j = numint;
figure('Position',pos);
for k = [1,2,4,5]
    if k < 3
        subplot(4,2,2*(k-1)+1)
    else
        subplot(4,2,2*(k-2)+1)
    end
    temp1 = [];
    spont1 = [];
    for i = 1:numfreq
        spont1 = [spont1; mean(mean(fm(1).freq(i).int(j).soa(k).spikerate(:,1:30)))];
        temp1 = [temp1; mean(fm(1).freq(i).int(j).soa(k).spikerate)];
    end
    temp1 = smoothts(smoothts(temp1')');
    temp1 = temp1(:,1:300);
    surf(temp1,'EdgeColor','none');
    view(0,90);
    set(gca,'YLim',[1 numfreq],'XLim', [1 length(temp1)]);
    set(gca,'YTick', [2.5:5:numfreq],'YTickLabel', round(freqs(2:5:numfreq)/100)/10);
    set(gca,'XTick', [35:50:350],'XTickLabel',[0:50:350],'FontWeight','bold');
    ylabel('Frequency (kHz)','FontWeight','Bold');
    line([35 35],[1 20],[10000 10000],'Color','w','LineStyle', '--','LineWidth',2);
%     colormap('hot');
    graphmax = max(max(temp1(:,1:57)));
    graphmin = min(min(temp1));
    set(gca,'CLim',[graphmin graphmax]);
    line([soas(k)+35 soas(k)+35],[1 20],[10000 10000],'Color','w','LineStyle', '--','LineWidth',2);
    if k > 3
        text(198,1,10000,[num2str(soas(k)) ' ms SOA'],'VerticalAlignment','Bottom','HorizontalAlignment','Right','FontWeight','bold','Color','w');
    else
        text(298,1,10000,[num2str(soas(k)) ' ms SOA'],'VerticalAlignment','Bottom','HorizontalAlignment','Right','FontWeight','bold','Color','w');
    end
    line([0 350],[probenum+0.5 probenum+0.5],[10000 10000],'Color','w','LineStyle', ':','LineWidth',2);
    a = colorbar('FontWeight','bold');
    y = get(a,'YTick');
    temp = {};
    for i = 1:length(y);
        temp(i) = {[' ' num2str(y(i))]};
    end
    set(a,'YTickLabel',temp);

    if k < 3
        subplot(4,2,2*k);
    else
        subplot(4,2,2*(k-1));
    end
    temp1 = [];
    spont1 = [];
    for i = 1:numfreq
        spont1 = [spont1; mean(mean(fm(2).freq(i).int(j).soa(k).spikerate(:,1:30)))];
        temp1 = [temp1; mean(fm(2).freq(i).int(j).soa(k).spikerate)];
    end
    temp1 = smoothts(smoothts(temp1')');
    temp1 = temp1(:,1:300);
    surf(temp1,'EdgeColor','none');
    view(0,90);
    set(gca,'YLim',[1 numfreq],'XLim', [1 length(temp1)]);
    set(gca,'YTick', [2.5:5:numfreq],'YTickLabel', round(freqs(2:5:numfreq)/100)/10);
    set(gca,'XTick', [35:50:350],'XTickLabel',[0:50:350],'FontWeight','bold');
    ylabel('Frequency (kHz)','FontWeight','Bold');
    line([35 35],[1 20],[10000 10000],'Color','w','LineStyle', '--','LineWidth',2);
%     colormap('hot');
    graphmax = max(max(temp1(:,1:57)));
    graphmin = min(min(temp1));
    set(gca,'CLim',[graphmin graphmax]);
    line([soas(k)+35 soas(k)+35],[1 20],[10000 10000],'Color','w','LineStyle', '--','LineWidth',2);
    if k > 3
        text(198,1,10000,[num2str(soas(k)) ' ms SOA'],'VerticalAlignment','Bottom','HorizontalAlignment','Right','FontWeight','bold','Color','w');
    else
        text(298,1,10000,[num2str(soas(k)) ' ms SOA'],'VerticalAlignment','Bottom','HorizontalAlignment','Right','FontWeight','bold','Color','w');
    end
    line([0 350],[probenum+0.5 probenum+0.5],[10000 10000],'Color','w','LineStyle', ':','LineWidth',2);
    a = colorbar('FontWeight','bold');
    y = get(a,'YTick');
    temp = {};
    for i = 1:length(y);
        temp(i) = {[' ' num2str(y(i))]};
    end
    set(a,'YTickLabel',temp);
end
subplot(4,2,7);
xlabel('Time (ms)','FontWeight','Bold');
subplot(4,2,8);
xlabel('Time (ms)','FontWeight','Bold');
subplot(4,2,1);
title(['Un-Anesthetized'],'FontWeight','Bold','FontSize',12);
subplot(4,2,2);
title(['Anesthetized'],'FontWeight','Bold','FontSize',12);