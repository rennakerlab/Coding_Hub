function PlotLFPs

%When we get around to doing significance tests, it helps to define alpha
%at the beginning as a variable, so that if we ever want to change the
%significance level of our tests, we only have to change one line of code.
alpha = 0.05;
disp(['alpha = ' num2str(alpha)]);

%This line keeps the t-test from freaking out when you hand it a column of
%zeros.
warning off MATLAB:divideByZero;

%Here we set how large a percentage we want to use in the trim means for
%the LFPs.  Note that the trimmean function wants an input percent between
%1 and 100, not a decimal input, i.e. 0.2.
trimpercent = 20;

%I like my figures nice and big, so here's a trick that will let us set the
%figure size to about 80% of the screensize.
scrnsize = get(0,'ScreenSize');
pos = [scrnsize(3)/20 scrnsize(4)/16 (scrnsize(3)-2*(scrnsize(3)/20)) (scrnsize(4)-3*(scrnsize(4)/16))];

%We'll use a common dialog box to select which file we'd like to take a
%look at.  We'll also change the current directory to the folder that file
%is in.
[file path] = uigetfile('*.LFP');
cd(path);

rootname = file(4:length(file));
files = dir(['*' rootname]);

figure('Position',[7          76        2539         876]);
for currentfile = 1:length(files);
    channel = str2num(files(currentfile).name(2:3));
    if channel ~= 1
        subplot(3,5,17-channel);
        
        %We'll use the "LFPFileRead.m" function that came with Brainware to read the
        %*.f32 file.
        data = LFPFileRead(files(currentfile).name);
        
        %We'll pull out the spontaneous recording delay, in milliseconds.
        spont_delay = data.spont_delay;

        %*.f32 files index data according to the number of stimulus parameter
        %combinations.  To simplify things, we'll put these values into one big
        %matrix, with rows equal to the number of sets.
        stimuli = [data(:).stim]';

        %We'll need to have lists of all the possible frequencies, intensities,
        %and durations included in the tuning curve.
        freqs = unique(data(:).param(1).value');
        ints = unique(data(:).param(2).value');
        durs = unique(data(:).param(3).value');

        %It will be handy to have variables storing the number of frequencies and
        %intensities, and it's better to take these values from the file rather
        %than write them in directly, because then you'd have to change your code
        %if you change your sound file.
        numfreq = length(freqs);
        numint = length(ints);
        numdur = length(durs);

        %Again, it's best not to put in hard numbers for the sweeplength, because
        %you might change it, better to pull it out of the data structure.
        sweeplength = 1000*data(1).stim(1).sweeplength;

        %We repeat each stimuli combination ten times in a session, but again,
        %better to pull it out of the data structure just in case you change it
        %either way.
        numreps = length(data.stim(1).timestamp);

        %This loop arranges the data into Local Field Potential Receptive Fields
        %(LFPRFs), which are color plots of the response strength (in volts)
        %across axes of frequency (Hz) and time (ms).  There is one LFPRF for
        %each intensity.
        for i = 1:numint
            %We'll start by pulling up the indices of those sets which have the
            %desired intensity.
            a = find(data.param(2).value == ints(i));
            lfprf(i).mean = zeros(numfreq,sweeplength);
            for j = a
                b = find(data.param(1).value(j) == freqs);
                lfprf(i).mean(b,:) = trimmean(data.stim(b).lfp, trimpercent);
            end
        end

        %The LFPRFs may be a little choppy, so to better visualize them, we can
        %smooth them with a box smooth.
        for i = 1:numint
            lfprf(i).smooth = boxsmooth(lfprf(i).mean,5);
        end

        %We want to set the colorscales to the same values on each plot, so we'll
        %find the maximum and minimum value of voltage across all LFPRFs.
        graphmax = -1000;
        graphmin = 1000;
        for i = 1:numint;
            if max(max(lfprf(i).smooth)')>graphmax;
                graphmax = max(max(lfprf(i).smooth)');
            end
            if min(min(lfprf(i).smooth)')<graphmin;
                graphmin = min(min(lfprf(i).smooth)');
            end
        end

        %In this program, we're really only interested in checking to see
        %which channels have LFP activity, so we'll only plot the responses
        %to the highest intensity.
        i = numint;

        %PLOT LFPRF*************************************************************
        %Here we'll plot a surface plot of the LFPRF.  This is all straight-up
        %graphing calls, so I won't bother commenting much. The surface function 
        %cuts off the top row of your data when viewed from directly above, so 
        %to see everything you'll need to put in a dummy row of zeros.
    %     contourf(strf(i).smooth);
    %     [a,b] = size(strf(i).smooth);
        temp = [lfprf(i).smooth, zeros(size(lfprf(i).smooth,1),1); zeros(1,size(lfprf(i).smooth, 2) + 1)];
        surf(temp,'EdgeColor','none');
        axis tight;
        view(0,90);
        set(gca,'YTick', [1:round(numfreq/10):numfreq],'YTickLabel', round(freqs(1:round(numfreq/10):numfreq)/100)/10,'FontWeight','Bold');
        set(gca,'XTick', [0:round((sweeplength/5)):sweeplength],'FontWeight','Bold');
        set(gca,'CLim',[graphmin graphmax]);
        xlabel('Time (ms)');
        ylabel('Frequency (kHz)');
        line([spont_delay spont_delay],get(gca,'ylim'),[10000 10000],'Color','w','LineStyle', '--');
        title([files(currentfile).name(1:3) ': Intensity: ' num2str(ints(i)) ' dB']);
        a = colorbar;
        set(a,'FontWeight','Bold');
        colormap(flipud(jet));
        pause(0.1);
    end
end