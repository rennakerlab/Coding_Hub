function PlotTCs

%When we get around to doing significance tests, it helps to define alpha
%at the beginning as a variable, so that if we ever want to change the
%significance level of our tests, we only have to change one line of code.
alpha = 0.05;
disp(['alpha = ' num2str(alpha)]);

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
[file path] = uigetfile('*.f32');
cd(path);

rootname = file(4:length(file));
files = dir(['*' rootname]);

figure('Position',[7          76        2539         876]);
for currentfile = 1:length(files);
    channel = str2num(files(currentfile).name(2:3));
    if channel ~= 1
        subplot(3,5,17-channel);
        
        %We'll use the "spikedataf.m" function that came with Brainware to read the
        %*.f32 file.
        data = spikedataf(files(currentfile).name);
        
        %With the new NEL formats, the spontaneous recording delay is saved as the
        %last stimulus parameter in the f32 files.
        spont_delay = data(1).stim(length(data(1).stim));

        %*.f32 files index data according to the number of stimulus parameter
        %combinations.  To simplify things, we'll put these values into one big
        %matrix, with rows equal to the number of sets.
        stimuli = [data(:).stim]';

        %We'll need to have lists of all the possible frequencies and intensities
        %included in the tuning curve.
        freqs = unique(stimuli(:,1));
        ints = unique(stimuli(:,2));

        %It will be handy to have variables storing the number of frequencies and
        %intensities, and it's better to take these values from the file rather
        %than write them in directly, because then you'd have to change your code
        %if you change your sound file.
        numfreq = length(freqs);
        numint = length(ints);

        %Again, it's best not to put in hard numbers for the sweeplength, because
        %you might change it, better to pull it out of the data structure.
        sweeplength = data(1).sweeplength;

        %We repeat each stimuli combination ten times in a session, but again,
        %better to pull it out of the data structure just in case you change it
        %either way.
        numreps = length(data(1).sweep);

        %Now we'll go through each set and sweep and calculate the spikerates by
        %performing a histogram on the spike times.
        for i = 1:length(data);
            %Each repetition is one sweep, and we'll save the results of each
            %without immediately averaging so that we can run signficance tests
            %later with each repetition counting as a sample.
            data(i).spikerate = [];
            for j = 1:numreps; 
                %The easiest way to find spikerate is to take the spiketimes
                %from a sweep in the data structure and put them into the
                %"histc" histogram function, set so that the spikes are binned
                %into 1 ms bins.  Sometimes there are no spikes, and the
                %histogram function freaks out, hence the try/catch statment.
                try;
                    temp = histc(data(i).sweep(j).spikes,[0:sweeplength]);
                    data(i).spikerate(j,:) = 1000*temp(1:sweeplength);
                catch;
                    data(i).spikerate(j,:) = zeros(1,sweeplength);
                end;                
            end;
        end;

        %This loop arranges the data into pseudo-Spectral Temporal Receptive Fields
        %(STRFs), which are color plots of the response strength (in spikerate)
        %across axes of frequency (Hz) and time (ms).  There is one pseudo-STRF for
        %each intensity.
        for i = 1:numint
            %We'll start by pulling up the indices of those sets which have the
            %desired intensity.
            a = find(stimuli(:,2) == ints(i))';
            strf(i).mean = zeros(numfreq,sweeplength);
            for j = a
                b = find(stimuli(j,1) == freqs);
                strf(i).mean(b,:) = mean(data(j).spikerate);
            end
        end

        %The pseudo-STRFs are very choppy, so to better visualize them, we can
        %smooth them with a box smooth.
        for i = 1:numint
            strf(i).smooth = boxsmooth(strf(i).mean,5);
        end

        %We want to set the colorscales to the same values on each plot, so we'll
        %find the maximum and minimum value of spikerate across all smoothed STRFs.
        graphmax = 0;
        graphmin = 1000;
        for i = 1:numint;
            if max(max(strf(i).smooth)')>graphmax;
                graphmax = max(max(strf(i).smooth)');
            end
            if min(min(strf(i).smooth)')<graphmin;
                graphmin = min(min(strf(i).smooth)');
            end
        end

        %Here we're creating plots of the smoothed STRF for each intensity.
        %Remember that the tones played in a TC (Tuning Curve) experiment vary in
        %frequency and intensity, so these plots show use which frequencies each
        %neuron or multineuron cluster responds to each intensity, as well as when
        %that response happens relative to the start of the stimulus.  The white
        %line drawn across the plot marks the stimulus onset, which is also denoted
        %on the time scale as time zero.
        i = numint;

        %PLOT STSAD***********************************************************
        %Here we'll plot a surface plot of the STSAD.  This is all straight-up
        %graphing calls, so I won't bother commenting much. The surface function 
        %cuts off the top row of your data when viewed from directly above, so 
        %to see everything you'll need to put in a dummy row of zeros.
    %     contourf(strf(i).smooth);
    %     [a,b] = size(strf(i).smooth);
        temp = [strf(i).smooth; zeros(1,length(strf(i).smooth))];
        surf(temp,'EdgeColor','none');
        axis tight;
        view(0,90);
        set(gca,'YTick', [1:round(numfreq/10):numfreq],'YTickLabel', round(freqs(1:round(numfreq/10):numfreq)/100)/10,'FontWeight','Bold');
        set(gca,'XTick', [0:round((sweeplength/5)):sweeplength],'FontWeight','Bold');
%         set(gca,'CLim',[graphmin graphmax]);
        xlabel('Time (ms)');
        ylabel('Frequency (kHz)');
        line([spont_delay spont_delay],get(gca,'ylim'),[10000 10000],'Color','w','LineStyle', '--');
        title([files(currentfile).name(1:3) ': Intensity: ' num2str(ints(i)) ' dB']);
%         a = colorbar;
%         set(a,'FontWeight','Bold');
        pause(0.1);
    end
end

