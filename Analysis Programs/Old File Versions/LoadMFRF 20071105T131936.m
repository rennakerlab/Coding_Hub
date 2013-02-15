function loadMFRF

scrnsize = get(0,'ScreenSize');
pos = [scrnsize(3)/6 scrnsize(4)/6 (scrnsize(3)-2*(scrnsize(3)/4)) (scrnsize(4)-2*(scrnsize(4)/4))];

[File,Path] = uigetfile('*.f32');
disp(File);
File = [Path File];
cd(Path);

data = spikedataf(File);

TrimPercent = 20;

numreps = length(data(1).sweep);

temp = [data(:).stim];
fundfreqs = unique(temp(1,:)');
orders = unique(temp(2,:)');
firsthar = unique(temp(3,:)');

if data(1).sweeplength < 10
    for i = 1:length(data)
        data(i).sweeplength = 1000*data(i).sweeplength;
    end
end
temp = zeros(numreps,data(1).sweeplength);

for i = 1:length(data);
    for j = 1:numreps;
        try;
            temp(j,:) = histc(data(i).sweep(j).spikes,[1:data(i).sweeplength]);
        catch;
            temp(j,:) = zeros(1,data(i).sweeplength);
        end;
    end;
   data(i).spikerate = temp/(0.001);
end;

har(1).mean = [];
har(1).trim = [];
for i = 1:length(data);
    f = find(fundfreqs == data(i).stim(1));
    h = find(firsthar == data(i).stim(3));
    if length(har) < h
        har(h).mean = [];
        har(1).trim = [];
    end
    har(h).mean = [har(h).mean; mean(data(i).spikerate)];
    har(h).trim = [har(h).trim; trimmean(data(i).spikerate,TrimPercent)];
end
upperlimit = -10000;
lowerlimit = 10000;
for i = 1:length(har)
    har(i).smooth = boxsmooth(har(i).mean);
    if max(max(har(i).smooth)) > upperlimit
        upperlimit = max(max(har(i).smooth));
    end
    if min(min(har(i).smooth)) < lowerlimit
        lowerlimit = min(min(har(i).smooth));
    end
end

counter = 5;
for i = 1:length(har)
    if counter > 4
        figure('Position',pos);
        counter = 1;
    end
    subplot(2,2,counter);
    temp = [har(i).smooth; zeros(1,size(har(i).smooth,2))];
    surf(temp,'edgecolor','none');
    view(0,90);
    axis tight;
    caxis([lowerlimit, upperlimit]);
    ylim([1,length(fundfreqs)+1]);
    set(gca,'YTick', [1:3:length(fundfreqs)] + 0.5,'YTickLabel', round(fundfreqs(1:3:length(fundfreqs))/100)/10);
    set(gca,'XTick', [data(1).stim(5) - 50:50:data(1).sweeplength],'XTickLabel',[-50:50:(data(1).sweeplength-35)],'FontWeight','Bold');
    xlabel('Time (ms)','FontWeight','Bold','FontSize',10);
    ylabel(' Fundamental Frequency (Hz)','FontWeight','Bold','FontSize',10);
    line([data(1).stim(5), data(1).stim(5)],get(gca,'ylim'),[10000 10000],'Color','k','LineStyle', '--','LineWidth',2);
    title(['First Harmonic = #' num2str(i)],'FontWeight','Bold','FontSize',12);
    counter = counter + 1;
end