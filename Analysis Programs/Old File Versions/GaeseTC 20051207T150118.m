function h = GaeseTC(alpha)

%Load the f32 data file
[file,path] = uigetfile('*.f32')
file = [path file];
cd(path);

if isempty(alpha)
    alpha = 0.05
end

%**************************************************************************
%spikedataf.m is a function which will read Brainware f32 data into a data
%structure.  It has fields: sweeplength, stim, and sweep.  Sweeplength is
%the number of milliseconds of recording for each sound.  Stim is the
%parameters of a particualr stimulus, i.e. frequency and intensity.  Sweep
%denotes which repetition that particular data comes from.  
data = spikedataf(file);


%**************************************************************************
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


%**************************************************************************
%f32 files contain spike times, and we're going to look at spike rates, so
%this loop will calculate histograms of those spike times to create
%Peri-Stimulus Time Histograms (PSTH) for each repetition of each stimulus.
%This loop also creates a 4-D array of spikerate calculated  each 1 ms
%time-bin for each frequency, intensity, and repetition.  The dimensions of
%the 4-D array are frequency (x), time (y), intensity (z), and
%repetition (r).
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
end

scrnsize = get(0,'ScreenSize');
pos = [scrnsize(3)/20 scrnsize(4)/16 (scrnsize(3)-2*(scrnsize(3)/20)) (scrnsize(4)-2*(scrnsize(4)/16))];
dots = zeros(numfreq,numint);
for i = 1:numfreq
    for j = 1:numint
        temp = zeros(numreps,2);
        for k = 1:numreps
            temp(k,1) = mean(tc(i,11:30,j,k));
            temp(k,2) = mean(tc(i,36:55,j,k));
        end
        p = signrank(temp(:,1),temp(:,2));
        if mean(temp(k,2)) > mean(temp(k,1))
            dots(i,j) = p;
        else
            dots(i,j) = -p;
        end
    end
end
figure('Position',pos);
hold;
for i = 1:numfreq
    for j = 1:numint
        if abs(dots(i,j)) < alpha
            if dots(i,j) > 0
                plot(i,j,'Marker','.','MarkerSize',40,'Color','k');
            else
                plot(i,j,'Marker','o','MarkerSize',12,'Color','k');
            end
        else
            line([i-0.2,i+0.2],[j, j],'Color','k');
        end
    end
end
xlim([0.5,numfreq+0.5]);
ylim([0.5,numint+0.5]);
set(gca,'YTick',[1:numint],'YTickLabels',ints,'FontWeight','Bold');
set(gca,'XTick',[1:fix(numfreq/10):numfreq],'XTickLabels',round(0.01*freqs(1:fix(numfreq/10):numfreq))/10,'XMinorTick','On');
xlabel('Frequency (kHz)','FontSize',12,'FontWeight','Bold');
ylabel('Intensity (dB)','FontSize',12,'FontWeight','Bold');

h = 1