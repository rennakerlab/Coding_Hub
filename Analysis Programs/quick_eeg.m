function varargout = quick_eeg(varargin)
%
%QUICK_EEG.m - Rennaker Neural Engineering Lab/Kilgard Cortical Plasticity Lab, 2011
%
%   QUICK_EEG has the user select an *.f32 file and then creates a pooled 
%   PSTH from those spike times.
%
%   QUICK_EEG(file,...) creates a pooled PSTH for each file specified.  The 
%   variable "file" can either be a single string or a cell array of 
%   strings containing file names.
%
%   QUICK_EEG(winsize,...) creates a pooled PSTH smoothing with a longer
%   time bin specified by "winsize", an integer number of milliseconds.
%
%   Last updated November 22, 2010, by Drew Sloan.


winsize = 5;                                                                %Set the analysis window to 5 seconds.
buffer = [0.5 1.5];                                                         %Set the default length of the delays, if any, between VNS and the analysis windows, in seconds.
bws = [1 4; 4 8; 8 13; 13 30; 30 100];                                      %Set the default EEG bandwidths to test.
display = 1;                                                                %Set the default display property to create figures.
noise_ratio_cutoff = 3;                                                     %Set the default ratio of sweep noise-to-VNS artifact for rejecting sweeps.
alpha = 0.05;                                                               %Set the default alpha for determining significance.
offset = 1;                                                                 %Create a variable to track whether the user entered a filename.    
if length(varargin) >= 1                                                    %If the user entered any input arguments...
    temp = varargin{1};                                                     %Grab the first input argument.    
    if ischar(temp)                                                         %If the first input argument was a string...
        if ~any(strcmpi(temp,{'display','buffer','winsize','bws'}))         %If the argument doesn't match any of the accepted input property names...
            if exist(temp,'file')                                           %If the argument is a filename for a file that exists...
                files(1).name = temp;                                       %Save the filename as a string.
                files(1).fullname = temp;                                   %Also save the filename as the full filename.
                offset = 2;                                                 %Set the offset to start reading property names with the second input.
            else                                                            %Otherwise, if the input isn't a filename or a recongized property name...
                error(['ERROR in QUICK_EEG: "' temp ...
                    '" is not a filename or a recognized user-settable property.']);    %Show an error.
            end
        end
    elseif iscell(temp)                                                     %If the first input argument was a cell array.
        for j = 1:length(temp)                                              %Step through the supposed filenames....
            if ischar(temp{j})                                              %If this element of the cell array is a string
                files(j).name = cell2mat(temp(j));                          %Save the string as a filename.
                files(j).fullname = cell2mat(temp(j));                      %Also save the string as the full filename.
            else                                                            %Otherwise, if this element of the cell array isn't a string...
                error('ERROR in QUICK_EEG: An element of the input cell array isn''t a string filename.');      %Show an error.
            end
        end
        offset = 2;                                                         %Set the offset to start reading property names with the second input.
    else                                                                    %Otherwise, if the first input is numeric...
        error('ERROR in QUICK_EEG: The first input must be a file name, a cell array of file names, or the name of a property to set.');    %Show an error.
    end
end
for i = offset:2:length(varargin)
    temp = varargin{i};                                                     %Pull the variable out of the input argument.
    if ischar(temp)                                                         %If the argument is a string...
        if strcmpi(temp,'winsize')                                          %If the user specified an analysis window size.
            if isnumeric(varargin{i+1}) &&...
                    length(varargin{i+1}) == 1 && varargin{i+1} > 0         %If the specified window size is a single number greater than zero...
                winsize = varargin{i+1};                                    %Set the analysis window size to that specified.
            else                                                            %Otherwise...
                error('ERROR in QUICK_EEG: The value of the ''winsize'' property must be a single, non-zero number of seconds.');	%Show an error.
            end
        elseif strcmpi(temp,'buffer')                                       %If the user wants to specify a buffer between the VNS and the analysis window.            
            buffer = varargin{i+1};                                         %Set the buffer to that specified.
        elseif strcmpi(temp,'display')                                      %If the user wants to specified the display property.
            display = strcmpi(varargin{i+1},'ON');                          %Set the display property to that set by the user.
        elseif strcmpi(temp,'bws')                                          %If the user wants to specify the EEG bands to test...
            bws = varargin{i+1};                                            %Set the EEG bands to those specified.
        end
    else                                                                    %Otherwise, if the argument isn't a string.
    end
