function CompareMK801

close all;

%When we get around to doing significance tests, it helps to define alpha
%at the beginning as a variable, so that if we ever want to change the
%significance level of our tests, we only have to change one line of code.
alpha = 0.01;
disp(['alpha = ' num2str(alpha)]);
mwsize = 10;
disp(['Moving Window = ' num2str(mwsize) ' ms']);

%This line keeps the t-test from freaking out when you hand it a column of
%zeros.
warning off MATLAB:divideByZero;

%I like my figures nice and big, so here's a trick that will let us set the
%figure size to about 80% of the screensize.
scrnsize = get(0,'ScreenSize');
pos = [scrnsize(3)/20 scrnsize(4)/16 (scrnsize(3)-2*(scrnsize(3)/20)) (scrnsize(4)-3*(scrnsize(4)/16))];

%We'll use a common dialog box to select which file we'd like to take a
%look at.  We'll also change the current directory to the folder that file
%is in.
[file1 path1] = uigetfile('*.f32');
cd(path1);
temp = file1(1:4);
[file2 path2] = uigetfile([temp, '*.f32']);

%We'll use the "spikedataf.m" function that came with Brainware to read the
%*.f32 file.
data1 = spikedataf([path1 file1]);
data2 = spikedataf([path2 file2]);

%*.f32 files index data according to the number of stimulus parameter
%combinations.  To simplify things, we'll put these values into one big
%matrix, with rows equal to the number of sets.
stimuli1 = [data1(:).stim]';
stimuli2 = [data2(:).stim]';

%It would be nice if this program could open both randomized and
%nonrandomized full tuning curves.  Therefore, we'll first check to see if
%this is a randomized file first, then if it is not, we'll create a set of
%dummy onset times, all set to zero.
[a,b] = size(stimuli1);
if b == 2
    onsets1 = 35*ones(a,1);
    nonrand = 1;
else
    onsets1 = stimuli1(:,3);
    nonrand = 0;
end
[a,b] = size(stimuli2);
if b == 2
    onsets2 = 35*ones(a,1);
    nonrand = 1;
else
    onsets2 = stimuli1(:,3);
    nonrand = 0;
end

%We'll need to have lists of all the possible frequencies and intensities
%included in the tuning curve.
freqs = [];
ints = [];
for i = 1:length(stimuli1)
    if isempty(find(stimuli1(i,1) == freqs))
        freqs = [freqs; stimuli1(i,1)];
    end
    if isempty(find(stimuli1(i,2) == ints))
        ints = [ints; stimuli1(i,2)];
    end
end
for i = 1:length(stimuli2)
    if isempty(find(stimuli2(i,1) == freqs))
        freqs = [freqs; stimuli2(i,1)];
    end
    if isempty(find(stimuli2(i,2) == ints))
        ints = [ints; stimuli2(i,2)];
    end
end

%It will be handy to have variables storing the number of frequencies and
%intensities, and it's better to take these values from the file rather
%than write them in directly, because then you'd have to change your code
%if you change your sound file.
numfreq = length(freqs);
numint = length(ints);

%The onset of each sweep is actually 35 ms before the masker tone starts,
%allowing us 35 ms of "silence" in which to estimate the spontaneous
%activity.  So we'll subtract 35 ms from the masker onsets to find the
%sweep onsets.
onsets1 = onsets1 - 35;
onsets2 = onsets2 - 35;

%Again, it's best not to put in hard numbers for the sweeplength, because
%you might change it, better to pull it out of the data structure.
sweeplength1 = data1(1).sweeplength - max(onsets1);
sweeplength2 = data2(1).sweeplength - max(onsets2);

%We repeat each stimuli combination ten times in a session, but again,
%better to pull it out of the data structure just in case you change it
%either way.
numreps1 = length(data1(1).sweep);
numreps2 = length(data2(1).sweep);

temp = [];
%Now we'll go through each set and sweep and calculate the spikerates by
%performing a histogram on the spike times.
for i = 1:length(data1);
        
    %Each repetition is one sweep, and we'll save the results of each
    %without immediately averaging so that we can run signficance tests
    %later with each repetition counting as a sample.
    for j = 1:numreps1;
        
        %The easiest way to find spikerate is to take the spiketimes
        %from a sweep in the data structure and put them into the
        %"histc" histogram function, set so that the spikes are binned
        %into 1 ms bins.  Sometimes there are no spikes, and the
        %histogram function freaks out, hence the try/catch statment.
        try;
            temp(j,:) = histc(data1(i).sweep(j).spikes,[onsets1(i):(onsets1(i) + sweeplength1)]);
        catch;
            temp(j,:) = zeros(1,sweeplength1 + 1);
        end;

        %Last, we'll multiply the "temp" spike histogram by 1000, since
        %one spike in a 1 ms bin is a spikerate of 100 spikes/s.
        data1(i).spikerate = 1000*temp;
    end;            
