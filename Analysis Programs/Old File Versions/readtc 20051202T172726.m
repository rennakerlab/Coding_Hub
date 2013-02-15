function tc = readTC(file)

%spikedataf.m is a function which will read Brainware f32 data into a data
%structure.  It has fields: sweeplength, stim, and sweep.  Sweeplength is
%the number of milliseconds of recording for each sound.  Stim is the
%parameters of a particualr stimulus, i.e. frequency and intensity.  Sweep
%denotes which repetition that particular data comes from.  
data = spikedataf(file);

%We'll pull the frequencies and intensities of the stimuli out of the
%structure for later use.
numreps = length(data(1).sweep);
freqs = [];
ints = [];
for i = 1:length(data);
    if isempty(find(freqs==data(i).stim(1)));
        freqs = [freqs; data(i).stim(1)];
    end
    if isempty(find(ints==data(i).stim(2)));
        ints = [ints; data(i).stim(2)];
    end
end
numfreq = length(freqs);
numint = length(ints);

%f32 files contain spike times, and we're going to look at spike rates, so
%this loop will calculate histograms of those spike times to create
%Peri-Stimulus Time Histograms (PSTH) for each repetition of each stimulus
for i = 1:length(data);
    x = find(data(i).stim(1)==freqs);
    z = find(data(i).stim(2)==ints);
    temp1 = [];
    for r = 1:numreps;
        try;
            temp2 = histc(data(i).sweep(r).spikes,[0:1:data(i).sweeplength]);
        catch;
            temp2 = zeros(1,data(i).sweeplength+1);
        end;
        temp1 = [temp1; temp2];
        for y = 1:length(temp2);
            tc(x,y,z,r) = temp2(y)/0.001;
        end
    end
    data(i).spikerate = temp1/0.001;
end;

%This loop arranges the data into pseudo-Spectral Temporal Receptive Fields
%(STRFs), which are color plots of the response strength (in spikerate)
%across axes of frequency (Hz) and time (ms).  There is one pseudo-STRF for
%each intensity.
curint = 1;
strf(1).mean = zeros(numfreq,data(1).sweeplength+1);
for i = 1:length(data);
    if data(i).stim(2) ~= ints(curint);
        curint = curint + 1;
        strf(curint).mean = zeros(numfreq,data(1).sweeplength+1);
    end
    strf(curint).mean(i-numfreq*(curint-1),:) = mean(data(i).spikerate);
end

%We want to set the colorscales to the same values on each plot, so we'll
%find the maximum and minimum value of spikerate across all smoothed STRFs.
graphmax = 0;
graphmin = 1000;
for i = 1:numint;
    temp = smoothts(smoothts(strf(i).mean')');
    if max(max(temp)') > graphmax;
        graphmax = max(max(temp)');
    end
    if min(min(temp)') < graphmin;
        graphmin = min(min(temp)');
    end
end

%Here we're creating plots of the smoothed STRF for each intensity.
%Remember that the tones played in a TC (Tuning Curve) experiment vary in
%frequency and intensity, so these plots show use which frequencies each
%neuron or multineuron cluster responds to each intensity, as well as when
%that response happens relative to the start of the stimulus.  The white
%line drawn across the plot marks the stimulus onset, which is also denoted
%on the time scale as time zero.

scrnsize = get(0,'ScreenSize');
pos = [scrnsize(3)/20 scrnsize(4)/16 (scrnsize(3)-2*(scrnsize(3)/20)) (scrnsize(4)-2*(scrnsize(4)/16))];
figure('Position',pos);

%close all;
temp = fix(sqrt(numint))+1;
for i = 1:numint;
    subplot(temp,temp,i);
    surf(smoothts(smoothts(strf(i).mean')'),'EdgeColor', 'none');
    view(0,90);
    set(gca,'XLim',[1 data(1).sweeplength],'YLim', [1 numfreq]);
    if (i-1) == temp*fix(i/temp)
        set(gca,'YTick', [1:fix(numfreq/5):numfreq],'YTickLabel', round(freqs(1:fix(numfreq/5):numfreq)),'FontWeight','Bold');
        ylabel('frequency (Hz)');
    else
        set(gca,'YTickLabel', '','FontWeight','Bold');
    end
    if i+temp > numint
        set(gca,'XTick', [35:50:data(1).sweeplength],'XTickLabel',[0:50:(data(1).sweeplength-35)],'FontWeight','Bold');
        xlabel('time (ms)');
    else
        set(gca,'XTickLabel','');
    end
    set(gca,'CLim',[graphmin graphmax]);
    line([35 35],[1 numfreq],[10000 10000],'Color','w','LineStyle', '--');
    title([num2str(ints(i)) ' dB'],'FontWeight','Bold');
    %colorbar;
end

[a,b,c,d] = size(tc);

for k = 1:c
    d = smoothts(smoothts(strf(k).mean')');
	for i = 1:a
        for j = 1:b
            temp(i,j,k) = d(i,j);
        end
	end
end

graph1 = contourslice(temp,[],[],[1:c],8)
axis tight
            

