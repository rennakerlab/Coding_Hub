function Behav_Dur_LFPRF

[file path] = uigetfile('*.LFP');
channel = file(1:3);
cd(path);
files = dir([channel '*.LFP']);

freqs = [];
durs = [];
for i = 1:length(files);
    data = LFPFileRead(files(i).name);
    freqs = unique([freqs; data.param(2).value']);
    durs = unique([durs; data.param(7).value']);
end

for i = 1:length(freqs)
    for j = 1:length(durs)
        f(i).d(j).lfp = [];
    end
end

for j = 1:length(files)
    data = LFPFileRead(files(j).name);
    for i = 1:length(data.stim)
        a = find(data.param(2).value(i) == freqs);
        b = find(data.param(7).value(i) == durs);
        f(a).d(b).lfp = [f(a).d(b).lfp; data.stim(i).lfp(data.spont_delay-99:data.spont_delay + 2000)];
    end
end

for i = 1:length(freqs)
    figure(i);
    temp = [boxsmooth(trimmean(f(i).d(1).lfp,10),10); boxsmooth(trimmean(f(i).d(5).lfp,10),10)];
    plot(temp');
    axis tight;
    set(gca,'xtick',[100:300:2100]);
end