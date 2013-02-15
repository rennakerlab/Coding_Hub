function quick_startle_plot(varargin)

%
%QUICK_STARTLE_PLOT.m - Rennaker Neural Engineering Lab, 2010
%
%   QUICK_STARTLE_PLOT has the user select an *.STARTLE file and then
%   plots cued and uncued startle amplitudes organized by cue stimulus.
%
%   QUICK_STARTLE_PLOT(file,...) creates a cued vs. uncued plot for each
%   file specified.  The variable "file" can either be a single string of a
%   cell array of strings containing file names.
%
%   QUICK_STARTLE_PLOT(alpha,...) uses the significance level specified by
%   "alpha" when statistically comparing cued and uncued startle responses.
%   The default significance level is 0.05.
%
%   Last updated March 11, 2010, by Drew Sloan.

alpha = 0.05;                       %Confidence level for significance tests.
if length(varargin) > 2             %If the user entered too many arguments, show an error.
    error('Too many input arguments for QUICK_STARTLE_PLOT!  Inputs should be a filename string, or cell array of filename strings, and/or a significance level.');
end
for i = 1:length(varargin)
    temp = varargin{i};                 %Pull the variable out of the input argument.
    if ischar(temp)                     %If the argument is a string...
        files(1).name = temp;           %Save the filename as a string.
    elseif iscell(temp)                	%If the argument is a cell...
        for j = 1:length(temp)          %Step through the filenames....
            files(j).name = cell2mat(temp(j));  %And save the filenames in a structure.
        end
    elseif isnumeric(temp)             	%If the argument is a number...
        alpha = temp;                 	%The user has specified a binsize.
        if length(alpha) > 1 || alpha > 1 || alpha < 0      %If the alpha isn't a single number between 0 and 1, show an error.
            error('Bin size input must be a single value between 0 and 1!');
        end
    else            %If the input isn't a cell, string, or number, show an error.
        error(['Input argument #' num2str(i) ' is not recognized in QUICK_STARTLE_PLOT!  Inputs should be a filename string, or cell array of filename strings, and/or a significance level.']);
    end
end
if ~exist('files','var')      %If the user hasn't specified an input file...
    [temp path] = uigetfile('*.STARTLE','multiselect','on');   %Have the user pick an input file or files.
    cd(path);                         	%Change the current directory to the folder that file is in.
    if iscell(temp)                     %If the user's picked multiple files...
        for i = 1:length(temp)          %Step through each selected file.
            files(i).name = [path temp{i}];     %Save the file names in a structure.
        end
    elseif ischar(temp)                  %If only one file is selected...
        files(1).name = [path temp];    %Add the path to the filename.
    elseif isempty(temp)                %If no file is selected...
        error('No file selected!');     %Show an error message.
    end
end