end;

temp = [];
%Now we'll go through each set and sweep and calculate the spikerates by
%performing a histogram on the spike times.
for i = 1:length(data2);
        
    %Each repetition is one sweep, and we'll save the results of each
    %without immediately averaging so that we can run signficance tests
    %later with each repetition counting as a sample.
    for j = 1:numreps2;
        
        %The easiest way to find spikerate is to take the spiketimes
        %from a sweep in the data structure and put them into the
        %"histc" histogram function, set so that the spikes are binned
        %into 1 ms bins.  Sometimes there are no spikes, and the
        %histogram function freaks out, hence the try/catch statment.
        try;
            temp(j,:) = histc(data2(i).sweep(j).spikes,[onsets2(i):(onsets2(i) + sweeplength2)]);
        catch;
            temp(j,:) = zeros(1,sweeplength2 + 1);
        end;

        %Last, we'll multiply the "temp" spike histogram by 1000, since
        %one spike in a 1 ms bin is a spikerate of 100 spikes/s.
        data2(i).spikerate = 1000*temp;
    end;            
end;

%This loop arranges the data into pseudo-Spectral Temporal Receptive Fields
%(STRFs), which are color plots of the response strength (in spikerate)
%across axes of frequency (Hz) and time (ms).  There is one pseudo-STRF for
%each intensity.
spont1 = [];
for i = 1:numint
    %We'll start by pulling up the indices of those sets which have the
    %desired intensity.
    a = find(stimuli1(:,2) == ints(i))';
    strf1(i).mean = zeros(numfreq,sweeplength1 + 1);
    for j = a
        b = find(stimuli1(j,1) == freqs);
        strf1(i).mean(b,:) = mean(data1(j).spikerate);
        spont1 = [spont1, mean(data1(j).spikerate(:,1:30)')'];
    end
end
spont1 = mean(spont1')';
spont2 = [];
for i = 1:numint
    %We'll start by pulling up the indices of those sets which have the
    %desired intensity.
    a = find(stimuli2(:,2) == ints(i))';
    strf2(i).mean = zeros(numfreq,sweeplength2 + 1);
    for j = a
        b = find(stimuli2(j,1) == freqs);
        strf2(i).mean(b,:) = mean(data2(j).spikerate);
        spont2 = [spont2, mean(data2(j).spikerate(:,1:30)')'];
    end
end
spont2 = mean(spont2')';
        
%The pseudo-STRFs are very choppy, so to better visualize them, we can
%smooth them with a box smooth.
for i = 1:numint
    strf1(i).smooth = smoothts(strf1(i).mean - mean(spont1),'b',mwsize);
    strf2(i).smooth = smoothts(strf2(i).mean - mean(spont2),'b',mwsize);
end

%We want to set the colorscales to the same values on each plot, so we'll
%find the maximum and minimum value of spikerate across all smoothed STRFs.
graphmax = 0;
graphmin = 1000;
for i = 3:numint;
    if max(max(boxsmooth(strf1(i).smooth,3))) > graphmax;
        graphmax = max(max(boxsmooth(strf1(i).smooth,3)));
    end
    if min(min(boxsmooth(strf1(i).smooth,3))) < graphmin;
        graphmin = min(min(boxsmooth(strf1(i).smooth,3)));
    end
    if max(max(boxsmooth(strf2(i).smooth,3))) > graphmax;
        graphmax = max(max(boxsmooth(strf2(i).smooth,3)));
    end
    if min(min(boxsmooth(strf2(i).smooth,3))) < graphmin;
        graphmin = min(min(boxsmooth(strf2(i).smooth,3)));
    end
end
        
%Here we're creating plots of the smoothed STRF for each intensity.
%Remember that the tones played in a TC (Tuning Curve) experiment vary in
%frequency and intensity, so these plots show use which frequencies each
%neuron or multineuron cluster responds to each intensity, as well as when
%that response happens relative to the start of the stimulus.  The white
%line drawn across the plot marks the stimulus onset, which is also denoted
%on the time scale as time zero.

for i = 1:numint
    
    figure('Position',pos);
    
    %PLOT STRF***********************************************************
    %Here we'll plot a surface plot of the STRF.  This is all straight-up
    %graphing calls, so I won't bother commenting much. The surface function 
    %cuts off the top row of your data when viewed from directly above, so 
    %to see everything you'll need to put in a dummy row of zeros.
%     contourf(strf(i).smooth);
%     [a,b] = size(strf(i).smooth);
    subplot(2,3,1)
    temp = [strf1(i).smooth; zeros(1,length(strf1(i).smooth))];
    surf(boxsmooth(temp,3),'edgecolor','none');
    [a,b] = size(temp);
    xlim([1,b]);
    ylim([1,a]);
    view(0,90);
    set(gca,'YTick', [1:numfreq],'YTickLabel', round(freqs/100)/10,'FontWeight','Bold');
    set(gca,'XTick', [10:25:300],'XTickLabel',[-25:25:(300-35)]);
    %set(gca,'CLim',[graphmin graphmax]);
    xlabel('Time (ms)');
    ylabel('Frequency (kHz)');
    title(['File #1: ' file1(1:3) ': Intensity: ' num2str(ints(i)) ' dB']);
    set(gca,'yminortick', 'on');
    set(gca,'xminortick', 'on');
    set(gca,'YTick', [2:5:numfreq],'YTickLabel', round(freqs(2:5:numfreq)/100)/10,'FontWeight','Bold');
    set(gca,'XTick', [(-15-mwsize/2+1):50:300],'XTickLabel',[-50:50:(300-35)]);
    xlabel('Time (ms)');
    ylabel('Frequency (kHz)');
    line([35-mwsize/2+1, 35-mwsize/2+1],get(gca,'ylim'),[10000 10000],'Color','w','LineStyle', '--','linewidth',2);
    %a = colorbar('southoutside');
    %set(a,'FontWeight','Bold');
    
    subplot(2,3,2)
    temp = [strf2(i).smooth; zeros(1,length(strf2(i).smooth))];
    surf(boxsmooth(temp,3),'edgecolor','none');
    [a,b] = size(temp);
    xlim([1,b]);
    ylim([1,a]);
    view(0,90);
    set(gca,'YTick', [1:numfreq],'YTickLabel', round(freqs/100)/10,'FontWeight','Bold');
    set(gca,'XTick', [10:25:300],'XTickLabel',[-25:25:(300-35)]);
    %set(gca,'CLim',[graphmin graphmax]);
    xlabel('Time (ms)');
    ylabel('Frequency (kHz)');
    title(['File #2: ' file2(1:3) ': Intensity: ' num2str(ints(i)) ' dB']);
    set(gca,'yminortick', 'on');
    set(gca,'xminortick', 'on');
    set(gca,'YTick', [2:5:numfreq],'YTickLabel', round(freqs(2:5:numfreq)/100)/10,'FontWeight','Bold');
    set(gca,'XTick', [(-15-mwsize/2+1):50:300],'XTickLabel',[-50:50:(300-35)]);
    xlabel('Time (ms)');
    ylabel('Frequency (kHz)');
    line([35-mwsize/2+1, 35-mwsize/2+1],get(gca,'ylim'),[10000 10000],'Color','w','LineStyle', '--','linewidth',2);
    
    subplot(2,3,3)
    temp = [strf2(i).smooth - strf1(i).smooth; zeros(1,length(strf1(i).smooth))];
    surf(boxsmooth(temp,3),'edgecolor','none');
    [a,b] = size(temp);
    xlim([1,b]);
    ylim([1,a]);
    view(0,90);
    set(gca,'YTick', [1:numfreq],'YTickLabel', round(freqs/100)/10,'FontWeight','Bold');
    set(gca,'XTick', [10:25:300],'XTickLabel',[-25:25:(300-35)]);
    %set(gca,'CLim',[graphmin graphmax]);
    xlabel('Time (ms)');
    ylabel('Frequency (kHz)');
    title(['Sig. Diff. : ' file1(1:3) ': Intensity: ' num2str(ints(i)) ' dB']);
    set(gca,'yminortick', 'on');
    set(gca,'xminortick', 'on');
    set(gca,'YTick', [2:5:numfreq],'YTickLabel', round(freqs(2:5:numfreq)/100)/10,'FontWeight','Bold');
    set(gca,'XTick', [(-15-mwsize/2+1):50:300],'XTickLabel',[-50:50:(300-35)]);
    xlabel('Time (ms)');
    ylabel('Frequency (kHz)');
    line([35-mwsize/2+1, 35-mwsize/2+1],get(gca,'ylim'),[10000 10000],'Color','w','LineStyle', '--','linewidth',2);
    %a = colorbar('southoutside');
    %set(a,'FontWeight','Bold');

    subplot(2,3,4)
    a = find(stimuli1(:,2) == ints(i))';
    for j = a
        b = find(stimuli1(j,1) == freqs);
        sig1(b).v = data1(j).spikerate;
    end
    temp = zeros(numfreq,sweeplength1-mwsize+1);
    for j = 1:length(sig1)
        for k = 1:(sweeplength1-mwsize+1)
            [h,p] = ttest2(mean(sig1(j).v(:,k:(k+mwsize-1))')',spont1,alpha);
            if mean(mean(sig1(j).v(:,k:(k+mwsize-1)))) > mean(spont1)
                temp(j,k) = h;
            else
                temp(j,k) = -h;
            end
        end
    end
    v = [-1.5,-0.5,0.5];
    contourf(boxsmooth(temp,3),v);
    axis tight;
    set(gca,'yminortick', 'on');
    set(gca,'xminortick', 'on');
    set(gca,'YTick', [2:4:numfreq],'YTickLabel', round(freqs(2:4:numfreq)/100)/10,'FontWeight','Bold');
    set(gca,'XTick', [(-15-mwsize/2+1):50:300],'XTickLabel',[-50:50:(300-35)]);
    xlabel('Time (ms)');
    ylabel('Frequency (kHz)');
    %line([35-mwsize/2+1 35-mwsize/2+1],get(gca,'ylim'),[10000 10000],'Color','w','LineStyle', '--','linewidth',2);
    title(['File #1: ' file1(1:3) ': Intensity: ' num2str(ints(i)) ' dB']);
    
    subplot(2,3,5)
    a = find(stimuli2(:,2) == ints(i))';
    for j = a
        b = find(stimuli2(j,1) == freqs);
        sig2(b).v = data2(j).spikerate;
    end
    temp = zeros(numfreq,sweeplength2-mwsize+1);
    for j = 1:length(sig2)
        for k = 1:(sweeplength2-mwsize+1)
            [h,p] = ttest2(mean(sig2(j).v(:,k:(k+mwsize-1))')',spont2,alpha);
            if mean(mean(sig2(j).v(:,k:(k+mwsize-1)))) > mean(spont2)
                temp(j,k) = h;
            else
                temp(j,k) = -h;
            end
        end
    end
    v = [-1.5,-0.5,0.5];
    contourf(boxsmooth(temp,3),v);
    axis tight;
    set(gca,'yminortick', 'on');
    set(gca,'xminortick', 'on');
    set(gca,'YTick', [2:4:numfreq],'YTickLabel', round(freqs(2:4:numfreq)/100)/10,'FontWeight','Bold');
    set(gca,'XTick', [(-15-mwsize/2+1):50:300],'XTickLabel',[-50:50:(300-35)]);
    xlabel('Time (ms)');
    ylabel('Frequency (kHz)');
    %line([35-mwsize/2+1 35-mwsize/2+1],get(gca,'ylim'),[10000 10000],'Color','w','LineStyle', '--','linewidth',2);
    title(['File #2: ' file2(1:3) ': Intensity: ' num2str(ints(i)) ' dB']);
    
    subplot(2,3,6);
    a = find(stimuli1(:,2) == ints(i))';
    for j = a
        b = find(stimuli1(j,1) == freqs);
        sig1(b).v = data1(j).spikerate - mean(spont1);
    end
    a = find(stimuli2(:,2) == ints(i))';
    for j = a
        b = find(stimuli2(j,1) == freqs);
        sig2(b).v = data2(j).spikerate - mean(spont2);
    end
    temp = [];
    for j = 1:length(sig1)
        for k = 1:(sweeplength1-mwsize+1)
            disp([num2str(i) '-' num2str(j) '-' num2str(k)]);
            [h,p] = ttest2(mean(sig1(j).v(:,k:(k+mwsize-1))')',mean(sig2(j).v(:,k:(k+mwsize-1))')',alpha);
            if mean(mean(sig2(j).v(:,k:(k+mwsize-1)))) > mean(mean(sig1(j).v(:,k:(k+mwsize-1))))
                temp(j,k) = h;
            else
                temp(j,k) = -h;
            end
        end
    end
    v = [-1.5,-0.5,0.5,1.5];
    contourf(boxsmooth(temp,3),v);
    axis tight;
    set(gca,'yminortick', 'on');
    set(gca,'xminortick', 'on');
    set(gca,'YTick', [2:4:numfreq],'YTickLabel', round(freqs(2:4:numfreq)/100)/10,'FontWeight','Bold');
    set(gca,'XTick', [(-15-mwsize/2+1):50:300],'XTickLabel',[-50:50:(300-35)]);
    xlabel('Time (ms)');
    ylabel('Frequency (kHz)');
    %line([35-mwsize/2+1 35-mwsize/2+1],get(gca,'ylim'),[10000 10000],'Color','w','LineStyle', '--','linewidth',2);
    title(['Sig. Diff.: ' file2(1:3) ': Intensity: ' num2str(ints(i)) ' dB']);

end