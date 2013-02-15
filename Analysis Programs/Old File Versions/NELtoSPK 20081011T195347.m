function thresh = NELtoSPK(file,varargin)

%
%NELtoSPK.m - OU Neural Engineering Lab, 2007
%
%   NELtoSPK takes the raw, unfiltered sweeep traces from neural recordings
%   saved in the *.NEL format, filters the signal, and then thresholds the
%   filtered signal to identify spikes.  Spike shapes and spike times are then
%   saved in the *.SPK file format.  All spikes are preliminarily assigned to
%   cluster #1 prior to spike sorting.
%
%   thresh = NELtoSPK(file) thresholds the input *.NEL file using all 
%   function defaults and returns the set threshold value in volts.
%
%   thresh = NELtoSPK(...,'Property1',PropertyValue1,...) sets the values 
%   of any of the following optional thresholding properties:
%
%   * 'Method' - Threshold using a manually set threshold or through an
%                automatically calculated threshold, set with input values
%                of 'Manual' or 'Auto', respectively.  Default value is
%                'Auto'.
%
%   * 'SetThreshold' - Manually set the threshold to a specified value.
%                      Specified value should be a non-zero number,
%                      positive or negative, indicating positive or
%                      negative thresholding, respectively.  Setting
%                      threshold here also sets the 'Method' to 'Manual'
%                      and overrides any value entered for
%                      'MinimumThreshold'.
%
%   * 'Interpolate' - Use spline interpolation to better estimate spike
%                     timing and save interpolation-adjusted spike shapes.
%                     'Interpolation' can have values of 'On' or 'Off'.
%                     Default value is 'Off'.
%
%   * 'ThresholdType' - Use 'ThresholdType' to specify a positive or
%                       negative threshold using the values 'Pos' or 'Neg',
%                       respectively.  Setting 'ThresholdType' overrides
%                       the type set by the sign in 'SetThreshold'.
%                       Default value is 'Neg'.
%
%   * 'MinimumThreshold' - Set the minimum number of standard deviations
%                          for calculation of the automatic threshold.
%                          Input value should be a positive, no-zero
%                          number.  Default value is 3.
%
%   * 'FilterSettings' - Set the frequency cutoffs for the passband filter.
%                        Input value should be a 1 by 2 matrix of frequency
%                        cutoffs (in Hz).  The default value is [825 4500].
%
%   * 'CAR' - Use a common average reference to try and remove some of the
%             noise from all the channels.  This method takes the filtered
%             trace from all available channels, averages those traces
%             together, and then subtracts that average from the individual
%             channel's trace.  'CAR' can have values of 'On' or 'Off', the
%             default value is 'off'.
%
%   * 'NoiseMethod' - Set the noise level using a manually set level or
%                     an arbitrarily defined noise level, set with input 
%                     values of 'Manual' or 'Auto', respectively.  The 
%                     default value is 'Auto'.
%
%   * 'NoiseCeiling' - Set the maximum allowable voltage before a spike is
%                      considered noise.  Input value should be a positive,
%                      non-zero number.  Default value is 0.00025 volts.
%
%   * 'Display' - Display plots of the threshold process, set with values 
%                 of 'On' or 'Off'.  Default value is 'Off'.
%
%   * 'SavePlots' - Save an image file of several plots of the signal with
%                   the threshold overlaid, so that we can judge whether
%                   the threshold was appropriate, set with values of 'On'
%                   or 'Off'.  Default value is 'On'.
%
%   Last updated October 11, 2008, by Drew Sloan.


%First, we'll check the input file to make sure it's a *.NEL file.
if ~strcmpi(file(length(file)-3:length(file)),'.NEL');
    error('- Input file is not a *.NEL file.');
end

%We'll time the thresholding so that we can get a good idea of how long
%future threshold runs will take.
tic;

%We'll start by defining the default terms up front, and then change them
%if the user specifies any different values.
thresh_method = 'auto';         %Thresholds are calculated automatically based on the median signal amplitude.
noise_method = 'auto';          %Noise ceilings are set automatically to some arbitrary value.
thresh = [];                    %We begin with no pre-set threshold.
interpolate = 0;                %Interpolation if turned off by default.
threshold_type = 'NEG';         %We'll apply a negative threshold.
displayopt = 0;                 %Threshold plots are turned off by default
saveplots = 0;                  %Saving of representive threshold plots is turned off.
min_thresh = 3;                 %Minimum threshold for detection, in standard deviations of the noise.
high_pass_cutoff = 825;         %High-pass cutoff for the passband filter, in Hz.
low_pass_cutoff = 4500;         %Low-pass cutoff for the passband filter, in Hz.
noise_ceiling = 0.00025;       	%Maximum allowable voltage to be considered a spike.
car = 0;                        %Use of a common average reference is not used by default.