%Now step through each filename and create a startle plot for each.
for i = 1:length(files)
    if ~exist(files(i).name,'file')                 %Check to make sure the input file exists.
        error([files(i).name ' doesn''t exist!']);
    end
    if ~any(strfind(files(i).name,'.STARTLE'));     %Check to make sure the input file is an *.STARTLE file.
        error([files(i).name ' is not an *.STARTLE file!']);
    end
    data = StartleFileRead(files(i).name);        	%Use StartleFileRead to read the *.STARTLE file.
    fig = figure;           %Create a new figure for each file.
    temp = get(fig,'position'); %Find the current position of the figure.
    set(fig,'position',[temp(1),temp(2)-0.5*temp(4),1.5*temp(3),temp(4)]);	%Make the figure 50% taller than the default.
    set(fig,'color','w');   %Set the background color on the figure to white.
    a = find(files(i).name == '\',1,'last');        %Find the last forward slash in the filename.
    b = find(files(i).name == '.',1,'last');        %Find the last period in the filename.
    if isempty(a)                                   %If there's no directory name in this filename...
        set(fig,'name',files(i).name(1:b-1));       %Set the filename as the figure title.
        disp(['Calculating startle results for ' files(i).name(1:b-1) '.']);
    else                                            %Otherwise...
        set(fig,'name',files(i).name(a+1:b-1));    	%Set the filename minus the directory as the figure title.
        disp(['Calculating startle results for ' files(i).name(a+1:b-1) '.']);
    end
    a = strmatch('Background Center Frequency (kHz)',{data.param(:).name});      %Find the stimuli column for center frequency.
    stimuli = vertcat(data.param(:).value)';        %Organize all the stimulus parameters.
    [stimuli,j] = sortrows(stimuli,a);             	%Sort the stimuli by rows.
    data.stim = data.stim(j);                       %Re-arrange the data structure to reflect the sorting.
    cueddata = zeros(2,length(data.stim));        	%Preallocate an array for cued response data.
    uncueddata = zeros(2,length(data.stim));      	%Preallocate an array for uncued response data.
    p = zeros(1,length(data.stim));                 %Preallocate an array to hold significance tests.
    b = ceil(data.sampling_rate*(data.startler_delay+(0:300))/1000);	%Find all samples in the 300 ms after the startler onset.
    for j = 1:length(data.stim);                   	%Step through the data by stimulus parameters.
        c = data.stim(j).signal(find(data.stim(j).predicted),b);            %Grab all predicted sweeps.
        c = range(c,2);                             %Find the max peak-to-peak excursion in each signal.
        cueddata(1,j) = mean(c);                    %Save the mean maximum excursion.
        cueddata(2,j) = simple_ci(c,alpha);        	%Save the confidence interval for excursion size.
        u = data.stim(j).signal(find(~data.stim(j).predicted),b);            %Grab all predicted sweeps.
        u = range(u,2);                             %Find the max peak-to-peak excursion in each signal.
        uncueddata(1,j) = mean(u);                 	%Save the mean maximum excursion.
        uncueddata(2,j) = simple_ci(u,alpha);      	%Save the confidence interval for excursion size.
        if length(c) == length(u)                   %If the sample sizes for cued and uncued responses are the same...
            p(j) = signrank(c,u,'alpha',alpha);     %...use an MPSR test to find significance.
        else                                        %Otherwise...
            [u,c] = ttest2(c,u,alpha);             	%...use a two-sample t-test to find signifance...
            p(j) = c;                               %...and save the p-value.
        end         
    end
    for j = 1:size(uncueddata,2)                                            %Step through each noise that was tested.
        cueddata(:,j) = cueddata(:,j)/uncueddata(1,j);                      %Normalize the cued response by the uncued response.
        uncueddata(:,j) = uncueddata(:,j)/uncueddata(1,j);                  %Normalize the uncued response by itself.
    end
    errorbar([cueddata(1,:)', uncueddata(1,:)'],[cueddata(2,:)', uncueddata(2,:)'],'linewidth',2);  %Plot the startle response means as error bars.
    box off;        %Get rid of the plot box.
    axis tight;     %Tighten the axes.
    xlim([0.5,length(data.stim)+0.5]);  %Set the x-axis limits.
    temp = get(gca,'ylim');             %Grab the current y-axis limits.
    ylim(temp + [-0.05,0.05]*range(temp));  %Slightly widen the y-axis limits.
    temp = {};                          %Create an empty matrix to hold x labels.
    for j = 1:length(data.stim)         %Step through all stimuli.
        if stimuli(j,a) == 0            %If this was broadband noise.
            temp{j} = 'BBN';            %...mark it as such.
        else                            %Otherwise...
            temp{j} = [num2str(stimuli(j,a)) 'kHz'];    %...indicate the center frequency.
        end
    end
    set(gca,'xtick',1:length(data.stim),'xticklabel',temp,'fontweight','bold');
    temp = get(gca,'ylim');             %Grab the current y-axis limits again.
    a = find(p < alpha);                %Find all significant comparisons.
    hold on;                            %Hold the plot.
    plot(a,repmat(max(temp),length(a)),'markerfacecolor','r','marker','*','markersize',10,'linestyle','none');  %Plot significance markers.
    hold off;                           %Release the plot.
    ylabel('Normalized Startle Amplitude','fontweight','bold','fontsize',12); %Label the y-axis.
    legend('Cued','Uncued','location','best','orientation','horizontal');   %Make a legend.
end