end
if ~exist('files','var')                                                    %If the user hasn't specified an input file...
    [temp path] = uigetfile({'*.NEL';'*.LFP'},'multiselect','on');          %Have the user pick an input file or files.
    cd(path);                                                               %Change the current directory to the folder that file is in.
    if iscell(temp)                                                         %If the user's picked multiple files...
        for i = 1:length(temp)                                              %Step through each selected file.
            files(i).name = temp{i};                                        %Save the file name in the structure.
            files(i).fullname = [path temp{i}];                             %Also save the filename with the path.
        end
    elseif ischar(temp)                                                     %If only one file is selected...
        files(1).fullname = [path temp];                                    %Add the path to the filename.
        files(1).name = temp;                                               %Also save the filename without the path.
    elseif isempty(temp)                                                    %If no file is selected...
        error('ERROR IN QUICK_EEG: No file selected!');                     %Show an error message.
    end
end

pop_banddata = nan(length(files),size(bws,1),2);                            %Create a matrix to receive the mean change in EEG bandpower for each file.
pop_pre_fft = 0;                                                            %Create a matrix to receive the mean PRE FFT from each file.
pop_catch_fft = 0;                                                          %Create a matrix to receive the mean CATCH FFT from each file.
pop_max_fft = 0;                                                            %Create a matrix to receive the mean MAX FFT from each file.
pop_pre_N = 0;                                                              %Create a matrix to count the number of samples that go into the mean population PRE FFT.
pop_catch_N = 0;                                                            %Create a matrix to count the number of samples that go into the mean population CATCH FFT.
pop_max_N = 0;                                                              %Create a matrix to count the number of samples that go into the mean population MAX FFT.

bandlabels = {};                                                            %Create a cell array to hold EEG band labels.
for i = 1:size(bws,1)                                                       %Step through each EEG band to test.
    bandlabels{i} = [num2str(bws(i,1)) '-' num2str(bws(i,2)) ' Hz'];        %Label the band with it's frequency endpoints.
end

