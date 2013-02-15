function quick_aer(varargin)

%
%QUICK_AER.m - Rennaker Neural Engineering Lab, 2010
%
%   QUICK_AER has the user select an *.LFP file and then creates a pooled 
%   average evoked response (AER) from the local field potentials.
%
%   QUICK_AER(file,...) creates a pooled AER for each file specified.  The 
%   variable "file" can either be a single string or a cell array of 
%   strings containing file names.
%
%   QUICK_AER(smoothsize,...) creates a pooled AER smoothing with a longer
%   time bin specified by "smoothsize", an integer number of milliseconds.
%
%   Last updated May 19, 2011, by Drew Sloan.


smoothsize = 1;                         %Set the smoothing bin size to a default of 1 ms.
if length(varargin) > 2                 %If the user entered too many arguments, show an error.
    error('Too many input arguments for QUICK_AER!  Inputs should be a filename string, or cell array of filename strings, and/or an integer smoothing size.');
end
for i = 1:length(varargin)
    temp = varargin{i};                 %Pull the variable out of the input argument.
    if ischar(temp)                     %If the argument is a string...
        files(1).name = temp;           %Save the filename as a string.
    elseif iscell(temp)                         %If the argument is a cell...
        for j = 1:length(temp)                  %Step through the filenames....
            files(j).name = cell2mat(temp(j));  %And save the filenames in a structure.
        end
    elseif isnumeric(temp)                      %If the argument is a number...
        smoothsize = temp;                      %The user has specified a smoothsize.
        if length(smoothsize) > 1 || smoothsize < 1   %If the bin size isn't a single integer or is less than 1, show an error.
            error('Smooth size input must be a single integer greater than or equal to 1!');
        end
    else            %If the input isn't a cell, string, or number, show an error.
        error(['Input argument #' num2str(i) ' is not recognized in QUICK_AER!  Inputs should be a filename string, or cell array of filename strings, and/or an integer smoothing size.']);
    end
end
if ~exist('files','var')      %If the user hasn't specified an input file...
    [temp path] = uigetfile({'*.LFP';'*.dam'},'multiselect','on');   %Have the user pick an input file or files.
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

%Now step through each filename and create a STLFPD and pooled AER for each.
for i = 1:length(files)
    if ~exist(files(i).name,'file')
        error([files(i).name ' doesn''t exist!']);
    end
    if ~any([strfind(files(i).name,'.LFP'),strfind(files(i).name,'.dam')]);
        error([files(i).name ' is not an *.LFP or *.dam file!']);
    end
    if any(strfind(files(i).name,'.LFP'))                 	%If this is an LFP file...
        data = LFPFileRead(files(i).name);                	%Use LFPFileRead to read the *.LFP file.
    else                                                    %Otherwise, if this is a *.dam file...
        data = damFileRead(files(i).name);                  %Use damFileRead to read the *.dam file.
    end
%     spont_delay = data(1).stim(length(data(1).stim));     %The spontaneous delay is always the last parameter.
    if isfield(data.stim,'sweeplength');                    %If sweeplength is a field in the data structure...
        sweeplength = 1000*data.stim(1).sweeplength;     	%...grab the first stimulus sweeplength and assume all sweeps will have the same sweeplength.
    else                                                    %If sweeplength isn't in the data structure...
        sweeplength = size(data.stim(1).lfp,2);             %...just assume the sampling rate is 1000 Hz.
    end
    stlfpd = zeros(length(data.stim),sweeplength-1);          %Pre-allocate a matrix to hold the STLFPD.
    aer = zeros(1,sweeplength-1);                         	%Pre-allocate a matrix to hold the AER as a sum of LFPs.
    aer_n = 0;                                              %To find average evoked responses, we'll have to keep track of the total number of sweeps.
    for j = 1:length(data.stim)                          	%Step through each stimulus...
        stlfpd(j,:) = mean(data.stim(j).lfp(:,1:end-1),1); 	%Save the AER specific to this stimulus.
        aer = aer + sum(data.stim(j).lfp(:,1:end-1),1);    	%Add the local field potentials to the overall sum.
        aer_n = aer_n + size(data.stim(j).lfp,1);         	%Add this stimulus's sweep count to the total number of sweeps.
    end
    fig = figure;               %Create a new figure for each file.
    temp = get(fig,'position'); %Find the current position of the figure.
    set(fig,'position',[temp(1),temp(2)-0.5*temp(4),temp(3),1.5*temp(4)]);	%Make the figure 50% taller than the default.
    set(fig,'color','w');       %Set the background color on the figure to white.
    subplot(3,1,1:2);           %Plot the STLFPD as the top 2/3rds of the figure.
    a = find(files(i).name == '\',1,'last');        %Find the last forward slash in the filename.
    b = find(files(i).name == '.',1,'last');        %Find the last period in the filename.
    if isempty(a)                                   %If there's no directory name in this filename...
        set(fig,'name',files(i).name(1:b-1));       %Set the filename as the figure title.
        disp(['Calculating STLFPD and pooled AER for ' files(i).name(1:b-1) '.']);
    else                                            %Otherwise...
        set(fig,'name',files(i).name(a+1:b-1));    	%Set the filename minus the directory as the figure title.
        disp(['Calculating STLFPD and pooled AER for ' files(i).name(a+1:b-1) '.']);
    end
    temp = boxsmooth(stlfpd,[1 smoothsize]);   	%Boxsmooth the spikerates in the STLFPD by row.
    temp = [[temp, zeros(size(temp,1),1)]; zeros(1,size(temp,2)+1)];    %Pad the edges with zeros so it shows the whole STLFPD.
    surf(temp,'edgecolor','none');                  %Plot the STLFPD as a surface plot.
%     colormap(flipud(gray(500)));                  %Color the surface with a flipped grayscale.
    colormap(flipud(jet));                      	%Color the surface with an inverted jet colorscale.
    view(0,90);                                     %Rotate the plot to look straight down at it.
    axis tight;                                     %Tighten up the axes.
    xlim([1,sweeplength+1]);                        %Set the limits of the x-axis to the sweeplength.
    ylim([1,length(data.stim)+1]);                  %Set the limits of the y-axis to the number of stimuli.
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
    subplot(3,1,3);                         %Plot the pooled AER as the bottom 1/3rd of the figure.
    aer = 1000000*aer/aer_n;                  	%Find the average spikerate by dividing by the total number of sweeps.
    if smoothsize >1                        %If the user has specified a bin size larger than 1 ms...
        aer = boxsmooth(aer,smoothsize);    %Box smooth the AER.
    end
    plot(aer,'color','k','linewidth',2);   	%Plot the pooled AER as an area plot.
    axis tight;                             %Tighten the plot around the AER.
    xlim([0,sweeplength]);                  %Set the x-axis limits to the sweeplength.
    line([0,sweeplength],[0,0],'color','k','linestyle','--');    %Put a dashed line to show zero voltage.
    ylim(get(gca,'ylim') + [-0.1,0.1]*range(get(gca,'ylim')));    %Adjust the y limits to put a little space at the bottom and the top.
    box on;                                %Turn off the plot box.
    ylabel('evoked response (\muV)');       	%Label the y-axis.
    xlabel('sweep time (ms)');              %Label the x-axis.
    drawnow;                                %Finish drawing the current plot before starting another.
end