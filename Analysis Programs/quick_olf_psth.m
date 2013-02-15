function quick_olf_psth(varargin)

%
%QUICK_OLF_PSTH.m - Rennaker Neural Engineering Lab, 2011
%
%   QUICK_OLF_PSTH has the user select an *.f32 file from a neural
%   recording session with olfactory stimuli and then segments the
%   responses to odor sequences into responses to individual odors in the
%   sequence and creates an STRF and a pooled PSTH from those spike times.
%
%   QUICK_OLF_PSTH(file,...) creates a pooled PSTH for each file specified.  The 
%   variable "file" can either be a single string or a cell array of 
%   strings containing file names.
%
%   QUICK_OLF_PSTH(binsize,...) creates a pooled PSTH smoothing with a longer
%   time bin specified by "binsize", an integer number of milliseconds.
%
%   Last updated December 14, 2012, by Drew Sloan.



binsize = 20;                                                              %Set the default smoothing bin size to 150 ms.
if length(varargin) > 2                                                     %If the user entered too many arguments, show an error.
    error('Too many input arguments for QUICK_OLF_PSTH!  Inputs should be a filename string, or cell array of filename strings, and/or an integer bin size.');
end
for i = 1:length(varargin)
    temp = varargin{i};                 %Pull the variable out of the input argument.
    if ischar(temp)                     %If the argument is a string...
        files(1).name = temp;           %Save the filename as a string.
    elseif iscell(temp)                	%If the argument is a cell...
        for j = 1:length(temp)          %Step through the filenames....
            files(j).name = cell2mat(temp(j));  %And save the filenames in a structure.
        end
    elseif isnumeric(temp)                  %If the argument is a number...
        binsize = temp;                     %The user has specified a binsize.
        if length(binsize) > 1 || binsize < 1   %If the bin size isn't a single integer or is less than 1, show an error.
            error('Bin size input must be a single integer greater than or equal to 1!');
        end
    else            %If the input isn't a cell, string, or number, show an error.
        error(['Input argument #' num2str(i) ' is not recognized in QUICK_OLF_PSTH!  Inputs should be a filename string, or cell array of filename strings, and/or an integer bin size.']);
    end
end
if ~exist('files','var')      %If the user hasn't specified an input file...
    [temp path] = uigetfile('*.f32','multiselect','on');   %Have the user pick an input file or files.
    cd(path);                         	%Change the current directory to the folder that file is in.
    if iscell(temp)                     %If the user's picked multiple files...
        for i = 1:length(temp)          %Step through each selected file.
            files(i).name = [path temp{i}];     %Save the file names in a structure.
        end
    elseif ischar(temp)                	%If only one file is selected...
        files(1).name = [path temp];    %Add the path to the filename.
    elseif isempty(temp)                %If no file is selected...
        error('No file selected!');     %Show an error message.
    end
end

fig = figure;                                                               %Create a new figure.

low_pass_cutoff = 12;                                                       %Kick out any breathing faster than 12 Hz.

%Now step through each filename and create a STSAD and pooled PSTH for each.
for f = 1:length(files)                                                     %Step through each selected *.f32 file.
    if ~exist(files(f).name,'file')                                         %If the selected file doesn't exist...
        error([files(f).name ' doesn''t exist!']);                          %Show an error.
    end
    if ~any(strfind(files(f).name,'.f32'));                                 %If the selected file isn't an *.f32 file...
        error([files(f).name ' is not an *.f32 file!']);                    %Show an error.
    end
    data = f32FileRead(files(f).name);                                      %Use f32FileRead to read the *.f32 file.
