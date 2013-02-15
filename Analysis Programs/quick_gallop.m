function quick_gallop(varargin)

%
%QUICK_GALLOP.m - Rennaker Neural Engineering Lab, 2010
%
%   QUICK_GALLOP has the user select an *.f32 file and then creates a pooled 
%   PSTH from those spike times.
%
%   QUICK_GALLOP(file,...) creates a pooled PSTH for each file specified.  The 
%   variable "file" can either be a single string or a cell array of 
%   strings containing file names.
%
%   QUICK_GALLOP(binsize,...) creates a pooled PSTH smoothing with a longer
%   time bin specified by "binsize", an integer number of milliseconds.
%
%   Last updated November 22, 2010, by Drew Sloan.


binsize = 5;                                                                %Set the smoothing bin size to 5 ms.
if length(varargin) > 2                                                     %If the user entered too many arguments, show an error.
    error('Too many input arguments for QUICK_GALLOP!  Inputs should be a filename string, or cell array of filename strings, and/or an integer bin size.');
end
for i = 1:length(varargin)
    temp = varargin{i};                                                     %Pull the variable out of the input argument.
    if ischar(temp)                                                         %If the argument is a string...
        files(1).name = temp;                                               %Save the filename as a string.
    elseif iscell(temp)                                                     %If the argument is a cell...
        for j = 1:length(temp)                                              %Step through the filenames....
            files(j).name = cell2mat(temp(j));                              %And save the filenames in a structure.
        end
    elseif isnumeric(temp)                                                  %If the argument is a number...
        binsize = temp;                                                     %The user has specified a binsize.
        if length(binsize) > 1 || binsize < 1                               %If the bin size isn't a single integer or is less than 1, show an error.
            error('Bin size input must be a single integer greater than or equal to 1!');
        end
    else                                                                    %If the input isn't a cell, string, or number, show an error.
        error(['Input argument #' num2str(i) ' is not recognized in QUICK_GALLOP!  Inputs should be a filename string, or cell array of filename strings, and/or an integer bin size.']);
    end
end
if ~exist('files','var')                                                    %If the user hasn't specified an input file...
    [temp path] = uigetfile('*GALLOP*.f32','multiselect','on');             %Have the user pick an input file or files.
    cd(path);                                                               %Change the current directory to the folder that file is in.
    if iscell(temp)                                                         %If the user's picked multiple files...
        for i = 1:length(temp)                                              %Step through each selected file.
            files(i).name = [path temp{i}];                                 %Save the file names in a structure.
        end
    elseif ischar(temp)                                                     %If only one file is selected...
        files(1).name = [path temp];                                        %Add the path to the filename.
    elseif isempty(temp)                                                    %If no file is selected...
        error('No file selected!');                                         %Show an error message.
    end
end

%Now step through each filename and create a STSAD and pooled PSTH for each.
for i = 1:length(files)
    if ~exist(files(i).name,'file')
        error([files(i).name ' doesn''t exist!']);
    end
    if ~any(strfind(files(i).name,'.f32'));
        error([files(i).name ' is not an *.f32 file!']);
    end
    data = f32FileRead(files(i).name);                   %Use f32FileRead to read the *.f32 file.
