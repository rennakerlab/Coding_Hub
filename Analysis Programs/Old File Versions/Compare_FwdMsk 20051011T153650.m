function Compare_FwdMsk

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

spont1 = [];
spont2 = [];
for j = 1:numint
    for k = 1:numsoas
        temp1 = [];
        for i = 1:numfreq
            spont1 = [spont1; mean(mean(fm(1).freq(i).int(j).soa(k).spikerate(:,1:30)))];
            temp1 = [temp1; mean(fm(1).freq(i).int(j).soa(k).spikerate)];
        end
        figure('Position',pos,'Name',['Ch ' num2str(channel) ', Intensity: ' num2str(ints(j)) ' dB, SOA: ' num2str(soas(k)) ' ms']);
        subplot(1,3,1);
        surf(rot90(smoothts(smoothts(temp1')')),'EdgeColor', 'none');
        view(0,90);
        set(gca,'XLim',[1 numfreq],'YLim', [1 length(temp1)]);
        set(gca,'XTick', [2.5:5:numfreq],'XTickLabel', round(freqs(2:5:numfreq)/100)/10);
        %zlim([graphmin graphmax]);
        temp = length(temp1)-1;
        set(gca,'YTick', fliplr([(temp-35):(-50):0]),'YTickLabel',fliplr([0:50:(temp-35)]));
        %set(gca,'CLim',[graphmin graphmax]);
        xlabel('frequency (kHz)','FontWeight','Bold');
        ylabel('time (ms)','FontWeight','Bold');
        line([1 numfreq],[temp-35 temp-35],[10000 10000],'Color','w','LineStyle', ':');
        line([1 numfreq],[temp-35-soas(k) temp-35-soas(k)],[10000 10000],'Color','w','LineStyle', ':');
        line([probenum+0.5 probenum+0.5],[0 temp],[10000 10000],'Color','w','LineStyle', ':');
        title(['Un-Anesthetized'],'FontWeight','Bold','FontSize',12);
        colorbar;
        temp2 = [];
        for i = 1:numfreq
            spont2 = [spont2; mean(mean(fm(2).freq(i).int(j).soa(k).spikerate(:,1:30)))];
            temp2 = [temp2; mean(fm(2).freq(i).int(j).soa(k).spikerate)];
        end
        subplot(1,3,2);
        surf(rot90(smoothts(smoothts(temp2')')),'EdgeColor', 'none');
        view(0,90);
        set(gca,'XLim',[1 numfreq],'YLim', [1 length(temp2)]);
        set(gca,'XTick', [2.5:5:numfreq],'XTickLabel', round(freqs(2:5:numfreq)/100)/10);
        %zlim([graphmin graphmax]);
        temp = length(temp2)-1;
        set(gca,'YTick', fliplr([(temp-35):(-50):0]),'YTickLabel',fliplr([0:50:(temp-35)]));
        %set(gca,'CLim',[graphmin graphmax]);
        xlabel('frequency (kHz)','FontWeight','Bold');
        ylabel('time (ms)','FontWeight','Bold');
        line([1 numfreq],[temp-35 temp-35],[10000 10000],'Color','w','LineStyle', ':');
        line([1 numfreq],[temp-35-soas(k) temp-35-soas(k)],[10000 10000],'Color','w','LineStyle', ':');
        line([probenum+0.5 probenum+0.5],[0 temp],[10000 10000],'Color','w','LineStyle', ':');
        title(['Anesthetized'],'FontWeight','Bold','FontSize',12);
        colorbar;        subplot(1,3,3);
        surf(rot90(smoothts(smoothts((temp2-temp1)')')),'EdgeColor', 'none');
        view(0,90);
        set(gca,'XLim',[1 numfreq],'YLim', [1 length(temp1)]);
        set(gca,'XTick', [2.5:5:numfreq],'XTickLabel', round(freqs(2:5:numfreq)/100)/10);
        %zlim([graphmin graphmax]);
        temp = length(temp1)-1;
        set(gca,'YTick', fliplr([(temp-35):(-50):0]),'YTickLabel',fliplr([0:50:(temp-35)]));
        %set(gca,'CLim',[graphmin graphmax]);
        xlabel('frequency (kHz)','FontWeight','Bold');
        ylabel('time (ms)','FontWeight','Bold');
        line([1 numfreq],[temp-35 temp-35],[10000 10000],'Color','w','LineStyle', ':');
        line([1 numfreq],[temp-35-soas(k) temp-35-soas(k)],[10000 10000],'Color','w','LineStyle', ':');
        line([probenum+0.5 probenum+0.5],[0 temp],[10000 10000],'Color','w','LineStyle', ':');
        title(['Difference'],'FontWeight','Bold','FontSize',12);
        colorbar;
        temp = ['Ch ' num2str(channel) ', Intensity ' num2str(ints(j)) ' dB, SOA ' num2str(soas(k)) ' ms'];
        hgsave(temp);
    end
end