%     temp = dir('*.RESP');                                                   %Grab all of the respiration files in the folder.
%     for i = 1:length(temp)                                                  %Step through each respiration file.
%         temp(i).match = strfind(files(f).name,temp(i).name(1:end-5));       %Check to see if the respiration file matches the *.f32 files.
%         temp(i).match = ~isempty(temp(i).match);                            %Mark the respiration file as matching if any *.f32 files match.
%     end
%     resp_file = temp(find([temp.match] == 1,1,'first')).name;               %Grab the first respiration file that matches the *.f32 files.
%     resp = RESPFileRead(resp_file);                                         %Read in the respiration file data.
%     [b,a] = butter(2,low_pass_cutoff*2/resp.sampling_rate,'low');           %Create low-pass butterworth filter coefficients.
%     filter_coefs = [b; a];                                                  %Save the filter coefficients.
%     for i = 1:length(resp.stim)                                             %Step through each stimulus in the respiration signal.
%         for j = 1:size(resp.stim(i).signal,1)                               %Step through each sweep of the respiration signal.
%             signal = resp.stim(i).signal(j,:);                              %Grab the respiration signal for this sweep.
%             signal = [repmat(signal(1),1,500), signal,...
%                 repmat(signal(length(signal)),1,500)];                      %Add 500 sample "tails" to the beginning and end of the signal.
%             signal = filtfilt(filter_coefs(1,:),filter_coefs(2,:),...
%                 double(signal));                                            %Apply the passband filter.
%             signal = single(signal(501:(length(signal)-500)));              %Removing the "tails".
%             resp.stim(i).signal(j,:) = signal;                              %Overwrite the filtered signal back to the structure.
%         end
%     end
%     j = 1;                                                                  %Start a counter to count through the respiration file.
%     exclude = zeros(1,length(resp.stim));                                   %Create a list to mark each sweep for exclusion.
%     params = vertcat(resp.param.value);                                     %Concatenate all of the parameters in the respiration file.
%     for i = 1:length(data)                                                  %Step through each sweep in the data structure.
%         temp = params(:,j)-data(i).params(1:end-1);                         %Subtract the respiration sweep parameters from the *.f32 sweep parameters.
%         while ~all(isnan(temp) | temp == 0)  && j < length(resp.stim)       %If the sweeps don't match...
%             exclude(j) = 1;                                                 %Mark this respiration sweep for exclusion.
%             j = j + 1;                                                      %Increment the respiration sweep counter.
%             temp = params(:,j)-data(i).params(1:end-1);                     %Subtract the respiration sweep parameters from the *.f32 sweep parameters.
%         end
%         j = j + 1;                                                          %Increment the sweep counter.
%     end
%     resp.stim(exclude == 1) = [];                                           %Kick out all excluded sweeps.
    params = horzcat(data.params)';                                         %Make a matrix of the stimulus parameters.
    odorlist = params(:,10:end-1);                                          %Grab all the odors presented to the rat.
    odorlist = unique(odorlist(~isnan(odorlist)));                          %Grab all the unique non-NaN odor numbers.
    numodors = length(odorlist);                                            %Find the number of odors.
    spont_delay = params(1,end);                                            %Grab the spontaneous recording delay, which is always the last parameter.
    dur = params(1,8);                                                      %Grab the odor duration.
    isi = params(1,9);                                                      %Grab the ISI.
    if size(params,2) == 11                                                 %If there's only one odor per trial...
        sweeplength = data(1).sweeplength;                                  %Set the sweeplength to the spontaneous delay plus the ISI.
        isi = sweeplength;                                                  %Set the ISI to the sweeplength.
    else                                                                    %Otherwise, if there's odor trains on each trial...
        sweeplength = spont_delay + isi;                                    %Set the sweeplength to the spontaneous delay plus the ISI.
    end
    stsad = zeros(numodors,sweeplength);                                    %Pre-allocate a matrix to hold an STSAD.
    stsad_n = zeros(numodors,1);                                            %Make a counter to count the sweeps for each odor.
    psth = zeros(1,sweeplength);                                            %Pre-allocate a matrix to hold the PSTH as a sum of spikecounts.
    psth_n = 0;                                                             %To find average spikerates, we'll have to keep track of the total number of sweeps.
    for i = 1:length(data)                                                  %Step through each stimulus...
        numsweeps = length(data(i).sweep);                                  %We'll need to know the number of sweeps for plotting.
        for j = 1:numsweeps                                                 %Step through each sweep...
            for k = 0:isi:data(i).sweeplength - sweeplength                 %Step through each odor.
                if ~isempty(data(i).sweep(j).spikes);                       %If there are any spikes in this sweep...
                    temp = histc(data(i).sweep(j).spikes,k:k+sweeplength);  %Calculate a millisecond-scale histogram for this sweep.
                else                                                        %Otherwise, if there are no spikes in this sweep...
                    temp = zeros(1,sweeplength);                            %Make a temporary PSTH of zeros for this sweep.
                end
                o = k/isi + 1;                                              %Find the order of the current odor in the sequence.
                o = params(i,9+o);                                          %Find the valve number for this odor.
                o = (o == odorlist);                                        %Find the index for this odor in the odorlist.
                