%     spont_delay = data(1).stim(length(data(1).stim));   %The spontaneous delay is always the last parameter.
    sweeplength = data(1).sweeplength;                  %All sweeps will have the same sweeplength.
    stsad = zeros(length(data),sweeplength);            %Pre-allocate a matrix to hold an STSAD.
    psth = zeros(1,sweeplength);                        %Pre-allocate a matrix to hold the PSTH as a sum of spikecounts.
    psth_n = 0;                                     	%To find average spikerates, we'll have to keep track of the total number of sweeps.
    for j = 1:length(data)      %Step through each stimulus...
        numsweeps = length(data(j).sweep);      %We'll need to know the number of sweeps for plotting.
        for k = 1:numsweeps                     %Step through each sweep...
            if ~isempty(data(j).sweep(k).spikes);                       %If there are any spikes in this sweep...
                temp = histc(data(j).sweep(k).spikes,0:sweeplength);    %Calculate a millisecond-scale histogram for this sweep.
                data(j).sweep(k).spikes = [];               %Pare down the data structure as we work through it to save memory.
                psth = psth + temp(1:sweeplength);                      %Add the histogram to the pooled PSTH.
                stsad(j,1:sweeplength) = stsad(j,1:sweeplength) + temp(1:sweeplength);	%Add the histogram to the STSAD.
            end
            
        end
        psth_n = psth_n + numsweeps;                    %Add a count to the total number of sweeps regardless of if there spikes.
        stsad(j,1:sweeplength) = stsad(j,1:sweeplength)/numsweeps;  %Divide spike count by the number of sweeps to find spikerate.
    end
    fig = figure;               %Create a new figure for each file.
    temp = get(fig,'position'); %Find the current position of the figure.
    set(fig,'position',[temp(1),temp(2)-0.5*temp(4),temp(3),1.5*temp(4)]);	%Make the figure 50% taller than the default.
    set(fig,'color','w');       %Set the background color on the figure to white.
    subplot(3,1,1:2);           %Plot the STSAD as the top 2/3rds of the figure.
    a = find(files(i).name == '\',1,'last');        %Find the last forward slash in the filename.
    b = find(files(i).name == '.',1,'last');        %Find the last period in the filename.
    if isempty(a)                                   %If there's no directory name in this filename...
        set(fig,'name',files(i).name(1:b-1));       %Set the filename as the figure title.
        disp(['Calculating STSAD and pooled PSTH for ' files(i).name(1:b-1) '.']);
    else                                            %Otherwise...
        set(fig,'name',files(i).name(a+1:b-1));    	%Set the filename minus the directory as the figure title.
        disp(['Calculating STSAD and pooled PSTH for ' files(i).name(a+1:b-1) '.']);
    end
    temp = boxsmooth(stsad,[1 binsize]);   	%Boxsmooth the spikerates in the STSAD by row.
    temp = [[temp, zeros(size(temp,1),1)]; zeros(1,size(temp,2)+1)];    %Pad the edges with zeros so it shows the whole STSAD.
    surf(temp,'edgecolor','none');          %Plot the STSAD as a surface plot.
%     colormap(flipud(gray(500)));            %Color the surface with a flipped grayscale.
    colormap(jet);                          %Color the surface with a jet colorscale.
    view(0,90);                             %Rotate the plot to look straight down at it.
    axis tight;                             %Tighten up the axes.
    xlim([1,sweeplength+1]);                %Set the limits of the x-axis to the sweeplength.
    ylim([1,length(data)+1]);               %Set the limits of the y-axis to the number of stimuli.
    temp = unique(floor(get(gca,'xtick')));         %Grab the auto-set x-ticks.
    set(gca,'xtick',temp+0.5,'xticklabel',temp);    %Shift the x-ticks 0.5 and label with time minus the spontaneous delay.
    temp = unique(floor(get(gca,'ytick')));         %Grab the auto-set y-ticks.
    set(gca,'ytick',temp+0.5,'yticklabel',temp);  	%Shift the y-ticks 0.5 and label with stimulus indices.
    box on;                                 %Put a box around the plot.
    ylabel('stimulus index');               %Label the y-axis.
    a = find(files(i).name == '\',1,'last');        %Find the last forward slash in the filename.
    b = find(files(i).name == '.',1,'last');        %Find the last period in the filename.
    if isempty(a)                                   %If there's no directory name in this filename...
        title(files(i).name(1:b-1),'fontweight','bold','interpreter','none');   %Set the filename as this subplot's title.
    else                                            %Otherwise...
        title(files(i).name(a+1:b-1),'fontweight','bold','interpreter','none'); %Set the filename as this subplot's title.
    end
    subplot(3,1,3);                     %Plot the pooled PSTH as the bottom 1/3rd of the figure.
    psth = 1000*psth/psth_n;          	%Find the average spikerate by dividing by the total number of sweeps.
    if binsize >1                       %If the user has specified a bin size larger than 1 ms...
        psth = boxsmooth(psth,binsize); %Box smooth the PSTH.
    end
    area(psth,'facecolor','k');         %Plot the pooled PSTH as an area plot.
    axis tight;                         %Tighten the plot around the PSTH.
    xlim([0,sweeplength]);              %Set the x-axis limits to the sweeplength.
    box off;                            %Turn off the plot box.
    ylabel('spikerate (spks/s)');       %Label the y-axis.
    xlabel('sweep time (ms)');          %Label the x-axis.
    drawnow;                            %Finish drawing the current plot before starting another.
end