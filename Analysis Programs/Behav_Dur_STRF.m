function Behav_Dur_STRF

[file path] = uigetfile('*.f32');
channel = file(1:3);
cd(path);
files = dir([channel '*.f32']);

durs = [];
freqs = [];
for f = 1:length(files);
    data = spikedataf(files(f).name);
    for i = 1:length(data)
        freqs = [freqs; data(i).stim(2)];
    end
    freqs = unique(freqs);
    for i = 1:length(data)
        durs = [durs; data(i).stim(7)];
    end
    durs = unique(durs);
end

for i = 1:length(freqs)
    for j = 1:length(durs)
        c(i).d(j).psth = [];
    end
end

for f = 1:length(files)
    data = spikedataf(files(f).name);
    spont_delay = data(1).stim(length(data(1).stim));
    if spont_delay < 1
        spont_delay = 100;
    end
    for i = 1:length(data)
        a = find(data(i).stim(2) == freqs);
        b = find(data(i).stim(7) == durs);
        if isempty(data(i).sweep.spikes)
            n = zeros(1,2200);
        else
            n = 1000*histc(data(i).sweep.spikes,[0:2200]);
        end
        c(a).d(b).psth = [c(a).d(b).psth; n(spont_delay-99:spont_delay+2000)];
    end
end

for i = 1:length(freqs)
    a = figure(i);
    set(gca,'position',[0.05 0.05 0.9 0.9]);
    temp = [boxsmooth(mean(c(i).d(1).psth),20);...
        boxsmooth(mean(c(i).d(2).psth),20);...
        boxsmooth(mean(c(i).d(3).psth),20);...
        boxsmooth(mean(c(i).d(4).psth),20);...
        boxsmooth(mean(c(i).d(5).psth),20)];
    temp = [temp; zeros(1,length(temp))];
    surf(temp,'edgecolor','none');
    view(0,90);
    plot(temp');
    axis tight;
    set(gca,'xtick',[100:300:2100]);
end