output = [];                                                                %Create a structure to fill with banddata information from each file.
for f = 1:length(files)                                                     %Step through each *.NEL file and perform the EEG analysis on each.
    if ~exist(files(f).fullname,'file')                                     %If the specified input file doesn't exist...
        error(['ERROR IN QUICK_EEG: ' files(f).name ' doesn''t exist!']);   %...show an error.
    end
    if ~any(strcmpi(files(f).name(end-3:end),{'.NEL','.LFP'}))              %If the specified input file isn't an *.NEL or *.LFP file...
        error(['ERROR IN QUICK_EEG: ' files(f).name...
            ' is not an *.NEL or *.LFP file!']);                            %...show an error.
    end
    if strcmpi(files(f).name(end-3:end),'.NEL')                             %If the file is an *.NEL file...
        data = NELFileRead(files(f).fullname);                              %Use NELFileRead to read the data from the *.NEL file.
    else                                                                    %Otherwise, if the file is an *.LFP file...
        data = LFPFileRead(files(f).fullname);                              %Use LFPFileRead to read the data from the *.LFP file.
        for i = 1:length(data.stim)                                         %Step through each stimulus in the *.LFP file.
            data.stim(i).signal = data.stim(i).lfp;                         %Rename the "lfp" field to "signal".
            data.stim(i).lfp = [];                                          %Empty the "lfp" field.
        end
        data.stim = rmfield(data.stim,'lfp');                               %Remove the "lfp" field.
    end
    if ~isfield(data,'stim') || isempty(data.stim)                         	%If there's no sweeps in the data file...
        warning(['No sweeps in file "' files(f).name '. Skipping this file.']);     %Show a warning.
        continue;                                                           %Skip analysis of this file.
    end
    if ~isfield(data,'sampling_rate')                                       %If there's no sampling rate field in the data structure.
        data.sampling_rate = 1000;                                          %Set the sampling rate to the 1000 Hz default for LFP files.
    end
    spont_delay = round(data.sampling_rate*double(data.spont_delay)/1000);  %Pull out pre-VNS recording delay and convert it to number of samples.
    N_winsize = fix(data.sampling_rate*winsize);                            %Calculate the number of samples in the analysis window.
    N_buffer = round(data.sampling_rate*buffer);                            %Calculate the number of samples in the analysis window buffer.
    if N_winsize > spont_delay - N_buffer(1) - 1                            %If the specified analysis window is larger than the spontaneous recording delay...
        N_winsize = spont_delay  - N_buffer(1) - 1;                         %Set the analysis window length to the length of the spontaneous recording delay.
    end
    nfft = 2^nextpow2(N_winsize);                                           %Find the number of frequency steps to test in the FFT.    
    freq_list = data.sampling_rate/2*linspace(0,1,nfft/2+1);                %Generate an evenly-spaced list of frequencies for plotting the FFT results.
    nfft_save = find(freq_list > max(bws(:,2)),1,'first');                  %Find the right bound of the desired bandwidths in the FFT.    
    sweepcount = 0;                                                         %Create a variable to count the total number of sweeps.
    N = 0;                                                                  %Create a variable to find the maximum number of samples in a sweep.
    for s = 1:length(data.stim)                                             %Step through each stimulus in the data structure.
        if size(data.stim(s).signal,2) > N                                  %If the length of the current sweep is longer than the previous maximum...
            N = size(data.stim(s).signal,2);                                %Save this sweeplength as the new maximum.
        end
        sweepcount = sweepcount + size(data.stim(s).signal,1);              %Add the number of sweeps for this stimulus to the sweep counter.
    end
    banddata = nan(sweepcount,size(bws,1),2);                               %Pre-allocate an array to hold EEG band values.
    params = zeros(size(banddata,1),5);                                     %Pre-allocate a matrix to hold sweep parameters.
    max_trials = zeros(sweepcount,1);                                       %Create a matrix to track which trials are those with the maximum VNS parameters.
    c = 0;                                                                  %Create a counter to count through the parameters.
    param_i = zeros(1,5);                                                   %Create a matrix to keep track of which parameter indices correspond to which parameters.
    param_names = {'Current Amplitude (µA)',...
            'First Phase (1 = Anodic, -1 = Cathodic)',...
            'Phase Duration (µs)',...
            'Interpulse Interval (ms)',...
            'Pulse-Train Duration (ms)'};                                   %Create a list of the stimulus parameters we care about.
    for i = 1:length(param_names)                                           %Step through each of those stimulus parameters.
        sweepcount = 0;                                                     %Set the sweep counter back to zero.
        c = c + 1;                                                          %Add one to the parameter counter.
        temp = find(strcmpi(param_names{i},{data.param.name}));             %Find the index that corresponds to the current stimulus parameter.
        if isempty(temp)                                                    %If no corresponding index was found...
            param_names{1} = 'Amplitude (µA)';                              %Change the first parameter name.
            param_names{5} = 'Pulse Train Duration (ms)';                   %Change the fifth parameter name.
            temp = find(strcmpi(param_names{i},{data.param.name}));         %Find the index that corresponds to the current stimulus parameter.
        end
        param_i(c) = temp;                                                  %Save the index that corresponds to the current stimulus parameter.
        for j = 1:length(data.stim)                                         %Step through each stimulus.
            for k = 1:size(data.stim(j).signal,1)                           %Step through each sweep of the stimulus.
                sweepcount = sweepcount + 1;                                %Add one to the sweep count.
                params(sweepcount,i) = data.param(param_i(c)).value(j);     %Save the parameter value for this sweep.
            end
        end
    end
    disp([num2str(sweepcount) ' sweeps in this data file.']);               %Show the user how many sweeps are in this data file.    
    handles.cur_amp = unique(params(:,1));                                  %Find all the unique current amplitudes tested.
    handles.first_phase = unique(params(:,2));                              %Find all the unique first phases tested.
    handles.phase_dur = unique(params(:,3));                                %Find all the unique phase durations tested.
    handles.ipi = unique(params(:,4));                                      %Find all the unique interpulse intervals tested.
    handles.train_dur = unique(params(:,5));                                %Find all the unique pulsetrain durations tested.
    temp = handles.ipi;                                                     %Grab the list of interpulse intervals.
    temp(temp == 0) = Inf;                                                  %Set any IPI of zero to infinity.
    extremes = [max(handles.cur_amp), handles.first_phase(1),...
        max(handles.phase_dur), min(temp), max(handles.train_dur)];         %Save the parameter extremes to identify trials that should have the most effect.
    a = find(freq_list <= min(bws(:,1)),1,'last');                          %Find the sample in the mean FFT approximately at the left-most EEG band bound.
    medianfft = nan(sweepcount,nfft_save-a+1,2);                            %Pre-allocate a matrix to hold the mean PRE and POST FFTs.
    vns_ratio = nan(sweepcount,2);                                          %Pre-allocate a matrix to hold the ratio of the VNS artifact to off-VNS artifacts.
    meantrace = zeros(1,N);                                                 %Create a matrix to hold the mean EEG trace for all sweeps.
    sweepcount = zeros(1,N);                                                %Set the sweep counter to count for all samples in the trace.
    a = double(ceil(data.sampling_rate*...
        (max([data.param(param_i(5)).value])/1000)));                       %Calculate the number of samples in the longest VNS pulstrain.
    intervals = {spont_delay - N_buffer(1) + (-N_winsize:-1),...
        spont_delay + a + N_buffer(2) + (1:N_winsize),...
        spont_delay + (1:a)};                                               %Set the samples for the pre and post analysis window and a window containing the VNS train.
    for s = 1:length(data.stim)                                             %Step through each stimulus in the data structure.
        for j = 1:size(data.stim(s).signal,1)                               %Step through each sweep of this stimulus.
            N = size(data.stim(s).signal,2);                                %Find the number of samples in the sweep trace.
            sweepcount(1:N) = sweepcount(1:N) + 1;                          %Add one to the sweep counter.                 
            trace = data.stim(s).signal(j,:);                               %Pull out the recording trace for this sweep.
            meantrace(1:N) = meantrace(1:N) + trace;                        %Add the current trace to the mean trace.
            vns_ratio(sweepcount(1),1) = ...
                max(abs(data.stim(s).signal(j,intervals{3})));              %Save the maximum voltage amplitude during the VNS artifact.
            vns_ratio(sweepcount(1),2) = max(abs(data.stim(s).signal(j,...
                [intervals{1},intervals{2}])));                             %Save the maximum voltage amplitude outside of the VNS artifact.
            for k = 1:2                                                     %Step through the pre and post analysis windows.                
                temp = trace(intervals{k});                                 %Grab the snippet of the trace preceding VNS onset.
                Y = fft(temp,nfft)'/length(temp);                           %Compute the FFT within the specified analysis window.
                Y = 2*abs(Y(1:nfft/2+1));                                   %Compute the power spectrum from the FFT.
                a = find(freq_list <= min(bws(:,1)),1,'last');              %Find the sample in the mean FFT approximately at the left-most EEG band bound.
                medianfft(sweepcount(1),:,k) = Y(a:nfft_save)';             %Save the FFT for this analysis window.
                if isequal(params(sweepcount(1),:),extremes)                %If this FFT is for a trial with the most extreme VNS parameter combination...
                    max_trials(sweepcount(1)) = 2;                          %Mark that this trial had the maximum VNS parameters.
                end
                for b = 1:size(bws)                                         %Step through each of the EEG bands.
                    a = 0;                                                  %Clear a temporary variable to hold the total power in the EEG band.
                    i = [find(freq_list >= bws(b,1),1,'first'),...
                        find(freq_list <= bws(b,2),1,'last')];              %Find the tested frequency steps bounding the EEG band.
                    if bws(b,1) ~= freq_list(i(1))                          %If the EEG band lower edge doesn't exactly match a tested frequency step...
                        y = Y(i(1)-1:i(1));                                 %Grab the value of the power spectrum at the closest frequency steps.
                        x = freq_list(i(1)-1:i(1));                         %Grab the frequency values at the closest frequency steps.
                        y(1) = y(1) + ...
                            (bws(b,1)-x(1))*(y(2)-y(1))/(x(2)-x(1));        %Interpolate the power spectrum value at the frequency band's edge.
                        x(1) = bws(b,1);                                    %Grab the frequency value of the lower edge of the frequency band.
                        a = a + 0.5*(y(1)+y(2))*(x(2)-x(1));                %Save area under the partial frequency step.
                    end
                    if bws(b,2) ~= freq_list(i(2))                          %If the EEG band upper edge doesn't exactly match a tested frequency step...
                        y = Y(i(2):i(2)+1);                                 %Grab the value of the power spectrum at the closest frequency steps.
                        x = freq_list(i(2):i(2)+1);                         %Grab the frequency values at the closest frequency steps.
                        y(2) = y(1) + ...
                            (bws(b,2)-x(1))*(y(2)-y(1))/(x(2)-x(1));        %Interpolate the power spectrum value at the frequency band's edge.
                        x(2) = bws(b,2);                                    %Grab the frequency value of the lower edge of the frequency band.
                        a = a + 0.5*(y(1)+y(2))*(x(2)-x(1));                %Save area under the partial frequency step.
                    end
                    a = a + trapz(freq_list(i(1):i(2)),...
                        Y(i(1):i(2)));                                      %Add the power from the remaining frequency steps.
                    banddata(sweepcount(1),b,k) = a/range(bws(b,:));        %Save the power within the EEG bandwidth as a pre-therapy baseline.
                end
            end
        end
    end
    vns_ratio = vns_ratio(:,2)/median(vns_ratio(max_trials == 2,1));        %Calculate the sweep noise ratio for each sweep, relative to the maximum VNS artifact.
    vns_ratio = vns_ratio < noise_ratio_cutoff;                             %Identify all the sweeps that have a sweep noise ratio less than the set cut-off value.
    if any(vns_ratio == 0)                                                  %If any of the sweeps exceeded the cut-off value...
        disp(['Kicking out ' num2str(sum(vns_ratio == 0)) ' sweeps that exceeded the noise cut-off.']);     %...show how many sweeps were kicked out.
    end
    banddata(vns_ratio ~= 1,:,:) = [];                                      %Kick out the bandpower data for all sweeps that exceeded the noise cut-off.
    params(vns_ratio ~= 1,:) = [];                                          %Also kick out the parameters for all sweeps that exceeded the noise cut-off.
    medianfft(vns_ratio ~= 1,:,:) = [];                                     %Also kick out the FFTs for all sweeps that exceeded the noise cut-off.
    max_trials(vns_ratio ~= 1) = [];                                        %Also kick out the indices for maximum-VNS sweeps that exceeded the noise cut-off.
    meantrace = 1000000*meantrace./sweepcount;                              %Calculate the mean EEG trace by dividing by the number of samples and convert it to uV.
    banddata = 100*squeeze(banddata(:,:,2)./banddata(:,:,1) - 1);           %Normalize the post-VNS EEG bandpower values by their respective pre-VNS values.
    pop_banddata(f,:,1) = nanmedian(banddata(params(:,1) == 0,:),1);        %Save the median CATCH bandpower for all the EEG bands into the population results matrix.
    pop_banddata(f,:,2) = nanmedian(banddata(max_trials == 2,:),1);         %Save the median MAX bandpower for all the EEG bands into the population results matrix.
    if size(medianfft,2) > size(pop_pre_fft,2)                              %If there's more samples in this PRE FFT than for previous files...
        pop_pre_fft(1:end,(length(pop_pre_fft)+1):size(medianfft,2)) = 0;   %Expand the population PRE mean FFT matrix.
        pop_pre_N(1:end,(length(pop_pre_N)+1):size(medianfft,2)) = 0;       %Expand the population PRE mean FFT sample counter.
    end
    pop_pre_fft(1:size(medianfft,2)) = pop_pre_fft(1:size(medianfft,2))...
        + nanmedian(medianfft(:,:,1));                                      %Add this file's PRE FFT to the population matrix.
    pop_pre_N(1:size(medianfft,2)) = pop_pre_N(1:size(medianfft,2)) + 1;    %Add one to the counter for each sample of the PRE FFT.
    if size(medianfft,2) > size(pop_catch_fft,2)                            %If there's more samples in this PRE FFT than for previous files...
        pop_catch_fft(1:end,...
            (length(pop_catch_fft)+1):size(medianfft,2)) = 0;               %Expand the population CATCH mean FFT matrix.
        pop_catch_N(1:end,(length(pop_catch_N)+1):size(medianfft,2)) = 0;   %Expand the population CATCH mean FFT sample counter.
    end
    pop_catch_fft(1:size(medianfft,2)) = ...
        pop_catch_fft(1:size(medianfft,2)) + ...
        nanmedian(medianfft(params(:,1) == 0,:,2));                         %Add this file's CATCH FFT to the population matrix.
    pop_catch_N(1:size(medianfft,2)) = ...
        pop_catch_N(1:size(medianfft,2)) + 1;                               %Add one to the counter for each sample of the CATCH FFT.
    if size(medianfft,2)> size(pop_max_fft,2)                               %If there's more samples in this MAX FFT than for previous files...
        pop_max_fft(1:end,(length(pop_max_fft)+1):size(medianfft,2)) = 0;   %Expand the population MAX mean FFT matrix.
        pop_max_N(1:end,(length(pop_max_N)+1):size(medianfft,2)) = 0;       %Expand the population MAX mean FFT sample counter.
    end
    pop_max_fft(1:size(medianfft,2)) = pop_max_fft(1:size(medianfft,2))...
        + nanmedian(medianfft(max_trials == 2,:,2));                       	%Add this file's MAX FFT to the population matrix.
    pop_max_N(1:size(medianfft,2)) = pop_max_N(1:size(medianfft,2)) + 1;    %Add one to the counter for each sample of the MAX FFT.
    
    if display == 1                                                         %If the display option is on, create and display a figure.
        pos = get(0,'ScreenSize');                                          %Grab the current screensize.
        pos = [(0.2+0.01*(f-1))*pos(3),(0.1-0.01*(f-1))*pos(4),...
            0.6*pos(3),0.8*pos(4)];                                         %Scale the recording figure relative to the screensize.
        handles.mainfig = figure('position',pos,...
            'color','w',...
            'name',files(f).name);                                          %Create, size, and specify the properties of a new figure.
    
        %Plot the mean EEG trace in the top plot and show the analysis windows on it.
        subplot(3,1,1);                                                     %Create a subplot in the top third of the figure.
        hold on;                                                            %Hold the axes for multiple plots.
        plot(meantrace,'color','k');                                        %Plot the whole sweep trace as a black line.
        colors = [0 0 .5; 0 .5 0; .5 0 0];                                  %Save the blue, green, and red colors to use in showing the analysis windows.
        plot(intervals{1},meantrace(intervals{1}),'color',colors(1,:));     %Plot the PRE analysis window mean trace in blue.
        plot(intervals{2},meantrace(intervals{2}),'color',colors(2,:));     %Plot the POST analysis window mean trace in green.
        plot(intervals{3},meantrace(intervals{3}),'color',colors(3,:));     %Plot the VNS pulsetrain window mean trace in red.
        axis tight;                                                         %Tighten the axes.
        temp = get(gca,'ylim');                                             %Grab the y-limits.
        set(gca,'ylim',temp + 0.05*[-1,1]*range(temp));                     %Add a small space to the top and bottom of the plot.
        box on;                                                             %Turn on a bounding box for the plot.
        temp = temp(1) + 0.95*range(temp);                                  %Compute a good y-value for plotting window labels.
        a = spont_delay + (-25:25)*data.sampling_rate;                      %Find the sample points corresponding to second ticks.
        set(gca,'xtick',a,'xticklabel',-25:25,'fontweight',...
            'bold','fontsize',12);                                          %Label the x axis.
        labels = {'PRE','POST','VNS'};                                      %Create labels for the analysis windows.
        ylabel('Voltage (\muA)','fontweight','bold','fontsize',12);         %Label the y axis.
        xlabel('Sweep Time (s)','fontweight','bold','fontsize',12);         %Label the x axis.
        for i = 1:3                                                         %Step through the PRE, POST, and VNS windows.
            line([1,1]*intervals{i}(1),get(gca,'ylim'),'color',...
                colors(i,:),'linestyle','--');                              %Plot a line on the left bound of the window.
            line([1,1]*intervals{i}(end),get(gca,'ylim'),'color',...
                colors(i,:),'linestyle','--');                              %Plot a line on the right bound of the window.
            line([intervals{i}(1),intervals{i}(end)],[1,1]*temp,'color',...
                colors(i,:),'linestyle','-');                               %Plot a line across the top of the window.
            text(mean(intervals{i}),temp,labels{i},'fontsize',12,...
                'fontweight','bold','horizontalalignment','center',...
                'verticalalignment','middle','background','w',...
                'edgecolor',colors(i,:),'color','k','margin',2);            %Label the window.
        end
    
        %Plot the mean PRE, extreme-POST, and catch-trial-POST FFTs. 
        subplot(3,1,2);                                                     %Create a subplot in the top third of the figure.
        a = find(freq_list <= min(bws(:,1)),1,'last');                      %Find the sample in the mean FFT approximately at the left-most EEG band bound.
        medianfft = [nanmedian(medianfft(:,:,1));...
            nanmedian(medianfft(params(:,1) == 0,:,2));...
            nanmedian(medianfft(max_trials == 2,:,2))];                     %Find the median of the PRE, CATCH, and MAX FFTs.
        semilogy(repmat(freq_list(a:nfft_save)',1,3),medianfft',...
            'linewidth',2);                                                 %Plot the median FFTs on a logarithmic y axis.
        axis tight;                                                         %Tighten the axes.
        xlim([min(bws(:,1)), max(bws(:,2))]);                               %Set the x axis limits to the left- and right-most bounds of the EEG bands.
        box on;                                                             %Turn on a bounding box for the plot.
        temp = get(gca,'ylim');                                             %Grab the y axis limits.
        ylim(10.^(log10(temp) + [-0.05,0.05]*(range(log10(temp)))));        %Add a small space to the top and bottom of the plot.
        set(gca,'fontweight','bold','fontsize',12);                         %Make the x axis ticks bold and 12 point font.
        for b = 1:size(bws,1)                                               %Step through each of the EEG bands to test.
            line(bws(b,1)*[1,1],get(gca,'ylim'),'color','k','linestyle',...
                '--');                                                      %Plot a dashed line at the left-hand bound of the EEG band
            line(bws(b,2)*[1,1],get(gca,'ylim'),'color','k','linestyle',...
                '--');                                                      %Plot a dashed line at the right-hand bound of the EEG band
            line(bws(b,:),[1,1]*temp(2),'color','k','linestyle','-');       %Plot a line across the top of the window.
            text(mean(bws(b,:)),temp(2),bandlabels{b},'fontsize',8,...
                'fontweight','bold','horizontalalignment','center',...
                'verticalalignment','middle','background','w','color',...
                'k','margin',1);                                            %Label the EEG band.
        end
        ylabel('Power','fontweight','bold','fontsize',12);                  %Label the y axis.
        xlabel('Frequency (Hz)','fontweight','bold','fontsize',12);         %Label the x axis.
        a = legend({'PRE','POST: 0 \muA','POST: Max. VNS'},'location',...
            'northeast');                                                   %Create a legend on the plot.
        set(a,'fontsize',12','fontweight','bold');                          %Set the font size and font weight on the legend.
    
        %Plot the mean PRE, extreme-POST, and catch-trial-POST bandpowers.
        subplot(3,1,3);                                                     %Create a subplot in the top third of the figure.
        hold on;                                                            %Hold the axes for multiple plots.
        max_trials(params(:,1) == 0) = 1;                                   %Change the maximum VNS sweep tracking matrix to also show catch trials.             
        colors = [0 0 .5; 0 .5 0];                                          %Create a colors for the CATCH and MAX sweeps.
        line([0,size(bws,1)+1],[0,0],'color','k');                          %Plot a black line at zero.
        p = zeros(1,3);                                                     %Keep track of the handles for the bars for the legend.
        s = zeros(2,size(bws,1));                                           %Pre-allocate a matrix to hold the p-value from significance test.
        for b = 1:size(bws,1)                                               %Step through each of the EEG bands.
            for i = 1:2                                                     %Step through the CATCH and MAX sweeps.
                a = nanmedian(banddata(max_trials == i,b));                 %Find the median bandpower.
                c = quartiles(banddata(max_trials == i,b));                 %Calculate the 25% and 75% quartiles.
                s(i,b) = signrank(banddata(max_trials == i,b));             %Check for a significant bandpower change with a Wilcoxon MPSR test.
%                 c = simple_ci(banddata(max_trials == i,b));                 %Find the 95% confidence interval for the bandpower change.
                p(i) = fill([b-0.8+i*0.4;b-0.8+i*0.4;b-0.4+i*0.4;b-0.4+i*0.4],...
                    [0;a;a;0],colors(i,:),'linewidth',2);                   %Plot a bar for the bandpower.
                line((b-0.6+i*0.4)*[1,1],c,'linewidth',2,...
                    'color','k');                                           %Draw a vertical error bar.
%                 line((b-0.6+i*0.4)*[1,1],a+c*[-1,1],'linewidth',2,...
%                     'color','k');                                           %Draw a vertical error bar.
                line((b-0.6+i*0.4)+[-0.05,0.05],c(1)*[1,1],'linewidth',2,...
                    'color','k');                                           %Draw a bar across the upper error limit.
                line((b-0.6+i*0.4)+[-0.05,0.05],c(2)*[1,1],'linewidth',2,...
                    'color','k');                                           %Draw a bar across the lower error limit.
            end
        end
        axis tight;                                                         %Tighten the axes.
        xlim([0,size(bws,1)+1]);                                            %Set the x axis limits.
        box on;                                                             %Turn on a bounding box for the plot.
        temp = get(gca,'ylim');                                             %Grab the y axis limits.
        ylim(temp + [-0.05,0.15]*range(temp));                              %Add a small space to the top and bottom of the plot.
        a = temp(2) + 0.1*range(temp);                                      %Set a y-coordinate for plotting signficance markers.
        for b = 1:size(bws,1)                                               %Step through each of the EEG bands.
            for i = 1:2                                                     %Step through the CATCH and MAX sweeps.
                if s(i,b) < alpha                                           %If the bandpower change is signficantly different from zero...
                    p(3) = plot(b-0.6+i*0.4,a,'*k');                        %Plot a black asterix above all significant changes.
                end
            end
        end
        set(gca,'xtick',1:size(bws,1),'xticklabel',bandlabels,...
            'fontweight','bold','fontsize',12);                             %Make the x axis ticks bold and 12 point font.
        ylabel('Power Change (%)','fontweight','bold','fontsize',12);       %Label the y axis.
        if p(3) == 0                                                        %If there are no significant comparisons...
            a = legend(p(1:2),{'POST: 0 \muA','POST: Max. VNS'},...
                'location','best');                                         %Create a legend on the plot without showing the asterix.
        else                                                                %Otherwise, if there are significant comparisons...
            a = legend(p,{'POST: 0 \muA','POST: Max. VNS',...
                ['MPSR \itp \rm\bf< ' num2str(alpha)]},'location','best');  %Create a legend on the plot showing the asterix.
        end
        set(a,'fontsize',12','fontweight','bold');                          %Set the font size and font weight on the legend.
        set(gca,'ygrid','on');                                              %Turn on the y-axis grid.
        hold off;                                                           %Release the plot hold.
        drawnow;                                                            %Finish drawing the current plot before starting another.        
    end
    
    output(f).file = files(f).name;                                         %Save the filename in the output structure.
    output(f).bands = bws;                                                  %Save the EEG bands as a field in the output structure.
    output(f).param.name = param_names;                                     %Save the parameter names.
    output(f).param.value = unique(params,'rows');                          %List the unique parameter combinations in the output structure.
    output(f).banddata = zeros(size(output(f).param.value,1),size(bws,1));  %Pre-allocate a matrix to hold median bandpower changes for each parameter combination.
    for i = 1:size(output(f).param.value,1)                                 %Step through each parameter combination.
        a = output(f).param.value(i,:);                                     %Grab the current parameter combination.
        temp = zeros(size(params,1),1);                                     %Create a temporary matrix to check sweeps.
        for j = 1:size(params,1)                                            %Step through each sweep.
            temp(j) = isequal(params(j,:),a);                               %Check to see if each sweep has the current sweep parameters.
        end
        temp = banddata(temp == 1,:);                                       %Grab the bandpower change data for these sweeps.
        output(f).change(i,:) = nanmedian(temp,1);                          %Save the median bandpower change for this parameter combination.
    end
end

if nargout > 1                                                              %If the user asked for a first output argument...
    varargout{1} = output;                                                  %The first optional argument out will be the individual bandpower changes.
end
banddata = [];                                                              %Clear out the banddata matrix.
banddata.values = pop_banddata;                                             %Save population EEG bandpower change data as a field of a structure.
banddata.bands = bws;                                                       %Save the EEG bands as another field in the structure.
if nargout > 1                                                              %If the user asked for a second output argument...
    varargout{2} = banddata;                                                %The second optional argument out will be the population EEG bandpower changes.
end
popfft.pre = pop_pre_fft./pop_pre_N;                                        %Divide the PRE population mean FFT by the sample counter to find the mean.
popfft.catch = pop_catch_fft./pop_catch_N;                                  %Divide the CATCH population mean FFT by the sample counter to find the mean.
popfft.max = pop_max_fft./pop_max_N;                                        %Divide the MAX population mean FFT by the sample counter to find the mean.
a = find(freq_list <= min(bws(:,1)),1,'last');                              %Find the sample in the mean FFT approximately at the left-most EEG band bound.
popfft.freqs = freq_list(a:nfft_save);                                      %Attach the FFT frequencies to the FFT structure.
if nargout > 2                                                              %If the user asked for three output arguments...
    varargout{3} = popfft;                                                  %The third optional argument out will be the population PRE, CATCH, and MAX FFTs.
end