function loadSTRF

scrnsize = get(0,'ScreenSize');
pos = [scrnsize(3)/6 scrnsize(4)/6 (scrnsize(3)-2*(scrnsize(3)/4)) (scrnsize(4)-2*(scrnsize(4)/4))];


[File,Path] = uigetfile('*.f32')
File = [Path File];
cd(Path);

data = spikedataf(File);

TrimPercent = 0.2

numreps = length(data(1).sweep);
numfreq = length([data(:).stim]);
temp = [data(:).stim];
freqs = temp(1,:)';
if data(1).sweeplength < 10
    for i = 1:length(data)
        data(i).sweeplength = 1000*data(i).sweeplength;
    end
end
temp = zeros(length(data(1).sweep),data(1).sweeplength);

for i = 1:numfreq;
    for j = 1:numreps;
        try;
            temp(j,:) = histc(data(i).sweep(j).spikes,[1:data(i).sweeplength]);
        catch;
            temp(j,:) = zeros(1,data(i).sweeplength);
        end;
    end;
   data(i).spikerate = temp/(0.001);
end;

temp = zeros(numfreq,data(1).sweeplength);
for i = 1:numfreq;
    temp(i,:)=mean(data(i).spikerate);
end;
STRF.Mean = temp;
for i = 1:numfreq;
    temp(i,:)=trimmean(data(i).spikerate,TrimPercent);
end;
STRF.Trim = temp;
% for i = 1:numfreq
%     for j = 1:(data(i).sweeplength-4)
%         temp(i,j)=mean(STRF.Mean(i,j:(j+4)));
%     end
% end
% STRF.Smooth = temp;
STRF.Smooth = boxsmooth(STRF.Mean);
STRF.PSTH = mean(STRF.Mean);
for i = 1:numfreq;
    temp(i,:)=std(data(i).spikerate);
end;

STRF.StDev = temp;

%close all;

% temp = STRF.PSTH(1:30)';
% temp = mean(temp)+2*std(temp);
% temp = find(STRF.PSTH>=temp)';
% temp = temp(find(temp>42));
% latency = min(temp)-35

figure('Position',pos);
surf(STRF.Mean,'EdgeColor', 'none');
set(gca,'XLim',[1 data(1).sweeplength],'YLim', [1 numfreq]);
set(gca,'YTick', [1:5:numfreq],'YTickLabel', round(freqs(1:5:numfreq)));
set(gca,'XTick', [10:25:data(1).sweeplength],'XTickLabel',[-25:25:(data(1).sweeplength-35)],'FontWeight','Bold');
xlabel('Time (ms)','FontWeight','Bold','FontSize',14);
ylabel('Frequency (Hz)','FontWeight','Bold','FontSize',14);
line([35 35],[1 numfreq],[10000 10000],'Color','k','LineStyle', '--','LineWidth',2);
%title(['Intensity: ' num2str(ints(i)) ' dB']);
colorbar('FontWeight','Bold');
view(0,90);

figure('Position',pos);
surf(STRF.Smooth,'EdgeColor', 'none');
set(gca,'XLim',[1 data(1).sweeplength],'YLim', [1 numfreq]);
set(gca,'YTick', [1:5:numfreq],'YTickLabel', round(freqs(1:5:numfreq)));
set(gca,'XTick', [10:25:data(1).sweeplength],'XTickLabel',[-25:25:(data(1).sweeplength-35)],'FontWeight','Bold');
xlabel('Time (ms)','FontWeight','Bold','FontSize',14);
ylabel('Frequency (Hz)','FontWeight','Bold','FontSize',14);
line([35 35],[1 numfreq],[10000 10000],'Color','k','LineStyle', '--','LineWidth',2);
title('R-RD: Channel 8','FontWeight','Bold','FontSize',16);
colorbar('FontWeight','Bold');
view(0,90);

figure(3);
bar(STRF.PSTH);

figure(4);
plot(smoothts(STRF.PSTH));
% [latency,y]=ginput(1);
% floor(latency-35)

end