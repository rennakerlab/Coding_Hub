function NEL_View_Tonotopy

%NEL_View_Tonotopy.m - OU Neural Engineering Lab, 2008
%
%   NEL_View_Tonotopy lets the user select an f32 file of an IsoTC test,
%   opens all the corresponding f32 files for each channel, and computes
%   the best frequency, and plots those frequencies on a 2-D representation
%   of A1 based on the standard NEL 15-electrode configuration.
%
%   Last updated February 13, 2008, by Drew Sloan.

%When we get around to doing significance tests, it helps to define alpha
%at the beginning as a variable, so that if we ever want to change the
%significance level of our tests, we only have to change one line of code.
alpha = 0.05;
disp(['alpha = ' num2str(alpha)]);

%First, we'll have the user select a single IsoTC file to open.
[file, path] = uigetfile('*IsoTC*.f32');
if isempty(file)    %If no "cancel" is selected, quit the program.
    return;
end
cd(path);   %Change the path to where the file is located
rootname = file(4:length(file));    %Find the root name of the file without the channel number.
files = dir(['*' rootname]);        %Find all files with that root name.

%The standard electrode configuration is 3 rows and five columns.
tonotopy = repmat(NaN,5,3);

%This divide by zero warning can be pretty irritating if you don't shut it off.
warning off MATLAB:divideByZero;

%Now we'll go through each file and find the best frequency for each
%channel.
for currentfile = 1:length(files)
    channel = str2num(files(currentfile).name(2:3));    %We pull the channel number out of the file name.
    if channel ~= 1     %Channel 1 is always disconnected in the standard configuration and can be ignored.
        
        disp(['Analyzing Channel #' num2str(channel)]);
        
        %We'll use the "spikedataf.m" function that came with Brainware to read the *.f32 file.
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
        
        %The duration of the stimuli will be recorded in the third column of the
        %stimuli matrix, and we'll pull that out here.
        duration = max(stimuli(:,3));
        
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
        
        %Because the neuron/MUC may show frequency selectivity only at certain
        %timepoints, we'll set the analysis window for the RF dynamically, by
        %running a kruskalwallis ANOVA across frequencies for a series of moving
        %timebins and then keep only those bins with significant frequency
        %selectivity.
        binsize = 5;    %We'll use time-bins of 5 ms because that seems to give a good, consistent result.
        selectbins = [];
        for i = 1:numfreq           %We'll need to define the groups for the Kruskal-Wallis ANOVA beforehand.
            groupbyfreq(i) = {i};
        end
        for j = 1:sweeplength-binsize+1
            temp = [];
            for i = 1:numfreq
                %Average the data across the timebin, but not across repetition.
                temp = [temp, mean(data(i).spikerate(:,j:(j+binsize-1)),2)];    
            end
            %The Kruskal-Wallis is a nonparametric ANOVA, it will identify differences in response between frequencies.
            p = kruskalwallis(temp,groupbyfreq,'off');      
            %If there's significant frequency selectiviy, add these millisecond bins to the analysis window.
            if p < alpha        
                selectbins = [selectbins, j:(j+binsize-1)];
            end
        end
        %We'll then get rid of any bin repetitions in our analysis window.
        selectbins = unique(selectbins);
        
        %To make sure the responses we look at are significantly driven, we'll need
        %to first calculated the spontaneous rate over the time window from the
        %beginning of the sweep to the end of the spontaneous recording delay.
        spont = [];
        for i = 1:numfreq
            spont = [spont, mean(data(i).spikerate(:,1:spont_delay),2)];
        end
        %We'll collapse the spontaneous rate measurement across frequencies to give
        %us a sample size equal to that for each frequency response.
        spont = mean(spont,2);
        
        %Using the analysis window we just created, we'll collapse the data across
        %time and look at a frequency receptive field with error bars.
        rf = [];
        rf_error = [];
        for i = 1:numfreq
            rf = [rf, mean(data(i).spikerate(:,selectbins),2)];
            [h,p,ci] = ttest2(mean(data(i).spikerate(:,selectbins),2),spont);
            rf_error = [rf_error, ci(1)];
        end
        
        %We'll define the best frequency as the one with the highest lower-end of
        %the confidence interval.
        bf = freqs(find(rf_error == max(rf_error)));
        
        %We'll include the bf in the tonotopic map only if the RF has a significant
        %frequency-wise ANOVA.
        p = kruskalwallis(rf,groupbyfreq,'off');
        %if p < alpha
        if ~isempty(bf)
            tonotopy(channel-1) = bf;
        end      
    end
end

%It's nice to have large figures fitted to the screensize, so we'll set that up here.
scrnsize = get(0,'ScreenSize');
pos = [scrnsize(3)/6 scrnsize(4)/6 (scrnsize(3)-2*(scrnsize(3)/4)) (scrnsize(4)-2*(scrnsize(4)/4))];
figure('position',pos);
hold on;

%We'll plot the tonotopy as a colormap with the range of the colormap going
%between our minimum and maximum test frequencies.
colors = [0 0 0; autumn(1000)];
for i = 2:16
    if ~isnan(tonotopy(i-1))
        temp = round(1000*(log2(tonotopy(i-1))-log2(min(freqs)))/(log2(max(freqs))-log2(min(freqs)))) + 1;
    else
        temp = 1;
    end
    rectangle('position',[7 - i + 5*fix((i-2)/5), fix((i-2)/5), 1, 1],'facecolor',colors(temp,:),'edgecolor',colors(temp,:));
end
set(gca,'xticklabel',[],'yticklabel',[]);
xlabel('\leftarrow Caudal    -    Rostral \rightarrow','fontsize',14,'fontweight','bold');
ylabel('\leftarrow Ventral    -    Dorsal \rightarrow','fontsize',14,'fontweight','bold');
rootname(find(rootname == '_')) = ' ';
title(rootname(2:length(rootname)-4),'fontweight','bold','fontsize',14);
a = colorbar;
colormap(autumn);
temp = get(a,'ylim');
range = temp(2) - temp(1);
ticks = range*(log2(freqs(1:round(numfreq/10):numfreq)) - log2(min(freqs)))/(log2(max(freqs)) - log2(min(freqs)));
set(a,'ytick',1+ticks,'yticklabel',roundn(freqs(1:round(numfreq/10):numfreq)/1000,-1),'fontweight','bold','fontsize',12);