%Now we'll go through any changes to the optional properties the user might have entered.
threshold_type_override = 0;    %Setting 'ThresholdType' may override the threshold type set by 'SetThreshold'.
method_override = 0;            %Setting the threshold with 'SetThresh' will override any attempt to set 'Method' to 'Auto'.
for i = 1:2:length(varargin)
    if length(varargin) <= i    %Input arguments must come in pairs, the property name and it's specified value.
        error(['- No corresponding input argument for ''' cell2mat(varargin(i)) '''.']);
    else
        if strcmpi(cell2mat(varargin(i)),'Method')      %Setting the 'Method' property.
            if ~isstr(cell2mat(varargin(i+1))) | ...    %If the input value is not one of the two 'Method' options, then indicate error.
                    ~(strcmpi(cell2mat(varargin(i+1)),'Manual') |  strcmpi(cell2mat(varargin(i+1)),'Auto'))
                error('- The ''Method'' property must set to ''Auto'' or ''Manual''.');
            else
                thresh_method = cell2mat(varargin(i+1));       %Set the method to that specified.
                if strcmpi(thresh_method,'auto') & method_override     %If the user enters a set threshold, disregard 'Auto' method setting.
                    thresh_method = 'manual';
                    disp('WARNING: Preset threshold overriding specified auto-thresholding in NELtoSPK.');
                end
            end                
        elseif strcmpi(cell2mat(varargin(i)),'SetThreshold')    %Setting the 'SetThreshold' property.
            if isstr(cell2mat(varargin(i+1))) | ...     %'SetThreshold' input must be numeric and non-zero.
                    any(cell2mat(varargin(i+1)) == 0) | length(cell2mat(varargin(i+1))) > 1
                error('- The ''SetThreshold'' property must be a single, non-zero number.');
            else
                thresh = cell2mat(varargin(i+1));    %Set the threshold to that specified.
                %Threshold sign will indicate threshold type unless that property is set independently.
                if thresh > 0 & ~threshold_type_override     
                    threshold_type = 'POS';
                else ~threshold_type_override
                    threshold_type = 'NEG';
                end
                thresh = abs(thresh);          %We keep track of the sign of the threshold with "threshold_type".
                thresh_method = 'manual';      %Setting the threshold forces the thresholding method to manual.
                method_override = 1;    %Ignore any subsequent attempts to set 'Method' to 'Auto'.
            end
        elseif strcmpi(cell2mat(varargin(i)),'Interpolate');    %Turn spike shape interpolation on or off.
            if strcmpi(cell2mat(varargin(i+1)),'On')    
                interpolate = 1;    %Turn interpolation on.
            elseif strcmpi(cell2mat(varargin(i+1)),'Off')
                interpolate = 0;    %Turn interpolation off.
            else    %If the input value is neither 'On' or 'Off', indicate an error.
                error('- The ''Interpolate'' property must be set to either ''On'' or ''Off''.');
            end
        elseif strcmpi(cell2mat(varargin(i)),'ThresholdType');  %Setting the threshold type.
            threshold_type_override = 1;    %Setting the threshold type will override the threshold type set by the sign of a preset threshold.
            if strcmpi(cell2mat(varargin(i+1)),'POS')
                threshold_type = 'POS';     %Set thresholding to positive thresholding.
            elseif strcmpi(cell2mat(varargin(i+1)),'NEG')
                threshold_type = 'NEG';     %Set thresholding to negative thresholding.
            else    %If the input value is neither 'POS' or 'NEG', then indicate error.
                error('- The ''ThresholdType'' property must set to either ''POS'' or ''NEG''.');
            end
        elseif strcmpi(cell2mat(varargin(i)),'Display');    %Turn thresholding plot displays on or off.
            if strcmpi(cell2mat(varargin(i+1)),'On')
                displayopt = 1;     %Turn displays on.
            elseif strcmpi(cell2mat(varargin(i+1)),'Off')
                displayopt = 0;     %Turn displays off.
            else    %If the input value is neither 'On' or 'Off', then indicate error.
                error('- The ''Display'' property must set to either ''On'' or ''Off''.');
            end
        elseif strcmpi(cell2mat(varargin(i)),'SavePlots');	%Option to save representative thresholding plots for later evaluation.
            if strcmpi(cell2mat(varargin(i+1)),'On')
                saveplots = 1;     %Turn displays on.
            elseif strcmpi(cell2mat(varargin(i+1)),'Off')
                saveplots = 0;     %Turn displays off.
            else    %If the input value is neither 'On' or 'Off', then indicate error.
                error('- The ''SavePlots'' property must set to either ''On'' or ''Off''.');
            end
        elseif strcmpi(cell2mat(varargin(i)),'MinimumThreshold');   %Setting the minimum threshold for auto-thresholding in standard deviations.
            if isstr(cell2mat(varargin(i+1))) | ...     %Minimum threshold for auto-thresholding must be non-zero and numeric.
                    any(cell2mat(varargin(i+1)) <= 0) | length(cell2mat(varargin(i+1))) > 1
                error('- The ''MinimumThreshold'' property for auto-threshold setting must be a single, non-zero number.');
            elseif ~method_override
            	min_thresh = cell2mat(varargin(i+1));
            else
                disp('WARNING: Preset threshold overriding specified auto-thresholding minimum threshold in NELtoSPK.');
            end
        elseif strcmpi(cell2mat(varargin(i)),'FilterSettings');     %Setting the passband filter settings.
            temp = cell2mat(varargin(i+1));
            if isstr(temp) | ~all(size(temp) == [1 2]) | any(temp < 0)  %Filter settings must be non-zero and numeric.
                error('- The ''FilterSettings'' property must be a 1 by 2 matrix of positive, non-zero frequency values (in Hz).');
            else
                low_pass_cutoff = max(temp);    %Setting the low-pass cutoff.
                high_pass_cutoff = min(temp);   %Setting the high-pass cutoff.
            end
        elseif strcmpi(cell2mat(varargin(i)),'CAR');	%Option to turn on common average referencing.
            if strcmpi(cell2mat(varargin(i+1)),'On')
                car = 1;     %Turn common average referencing on.
            elseif strcmpi(cell2mat(varargin(i+1)),'Off')
                car = 0;     %Turn common average referencing off.
            else    %If the input value is neither 'On' or 'Off', then indicate error.
                error('- The ''CAR'' (Common Average Reference) property must set to either ''On'' or ''Off''.');
            end
        elseif strcmpi(cell2mat(varargin(i)),'NoiseMethod')      %Setting the 'Method' property.
            if ~isstr(cell2mat(varargin(i+1))) | ...    %If the input value is not one of the two 'Method' options, then indicate error.
                    ~(strcmpi(cell2mat(varargin(i+1)),'Manual') |  strcmpi(cell2mat(varargin(i+1)),'Auto'))
                error('- The ''NoiseMethod'' property must set to ''Auto'' or ''Manual''.');
            else
                noise_method = cell2mat(varargin(i+1));       %Set the method to that specified.
            end     
        elseif strcmpi(cell2mat(varargin(i)),'NoiseCeiling')    %Setting the maximum allowable voltage before a spike is considered noise.
            if isstr(cell2mat(varargin(i+1))) | ...     %Noise ceiling must be positive and numeric.
                    any(cell2mat(varargin(i+1)) == 0) | length(cell2mat(varargin(i+1))) > 1     
                error('- The ''NoiseCeiling'' property input must be a single, non-zero number.');
            else
            	noise_ceiling = abs(cell2mat(varargin(i+1)));
            end
        else
            error(['- ''' cell2mat(temp) ''' is not a recognized input argument.']);
        end
    end
end

%Here's some terms we'll define for spike shape interpolation.
pre_pts = 19;                   %The number of sample points to grab before a threshold crossing.
post_pts = 44;                  %The number of sample points to grab after a threshold crossing.
int_fact = 100;                 %Interpolation factor for fitting splines to spikeshapes.

%The output file will have the same name as the input file, but with the *.SPK file extension.
newfile = [file(1:length(file)-4) '.SPK'];
disp(['Thresholding "' file '" to "' newfile '"']);

%We'll use NELFileRead to open the data file.
data = NELFileRead(file);

%Here we'll generate the filter coefficients for the passband filter.
[b,a] = ellip(2,0.1,40,[high_pass_cutoff low_pass_cutoff]*2/data.sampling_rate);       
filter_coefs = [b; a];

%If this is a microstimulation-recording file, the first thing we need to
%do is to "blank" out the microstimulation pulse so that artefacts don't
%show up from filtering.  We'll do that by cutting out the microstimulation
%sections, and filling the gap with a straight line.
if strcmpi(file(5:8),'STIM')
    disp('This is a microstimulation-recording file, cutting out microstimulation artefact...');
    for i = 1:length(data.stim)
        phasedur = data.param(2).value(i);      %Pull out the phase duration, in milliseconds.
        ipp = data.param(4).value(i);           %Pull out the interpulse-period, in milliseconds.
        numpulse = data.param(5).value(i);      %Pull out the number of pulses.
        for j = 1:size(data.stim(i).signal,1)
            for k = 1:numpulse
                a = data.spont_delay + ipp*(k-1) + 0.25;   %Find the onset time of the microstimulation.
                b = a + 2*phasedur + 2;                     %We'll blank out the 2 ms following the microstimulation.
                a = fix(data.sampling_rate*a/1000);     %Change onset time to number of samples, rounding down.
                b = ceil(data.sampling_rate*b/1000);	%Change offset time to number of samples, rounding up.
                temp = [data.stim(i).signal(j,a); data.stim(i).signal(j,b)];    %Find the signal values at the gap endpoints.
                temp = [ones(2,1), [a; b]]\temp;                                %Create a regression matrix.
                temp = [ones(length([a:b]),1), [a:b]']*temp;                    %Find points on a straight line connecting the gap.
%                 plot([1:size(data.stim(i).signal,2)]',data.stim(i).signal(j,:)');
%                 line([a, a], get(gca,'ylim'),'color','r');
%                 line([b, b], get(gca,'ylim'),'color','r');
%                 line([a, b], [temp(1), temp(length(temp))],'color','g');
%                 xlim([a-50,b+50]);
%                 pause(0.1);
                data.stim(i).signal(j,a:b) = temp;                              %Replace artefact with the straight line points.
            end
        end
    end
end    

%If we're using common average referencing, we'll need work with data from
%all channels corresponding to this particular recording session, but to
%open them all with NELFileRead would require to much RAM, so we'll simply
%read out each sweep from the hard drive as we need it.  To do that, we'll
%need to identify the associated files and then index the sweeps contained
%in each.
if car
    if any(findstr(file,'\'))    %If the file isn't in the working directory, identify the directory it came out of.
        temp = file(1:max(findstr(file,'\')));                  %Pull the directory out of the file name.
        root = file(max(findstr(file,'\'))+4:length(file));     %Grab the root file name without the channel indicator.
    else
        temp = [cd '\'];                      %Otherwise, use the current directory.
        root = file(4:length(file)); 	%Grab the root file name without the channel indicator.
    end
    carfiles = dir([temp '*' root]);    %Find all *.NEL files from this session.
    for i = 1:length(carfiles)
        carfiles(i).name = [temp carfiles(i).name];     %Add the path to the filename.
        carchan(i).data = NELFileIndex(carfiles(i).name);    %Use NELFileIndex to find the location of the sweeps in the file.
    end
end

%First, we'll filter the sweep data.
for i = 1:length(data.stim)
    for j = 1:size(data.stim(i).signal,1)
        signal = data.stim(i).signal(j,:);
        %To avoid transients on the beginning and end of the signal, we'll 
        %add 500 sample disposable "tails" that the transients will appear 
        %on, but not on the saved signal.
        signal = [repmat(signal(1),1,500), signal, repmat(signal(length(signal)),1,500)];
        signal = filtfilt(filter_coefs(1,:),filter_coefs(2,:),signal);      %Applying the passband filter.
        signal = signal(501:(length(signal)-500));                          %Removing the "tails".
        data.stim(i).signal(j,:) = signal;                                  %Overwriting the filtered signal back to the structure.
    end
end

%Next, if we're manually setting the noise ceiling, we'll ask the user to
%set that here, so that we can exclude noise from subsequent threshold
%calculations.
%Now, if we're manually thresholding without a preset threshold, we'll open
%a figure, plot a section of the waveform, and ask for user input.
if strcmpi(noise_method,'manual')
    noise_ceiling = [];
    a = figure(1);          %Open a figure for plotting waveforms.
    set(a,'position',[15,200,1250,700]);    %Size the figure to a large size.
    for i = 1:length(data.stim)
        for j = 1:size(data.stim(i).signal,1)
            sweeplength = 1000*length(data.stim(i).signal(j,:))/data.sampling_rate;     %Calculate the sweeplength in milliseconds.
            if sweeplength < 500    %If the sweeplength is less than 500 milliseconds, plot the whole signal.
                numsamples = length(data.stim(i).signal(j,:));
            else                    %Otherwise, only plot the first 500 milliseconds of the signal.
                numsamples = fix(0.5*data.sampling_rate);
            end
            plot(data.stim(i).signal(j,1:numsamples),'color',[0 0.5 0]);    %Plotting the signal for this sweep.
            axis tight;
            a = get(gca,'ylim');
            ylim(1.1*[-max(abs(a)),max(abs(a))]);
            set(gca,'xtick',[data.spont_delay*data.sampling_rate/1000:data.sampling_rate/10:numsamples],'xticklabel',1000*[0:0.1:20]);
            xlabel('Time (ms)','fontweight','bold','fontsize',14);    %Label the x-axis.
            set(gca,'yticklabel',1000000*get(gca,'ytick'),'fontweight','bold','fontsize',12);
            ylabel('Voltage (\muV)','fontweight','bold','fontsize',14);  %Label the y-axis.
            line([data.spont_delay*data.sampling_rate/1000,data.spont_delay*data.sampling_rate/1000],get(gca,'ylim'),'color','b','linestyle','--','linewidth',2);   %Make a line at the stimulus onset.
            title(['Trial #' num2str(data.stim(i).order(j))], 'fontweight','bold','fontsize',14);   %Identify the trial number.
            a = max(get(gca,'ylim'));
            %Now we'll create a skip sweep "button" on the plot.
            rectangle('position',[1,0.8*a,data.spont_delay*data.sampling_rate/1000-1,0.2*a],'facecolor','b','edgecolor','b');   
            text(data.spont_delay*data.sampling_rate/2000,0.94*a,'Skip this','horizontalalignment','center','verticalalignment','middle','fontweight','bold','fontsize',14);
            text(data.spont_delay*data.sampling_rate/2000,0.86*a,'sweep','horizontalalignment','center','verticalalignment','middle','fontweight','bold','fontsize',14);
            text(numsamples/2,0.9*a,'Manually set the noise ceiling:','horizontalalignment','center','verticalalignment','middle','fontweight','bold','fontsize',14);
            [x,y] = ginput(1);  %After everything is plotted, we'll ask the user to set the threshold graphically.
            if (x > data.spont_delay*data.sampling_rate/1000-1 | y < 0.8*a) & y ~= 0    %If the user didn't press the skip sweep "button".
                noise_ceiling = abs(y);    %Set the noise ceiling value.
                line(get(gca,'xlim'),[y, y],'color','r','linestyle','--','linewidth',2);    %Plot a line showing the set threshold.
                pause(1);   %Pause for one second to view the set noise ceiling.
                disp(['Noise ceiling set to ' num2str(noise_ceiling) ' V.']);
                break;      %With noise ceiling set, break out of the "j" for loop.
            end    
        end     %If no noise ceiling is set for this sweep, loop to display another sweep.
        if ~isempty(noise_ceiling) 
            break;      %If the threshold is set, break out of the "i" for loop.
        end
    end
    close(1);       %Now that we're done with the manual thresholding figure, close it.
    pause(0.01);    %Pause briefly to allow the figure to close.
    if isempty(noise_ceiling)
        disp(['No more sweeps available for manual setting of the noise ceiling!']);
        disp(['Thresholding of ' file ' aborted!']);
        return;
    end
end

%If we're auto-thresholding, then the threshold is a set multiple of the
%standard deviation estimated from the median by Rodrigo Quiroga's neural
%signal standard deviation approximation.  Since we might have very long 
%signals, we'll need to "cheat" to estimate the median amplitude of the 
%concatenated signal by taking the median of the median of each sweep.
if strcmpi(thresh_method,'auto')
    for i = 1:length(data.stim)
        for j = 1:size(data.stim(i).signal,1)
            if strcmpi(thresh_method,'auto')                           %If the threshold is not preset by the user, then auto-threshold.
                signal = abs(data.stim(i).signal(j,:));                         %Finding the absolute value of all sample points.
                signal = signal(find(signal < noise_ceiling));                  %Excluding samples above the noise ceiling.
                thresh = [thresh; median(signal)];                              %Finding the median.
            end
        end
    end
    thresh = min_thresh*median(thresh)/0.6745;
end
 
%Now, if we're manually thresholding without a preset threshold, we'll open
%a figure, plot a section of the waveform, and ask for user input.
if strcmpi(thresh_method,'manual') && isempty(thresh)
    a = figure(1);          %Open a figure for plotting waveforms.
    set(a,'position',[15,200,1250,700]);    %Size the figure to a large size.
    for i = 1:length(data.stim)
        for j = 1:size(data.stim(i).signal,1)
            sweeplength = 1000*length(data.stim(i).signal(j,:))/data.sampling_rate;     %Calculate the sweeplength in milliseconds.
            if sweeplength < 500    %If the sweeplength is less than 500 milliseconds, plot the whole signal.
                numsamples = length(data.stim(i).signal(j,:));
            else                    %Otherwise, only plot the first 500 milliseconds of the signal.
                numsamples = fix(0.5*data.sampling_rate);
            end
            plot(data.stim(i).signal(j,1:numsamples),'color',[0 0.5 0]);    %Plotting the signal for this sweep.
            axis tight;
            a = get(gca,'ylim');
            if max(abs(a)) > noise_ceiling  %Constrain the plot to the bounds of the noise ceiling and center the plot.
                ylim([-noise_ceiling, noise_ceiling]);
            else
                ylim([-max(abs(a)),max(abs(a))]);
            end
            set(gca,'xtick',[data.spont_delay*data.sampling_rate/1000:data.sampling_rate/10:numsamples],'xticklabel',1000*[0:0.1:20]);
            xlabel('Time (ms)','fontweight','bold','fontsize',14);    %Label the x-axis.
            set(gca,'yticklabel',1000000*get(gca,'ytick'),'fontweight','bold','fontsize',12);
            ylabel('Voltage (\muV)','fontweight','bold','fontsize',14);  %Label the y-axis.
            line([data.spont_delay*data.sampling_rate/1000,data.spont_delay*data.sampling_rate/1000],get(gca,'ylim'),'color','b','linestyle','--','linewidth',2);   %Make a line at the stimulus onset.
            title(['Trial #' num2str(data.stim(i).order(j))], 'fontweight','bold','fontsize',14);   %Identify the trial number.
            a = max(get(gca,'ylim'));
            %Now we'll create a skip sweep "button" on the plot.
            rectangle('position',[1,0.8*a,data.spont_delay*data.sampling_rate/1000-1,0.2*a],'facecolor','b','edgecolor','b');   
            text(data.spont_delay*data.sampling_rate/2000,0.94*a,'Skip this','horizontalalignment','center','verticalalignment','middle','fontweight','bold','fontsize',14);
            text(data.spont_delay*data.sampling_rate/2000,0.86*a,'sweep','horizontalalignment','center','verticalalignment','middle','fontweight','bold','fontsize',14);
            text(numsamples/2,0.9*a,'Manually set the spike threshold:','horizontalalignment','center','verticalalignment','middle','fontweight','bold','fontsize',14);
            [x,y] = ginput(1);  %After everything is plotted, we'll ask the user to set the threshold graphically.
            if (x > data.spont_delay*data.sampling_rate/1000-1 | y < 0.8*a) & y ~= 0    %If the user didn't press the skip sweep "button".
                thresh = abs(y);    %Set the threshold value.
                if y > 1
                    threshold_type = 'POS';     %If the set threshold is negative, set the threshold type to negative thresholding.
                else
                    threshold_type = 'NEG';     %If the set threshold is negative, set the threshold type to negative thresholding.
                end
                line(get(gca,'xlim'),[y, y],'color','r','linestyle','--','linewidth',2);    %Plot a line showing the set threshold.
                pause(1);   %Pause for one second to view the set threshold.
                disp(['Threshold set to ' num2str(y) ' V.']);
                break;      %With threshold set, break out of the "j" for loop.
            end    
        end     %If no threshold is set for this sweep, loop to display another sweep.
        if ~isempty(thresh) 
            break;      %If the threshold is set, break out of the "i" for loop.
        end
    end
    close(1);       %Now that we're done with the manual thresholding figure, close it.
    pause(0.01);    %Pause briefly to allow the figure to close.
    if isempty(thresh)
        disp(['No more sweeps available for manual thresholding!']);
        disp(['Thresholding of ' file ' aborted!']);
        return;
    end
end

%If the 'SavePlots' option is set to 'On', we'll create some plots of the
%signal from randomly chosen sweeps with the threshold overlaid and save
%that figure as an image file.
if saveplots
    sniplen = 0.5;          %Length of snippet length to plot, in seconds.
    numsnips = 5;           %The number of snippets to plot.
    a = figure(1);          %Create a new figure window.
    pos = get(0,'ScreenSize');  %We'll make the figure large because it's going to have multiple plots.
    pos = [0.1*pos(3),0.1*pos(4),0.8*pos(3),0.8*pos(4)];
    set(a,'Position',pos);
    hold on;
    a = [];     %Now we'll randomly choose several sweeps to plot.
    for i = 1:length(data.stim)     %Create a list of all sweeps.
        a = [a; repmat(i,size(data.stim(i).signal,1),1), [1:size(data.stim(i).signal,1)]'];
    end
    a = a(randperm(size(a,1)),:);   %Randomize the sweep list.
    a = a(1:numsnips,:);    %Truncate the list to the number of snippets to plot.
    for i = 1:size(a,1);
        signal = data.stim(a(i,1)).signal(a(i,2),:);    %Grab the signal for the given sweep.
        if length(signal)/data.sampling_rate > sniplen  %If the signal is longer that the desired snippet length, we'll truncate.
            temp = length(signal) - data.sampling_rate*sniplen + 1;     %We'll find all possible starting points for a snippet.
            temp = round(rand*temp);    %Randomly picking one starting point.   
            signal = signal(temp:(temp + round(sniplen*data.sampling_rate)-1)); %Truncate the larger signal to the desired length.
        end
        temp = max(abs(signal));    %Determine the normalization factor.
        if temp > noise_ceiling
            temp = noise_ceiling;   %If the normalization factor is above the noise ceiling, adjust it to the noise ceiling.
        end
        plot(2*i+signal/temp,'color',[0 0.1 0]);    %Plot the signal in dark green, including any noise.
        signal(find(signal > noise_ceiling)) = noise_ceiling;   %Cut off any noise points.
        plot(2*i+signal/temp,'color',[0 0.5 0]);    %Plot the cut off signal in lighter green.
        if strcmpi(threshold_type,'POS');   %Draw a line indicating the threshold setting, whether positive or negative.
            line([1,length(signal)],2*i+[thresh thresh]/temp,'color','r','linestyle',':');
        else
            line([1,length(signal)],2*i-[thresh thresh]/temp,'color','r','linestyle',':');
        end
    end
    axis tight;     %Tighten the axes.
    set(gca,'ylim',[1 2*numsnips+1],'Position',[0 0 1 0.95],'color','k');   %Set y-limit, position, and background color.
    set(gca,'xtick',[],'xticklabel',[]);  
    title(['Threshold setting: ' file],'fontweight','bold','fontsize',12,'interpreter','none');     %Display title with file name.
	drawnow;    %Draw the figure.
    a = figure(get(0,'CurrentFigure'));     %Now we'll save this plot as a bitmap in the same folder as the original data.
    temp = [file(1:length(file)-4) '_THR'];
    saveas(a,temp,'bmp');
    close(a);   %Close the figure.
end

%Now we'll create the *.SPK file to write spikeshapes to and enter in the
%session parameters.
fid = fopen(newfile,'w');
if fid == -1
    pause(180);
    fid = fopen(newfile,'w');
end
fwrite(fid,data.daycode,'int8');                %DayCode.
fwrite(fid,length(data.rat),'int8');            %Number of characters in the rat's name.
fwrite(fid,data.rat,'uchar');                   %Characters of the rat's name.
fwrite(fid,data.spont_delay,'int16');           %Spontaneous measurement delay.
fwrite(fid,data.sampling_rate,'float32');       %Sampling rate, in Hz.          <---Implemented 4/7/4007.
fwrite(fid,(pre_pts+post_pts+1),'int16');       %Number of samples in each spikeshape.
fwrite(fid,length(data.param),'int8');          %Number of parameters.
for j = 1:length(data.param)
    fwrite(fid,length(data.param(j).name),'int16');     %Number of characters in each parameter name.
    fwrite(fid,data.param(j).name,'uchar');             %Characters of each parameter name.
end    
        
%Now we'll go back and threshold each sweep and pull out the spike shapes.
if displayopt   %If the display option is on, we'll open a figure.
    a = figure(1);
    pos = get(0,'ScreenSize');  %We'll make the figure large because it's going to have many subplots.
    pos = [0.05*pos(3),0.05*pos(4),0.9*pos(3),0.9*pos(4)];
    set(a,'Position',pos,'MenuBar','none');
    PSTH = zeros(1,1000*max([data.stim(:).sweeplength])+1);     %For kicks, we'll create a PSTH of spike times as we threshold.
end
numspikes = 0;
for i = 1:length(data.stim)         %New Stimulus.
    fwrite(fid,i,'uint16');                                 %Stimulus index.
    fwrite(fid,data.stim(i).sweeplength,'float32');         %Sweeplength, in seconds.
    for k = 1:length(data.param)
        fwrite(fid,data.param(k).value(i),'float32');	%Parameter values.
    end
    numsweeps = size(data.stim(i).signal,1);
    fwrite(fid,numsweeps,'uint16');             %The number of sweeps to follow.
    for j = 1:size(data.stim(i).signal,1)       %New Sweep.
        fwrite(fid,data.stim(i).timestamp(j),'float64');    %Timestamp.
        fwrite(fid,data.stim(i).order(j),'uint16');         %Order of presentation (trial number).
        signal = data.stim(i).signal(j,:);
        noise_estimate = length(find(abs(signal) >= noise_ceiling))/length(signal);
        fwrite(fid,noise_estimate,'float32');               %Noise estimate (Ratio: above noise ceiling samples/total samples).
        if strcmpi(threshold_type,'POS')	%If we're applying a positive threshold.
            index = intersect(find(signal >= thresh),find(signal < thresh)+1);
        else                                %Otherwise, we're applying a negative threshold.
            index = intersect(find(signal <= -thresh),find(signal > -thresh)+1);
        end
        for k = 1:length(index);
            if index(k) <= pre_pts + 2   %If the spike is too early in the signal to get a full trace, we'll fill the gap with zeros.
                trace = signal(1:index(k)+post_pts+2);
            elseif index(k) > length(signal) - post_pts - 2     %Likewise if the spike is too late in the signal.
                trace = signal(index(k)-pre_pts-2:end);
            else    %Otherwise, we'll just grab the spike snippet normally.
                trace = signal(index(k)-pre_pts-2:index(k)+post_pts+2);
            end
            if max(abs(trace)) > noise_ceiling  %If a spike passes the noise ceiling, we'll kick it out.
                index(k) = nan;
            end
        end
        index(isnan(index)) = [];
        numspikes = numspikes + length(index);
        fwrite(fid,length(index),'uint32');       %Number of spikes.
        if displayopt       %If the display option is turned on, we can watch the signals being thresholded.
            subplot(2,2,[1 2]);     %Full signal plot;
            cla;
            plot(signal,'color',[0 0.5 0]);     %Plot the filtered signal.
            axis tight;
            a = get(gca,'ylim');
            if max(abs(a)) > noise_ceiling  %Constrain the plot to the bounds of the noise ceiling and center the plot.
                ylim([-noise_ceiling, noise_ceiling]);
            else
                ylim([-max(abs(a)),max(abs(a))]);
            end
            set(gca,'xtick',[data.spont_delay*data.sampling_rate/1000:data.sampling_rate/10:length(data.stim(i).signal)],'xticklabel',[0:0.1:20]);
            xlabel('Time (s)','fontweight','bold','fontsize',12);           %Set up the x-axis.
            set(gca,'yticklabel',1000000*get(gca,'ytick'));
            ylabel('Voltage (\muV)','fontweight','bold','fontsize',12);     %Set up the y-axis.
            line([data.spont_delay*data.sampling_rate/1000,data.spont_delay*data.sampling_rate/1000],get(gca,'ylim'),'color','b','linestyle','--','linewidth',2);   %Make a line at the stimulus onset.
            if strcmpi(threshold_type,'POS')     %Make a line showing the threshold.
                line(get(gca,'xlim'),[thresh, thresh],'color','r','linestyle','--','linewidth',2);
            else
                line(get(gca,'xlim'),[-thresh, -thresh],'color','r','linestyle','--','linewidth',2);
            end
            title(['Trial #' num2str(data.stim(i).order(j))], 'fontweight','bold','fontsize',14);
            hold on;
            subplot(2,2,3);     %Spike waveform plot;
            cla;
            set(gca,'color','k');   %Change the background of the spike shape plot to black.
            xlim([1, pre_pts + post_pts+1]);
            set(gca,'xtick',[pre_pts-20:5:pre_pts + post_pts],'xticklabel',[-20:5:100]);
            xlabel('Samples','fontweight','bold','fontsize',12);
            ylabel('Voltage (\muV)','fontweight','bold','fontsize',12);
            if strcmpi(threshold_type,'POS')     %If we're applying a positive threshold.
                line(get(gca,'xlim'),[thresh, thresh],'color','r','linestyle',':');
            else
                line(get(gca,'xlim'),[-thresh, -thresh],'color','r','linestyle',':');
            end
            title('Spike Shapes', 'fontweight','bold','fontsize',14);
            hold on;
            subplot(2,2,4);     %Create a PSTH plot;
            xlim([1,1000*data.stim(i).sweeplength + 1]);
            set(gca,'xtick',[data.spont_delay-50:1000*data.stim(i).sweeplength/5:1000*data.stim(i).sweeplength],...
                'xticklabel',[-50:1000*data.stim(i).sweeplength/5:1000*data.stim(i).sweeplength]);
            xlabel('Time from Stimulus Onset (ms)','fontweight','bold','fontsize',12);
            ylabel('Spike Count','fontweight','bold','fontsize',12);
            title('Pooled PSTH', 'fontweight','bold','fontsize',14);
            hold on;
            pause(0.001);
        end
        for k = 1:length(index)     %Now stepping through spike by spike.
            if interpolate  %If we're using spine interpolation to estimate better spike time accuracy.
                if index(k) <= pre_pts + 2   %If the spike is too early in the signal to get a full waveform, we'll fill the gap with zeros.
                    spike_shape = [zeros(1,pre_pts+3-index(k)), signal(1:index(k)+post_pts+2)];
                elseif index(k) > length(signal) - post_pts - 2     %Likewise if the spike is too late in the signal.
                    spike_shape = [signal(index(k)-pre_pts-2:end), zeros(1,post_pts+2-length(signal)+index(k))];
                else    %Otherwise, we'll just grab the spike snippet normally.
                    spike_shape = signal(index(k)-pre_pts-2:index(k)+post_pts+2);
                end
                curve_fit = spline(1:length(spike_shape),spike_shape,1/int_fact:1/int_fact:size(spike_shape,2));
                if strcmpi(threshold_type,'POS')     %Again, if we're applying a positive threshold.
                    spike_time = intersect(find(curve_fit >= thresh),find(curve_fit < thresh)+1)/int_fact;
                else
                    spike_time = intersect(find(curve_fit <= -thresh),find(curve_fit > -thresh)+1)/int_fact;
                end
                spike_time = min(spike_time(find(spike_time >= pre_pts+2 & spike_time <= pre_pts+3)));
                spike_n = spike_time*int_fact;
                spike_shape = curve_fit(spike_n - int_fact*pre_pts:int_fact:spike_n + int_fact*post_pts);
                index(k) = index(k)-pre_pts - 3 + spike_time(find(spike_time >= pre_pts+2 & spike_time <= pre_pts+3));
            else	%If we're not using spine interpolation.
                if index(k) <= pre_pts  %If the spike is too early in the signal to get a full waveform, we'll fill the gap with zeros.
                    spike_shape = [zeros(1,pre_pts+1-index(k)), signal(1:index(k)+post_pts)];
                elseif index(k) > length(signal) - post_pts     %Likewise if the spike is too late in the signal.
                    spike_shape = [signal(index(k)-pre_pts:end), zeros(1,post_pts-length(signal)+index(k))];
                else    %Otherwise, we'll just grab the spike snippet normally.
                    spike_shape = signal(index(k)-pre_pts:index(k)+post_pts);
                end
            end
            fwrite(fid,1000*index(k)/data.sampling_rate,'float32');     %Spike time.
            fwrite(fid,1,'uint8');                                      %Cluster assignment.
            fwrite(fid,spike_shape','float32');                         %Spike shape.
            if displayopt       %If the display option is on, we'll plot each spike.
                subplot(2,2,[1 2]);
                plot(index(k)-pre_pts:index(k)+post_pts,spike_shape,'color',[0.5 0 0.5]);   %Plot spikes in magenta on the overall signal.
                subplot(2,2,3);
                plot(spike_shape,'color','w');  %Plot separated spike shape.
                set(gca,'yticklabel',1000000*get(gca,'ytick'),'fontweight','bold');
                ylabel('microVolts','fontweight','bold','fontsize',12);
                if strcmpi(threshold_type,'POS')     %If we're applying a positive threshold.
                    line(get(gca,'xlim'),[thresh, thresh],'color','r','linestyle',':');     %Draw the threshold.
                else
                    line(get(gca,'xlim'),[-thresh, -thresh],'color','r','linestyle',':');
                end
                subplot(2,2,4);
                PSTH(1:round(1000*data.stim(i).sweeplength+1)) = PSTH(1:round(1000*data.stim(i).sweeplength+1)) + ...
                    histc(1000*index(k)/data.sampling_rate,[0:1000*data.stim(i).sweeplength]);
                bar(PSTH);  %Plot the PSTH as a bar chart.
                pause(0.001);
            end
        end
    end
    data.stim(i).signal = [];
end
fclose(fid);    %Finally, we'll close the *.SPK file and disp how long it took to threshold this file.
disp(['-----> ' num2str(numspikes) ' spikes, ' num2str(toc) ' seconds to threshold.']);

%We've timed the thresholding process and now we'll save the number of
%spikes, whether or not we were interpolating, and how long it took to
%threshold the whole file.
if exist('Z:\Spike Sorting','dir')      %Check if the fileputer's connected.
    textfilename = 'Z:\Spike Sorting\Thresholding_Times.txt';
else                                        %If the fileputer's not connected.
    textfilename = 'C:\Documents and Settings\Owner\Desktop\Spike Sorting\Thresholding_Times.txt';
end
if exist(textfilename)          %If the text file already exists, open the existing list.
    temp = load(textfilename);
else                            %If it doesn't exist, build a new list.
    temp = [];
end
temp = [temp; numspikes, interpolate, toc];     %Add the number of spikes and the sort time to the list.
save(textfilename,'temp','-ascii');             %Re-save the file in text format.
if strcmpi(threshold_type,'NEG')	%If we're applying a negative threshold...
    thresh = -thresh;               %...return a negative number.
end