%                 set(0,'currentfigure',fig);
%                 subplot(2,1,1);
%                 plot(1000*boxsmooth(temp,100));
%                 line(spont_delay*[1,1],ylim,'color','g');
%                 line(spont_delay*[1,1]+ 800,ylim,'color','r');              %end of odor presentation for AWAKE recordings
% %                 line(spont_delay*[1,1]+ 2000,ylim,'color','r');             %end of odor presentation for ANES recordings
%                 title(['Trial ' num2str(i) ', Odor ' num2str(1+(k/isi)) ', Valve #' num2str(find(o))]);       
%                 subplot(2,1,2); 
%                 title('Respiration');
%                 a = [round(resp.sampling_rate*k/1000)+1,round(resp.sampling_rate*(k+sweeplength)/1000)-1];
%                 plot(resp.stim(i).signal(j,a(1):a(2)));               
%                 line(resp.sampling_rate*spont_delay*[1,1]/1000,ylim,'color','g');
%                 subplot(2,1,2);
% %                 line(resp.sampling_rate*spont_delay*[1,1]/1000,ylim,'color','r');
%                 set(gca,'xticklabel',1000*get(gca,'xticklabels')/resp.sampling_rate);
%                 waitforbuttonpress;

                stsad(o,:) = stsad(o,:) + temp(1:sweeplength);              %Add the histogram to the STSAD.
                stsad_n(o) = stsad_n(o) + 1;                                %Add one to the sweep counter for this odor in the STSAD.
                psth = psth + temp(1:sweeplength);                          %Add the histogram to the pooled PSTH.
                psth_n = psth_n + numsweeps;                                %Add one to the sweep counter for the PSTH.
            end            
        end
    end
    for o = 1:size(stsad)                                                   %Step through each odor in the STSAD.
        stsad(o,:) = stsad(o,:)/stsad_n(o);                                 %Divide the sum PSTH for this odor by the sweep count to find the mean PSTH.
    end
    fig = figure;                                                           %Create a new figure for each file.
    temp = get(fig,'position');                                             %Find the current position of the figure.
    set(fig,'position',[temp(1),temp(2)-0.5*temp(4),temp(3),1.5*temp(4)]);  %Make the figure 50% taller than the default.
    set(fig,'color','w');                                                   %Set the background color on the figure to white.
    subplot(3,1,1:2);                                                       %Plot the STSAD as the top 2/3rds of the figure.
    a = find(files(f).name == '\',1,'last');                                %Find the last forward slash in the filename.
    b = find(files(f).name == '.',1,'last');                                %Find the last period in the filename.
    if isempty(a)                                                           %If there's no directory name in this filename...
        set(fig,'name',files(f).name(1:b-1));                               %Set the filename as the figure title.
        disp(['Calculating STSAD and pooled PSTH for ' ...
            files(f).name(1:b-1) '.']);
    else                                                                    %Otherwise...
        set(fig,'name',files(f).name(a+1:b-1));                             %Set the filename minus the directory as the figure title.
        disp(['Calculating STSAD and pooled PSTH for ' ...
            files(f).name(a+1:b-1) '.']);
    end
    temp = boxsmooth(stsad,[1 binsize]);                                    %Boxsmooth the spikerates in the STSAD by row.
    imagesc(temp);                                                          %Plot the STSAD as a surface plot.
    colormap(jet);                                                          %Color the surface with a jet colorscale.
    axis tight;                                                             %Tighten up the axes.
    set(gca,'ydir','normal');                                               %Set the y-axis direction to normal.
    temp = get(gca,'xtick');                                                %Grab the auto-set x-ticks.
    set(gca,'xtick',temp,'xticklabel',temp-spont_delay);                    %Label the x-ticks with time minus the spontaneous delay.
    set(gca,'ytick',1:length(odorlist),'yticklabel',odorlist);              %Set the y-axis ticks.
    box on;                                                                 %Put a box around the plot.
    ylabel('odor valve number');                                            %Label the y-axis.
    a = find(files(f).name == '\',1,'last');                                %Find the last forward slash in the filename.
    b = find(files(f).name == '.',1,'last');                                %Find the last period in the filename.
    if isempty(a)                                                           %If there's no directory name in this filename...
        title(files(f).name(1:b-1),'fontweight','bold','interpreter',...
            'none');                                                        %Set the filename as this subplot's title.
    else                                                                    %Otherwise...
        title(files(f).name(a+1:b-1),'fontweight','bold','interpreter',...
            'none');                                                        %Set the filename as this subplot's title.
    end
    subplot(3,1,3);                                                         %Plot the pooled PSTH as the bottom 1/3rd of the figure.
    psth = 1000*psth/psth_n;                                                %Find the average spikerate by dividing by the total number of sweeps.
    if binsize > 1                                                          %If the user has specified a bin size larger than 1 ms...
        psth = boxsmooth(psth,binsize);                                     %Box smooth the PSTH.
    end
    area(psth,'facecolor','k');                                             %Plot the pooled PSTH as an area plot.
    axis tight;                                                             %Tighten the plot around the PSTH.
    xlim([0,sweeplength]);                                                  %Set the x-axis limits to the sweeplength.
    box off;                                                                %Turn off the plot box.
    ylabel('spikerate (spks/s)');                                           %Label the y-axis.
    xlabel('sweep time (ms)');                                              %Label the x-axis.
%     saveas(fig,files(f).name(a+1:b-1),'png')                                %Save figure into parent folder
    drawnow;                                                                %Finish drawing the current plot before starting another.
end