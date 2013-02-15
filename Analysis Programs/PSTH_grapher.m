function PSTH_grapher

[file path] = uigetfile('*.f32');
cd(path);

data = spikedataf(file);

psth = [];
for i = 1:length(data)
    for j = 1:length(data(i).sweep)
        psth = [psth; histc(data(i).sweep(j).spikes,[0:1:data(i).sweeplength])];
    end
end
            
bar(sum(psth));

spont = mean(mean(psth(:,1:30)));
spont = mean(psth(:,1:30)')'/0.001;
driven = mean(psth(:,45:65)')'/0.001;
[h,sig,ci] = ttest2(spont,driven,0.001)