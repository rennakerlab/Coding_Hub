function varargout = NEL_Spike_Sorter_eric(varargin)

%
%NEL_Spike_Sorter.m - OU Neural Engineering Lab, 2008
%
%   NEL_Spike_Sorter is a GUI that allows an user to employ several
%   different spike-sorting methods to sort spikes stored in the NEL *.SPK
%   format, including super-paramagnetic clustering, PCA, window, and
%   template sorting methods.  Users also have the option of applying the
%   templates determined for one file to other associated files either by
%   loading the templates or by selecting files for batch sorting with the
%   template.
%
%   Last updated April 13, 2009, by Drew Sloan.

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @NEL_Spike_Sorter_OpeningFcn, ...
                   'gui_OutputFcn',  @NEL_Spike_Sorter_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


%**************************************************************************
%OPEN NEL_Spike_Sorter --- Executes just before NEL_Spike_Sorter is made visible.
function NEL_Spike_Sorter_OpeningFcn(hObject, eventdata, handles, varargin)
    %We'll declare these pathnames right at the top so we can change them easily.
    %First, we'll find out what the user name is for this computer's desktop.
    if exist('C:\Documents and Settings\user\Desktop','dir') == 7;
        handles.desktop = 'C:\Documents and Settings\user\Desktop';             %Path for data backups.
    elseif exist('C:\Documents and Settings\Owner\Desktop','dir') == 7
        handles.desktop = 'C:\Documents and Settings\Owner\Desktop';            %Path for data backups.
    elseif exist('C:\Documents and Settings\NEL_students\Desktop','dir') == 7
        handles.desktop = 'C:\Documents and Settings\NEL_students\Desktop';     %Path for data backups.
    elseif exist('C:\Documents and Settings\Drew\Desktop','dir') == 7
        handles.desktop = 'C:\Documents and Settings\Drew\Desktop';             %Path for data backups.
    elseif exist('C:\Documents and Settings\Doyle\Desktop','dir') == 7
        handles.desktop = 'C:\Documents and Settings\Doyle\Desktop';        %Path for data backups.
    elseif exist('C:\Documents and Settings\All Users\Desktop','dir') == 7
        handles.desktop = 'C:\Documents and Settings\All Users\Desktop';        %Path for data backups.
    end
    if exist('Z:\Pitch Discrimination')     %If the fileputer's connected.
        handles.rootpath = 'Z:';
    else                                    %If the fileputer's not connected.
        handles.rootpath = handles.desktop;
    end
    addpath([handles.rootpath '\Spike Sorting']);    %Add the program folder to the pathlist.
    addpath([handles.rootpath '\Analysis Programs']);       %Add the general NEL programs folder to the pathlist.
    if exist('E:\','dir') == 7
        handles.recordingpath = 'E:\';	%Main path for saving neural recordings, preferentially the secondary hard drive.
    else
        handles.recordingpath = 'C:\';
    end
    handles.load_sound = [handles.rootpath '\Spike Sorting\Load_Beep.wav']; %This sound will play to let the user know a file is loaded.
    % %We'll define some default terms up front, and then change them if the user specifies any different values.
    handles.max_radius = 3;    %The maximum radius of a cluster in standard deviations.
    handles.near_neigh = 10;   %The number of nearest neighbors.
    handles.min_nn = 10;       %The minimum number of nearest neighbors required for a vote.
    handles.template_type = 'CENTER';   %Method used to calculate distance to a template: nearest neighbor ('NN'), center ('CENTER'), gaussian ('GAUSS'), or mahalnobis ('MAHAL').
    % handles.feature = 'WAV';       %Feature to use for template matching: spike shape ('SPIKE') or wavelet coefficients ('WAV').
    handles.pointlimit = Inf;      %The limit on the number of points that can fall outside of a single dimension limit before excluding a template.    
    handles.mintemp = 0.00;             %Minimum temperature for SPC.
    handles.maxtemp = 0.201;            %Maximum temperature for SPC.
    handles.tempstep = 0.01;            %Temperature steps.
    handles.num_temp = floor((handles.maxtemp-handles.mintemp)/handles.tempstep);	%Total number of temperatures.
    handles.scales = 5;     %The number of scales used in the wavelet decomposition.
    handles.max_spikes = 25000;         %The maximum number of spikes to load up for visualization.
    handles.numplotspks = 500;          %The default number of spikeshapes allowed in plotting.
    handles.maxplotspks = 2000;         %The maximum number of spikeshapes allowed in plotting.
    handles.templates = [];             %Set up a field for templates.
    handles.windows = [];               %Set up a field for windows.
    handles.draw = [];                  %Set up a field for PCA user-drawn bounds.
    handles.template_type = 'CENTER';   %The default type for matching templates.
    axes(handles.picShapes);            %We'll put a message in the main plot asking the user to load an *.SPK file.
    set(gca,'xtick',[],'xtick',[],'color','k','xcolor','w','ycolor','w','yscale','linear'); 
    set(gca,'xlim',[-1 1],'ylim',[-1,1],'xticklabel',[],'yticklabel',[],'xtick',[],...
        'ytick',[],'color','k','xcolor','w','ycolor','w');    %Color the axes white and the background black.
    text(0,0,'Press "Load Shapes" to select an *.SPK file for sorting.','interpreter','none','fontweight','bold',...    
        'color','w','fontsize',16,'horizontalalignment','center','verticalalignment','middle'); %Show the "Load..." message.
    axes(handles.picSecondary);         %Also set the secondary plot to a blank black background.
    set(gca,'xtick',[],'ytick',[],'color','k','xcolor','w','ycolor','w','yscale','linear');
    cd(handles.recordingpath);          %Change the current directory to the neural recordings location.
    guidata(hObject, handles);          %Update handles structure

    
%**************************************************************************
%BUTTON PRESS ON cmdLoad --- Executes on button press in cmdLoad.
function cmdLoad_Callback(hObject, eventdata, handles)
    [file, path] = uigetfile('*.SPK');	%Select a *.SPK file to spike-sort.
    if file ~= 0	%If the user selected a file and didn't cancel...
        axes(handles.picShapes);        %We'll put a "Loading..." message in the main spikeshapes window.
        cla;    %Reset the spikeshapes plot to blank axes.
        set(gca,'xlim',[-1 1],'ylim',[-1,1],'xticklabel',[],'yticklabel',[],'xtick',[],...
            'ytick',[],'color','k','xcolor','w','ycolor','w','yscale','linear');
        text(0,0,['Loading: ' file],'interpreter','none','fontweight','bold',...    %Show the "Loading..." message.
            'color','w','fontsize',16,'horizontalalignment','center','verticalalignment','middle');
        drawnow;    %Refresh the axes before running the rest of the code.
        cd(path);   %Change to the *.SPK file's directory.
        handles.file = [path file];         %Save the full file name with path.
        handles.fileroot = [path file(1:length(file)-4)];   %Find the root file name.
        handles.SPC_clusters = [];      %Clear any SPC clusters left over from previous sorting.
        handles.SPC_tree = [];      	%Clear the SPC tree.
        handles.temperature = 1;        %Set an arbitrary initial temperature value.
        handles.PCs = [];               %Set up a field for PCA scores.
        handles.subthreshold = [];    	%Set up a field for resetting the threshold.
        handles = LoadSpikes(handles, hObject, 'Plot'); %Load only so many spikes as we need for plotting for now.        
        handles.sort_type = 'Undefined';	%We'll set the sort type to undefined at first.
        handles = PlotSpikes(handles, hObject);         %Plot the spikeshapes.
        if isempty(handles.templates)           %If no templates already exist for this file...
            handles = TemplateMaker(handles, hObject);  %Make templates based on existing sorting in the file.
        end
        if handles.numplotspks > handles.numspikes
            handles.numplotspks = handles.numspikes;
        end
        if handles.numspikes < handles.maxplotspks                  %If there's less than the maximum allowable spikeshapes for plotting...
            set(handles.hscNumPlotSpks,'Max',handles.numspikes);    %Set the slider limit to the total number of spikes.
        else        %Otherwise...
            set(handles.hscNumPlotSpks,'Max',handles.maxplotspks);  %Set the slider limit to the maximum.
        end
        set(handles.lblNumPlotSpks,'String',['Showing ' num2str(handles.numplotspks) ' Spikes']);
        set(handles.hscNumPlotSpks,'Value',handles.numplotspks);    %Set the slider to the default number of plotted spikeshapes.
        set(handles.hscMaxDist,'Max',5,'Min',0,'Value',handles.max_radius);       %Set the maximum radius slider to 0-5 standard deviations.
        if handles.pointlimit == Inf || size(handles.spikes,2) > handles.pointlimit  %If there's no point limit defined yet...
            handles.pointlimit = size(handles.spikes,2);	%Set the point limit initially to the total number of spike samples.
        end
        set(handles.hscPointLimit,'Max',handles.pointlimit,'Min',0,'Value',handles.pointlimit); %Set the point limit slider to the range of samples.
        %Set the strings on the max radius and point limit sliders.
        set(handles.hscMaxDist,'String',['Max. Radius = ' num2str(roundn(handles.max_radius,-2)) ' std']);
        set(handles.hscMaxDist,'String',['Point Limit = ' num2str(handles.pointlimit) ' std']);
        axes(handles.picSecondary);     %We'll put a "Caculating..." message in the secondary window.
        cla;                            %Reset the secondary plot to blank axes.
        set(gca,'xlim',[-1 1],'ylim',[-1,1],'xticklabel',[],'yticklabel',[],'xtick',[],...
            'ytick',[],'color','k','xcolor','w','ycolor','w','yscale','linear');
        text(0,0,['Calculating templates, PSTHs, and ISIs...'],'interpreter','none','fontweight','bold',...    %Show the "Calculating..." message.
            'color','w','fontsize',16,'horizontalalignment','center','verticalalignment','middle');
        drawnow;                        %Refresh the axes before running the rest of the code.
        handles = PlotClusters(handles, hObject);       %Plot the templates.
        handles = PlotSecondary(handles, hObject);      %Plot the appropriate secondary figure.
        handles = EnableButtons(handles, hObject);      %Enable the correct buttons.
        [signal, Fs, bits] = wavread(handles.load_sound);	%Load a sound to let the user know the file is loaded.
        soundsc(signal,Fs);                                	%Play the loaded sound.
        disp(['Loaded: ' handles.file(find(handles.file == '\',1,'last')+1:length(handles.file))]);   %Display the loaded file name.
    end
    guidata(hObject, handles);      %Update handles structure

    
%**************************************************************************
%FUNCTION LoadSpikes --- Load the spikes from the *.SPK file.
function [handles, max_spike_break] = LoadSpikes(handles, hObject, save_option)
    fid = fopen(handles.file,'r');   	%Open the *.SPK file for reading and writing.
    fseek(fid,1,'bof');               	%Skip past the daycode.
    numchar = fread(fid,1,'int8');      %Find the number of characters in the rat's name.
    handles.rat = char(fread(fid,numchar,'uchar'))';    %Rat name.
    handles.spont_delay = fread(fid,1,'int16');  %Spontaneous rate measurement delay (ms).
    handles.sampling_rate = single(fread(fid,1,'float32'));     %Sampling rate, in Hz.
    num_spike_samples = fread(fid,1,'int16');	%The number of spike shape samples.
    numparams = fread(fid,1,'int8');         	%Number of stimulus parameters.
    for i = 1:numparams                         %Step through the number of parameters.
        numchar = fread(fid,1,'int16');      	%Number of characters in a parameter name.
        fseek(fid,numchar,'cof');               %Skip the parameter name.
    end
    handles.spikes = single(zeros(handles.max_spikes,num_spike_samples));	%Preallocate the spikeshape matrix.
    handles.times = single(zeros(handles.max_spikes,1));                    %Preallocate the spike time matrix.
    handles.cluster = uint8(zeros(handles.max_spikes,1));                   %Preallocate the cluster matrix.
    index = 1;                                                              %Keep track of the current row in the spikeshap matrix.
    handles.numsweeps = 0;          %Set the number of sweeps to zero.
    max_spike_break = 0;            %Keep track of the point after which we've got >25,000 spikes.
    sweeplength = [];               %Save the sweeplengths.
    while ~feof(fid)
        i = fread(fid,1,'int16');       %Stimulus index
        try
            if ~isempty(i)
                sweeplength = [sweeplength; single(fread(fid,1,'float32'))];    %Sweeplength, in seconds.
                fseek(fid,4*numparams,'cof');     %Skip the parameter values.                
                numsweeps = uint16(fread(fid,1,'uint16'));      %Number of sweeps to follow.
                for j = 1:numsweeps
                    if ~feof(fid)
                        fseek(fid,14,'cof');     %Skip the timestamp, order, and noise estimate.
                        numspikes = fread(fid,1,'uint32');	%Number of spikes.
                        for m = 1:numspikes
                            handles.times(index) = single(fread(fid,1,'float32'));    %Grab the spike time.
                            handles.cluster(index) = uint8(fread(fid,1,'uint8'));	%Grab the cluster assignment
                            handles.spikes(index,:) = single(fread(fid,num_spike_samples,'float32')');   %Grab the spike shape.
                            index = index + 1;
                        end
                        %If we've loaded up enough spikes for spike-sorting,
                        %stop loading.
                        if index - 1 > handles.max_spikes  %Check to see if we're at maximum...
                            max_spike_break = index - 1;   %If so, save the number of spikes.
                            fseek(fid,0,'eof');     %Set the file position indicator to the end of the file.
                            break;
                        else        %Otherwise...
                            handles.numsweeps = handles.numsweeps + 1;	%Keep track of how many sweeps we've loaded.
                        end
                    end
                end
            end
        catch
            warning('NEL:SPKFileReadError',['Error in reading sweep ' num2str(i) ' for this file, stopping file read at last complete sweep.']);
        end
    end
    fclose(fid);    %Close the input file.
    if index <= handles.max_spikes
        handles.times(index:handles.max_spikes) = [];
        handles.cluster(index:handles.max_spikes) = [];
        handles.spikes(index:handles.max_spikes,:) = [];
    end
    handles.numspikes = size(handles.spikes,1);     %Find the exact number of spikeshapes we've grabbed.
    handles.sweeplength = 1000*min(sweeplength);	%Grab the shortest sweeplength from the data structure.
    if handles.sweeplength > 500            %If the sweeplength is long, we'll only plot the first 500 ms in our PSTHs.
        handles.sweeplength = 500;
    end
    handles.min_clus = handles.numsweeps/2;     %Set a minimum cluster size for SPC.
    handles.num_clusters = double(max(handles.cluster));    %Find the number of clusters identified in this *.SPK file.
    if isempty(handles.subthreshold)    %If the user hasn't reset the threshold.
        if size(handles.spikes,2) == 64     %Here we'll find the threshold used to grab these spikes.
            if mean(handles.spikes(:,20)) < 0
                handles.threshold = [20, max(handles.spikes(:,20))];
            else
                handles.threshold = [20, min(handles.spikes(:,20))];
            end
        elseif size(handles.spikes,2) == 27     %Find the threshold for Brainware-recorded spikes.
            if mean(handles.spikes(:,4)) < 0
                handles.threshold = [4, max(handles.spikes(:,4))];
            else
                handles.threshold = [4, min(handles.spikes(:,4))];
            end
        end
    end
    guidata(hObject, handles);      %Update handles structure

    
%**************************************************************************
%FUNCTION PlotSpikes --- Plot a subset of the spikes colored according to cluster assignment.
function handles = PlotSpikes(handles, hObject)
    axes(handles.picShapes);    %Set the current axes to the large plot.
    cla;                        %Clear the axes.
    set(gca,'color','k','xcolor','w','ycolor','w','yscale','linear');   %Set the axes properties.
    hold on;                    %Hold for multiple plots.
    colors = [0.5 0.5 0.5; lines(handles.num_clusters)];    %We'll grab a set of colors to identify different clusters.
    temp = randperm(length(handles.cluster))';              %Randomize the spikes for plotting.
    if size(temp,1) > handles.numplotspks           %If there's more spikeshapes than we want for plotting...  
        temp = temp(1:handles.numplotspks,:);       %Pare down the randomized list to the number of spikes for plotting.
    end
    plot_spikes = handles.spikes(temp,:);           %Grab the specified spikes on the randomized list.
    plot_clusters = handles.cluster(temp,:);        %Grab the cluster assignments for the spikes.
    for i = 0:handles.num_clusters                  %Step through by cluster...                      
        a = find(plot_clusters == i);               %Find all plotspikes for this cluster...
        if ~isempty(a)                              %If there's any plot spikes in this cluster...
            plot(1000000*plot_spikes(a,:)','color',colors(i+1,:));  %Plot those spikes with a unique color.
        end
    end
    axis tight;                         %Tighten up the axes bounds.
    xlim([min(xlim)-1,max(xlim)+1]);    %Set the x axis limits to give some space.
    hold off;                           %Release the plot hold.
    ylabel('Voltage (\muV)','fontweight','normal','fontsize',12);   %Set the y axis label.
    set(gca,'xtick',[],'ytick',[-300:50:300],'yticklabel',[-300:50:300]);  %Set the y axis ticks.
    guidata(hObject, handles);          %Update handles structure
    
    
%**************************************************************************
%FUNCTION PlotSecondary --- Creates plots in the secondary axes depending on sort type.
function handles = PlotSecondary(handles, hObject)
    axes(handles.picSecondary);     %Set axes to the secondary plot.
    set(gca,'color','k','xcolor','w','ycolor','w','yscale','linear','xscale','linear');   %Set the axes properties.
    set(gca,'ylimmode','auto','xlimmode','auto','xtickmode','auto',...
        'ytickmode','auto','xticklabelmode','auto','yticklabelmode','auto');    %Set the axes to auto scale.
    cla;            %Clear the secondary axes.
    hold on;        %Hold the axes for multiple plots.
    colors = [0.5 0.5 0.5; lines(handles.num_clusters)];    %We'll grab a set of colors to identify different templates.
    if strcmpi(handles.sort_type,'Template') | strcmpi(handles.sort_type,'Window')	%If we're plotting templates or windows...
        spike_samples = size(handles.spikes,2);
        for i = 1:handles.num_clusters      %Step through by cluster...     
            plot(1000000*handles.templates(i,1:spike_samples),'color',colors(i+1,:),'linewidth',4);   %Plot the templates with a unique color.
            plot(1000000*(handles.templates(i,1:spike_samples) + handles.templates(i,spike_samples+2:2*spike_samples+1)),...
                'color',colors(i+1,:),'linestyle','--','linewidth',2);   %Plot the template point distance limits with a unique color.
            plot(1000000*(handles.templates(i,1:spike_samples) - handles.templates(i,spike_samples+2:2*spike_samples+1)),...
                'color',colors(i+1,:),'linestyle','--','linewidth',2);   %Plot the template point distance limits with a unique color.
        end
        axis tight;     %Tighten up the axes bounds.
        xlim([min(xlim)-1,max(xlim)+1]);    %Set the x axis limits to give some space.
        ylabel('Voltage (\muV)','fontweight','normal','fontsize',12);   %Set the y axis label.
        xlabel('');                                                     %Set the x axis label to blank.
        set(gca,'xtick',[],'ytick',[-300:50:300]);                      %Set the y axis ticks.
        if strcmpi(handles.sort_type,'Window')
            for i = 1:length(handles.windows)   %Step through by cluster.
                for j = 1:size(handles.windows(i).values,1)     %Step through by window.
                    xy = handles.windows(i).values(j,:);        %Grab the endpoints for this window.
                    %Plot the window as a thick, darker line with circular endpoints.
                    plot(xy(1:2),xy(3:4),'color','w','linewidth',4,...
                        'marker','o','markerfacecolor',colors(i+1,:),'markersize',5);
                    plot(xy(1:2),xy(3:4),'color',colors(i+1,:),'linewidth',2);  
                end
            end
        end
    elseif strcmpi(handles.sort_type,'PCA')     %If we're plotting PCA...
        for i = 0:handles.num_clusters                          %Step through by cluster.
            a = find(handles.cluster == i);                     %Find all spikes for this cluster.
            if ~isempty(a);                                     %If there are any spikes...
                plot(handles.PCs(a,handles.currentPCs(1)),handles.PCs(a,handles.currentPCs(2)),...
                    'marker','.','linestyle','none','color',colors(i+1,:));     %Plot the PCA point.
            end
        end
        axis tight;     %Tighten up the axes bounds.
        xlabel(handles.PCAlabels{handles.currentPCs(1)},'fontweight','normal','fontsize',12);   %Set the x axis label.
        ylabel(handles.PCAlabels{handles.currentPCs(2)},'fontweight','normal','fontsize',12);   %Set the y axis label.
        set(gca,'xtick',[],'ytick',[]);     %Set the axes ticks to blank.
    elseif strcmpi(handles.sort_type,'SPC');    %If we're plotting SPC temperature...
        set(gca,'yscale','log');     %Set the axis limits.
        temperature = handles.mintemp + handles.temperature*handles.tempstep;	%Determine the temperature used for clustering.
        semilogy(handles.mintemp + (1:handles.num_temp)*handles.tempstep,...
            handles.SPC_tree(1:handles.num_temp,5:size(handles.SPC_tree,2)),'linewidth',2);   %Plotting cluster temperatures.
        xlim([0 1.05*handles.maxtemp]);     %Set the x axis limits.
        line(get(gca,'xlim'),[handles.min_clus, handles.min_clus], 'color','w','linestyle',':');	%Plot the minimum cluster size.
        line([temperature temperature], get(gca,'ylim'), 'color','w','linestyle',':');              %Plot the determined best temperature.
        xlabel('Temperature','fontsize',12,'fontweight','bold');        %Set the x label.
        ylabel('Clusters Size','fontsize',12,'fontweight','bold');      %Set the y label.
        set(gca,'color','k','xcolor','w','ycolor','w');     %Set the background to black and axes to white.
    elseif strcmpi(handles.sort_type,'Undefined');      %If the sort type isn't yet chosen...
        set(gca,'xlim',[-1 1],'ylim',[-1,1],'xticklabel',[],'yticklabel',[],'xtick',[],...
            'ytick',[],'color','k','xcolor','w','ycolor','w','yscale','linear');    
        text(0,0,['No sort method selected.'],'interpreter','none','fontweight','bold',...    %Show a "Undefined..." message.
            'color','w','fontsize',16,'horizontalalignment','center','verticalalignment','middle');
    end
    hold off;                   %Release the hold on the plots.
    guidata(hObject, handles); 	%Update handles structure
        

%**************************************************************************
%FUNCTION PlotClusters --- Plot templates, PSTHs, and interspike-intervals for all clusters in a separate window.
function handles = PlotClusters(handles, hObject)
    a = figure(1);      %Create the new figure or grab it's handle if it already exists.
    set(a,'name','Templates, PSTHs, and Interspike Intervals'); %Put a title in the top of the figure frame.
    clf;                %Clear all current plots.
    set(a,'menubar','none','color','k');    %Take the menubar off the figure window.
    numplots = handles.num_clusters + 2;    %We'll have a plot for each cluster, plus a plot for all spike data and a plot for "noise".
    colors = [0.5 0.5 0.5; lines(handles.num_clusters)];    %We'll grab a set of colors to identify different clusters.
    waveshapes = [];    %We'll create average waveshapes for each cluster.
    multipsth = [];     %We'll look at an overall unsorted PSTH for comparison.
    multiisi = [];      %We'll also look at overall unsorted interspike intervals.
    for c = 0:handles.num_clusters          %Step through by cluster.
        a = find(handles.cluster == c);     %Find all spikes in this cluster.
        b = a(randperm(size(a,1)),:);       %Pull out a random sample of spikes.
        if size(b,1) > handles.maxplotspks      %If there's more spikes than we want to plot...
            b = b(1:handles.maxplotspks,:);     %Pare down the random sample if there's more than we want to display.
        end
        if c == 0   %If this is noise, plot it in the right column.
            subplot(3,numplots, numplots);
            title('Noise','color','w','fontsize',12);
        else        %Otherwise, order the clusters by columns.
            subplot(3,numplots, c + 1);
            title(['Cluster #' num2str(c)],'color','w','fontsize',12);
        end
        hold on;    %Hold the plot.
        if ~isempty(b)  %If there are actually spikes in this cluster...
            plot(1000000*handles.spikes(b,:)','color',colors(c+1,:));   %Plot the spikeshapes, in microvolts.
            b = mean(handles.spikes(b,:),1);      %Calculate the mean waveshape.
            plot(1000000*b,'color', 2*colors(c+1,:)/3);     %Plot the mean waveshape, slightly darker than the regular spike color.
        end
        if c ~= 0 && ~isempty(b)     %If this isn't the noise cluster and there's spikes in this cluster, save the mean waveshape.
            waveshapes = [waveshapes; 1000000*b];   %Save the mean waveshape.
        elseif c ~= 0               %If the cluster exists, but there were no plot spikes in the randomized list...
            waveshapes = [waveshapes; nan(1,size(handles.spikes,2))];    %Hold the cluster's place with a line of NaNs.
        end
        axis tight;                         %Tighten the plot axes.
        xlim([min(xlim)-1,max(xlim)+1]);    %Set the x axis limits.
        set(gca,'color','k','xtick',[0:10:64],'xticklabel',[-20:10:60],'xcolor','w');	%Set the background to black, set the axes properties.
        hold off;                                   %Release the hold on the figure.
        xlabel('Samples','fontweight','normal');    %Set the x axis label.
        if ~isempty(a)  %If there's spikes in this cluster...
            temp = histc(handles.times(a),[0:handles.sweeplength])';    %Construct a PSTH with the spiketimes for this cluster.
        else            %Otherwise...
            temp = zeros(1,handles.sweeplength);    %If there's no spikes, just make a flat line.
        end
        temp = temp(1:handles.sweeplength);        %Cut off the histc tail.
        if c == 0       %If this is the noise cluster...
            subplot(3,numplots,2*numplots); %Plot in the last column.
        else            %Otherwise...
            multipsth = [multipsth; temp];  %Add the histogram to the unclustered PSTH.
            subplot(3,numplots,numplots+c+1);   %Plot the cluster PSTHs in the correct column.
        end
        b = bar(boxsmooth(1000*temp/handles.numsweeps,10),1);       %Plot the PSTH, smoothing over 5 ms.
        set(b,'edgecolor',colors(c+1,:),'facecolor',colors(c+1,:)); %Set the edgecolors and facecolors on the bar plot.
        set(gca,'color','k','xcolor','w','ycolor','w');             %Set the background color to black and axes colors to white.
        set(gca,'xtick',handles.spont_delay+[-500:100:500],'xticklabel',[-500:100:500]);   %Set the xticks.
        axis tight;     %Tighten the axes.
        xlabel('Time (ms)','fontweight','normal','fontsize',12);    %Set the x label.
        line([handles.spont_delay, handles.spont_delay],get(gca,'ylim'),'color','w','linestyle',':');   %Plot a line at stimulus onset.
        b = zeros(1,25);        %Set up an interstimulus interval histogram.
        for i = 2:20            %Step through interspike intervals for up to 10 spikes distant.
            if length(a) > i    %If there's enough spikes to histogram...
                temp = handles.times(a(i:length(a))) - handles.times(a(1:(length(a)-i+1)));     %Subtract spike times to get spike intervals.
                temp = temp(find(temp >= 0));   %Kick out any negative spike intervals returned for subtracting between different sweeps.
                if ~isempty(temp)       %If any interspike intervals remain, find the histogram.
                    temp = histc(temp,0:0.2:5,1)';
                else
                    temp = zeros(1,25); %Otherwise the histogram is all zeros.
                end
                b = b + temp(1:25);     %Add this histogram to the total.
            end
        end
        if c == 0   %If this is the noise cluster...
            subplot(3,numplots,3*numplots); %Plot in the last column.
        else    %Otherwise...
            multiisi = [multiisi; b];  %Add the histogram to the unclustered interspike interval histogram.
            subplot(3,numplots,2*numplots+c+1);   %Plot the cluster PSTHs in the correct column.
        end
        b = bar([0:0.2:4.8]',b',1);    %Plot the PSTH, smoothing over 5 ms.
        set(b,'edgecolor',colors(c+1,:),'facecolor',colors(c+1,:)); %Set the edgecolors and facecolors on the bar plot.
        set(gca,'color','k','xcolor','w','ycolor','w');             %Set the background color to black and axes colors to white.
        set(gca,'xtick',0:10,'xticklabel',0:5);   %Set the xticks.
        axis tight;         %Tighten the axes.
        xlabel('Time (ms)','fontweight','normal','fontsize',12);    %Set the x label.
    end
    subplot(3,double(numplots),1);  %Plot the mean waveshapes in the top left plot.
    hold on;                %Hold the plot.
    for c = 1:handles.num_clusters  %Step through by cluster.
        plot(waveshapes(c,:),'color', colors(c+1,:),'linewidth',2);     %Plot each mean waveshape.
    end
    hold off;               %Release the plot hold.
    set(gca,'color','k','xcolor','w','ycolor','w');     %Set the background to black and the axes to white.
    axis tight;             %Tighten the plot.
    set(gca,'xtick',[0:10:64],'xticklabel',[-20:10:60]);    %Set the x ticks.
    xlabel('Samples','fontweight','normal','fontsize',12);  %Set the x label.
    ylabel('Voltage (\muV)','fontweight','normal','fontsize',12);   %Set the y label.
    title('Templates','color','w','fontsize',12);       %Set the title.
    temp = [];
    for i = 1:handles.num_clusters + 2  %Step through the waveshape plots and pull out the y limits.
        subplot(3,numplots,i);          
        temp = [temp; ylim];    %Grab the y limits.
    end
    temp = [min(temp(:,1)), max(temp(:,2))];    %Find the minimum and maximum y limits.
    for i = 1:handles.num_clusters + 2          %Step through the plots and standardize the y limits.
        subplot(3,numplots,i);
        ylim(temp);
    end
    subplot(3,numplots,numplots+1);     %Plot the unclustered overall PSTH.
    a = bar(boxsmooth(1000*sum(multipsth,1)/handles.numsweeps,10),1);   %Plot the PSTH as a bar plot.
    set(a,'edgecolor','w','facecolor','w');     %Set the edgecolors and facecolors on the bar plot.
    set(gca,'color','k','xcolor','w','ycolor','w','yticklabel',get(gca,'ytick'));       %Set the background to black and the axes to white.
    set(gca,'xtick',handles.spont_delay+[-500:100:500],'xticklabel',[-500:100:500]);    %Set the xticks.
    axis tight;     %Tighten the axes.
    xlabel('Time (ms)','fontweight','normal','fontsize',12);    %Set the x label.
    line([handles.spont_delay, handles.spont_delay],get(gca,'ylim'),'color','w','linestyle',':');   %Plot a line at stimulus onset.
    subplot(3,numplots,2*numplots+1);     %Plot the unclustered overall interspike interval histogram.
    a = bar([0:0.2:4.8]',sum(multiisi,1)',1);
    set(a,'edgecolor','w','facecolor','w');     %Set the edgecolors and facecolors on the bar plot.
    set(gca,'color','k','xcolor','w','ycolor','w','yticklabel',get(gca,'ytick'));   %Set the background to black and the axes to white.
    set(gca,'xtick',0:10,'xticklabel',0:5);   %Set the xticks.
    axis tight;     %Tighten the axes.
    xlabel('Time (ms)','fontweight','normal','fontsize',12);    %Set the x label.
    guidata(hObject, handles);  %Update handles structure.

    
%**************************************************************************
%FUNCTION TemplateMaker --- Creates templates by averaging the waveshapes of all spikes in a cluster.
function handles = TemplateMaker(handles, hObject)
    switch handles.template_type    %We can use different types of algorithms to define spike-to-spike distances.
        case 'NN'
        case 'CENTER'   %Use a center-to-center Euclidian method.
            templates = zeros(handles.num_clusters, size(handles.spikes,2));    %Create blank templates for each cluster.
            maxdist = zeros(1,handles.num_clusters);                            %Define a maximum Euclidean distance for a spike to be included.
            pointdist = zeros(handles.num_clusters, size(handles.spikes,2));    %Define the maximum distance at each point for a spike to be included.
            for i = 1:handles.num_clusters                          %Step through by cluster number.
                fi = handles.spikes(find(handles.cluster == i),:);  %Grab all the spikes for this cluster.
                templates(i,:) = mean(fi);                          %The template is the mean waveshape.
                maxdist(i) = sqrt(sum(var(fi,1)));  %maxdist is the std dev of the euclidean distance from the mean.
                %Here we'll find the standard deviation of the variation along each dimension of
                %the spikes in this cluster.  The "1" in the var function means we want sum(x-m)^2/N, not N-1;
                pointdist(i,:) = sqrt(var(handles.spikes(find(handles.cluster == i),:),1));    %Single dimension standard deviation.
            end
            pointdist = pointdist*handles.max_radius;	%Multiply point-by-point standard deviation by the maximum radius factor.
            maxdist = maxdist*handles.max_radius;       %Multiply overall standard deviation by the maximum radius factor.
        case 'GAUSS'
        case 'MAHAL'
        otherwise
    end
    %Keep all the template data in one matrix.
    handles.templates = [templates, maxdist', pointdist, repmat(handles.pointlimit,handles.num_clusters,1)];
    guidata(hObject, handles);                              %Update handles structure
    
    
%**************************************************************************
%FUNCTION TemplateSortSpikes --- Sorts spikes using the set templates.
function handles = TemplateSortSpikes(handles, hObject)
	ssize = size(handles.spikes,2);                     %Grab the spike shape sample size.
    templates = handles.templates(:,1:ssize);           %Grab the template means.
    maxdist = handles.templates(:,ssize+1);             %Grab the euclidian distant limit.
    pointdist = handles.templates(:,ssize+2:2*ssize+1); %Grab the point-to-point limit.
    pointlimit = handles.templates(1,2*ssize+2);        %Grab the maximum number of points that can exceed the template.
    distances = nan(handles.numspikes,handles.num_clusters); %Set up a matrix to receive Euclidian distances.
    for i = 1:size(handles.templates,1)      %Step through by cluster.
        %Compute the Euclidian distance between the spike shapes and the template.
        distances(:,i) = sqrt(sum((handles.spikes - repmat(templates(i,:),handles.numspikes,1)).^2,2));
        distances(find(distances(:,i) > maxdist(i)),i) = NaN;   %Identify those spike within the maximum distance from the template.
         %Check how many points are outside of the maximum per-point distance.
        temp = sum(abs(handles.spikes - repmat(templates(i,:),handles.numspikes,1))...
            > repmat(pointdist(i,:),handles.numspikes,1),2) > pointlimit;  
        distances(find(temp == 1),i) = NaN;     %Kick out any spikes with too many points outside the point limits.
    end
    [c,i] = min(distances,[],2);                %Find the template with the minimum distance to each spike.
    handles.cluster(find(isnan(c))) = 0;        %Spikes outside of any template are set as noise.
    handles.cluster(find(~isnan(c))) = i(find(~isnan(c)));  %Clusters are assigned according to closest template.
    handles.cluster(handles.subthreshold) = 0;	%Set any subthreshold spikes to noise.
    handles.num_clusters = double(max(handles.cluster));	%Reset the number of clusters.
    guidata(hObject, handles);                  %Update handles structure


%**************************************************************************
%FUNCTION CalculatePCAs --- Calculate the PC scores and any other spike properties we want for PCA.
function handles = CalculatePCAs(handles, hObject)
    axes(handles.picSecondary);     %We'll put a "Caculating..." message in the secondary window.
    cla;                            %Reset the secondary plot to blank axes.
    set(gca,'xlim',[-1 1],'ylim',[-1,1],'xticklabel',[],'yticklabel',[],'xtick',[],...
        'ytick',[],'color','k','xcolor','w','ycolor','w','yscale','linear');
    text(0,0,['Calculating PCA scores...'],'interpreter','none','fontweight','bold',...    %Show the "Calculating..." message.
        'color','w','fontsize',16,'horizontalalignment','center','verticalalignment','middle');
    drawnow;                        %Refresh the axes before running the rest of the code.
    %To get better PCA results, we'll first line up all our spikes by the spike peaks.
    spike_samples = size(handles.spikes,2);     %Grab the number of samples in a spike.
    temp = nan(size(handles.spikes));	%Set up the aligned-spike matrix first for speed.
    for i = 1:handles.numspikes                 %Step through spike by spike.
        if handles.threshold(2) < 0             %If there was a negative threshold...
            a = find(diff(handles.spikes(i,handles.threshold(1):spike_samples)) > 0,1,'first'); %Find the first post-threshold valley;
            temp(i,1:spike_samples-a+1) = handles.spikes(i,a:spike_samples);    %Chop off samples before the threshold crossing to align the valleys.
        else                                    %If there was a positive threshold...
            a = find(diff(handles.spikes(i,handles.threshold(1):spike_samples)) < 0,1,'first'); %Find the first post-threshold peak;     
            temp(i,1:spike_samples-a+1) = handles.spikes(i,a:spike_samples);    %Chop off samples before the threshold crossing to align the peaks.
        end
    end
    a = find(isnan(mean(temp)),1,'first');  %Find all the columns that have NaNs in them.
    temp(:,a:spike_samples) = [];           %Cut out the NaN columns.
    [PC, PCscore, PCvar] = princomp(temp);  %Perform the PCA.
    handles.PCs = PCscore(:,1:3);           %Keep only the first three principal component scores, the others aren't very informative.
    clear PCscore PC PCvar;                 %Delete the PCA variables to save RAM.
    temp(:,1:handles.threshold(1)-1)  = [];   %Delete all sample points before the first peak.
    handles.PCs(:,4:6) = [temp(:,1), zeros(handles.numspikes,2)];	%Pre-arrange the component matrix for speed.
    if handles.threshold(2) < 0     %If these spikes are from a negative threshold...
        temp = -temp;               %Flip the spikes to make calculation easier.
    end
    for i = 1:handles.numspikes                         %Step through spike by spike.
        a = find(diff(temp(i,:)) > 0,1,'first')-1;      %Find the post-peak valley.
        if ~isempty(a)                                  %If a valley was found...
            handles.PCs(i,5:6) = [temp(i,a), a];        %Save the valley depth and peak-to-valley distance.
        else                                            %If for some reason there was no valley...
            handles.PCs(i,5) = min(temp(i,:));          %Use the post-peak minimum as the valley depth.
            handles.PCs(i,6) = find(temp(i,:) == min(temp(i,:)),1,'first');      %Use the time to minimum as the peak-to-valley distance.                
        end
    end
    if handles.threshold(2) < 0     %If these spikes are from a negative threshold...
        handles.PCs(i,5) = -handles.PCs(i,5);	%Flip the second peak heights back to positive.
    end
    clear temp;                             %Clear the temp variable to save RAM.
    %     temp = handles.spikes;
    %     for i = 1:handles.numspikes
    %         temp(i,:) = wavedec(temp(i,:),handles.scales,'haar');
    %     end
    %     trace = [];
    %     for i = 1:size(temp,2)
    %         %Before identifying which features are most important, we'll kick
    %         %out any outliers more than 3 standard deviations from the mean.
    %         dist_min = mean(temp(:,i)) - std(temp(:,i)) * 3;
    %         dist_max = mean(temp(:,i)) + std(temp(:,i)) * 3;
    %         a = temp(find(temp(:,i) > dist_min & temp(:,i) < dist_max),i);
    %         if length(a) > 10;
    %             [y_expcdf,x_expcdf] = cdfcalc(a);        %Calculates the CDF (expcdf)
    %             zScores  =  (x_expcdf - mean(a))./std(a);   %The theoretical CDF (theocdf) is assumed to be normal with unknown mean and sigma.
    %             theocdf  =  normcdf(zScores,0,1);
    %             %We'll compute the maximum distance: max|S(x) - theocdf(x)|.
    %             delta1    =  y_expcdf(1:end-1) - theocdf;	% Vertical difference at jumps approaching from the LEFT.
    %             delta2    =  y_expcdf(2:end)   - theocdf;   % Vertical difference at jumps approaching from the RIGHT.
    %             deltacdf  =  abs([delta1; delta2]);
    %             trace(i) = max(deltacdf);
    %         else
    %             trace(i) = 0;
    %         end
    %     end
    %     [a b] = sort(trace);
    %     b = fliplr(b);
    %     handles.PCs(:,7:16) = temp(:,b(1:10));
    handles.currentPCs = [1,2,NaN];         %By default, use the first two principal components as the default view.
    handles.PCAlabels = {'PC #1','PC #2','PC #3','1st Peak','2nd Peak','Peak-to-Peak'};  %A list of the columns in the PCs field for reference.
    guidata(hObject, handles);              %Update handles structure    
    

%**************************************************************************
%FUNCTION ClusterByTemp --- Reassign SPC clusters after the user changes the temperature.
function handles = ClusterByTemp(handles, hObject)
	%Here we use the temperature to decide assignment to clusters based on the
    %temperature, which is really just an index to the larger "cluster" matrix.
%     if size(handles.SPC_clusters,2) - 2 < handles.numspikes;	%If our cluster matrix is less than the number of spikes we have...
%         clusters = handles.SPC_clusters(handles.temperature,3:end) + 1;
%         clusters = [clusters(:)' zeros(1,size(handles.spikes,1) - handles.max_spikes)];
%     else
        clusters = handles.SPC_clusters(handles.temperature,3:end) + 1;
%     end
    %Noise spikes tend to get assigned to small outlier clusters.  If any
    %outlier clusters are less than our minimum cluster size, we'll assign them
    %a cluster value of zero to mark them as noise.   
    for i = 1:max(clusters)         %Step through by cluster.
        a = find(clusters == i);    %Find all spikes in this cluster.
        if length(a) < handles.min_clus     %If the cluster is smaller than the minimum allowed.
            break;      %Step out of the for loop, all subsequent clusters will only be smaller.
        end
    end
    a = find(clusters ~= 1);        %Find all the clusters that don't equal 1.
    for j = 2:i-1                   %Step through by cluster up to the smallest allowable cluster.
        a = intersect(a,find(clusters ~= j));   %Find all spikes that aren't in the allowable clusters.
    end
    clusters(a) = 0;                %Spikes in too-small clusters get reclassified as noise.
    %Now we'll re-number the clusters so that there's no gaps in numbering.
    handles.num_clusters = length(unique(clusters)) - 1 + min(clusters);    %Pull out the number of unique clusters.
    for i = 1:handles.num_clusters          %Step through by cluster.
        a = union(0,unique(clusters));      %Find all possible current cluster assignments.
        a = a(i+1);                         %Find the current cluster number.
        clusters(find(clusters == a)) = i;  %Assign a contiguous number.
    end
    clusters = clusters';                   %Transpose the cluster numbers.
    handles.cluster = uint8(clusters);              %Save the cluster assignments to the handles structure.
    handles.cluster(handles.subthreshold) = 0;     	%Set any subthreshold spikes to noise.
    guidata(hObject, handles);              %Update handles structure.
    

%**************************************************************************
%FUNCTION ClusterByPCA --- Assign clusters according to PCA boundaries.
function handles = ClusterByPCA(handles, hObject)
    if ~isempty(handles.draw)   %If user-defined boundaries exist...
        handles.cluster(:) = 0;   %Start with all clusters assigned to noise.
        %Step through drawn cluster boundaries, backwards so that
        %first-drawn boundaries supercede subsequent boundaries.
        for i = length(handles.draw):-1:1
            temp = handles.PCs(:,handles.draw(i).PCs);    %Grab the matrix of spike components.
            xy = handles.draw(i).values;    %Grab the vertice list for this boundary.
            a = find(temp(:,1) < max(xy(1,:)) & temp(:,1) > min(xy(1,:)));  %Kick out all spikes not within the max and min x range.
            b = find(temp(:,2) < max(xy(2,:)) & temp(:,2) > min(xy(2,:)));  %Kick out all spikes not within the max and min y range.
            a = intersect(a,b);
            for j = a'      %Step through spike by spike for the remaining candidates.
                b = find(xy(2,:) > temp(j,2));  %Find all vertices with y values above this point's y value.
                c = find(xy(2,:) < temp(j,2));  %Find all vertices with y values below this point's y value.
                %Find all vertex-to-vertex segments with y ranges including this points y value.
                indices = [intersect(b,c-1),intersect(c,b-1)];
                if any(indices == temp(j,2))    %If the y-value of this point falls exactly on a vertex...
                    %Kick out an vertices equal to the y-value of this point that have
                    %a downward "V" or upward "^" inflection.
                    indices(intersect(find(indices == temp(j,2)),...
                        intersect(intersect(indices,indices-1),intersect(indices,indices+1)))) = [];
                end
                %To determine whether this point falls within the boundaries, we'll use the
                %Jordan Curve Theorem.  Extend an infinite horizontal line out in one
                %direction from the point being tested.  Every boundary segment it crosses
                %"flips" the outside/inside assignment, so that if it cross an odd number
                %of segments, it must be inside the boundary, and if it crosses an even
                %number of segments, it must be outside.
                x = zeros(1,length(indices));   %Set up a matrix to receive the x-values for the segment intercepts.
                for k = indices     %Step through by segments.
                    %Calculate the x coordinate of the intersection between the horizontal line
                    %through the point's y-value and the segment in question.
                    x(k == indices) = xy(1,k)+(temp(j,2)-xy(2,k))*(xy(1,k+1)-xy(1,k))/(xy(2,k+1)-xy(2,k));  
                end
                %Find all intercept x-values greater ("to the right of") than the x-value of the test point.
                x = x(find(x >= temp(j,1)));
                %If there's an odd number of segment intercept x-values greater than the test point x-value...
                if mod(length(x),2) == 1
                    handles.cluster(j) = i;     %This point must fall within this boundary.
                end
            end   
        end
    else    %If there's no user-defined PCA values yet...
        handles.cluster(:) = 1;   %Set all spikes to cluster #1.
    end
    handles.num_clusters = double(max(handles.cluster));    %Reset the number of clusters.
    handles.cluster(handles.subthreshold) = 0;   	%Set any subthreshold spikes to noise.
    guidata(hObject, handles);                  %Update handles structure.   
    
    
%**************************************************************************
%FUNCTION ClusterByWindow --- Calculates cluster assignments according to windows.
function handles = ClusterByWindow(handles, hObject)
    if ~isempty(handles.windows)
        handles.cluster(:) = 0;   %Start with all clusters assigned to noise.
        %Step through drawn cluster windows.
        for i = 1:length(handles.windows)
            test = ones(handles.numspikes,1);       %Start off by assuming that all spikes pass through the window.
            test(find(handles.cluster ~= 0)) = 0;   %Any spikes already assigned in previous passes are ignored.
            for j = 1:size(handles.windows(i).values,1)   %Step through by window.
                xy = handles.windows(i).values(j,:);        %Grab the endpoints for this window.
                indices = [fix(min(xy(1:2))):ceil(max(xy(1:2)))];	%Find the sample indices for the spike snippets.
                temp = 1000000*handles.spikes(:,indices) - xy(3);  	%Create matrix with only the relevant spikeshape snippet.
                indices = indices - xy(1);              %Set the x-values relative to the first window endpoint.
                xy = [0, xy(2)-xy(1), 0, xy(4)-xy(3)];  %Set the first endpoint at the origin of rotated axes. 
                test(find(max(temp,[],2) < min(xy(3:4)) | min(temp,[],2) > max(xy(3:4)))) = 0;	%Disqualify all spikes that never cross the bounding box.
                a = find(test == 1);                    %Pull up all still-qualified spikes.
                temp(a,1) = (min(xy(1:2))-indices(1))*(temp(a,2)-temp(a,1)) + temp(a,1);	%Interpolate the left-most endpoint snippet values.
                b = size(temp,2);   %Find how many samples are in each snippet.
                temp(a,b) = (max(xy(1:2))-indices(b-1))*(temp(a,b)-temp(a,b-1)) + temp(a,b-1);  %Interpolate the right-most endpoint snippet values.
                indices([1,b]) = [min(xy(1:2)),max(xy(1:2))];   %Cut off the parts of the snippet that stick out past the window endpoints.
                if xy(2) ~= 0   %If the window isn't a straight vertical line...
                    xy = indices*(xy(4)/xy(2)); %Calculate the value of the segment at the discrete sample points.
                else            %Otherwise if it is a perfectly vertical line...
                    xy = [0 xy(4)];             %Set the values as the upper and lower endpoints.
                end
                for k = 1:length(xy)    %Step through by sample point...
                    temp(a,k) = temp(a,k) - xy(k);  %Subtract the value of the segment at the sample point.
                end
                a = a(find(max(temp(a,:),[],2) >= 0 & min(temp(a,:),[],2) <= 0));   %Find all spikeshapes with points above AND below the window.
                test(setdiff([1:handles.numspikes],a)) = 0;     %Any spikeshapes that don't pass through the window are tossed out.
            end
            handles.cluster(find(test == 1)) = i;   %Any spikeshapes that made it through all the windows are added to the cluster.        
        end
    else    %If there's no user-defined windows yet...
        handles.cluster(:) = 1;   %Set all spikes to cluster #1.
    end
    handles.num_clusters = double(max(handles.cluster));	%Reset the number of clusters.
    handles.cluster(handles.subthreshold) = 0;  	%Set any subthreshold spikes to noise.
    guidata(hObject, handles);                      %Update handles structure  
    
    
%**************************************************************************
%BUTTON PRESS ON cmdAdjustTemp --- Executes on button press in cmdAdjustTemp.
function cmdAdjustTemp_Callback(hObject, eventdata, handles)
    axes(handles.picSecondary);     %Set the focus to the temperature plot.
    [x,y] = ginput(1);              %Get graphical user input for the temperature setting.
    handles.min_clus = round(y);    %Set the minimum cluster size to the y value.
    handles.temperature = round(x/handles.tempstep);    %Set the temperature to the closest temperature step.
    axes(handles.picShapes);        %Set the main plot to tell the user we're recalculating.
    cla;        %Reset the spikeshapes plot to blank axes.
    set(gca,'xlim',[-1 1],'ylim',[-1,1],'xticklabel',[],'yticklabel',[],'xtick',[],...
        'ytick',[],'color','k','xcolor','w','ycolor','w','yscale','linear');
    text(0,0,'Recalculating...','interpreter','none','fontweight','bold',...    %Show the "Recalculating SPC Clusters..." message.
        'color','w','fontsize',16,'horizontalalignment','center','verticalalignment','middle');
    drawnow;     %Refresh the axes before running the rest of the code.
    handles = ClusterByTemp(handles, hObject);  %Cluster using the new temperature.
    handles = PlotSpikes(handles, hObject);     %Plot spikes in the main plot.
    axes(handles.picSecondary);     %We'll put a "Caculating..." message in the secondary window.
    cla;                            %Reset the secondary plot to blank axes.
    set(gca,'xlim',[-1 1],'ylim',[-1,1],'xticklabel',[],'yticklabel',[],'xtick',[],...
        'ytick',[],'color','k','xcolor','w','ycolor','w','yscale','linear');
    text(0,0,['Calculating templates, PSTHs, and ISIs...'],'interpreter','none','fontweight','bold',...    %Show the "Calculating..." message.
        'color','w','fontsize',16,'horizontalalignment','center','verticalalignment','middle');
    drawnow;                        %Refresh the axes before running the rest of the code.
    handles = PlotClusters(handles, hObject);   %Plot the cluster templates, PSTHs, and ISIs.
    handles = PlotSecondary(handles, hObject);   %Show the new temperature plot first.
    guidata(hObject, handles);                  %Update handles structure.

    
%**************************************************************************
%BUTTON PRESS ON cmdSPCsort --- Executes on button press in cmdSPCsort.
function cmdSPCsort_Callback(hObject, eventdata, handles)
    %First see if SPC output files already exist for this file.
    if ~exist([handles.fileroot '.dg_01']) | ~exist([handles.fileroot '.dg_01.lab'])    %If no SPC output files exist...
        %If this file hasn't been SPC clustered yet, ask the user if they'd like to continue.
        temp = questdlg('This file hasn''t yet been run through the SPC clustering program.  This may take as long as 20-60 minutes.  Do you want to continue?',...
            'Initiate SPC Clustering?','Continue', 'Cancel', 'Continue');   %As the user with a dialog box.
        if strcmpi(temp,'continue')     %If the user wants to continue...
            axes(handles.picShapes);    %We'll put a "SPC Clustering..." message in the main spikeshapes window.
            cla;        %Reset the spikeshapes plot to blank axes.
            set(gca,'xlim',[-1 1],'ylim',[-1,1],'xticklabel',[],'yticklabel',[],'xtick',[],...
                'ytick',[],'color','k','xcolor','w','ycolor','w','yscale','linear');
            text(0,0,['Running SPC Clustering Program...'],'interpreter','none','fontweight','bold',...    %Show the "SPC Clustering..." message.
                'color','w','fontsize',16,'horizontalalignment','center','verticalalignment','middle');
            drawnow;    %Refresh the axes before running the rest of the code.
            NEL_Auto_SPC(handles.file,'Display','On');	%Auto-Spike-Sort the given *.SPK file.
        end
    end
    %Check again to see if any method output files exist for this file and
    %also if SPC parameters aren't already loaded up to the handles structure.
    if exist([handles.fileroot '.dg_01']) & exist([handles.fileroot '.dg_01.lab']) & isempty(handles.SPC_clusters)
        handles.SPC_clusters = load([handles.fileroot '.dg_01.lab']);   %Load the SPC clusters.
        handles.SPC_tree = load([handles.fileroot '.dg_01']);           %Load the SPC tree.
        aux = [];
        for i = 5:size(handles.SPC_tree,2)
            aux = [aux, diff(handles.SPC_tree(:,i))];
        end
        handles.temperature = 1;                    %Set an arbitrary initial temperature value.
        for t = 1:handles.num_temp - 1              %Step upward by temperature.
            if any(aux(t,:) > handles.min_clus)     %Looks for any cluster larger than min_clus.
                handles.temperature = t + 1;        %Temperature is set to a point including the maximum number of spikes and clusters.
            end
        end
        if (handles.temperature == 1 & handles.SPC_tree(handles.temperature,6) < handles.min_clus)
            handles.temperature = 2;    %If the second cluster is too small, then we'll raise the temperature a little bit 
        end
    end        
    if ~isempty(handles.SPC_clusters)   %If SPC parameters aren't loaded up yet.
        axes(handles.picShapes);        %Set the main plot to tell the user we're loading the SPC data.
        cla;        %Reset the spikeshapes plot to blank axes.
        set(gca,'xlim',[-1 1],'ylim',[-1,1],'xticklabel',[],'yticklabel',[],'xtick',[],...
            'ytick',[],'color','k','xcolor','w','ycolor','w','yscale','linear');
        text(0,0,'Loading SPC Data.','interpreter','none','fontweight','bold',...    %Show the "Loading SPC Data." message.
            'color','w','fontsize',16,'horizontalalignment','center','verticalalignment','middle');
        drawnow;    %Refresh the axes before running the rest of the code.
        handles.sort_type = 'SPC';                  %Change the sort type to SPC.
        handles = ClusterByTemp(handles, hObject);  %Cluster using the new temperature.
        handles = PlotSpikes(handles, hObject);     %Plot spikeshapes in the main window.
        axes(handles.picSecondary);     %We'll put a "Caculating..." message in the secondary window.
        cla;                            %Reset the secondary plot to blank axes.
        set(gca,'xlim',[-1 1],'ylim',[-1,1],'xticklabel',[],'yticklabel',[],'xtick',[],...
            'ytick',[],'color','k','xcolor','w','ycolor','w','yscale','linear');
        text(0,0,['Calculating templates, PSTHs, and ISIs...'],'interpreter','none','fontweight','bold',...    %Show the "Calculating..." message.
            'color','w','fontsize',16,'horizontalalignment','center','verticalalignment','middle');
        drawnow;                        %Refresh the axes before running the rest of the code.
        handles = PlotClusters(handles, hObject);   %Plot the templates, PSTHs, and ISI is figure 1.
        handles = PlotSecondary(handles, hObject);       %Show the new temperature plot first.
    end
    handles = EnableButtons(handles, hObject);      %Enable the correct buttons.
    guidata(hObject, handles);                      %Update handles structure.
    
    
%**************************************************************************
%SLIDER MOVEMENT on hscNumPlotSpks --- Executes when user changes the value of the slider.
function hscNumPlotSpks_Callback(hObject, eventdata, handles)
    handles.numplotspks = round(get(hObject,'Value'));      %The number of plot spikes is the rounded value of the slider.
    set(handles.lblNumPlotSpks,'String',['Showing ' num2str(handles.numplotspks) ' Spikes']);   %Set the slider label to show the new value.
    handles = PlotSpikes(handles, hObject);     %Replot the spikes with the new number of plot spikes.
    guidata(hObject, handles);                  %Update the handles structure to the GUI.

    
%**************************************************************************
%BUTTON PRESS ON cmdPCAsort --- Executes on button press in cmdPCAsort.
function cmdPCAsort_Callback(hObject, eventdata, handles)
    handles.sort_type = 'PCA';      %Set the sort type to PCA.
    if isempty(handles.PCs)         %If the components aren't calculated yet...
        handles = CalculatePCAs(handles, hObject);  %Calculate spike features.
    end
    handles = ClusterByPCA(handles, hObject);       %Cluster using PCA.
    handles = PlotSpikes(handles, hObject);         %Plot the spikeshapes in the main window
    handles = PlotClusters(handles, hObject);       %Plot the Templates, PSTHs, and ISIs.
    handles = PlotSecondary(handles, hObject);      %Plot the secondary plot depending on sort type.
    handles = EnableButtons(handles, hObject);      %Enable the correct buttons.
    guidata(hObject, handles);                      %Update the handles structure to the GUI.

    
%**************************************************************************
%BUTTON PRESS ON cmdDefine --- Executes on button press in cmdDefine.
function cmdDefine_Callback(hObject, eventdata, handles)
    %Call the NEL_Spike_Sorter_PCA GUI for user input.
    [handles.currentPCs, handles.cluster, handles.draw] = ...
        NEL_Spike_Sorter_PCA(handles.cluster,handles.PCs,handles.currentPCs,handles.PCAlabels,handles.subthreshold,handles.draw);
    handles.num_clusters = double(max(handles.cluster));    %Reset the number of clusters.
    handles = PlotSpikes(handles, hObject);         %Plot the spikes in the main plot.
    axes(handles.picSecondary);     %We'll put a "Caculating..." message in the secondary window.
    cla;                            %Reset the secondary plot to blank axes.
    set(gca,'xlim',[-1 1],'ylim',[-1,1],'xticklabel',[],'yticklabel',[],'xtick',[],...
        'ytick',[],'color','k','xcolor','w','ycolor','w','yscale','linear');
    text(0,0,['Calculating templates, PSTHs, and ISIs...'],'interpreter','none','fontweight','bold',...    %Show the "Calculating..." message.
        'color','w','fontsize',16,'horizontalalignment','center','verticalalignment','middle');
    drawnow;                        %Refresh the axes before running the rest of the code.
    handles = PlotClusters(handles, hObject);       %Plot the templates, PSTHs, and ISI is figure 1.
    handles = PlotSecondary(handles, hObject);   	%Plot the PCA components plot.
    handles = EnableButtons(handles, hObject);      %Enable the correct buttons.
    guidata(hObject, handles);                      %Update the handles structure to the GUI.
    
    
%**************************************************************************
%BUTTON PRESS ON cmdWindowsort --- Executes on button press in cmdWindowsort.
function cmdWindowsort_Callback(hObject, eventdata, handles)
    handles.sort_type = 'Window';                   %Set the sort type to Window.
    handles = ClusterByWindow(handles, hObject);    %Cluster using windows.
    handles = PlotSpikes(handles, hObject);         %Plot the spikeshapes in the main window
    handles = PlotClusters(handles, hObject);       %Plot the Templates, PSTHs, and ISIs.
    handles = PlotSecondary(handles, hObject);      %Plot the secondary plot depending on sort type.
    handles = EnableButtons(handles, hObject);      %Enable the correct buttons.
    guidata(hObject, handles);                      %Update the handles structure to the GUI.


%**************************************************************************
%BUTTON PRESS ON cmdSetWindows --- Executes on button press in cmdSetWindows.
function cmdSetWindows_Callback(hObject, eventdata, handles)
    %Call the NEL_Spike_Sorter_PCA GUI for user input.
    [handles.windows, handles.cluster] = ...
        NEL_Spike_Sorter_Window(handles.cluster,handles.spikes,handles.windows,handles.subthreshold);
    handles.num_clusters = max(handles.cluster);    %Reset the number of clusters.
    handles = PlotSpikes(handles, hObject);         %Plot the spikes in the main plot.
    axes(handles.picSecondary);     %We'll put a "Caculating..." message in the secondary window.
    cla;                            %Reset the secondary plot to blank axes.
    set(gca,'xlim',[-1 1],'ylim',[-1,1],'xticklabel',[],'yticklabel',[],'xtick',[],...
        'ytick',[],'color','k','xcolor','w','ycolor','w','yscale','linear');
    text(0,0,['Calculating templates, PSTHs, and ISIs...'],'interpreter','none','fontweight','bold',...    %Show the "Calculating..." message.
        'color','w','fontsize',16,'horizontalalignment','center','verticalalignment','middle');
    drawnow;                        %Refresh the axes before running the rest of the code.
    handles = PlotClusters(handles, hObject);       %Plot the Templates, PSTHs, and ISIs.
    handles = TemplateMaker(handles, hObject);       %Make the templates for plotting.
    handles = PlotSecondary(handles, hObject);    	%Plot the Windows components plot.
    handles = EnableButtons(handles, hObject);      %Enable the correct buttons.
    guidata(hObject, handles);                      %Update the handles structure to the GUI.


%**************************************************************************
%BUTTON PRESS ON cmdRethreshold --- Executes on button press in cmdRethreshold.
function cmdRethreshold_Callback(hObject, eventdata, handles)
    axes(handles.picShapes);    %Set the current axes to the large plot.
    hold on;    %Hold the axes as they're plotted.
    %Display some text on the top of the plot tell the user how to select clusters.
    text(min(get(gca,'xlim')),max(get(gca,'ylim')),...
        [' Current Threshold is ' num2str(roundn(1000000*handles.threshold(2),-2))...
        ' \muV, click left button to set new threshold, click right button to cancel.'],...
        'fontsize',12,'verticalalignment','top','horizontalalignment','left','color','w');
    line(get(gca,'xlim'),1000000*[1,1]*handles.threshold(2),'color','w','linestyle',':');   %Show the existing threshold.
    line([1,1]*handles.threshold(1),get(gca,'ylim'),'color','w','linestyle',':');   %Show the existing threshold sample point.
    [x,y,b] = ginput(1);    %Have the user select a new threshold;
    if b == 1
        temp = length(handles.subthreshold);        %Grab the number of subthreshold spikes to begin with.
        handles.threshold = [round(x), y/1000000];  %Set the threshold to the user-defined level;
        if handles.threshold(2) > 0     %If the threshold is positive, set all spikes below the threshold to noise.
            handles.subthreshold = find(handles.spikes(:,handles.threshold(1)) < handles.threshold(2));
        else    %If the threshold is negative, set all spikes above the threshold to noise.
            handles.subthreshold = find(handles.spikes(:,handles.threshold(1)) > handles.threshold(2));
        end
        if temp > length(handles.subthreshold)  %If we lowered the threshold, we have to assign now-suprathreshold spikes.
            if strcmpi(handles.sort_type,'Template')    %If we're template sorting...
                handles = TemplateSortSpikes(handles, hObject);     %Sort using existing templates.
            elseif strcmpi(handles.sort_type,'SPC')     %If we're SPC sorting...
                handles = ClusterByTemp(handles, hObject);  %Cluster using the new temperature.
            elseif strcmpi(handles.sort_type,'PCA')     %If we're PCA sorting...
                handles = ClusterByPCA(handles, hObject);   %Cluster using PCA boundaries.
            elseif strcmpi(handles.sort_type,'Window')  %If we're window sorting...
                handles = ClusterByWindow(handles, hObject);    %Cluster using windows.
            else                                        %Or if the method isn't yet chosen...
                handles.cluster(:) = 1;                 %Set all spikes to cluster #1.
                handles.cluster(handles.subthreshold) = 0;	%Then set any subthreshold spikes to noise.
            end
        else    %If we've raised the threshold, just set nearly subthreshold spikes to noise.
            handles.cluster(handles.subthreshold) = 0;	%Set any subthreshold spikes to noise.
        end
    end
    handles = PlotSpikes(handles, hObject);         %Plot the spikeshapes in the main window
    handles = PlotClusters(handles, hObject);       %Plot the Templates, PSTHs, and ISIs.
    handles = PlotSecondary(handles, hObject);      %Plot the secondary plot depending on sort type.
    handles = EnableButtons(handles, hObject);      %Enable the correct buttons.
    guidata(hObject, handles);                      %Update the handles structure to the GUI.

    
%**************************************************************************
%BUTTON PRESS ON cmdClear --- Executes on button press in cmdClear.
function cmdClear_Callback(hObject, eventdata, handles)
    handles.cluster(:) = 1;                             %Assign all spikes to one cluster.
    handles.num_clusters = 1;                           %Reset the number of clusters.
    if size(handles.spikes,2) == 64                     %Reset the threshold.
        if mean(handles.spikes(:,20)) < 0
            handles.threshold = [20, max(handles.spikes(:,20))];
        else
            handles.threshold = [20, min(handles.spikes(:,20))];
        end
    end    
    handles.subthreshold = [];
    handles.draw = [];                                  %Clear any drawn boundaries.
    handles.windows = [];                            	%Clear any user-defined windows.
    handles.sort_type = 'Undefined';                    %Set the sort type to none.
    handles = PlotSpikes(handles, hObject);          	%Replot the spike shapes.
    handles = PlotSecondary(handles, hObject);      	%Replot the secondary plot.
    handles = PlotClusters(handles, hObject);          	%Replot the PSTHs and ISIs.
    handles = EnableButtons(handles, hObject);          %Enable the correct buttons.
    guidata(hObject, handles);                          %Update the handles structure to the GUI.


%**************************************************************************
%BUTTON PRESS ON cmdTemplatesort --- Executes on button press in cmdTemplatesort.
function cmdTemplatesort_Callback(hObject, eventdata, handles)
    if ~strcmpi(handles.sort_type,'Template')   %If templates aren't yet made for these spikes.
        handles = TemplateMaker(handles, hObject);  %Use current clusters to make templates.
    end
    handles.sort_type = 'Template';                 %Set the sort type to template.
    handles = TemplateSortSpikes(handles, hObject);     %Sort the spikes using the loaded templates.
    handles = PlotSpikes(handles, hObject);     %Plot the spikeshapes in the main window
    handles = PlotClusters(handles, hObject);       %Plot the Templates, PSTHs, and ISIs.
    handles = PlotSecondary(handles, hObject);	%Plot the templates in the secondary plot.
    handles = EnableButtons(handles, hObject);      %Enable the correct buttons.
    guidata(hObject, handles);                      %Update the handles structure to the GUI.
    

%**************************************************************************
%BUTTON PRESS ON cmdSave --- Executes on button press in cmdSave.
function cmdSave_Callback(hObject, eventdata, handles)
    handles = DisableButtons(handles, hObject);    	%Disable all buttons.
    pause(0.1);                                     %Pause for half a second to allow buttons to disable.
    handles = SaveClusters(handles, hObject);       %Use a separate function to call these clusters.
    handles = EnableButtons(handles, hObject);      %Enable the correct buttons.
    [signal, Fs, bits] = wavread(handles.load_sound);	%Load a sound to let the user know the file is loaded.
    soundsc(signal,Fs);                                	%Play the loaded sound.
    guidata(hObject, handles);                      %Update the handles structure to the GUI.
    
    
%**************************************************************************
%BUTTON PRESS ON cmdBatch --- Executes on button press in cmdBatch.
function cmdBatch_Callback(hObject, eventdata, handles)
    handles = DisableButtons(handles, hObject);    	%Disable all buttons.
    pause(0.1);                                     %Pause for half a second to allow buttons to disable.
    temp = find(handles.file == '\',1,'last'); 	%Find the point in the file name containing the channel number.
    temp = handles.file(temp+1:temp+3);         %Pull out the channel number.
    temp = ['*' temp '*' handles.rat '*.SPK'];  %Only allow the user to select file from the same channel from the same rat.
    %Have the user select files for batch sorting.
    [temp, path] = uigetfile(temp,'Select Multiple Files for Batch Sorting','Batch Sort','MultiSelect','On');
    files = [];     %Create a structure to hold file names.
    if isstr(temp)      %If the user only selected one *.SPK file.
        files(1).name = [temp];    %Add the path name to the file name.
    elseif iscell(temp)             %If the user selected multiple files.
        for i = 1:length(temp)      %Step through by file...
            files(i).name = [temp{i}];     %Add the path name to the file name for each file..
        end
    end
    if ~isempty(files)          %If any files were selected...
        cd(path);               %Change the directory to these files' path.
        for i = 1:length(files) %Step through by file.
            handles.file = [path files(i).name];                   %Set the current file.
            handles.fileroot = [path files(i).name(1:length(files(i).name)-4)];   %Find the root file name.
            handles = SaveClusters(handles, hObject);       %Use a separate function to call these clusters.
        end
    end
    handles = EnableButtons(handles, hObject);      %Enable the correct buttons.
    [signal, Fs, bits] = wavread(handles.load_sound);	%Load a sound to let the user know the file is loaded.
    soundsc(signal,Fs);                                	%Play the loaded sound.
    guidata(hObject, handles);                      %Update the handles structure to the GUI.
    

%**************************************************************************
%FUNCTION SaveClusters --- Save the new cluster assignments to the *.SPK file.
function handles = SaveClusters(handles, hObject)
    axes(handles.picShapes);        %We'll put a "Saving..." message in the main spikeshapes window.
    temp = find(handles.file == '\',1,'last'); 	%Find the point in the file name containing the channel number.
    temp = handles.file(temp+1:length(handles.file));         %Pull out the channel number.
    cla;    %Reset the spikeshapes plot to blank axes.
    set(gca,'xlim',[-1 1],'ylim',[-1,1],'xticklabel',[],'yticklabel',[],'xtick',[],...
        'ytick',[],'color','k','xcolor','w','ycolor','w','yscale','linear');
    text(0,0,['Sorting all spikes for: ' temp],'interpreter','none','fontweight','bold',...    %Show the "Loading..." message.
        'color','w','fontsize',16,'horizontalalignment','center','verticalalignment','middle');
    drawnow;    %Refresh the axes before running the rest of the code.
    %Here, we'll initialize any constants we'll need for sorting depending on the sort method.     
    disp(['Saving Clusters for: ' handles.file(find(handles.file == '\',1,'last')+1:length(handles.file))]);   %Display the file name to keep track of which files have been processed.
    fid = fopen(handles.file,'r+');   	%Open the *.SPK file for reading and writing.
    fseek(fid,1,'bof');               	%Skip past the daycode.
    numchar = fread(fid,1,'int8');      %Find the number of characters in the rat's name.
    handles.rat = char(fread(fid,numchar,'uchar'))';    %Rat name.
    handles.spont_delay = fread(fid,1,'int16');  %Spontaneous rate measurement delay (ms).
    handles.sampling_rate = single(fread(fid,1,'float32'));     %Sampling rate, in Hz.
    num_spike_samples = fread(fid,1,'int16');	%The number of spike shape samples.
    if strcmpi(handles.sort_type,'Template')    %If we're template sorting...
        templates = handles.templates(:,1:num_spike_samples);           %Grab the template means.
        maxdist = handles.templates(:,num_spike_samples+1);             %Grab the euclidian distant limit.
        pointdist = handles.templates(:,num_spike_samples+2:2*num_spike_samples+1); %Grab the point-to-point limit.
        pointlimit = handles.templates(1,2*num_spike_samples+2);        %Grab the maximum number of points that can exceed the template.
        distances = nan(1,handles.num_clusters);     %Set up a matrix to receive Euclidian distances.
    end
    numparams = fread(fid,1,'int8');         	%Number of stimulus parameters.
    for i = 1:numparams                         %Step through the number of parameters.
        numchar = fread(fid,1,'int16');      	%Number of characters in a parameter name.
        fseek(fid,numchar,'cof');               %Skip the parameter name.
    end
    handles.spikes = single(zeros(handles.max_spikes,num_spike_samples));	%Preallocate the spikeshape matrix.
    handles.times = single(zeros(handles.max_spikes,1));                    %Preallocate the spike time matrix.
    handles.cluster = uint8(zeros(handles.max_spikes,1));                   %Preallocate the cluster matrix.
    index = 1;                                                              %Keep track of the current row in the spikeshap matrix.
    handles.numsweeps = 0;          %Set the number of sweeps to zero.
    max_spike_break = 0;            %Keep track of the point after which we've got >25,000 spikes.
    sweeplength = [];               %Save the sweeplengths.
    while ~feof(fid)
        i = fread(fid,1,'int16');       %Stimulus index
        try
            if ~isempty(i)
                sweeplength = [sweeplength; single(fread(fid,1,'float32'))];    %Sweeplength, in seconds.
                fseek(fid,4*numparams,'cof');     %Skip the parameter values.                
                numsweeps = uint16(fread(fid,1,'uint16'));      %Number of sweeps to follow.
                for j = 1:numsweeps
                    fseek(fid,14,'cof');     %Skip the timestamp, order, and noise estimate.
                    numspikes = fread(fid,1,'uint32');	%Number of spikes.
                    for m = 1:numspikes
                        spiketime = single(fread(fid,1,'float32'));    %Grab the spike time.
                        cluster = uint8(fread(fid,1,'uint8'));          %Grab the cluster assignment
                        spikeshape = single(fread(fid,num_spike_samples,'float32')');   %Grab the spike shape.
                        if strcmpi(handles.sort_type,'Template')    %If we're template sorting...
                            for i = 1:size(handles.templates,1)      %Step through by cluster.
                                %Compute the Euclidian distance between the spike shape and the template.
                                distances(i) = sqrt(sum((spikeshape - templates(i,:)).^2));
                                %If the spike is more than than maximum distance from the template, or if 
                                %too many points fall outside the point limit.
                                if distances(i) > maxdist(i) || sum(abs(spikeshape - templates(i,:)) > pointdist(i,:)) > pointlimit
                                    distances(i) = NaN;         %Set the template match to NaN.
                                end
                            end
                            [c,i] = min(distances);     %Find the template with the minimum distance to the spikeshape.
                            if isnan(c)         %If no templates fit, this is a noise cluster.
                                cluster = 0;
                            else                %Otherwise the cluster is the matching template number.
                                cluster = i;
                            end
                        elseif strcmpi(handles.sort_type,'PCA')     %If we're PCA sorting...
                        elseif strcmpi(handles.sort_type,'Window')  %If we're window sorting...
%                             handles.cluster(:) = 0;   %Start with all clusters assigned to noise.
%                             %Step through drawn cluster windows.
%                             for i = 1:length(handles.windows)
%                                 test = 1;       %Start off by assuming that all spikes pass through the window.
%                                 test(find(handles.cluster ~= 0)) = 0;   %Any spikes already assigned in previous passes are ignored.
%                                 for j = 1:size(handles.windows(i).values,1)   %Step through by window.
%                                     xy = handles.windows(i).values(j,:);        %Grab the endpoints for this window.
%                                     indices = [fix(min(xy(1:2))):ceil(max(xy(1:2)))];	%Find the sample indices for the spike snippets.
%                                     temp = 1000000*handles.spikes(:,indices) - xy(3);  	%Create matrix with only the relevant spikeshape snippet.
%                                     indices = indices - xy(1);              %Set the x-values relative to the first window endpoint.
%                                     xy = [0, xy(2)-xy(1), 0, xy(4)-xy(3)];  %Set the first endpoint at the origin of rotated axes. 
%                                     test(find(max(temp,[],2) < min(xy(3:4)) | min(temp,[],2) > max(xy(3:4)))) = 0;	%Disqualify all spikes that never cross the bounding box.
%                                     a = find(test == 1);                    %Pull up all still-qualified spikes.
%                                     temp(a,1) = (min(xy(1:2))-indices(1))*(temp(a,2)-temp(a,1)) + temp(a,1);	%Interpolate the left-most endpoint snippet values.
%                                     b = size(temp,2);   %Find how many samples are in each snippet.
%                                     temp(a,b) = (max(xy(1:2))-indices(b-1))*(temp(a,b)-temp(a,b-1)) + temp(a,b-1);  %Interpolate the right-most endpoint snippet values.
%                                     indices([1,b]) = [min(xy(1:2)),max(xy(1:2))];   %Cut off the parts of the snippet that stick out past the window endpoints.
%                                     if xy(2) ~= 0   %If the window isn't a straight vertical line...
%                                         xy = indices*(xy(4)/xy(2)); %Calculate the value of the segment at the discrete sample points.
%                                     else            %Otherwise if it is a perfectly vertical line...
%                                         xy = [0 xy(4)];             %Set the values as the upper and lower endpoints.
%                                     end
%                                     for k = 1:length(xy)    %Step through by sample point...
%                                         temp(a,k) = temp(a,k) - xy(k);  %Subtract the value of the segment at the sample point.
%                                     end
%                                     a = a(find(max(temp(a,:),[],2) >= 0 & min(temp(a,:),[],2) <= 0));   %Find all spikeshapes with points above AND below the window.
%                                     test(setdiff([1:handles.numspikes],a)) = 0;     %Any spikeshapes that don't pass through the window are tossed out.
%                                 end
%                                 handles.cluster(find(test == 1)) = i;   %Any spikeshapes that made it through all the windows are added to the cluster.
                        else                                        %If there's no method chosen...
                            cluster = 1;    %Set all spikes to cluster #1.
                        end
                        fseek(fid,-1-4*num_spike_samples,'cof');            %Move the file position indicator back to the cluster assignment.
                        fwrite(fid,cluster,'uint8');                        %Write over the previous cluster assigment.
                        fseek(fid,4*num_spike_samples,'cof');               %Then skip back over the spike shape.
                        if max_spike_break == 0
                            handles.spikes(index,:) = spikeshape;           %Load up spikeshapes.
                            handles.cluster(index) = cluster;               %Load up cluster assignments.
                            handles.times(index) = spiketime;               %Load up spike times.
                            index = index + 1;
                        end
                    end
                    %If we've loaded up enough spikes for spike-sorting, stop loading.
                    if max_spike_break == 0     %If we haven't hit the maximum number of spikes we want to load...
                        if index - 1 > handles.max_spikes  %Check to see if we're at maximum...
                            max_spike_break = index - 1;   %If so, save the number of spikes.
                        else        %Otherwise...
                            handles.numsweeps = handles.numsweeps + 1;	%Keep track of how many sweeps we've loaded.
                        end
                    end
                end
            end
        catch
            warning(['Error in reading sweep ' num2str(i) ' for this file, stopping file read at last complete sweep.']); %#ok<WNTAG>
        end
    end
    fclose(fid);    %Close the input file.
    if index <= handles.max_spikes
        handles.times(index:handles.max_spikes) = [];
        handles.cluster(index:handles.max_spikes) = [];
        handles.spikes(index:handles.max_spikes,:) = [];
    end
    handles.numspikes = size(handles.spikes,1);     %Find the exact number of spikeshapes we've grabbed.
    handles.sweeplength = 1000*min(sweeplength);	%Grab the shortest sweeplength.
    if handles.sweeplength > 500            %If the sweeplength is long, we'll only plot the first 500 ms in our PSTHs.
        handles.sweeplength = 500;
    end
    handles.min_clus = handles.numsweeps/2;     %Set a minimum cluster size for SPC.
    handles.num_clusters = double(max(handles.cluster));    %Find the number of clusters identified in this *.SPK file.
    cla;    %Reset the spikeshapes plot to blank axes.
    set(gca,'xlim',[-1 1],'ylim',[-1,1],'xticklabel',[],'yticklabel',[],'xtick',[],...
        'ytick',[],'color','k','xcolor','w','ycolor','w','yscale','linear');
    text(0,0,['Saving Clusters for: ' temp],'interpreter','none','fontweight','bold',...    %Show the "Loading..." message.
        'color','w','fontsize',16,'horizontalalignment','center','verticalalignment','middle');
    drawnow;    %Refresh the axes before running the rest of the code.
    handles = PlotSpikes(handles, hObject);         %Plot the spikeshapes in the main window
    handles = PlotClusters(handles, hObject);       %Plot the Templates, PSTHs, and ISIs.
    handles = PlotSecondary(handles, hObject);      %Plot the secondary plot depending on sort type.
    axes(handles.picShapes);     %We'll put a "Clusters Saved." message in the secondary window.
    hold on;                %Hold the plot as it is.
    %Display some text on the top of the plot tell the user how to set windows.
    text(min(get(gca,'xlim')),max(get(gca,'ylim')),' Clusters Saved.',...
        'fontsize',12,'verticalalignment','top','horizontalalignment','left','color','w');
    hold off;               %Release the plot hold.
    pause(2);   %Pause for 2 seconds to let the user see the results of this spike-sorting.
    guidata(hObject, handles);                      %Update the handles structure to the GUI.

    
%**************************************************************************
%BUTTON PRESS ON cmdSaveTemplates --- Executes on button press in cmdSaveTemplates.
function cmdSaveTemplates_Callback(hObject, eventdata, handles)
    temp = double(handles.templates);   %The save function won't accept only the field of a structure.
    save([handles.fileroot '.NEL_template'],'temp','-ascii','-double');  %Save the templates as a simple ASCII file.
    axes(handles.picSecondary);     %We'll put a "Templates Saved." message in the secondary window.
    hold on;                %Hold the plot as it is.
    %Display some text on the top of the plot tell the user how to set windows.
    text(min(get(gca,'xlim')),max(get(gca,'ylim')),' Templates Saved.',...
        'fontsize',12,'verticalalignment','top','horizontalalignment','left','color','w');
    hold off;               %Release the plot hold.
    guidata(hObject, handles);                      %Update the handles structure to the GUI.

    
%**************************************************************************
%BUTTON PRESS ON cmdLoadTemplates --- Executes on button press in cmdLoadTemplates.
function cmdLoadTemplates_Callback(hObject, eventdata, handles)
    [file path] = uigetfile('*.NEL_template');  %Have the use select a template file.
    if file ~= 0
        handles.templates = single(load([path file]));     	%Load the templates.
        handles.num_clusters = size(handles.templates,1);   %Reset the number of clusters.
        handles = TemplateSortSpikes(handles, hObject);     %Sort the spikes using the loaded templates.
        handles = PlotSpikes(handles, hObject);     %Plot the spikeshapes in the main window
        handles = PlotClusters(handles, hObject);       %Plot the Templates, PSTHs, and ISIs.
        handles = PlotSecondary(handles, hObject);	%Plot the templates in the secondary plot.
        handles = EnableButtons(handles, hObject);      %Enable the correct buttons.
    end
    guidata(hObject, handles);                      %Update the handles structure to the GUI.


%**************************************************************************
%BUTTON PRESS ON cmdSavePCA --- Executes on button press in cmdSavePCA.
function cmdSavePCA_Callback(hObject, eventdata, handles)
    temp = 0;                                       %First we'll need to find the cluster with the most vertices.
    for i = 1:length(handles.draw)                  %Step through by cluster.
        if size(handles.draw(i).values,2) > temp    %If this has more vertices than the previous maximum...
            temp = size(handles.draw(i).values,2);  %Then this is the new maximum.
        end
    end
    temp = nan(2*length(handles.draw),temp+1);   %Define a simple matrix to hold the data.
    for i = 1:length(handles.draw)  %Step through by cluster and put the boundary vertices into the matrix.
        temp(2*i-1:2*i,1:size(handles.draw(i).values,2)+1) = [handles.draw(i).PCs',handles.draw(i).values];
    end
    save([handles.fileroot '.NEL_PCA'],'temp','-ascii','-double');  %Save the matrix as a simple ASCII file.
    axes(handles.picSecondary);     %We'll put a "PCA Saved." message in the secondary window.
    hold on;                %Hold the plot as it is.
    %Display some text on the top of the plot tell the user how to set windows.
    text(min(get(gca,'xlim')),max(get(gca,'ylim')),' PCA Saved.',...
        'fontsize',12,'verticalalignment','top','horizontalalignment','left','color','w');
    hold off;               %Release the plot hold.
    guidata(hObject, handles);                      %Update the handles structure to the GUI.


%**************************************************************************
%BUTTON PRESS ON cmdLoadPCA --- Executes on button press in cmdLoadPCA.
function cmdLoadPCA_Callback(hObject, eventdata, handles)
    [file path] = uigetfile('*.NEL_PCA');   %Have the use select a PCA file.
    if file ~= 0
        handles.draw = [];                  %Clear any existing boundaries.
        temp = load([path file]);         	%Load the PCA boundaries.
        for i = 1:size(temp,1)/2            %Step through by cluster.
            handles.draw(i).PCs = temp(2*i-1:2*i,1)';   %Grab the PC axes for this cluster.
            handles.draw(i).values = temp(2*i-1:2*i,2:find(~isnan(temp(2*i,:)),1,'last'));  %Grab the boundary values.
        end
        handles.num_clusters = length(handles.draw);   	%Reset the number of clusters.
        handles.currentPCs = [handles.draw(1).PCs, NaN];%Set the current PCs to the first cluster.
        handles = ClusterByPCA(handles, hObject);   	%Sort the spikes using the loaded templates.
        handles = PlotSpikes(handles, hObject);         %Plot the spikeshapes in the main window
        handles = PlotClusters(handles, hObject);       %Plot the Templates, PSTHs, and ISIs.
        handles = PlotSecondary(handles, hObject);      %Plot the PCAs in the secondary plot.
        handles = EnableButtons(handles, hObject);      %Enable the correct buttons.
    end
    guidata(hObject, handles);                      %Update the handles structure to the GUI.


%**************************************************************************
%BUTTON PRESS ON cmdSaveWindows --- Executes on button press in cmdSaveWindows.
function cmdSaveWindows_Callback(hObject, eventdata, handles)
    temp = 0;                                           %First we'll need to find the cluster with the most windows.
    for i = 1:length(handles.windows)                   %Step through by cluster.
        if size(handles.windows(i).values,1) > temp     %If this has more windows than the previous maximum...
            temp = size(handles.windows(i).values,1);   %Then this is the new maximum.
        end
    end
    temp = nan(temp,4*length(handles.windows));   %Define a simple matrix to hold the data.
    for i = 1:length(handles.windows)  %Step through by cluster and put the windows into the matrix.
        temp(1:size(handles.windows(i).values,1),4*i-3:4*i) = handles.windows(i).values;
    end
    save([handles.fileroot '.NEL_Window'],'temp','-ascii','-double');  %Save the matrix as a simple ASCII file.
    axes(handles.picSecondary);     %We'll put a "PCA Saved." message in the secondary window.
    hold on;                %Hold the plot as it is.
    %Display some text on the top of the plot tell the user how to set windows.
    text(min(get(gca,'xlim')),max(get(gca,'ylim')),' Windows Saved.',...
        'fontsize',12,'verticalalignment','top','horizontalalignment','left','color','w');
    hold off;               %Release the plot hold.
    guidata(hObject, handles);                      %Update the handles structure to the GUI.


%**************************************************************************
%BUTTON PRESS ON cmdLoadWindows --- Executes on button press in cmdLoadWindows.
function cmdLoadWindows_Callback(hObject, eventdata, handles)
    [file path] = uigetfile('*.NEL_Window');   %Have the use select a Window file.
    if ~isempty(file)
        handles.windows = [];               %Clear any existing windows.
        temp = load([path file]);         	%Load the cluster windows.
        for i = 1:size(temp,2)/4            %Step through by cluster.
            handles.windows(i).values = temp(1:max(find(~isnan(temp(:,4*i-3)))),4*i-3:4*i);  %Grab the windows for this cluster.
        end
        handles.num_clusters = length(handles.windows);	%Reset the number of clusters.
        handles = ClusterByWindow(handles, hObject);       %Sort the spikes using the loaded templates.
        handles = PlotSpikes(handles, hObject);         %Plot the spikeshapes in the main window
        handles = PlotClusters(handles, hObject);       %Plot the Templates, PSTHs, and ISIs.
        handles = PlotSecondary(handles, hObject);      %Plot the PCAs in the secondary plot.
    end
    guidata(hObject, handles);                      %Update the handles structure to the GUI.


%**************************************************************************
%FUNCTION EnableButtons --- Sets "Enable" properties on buttons based on the selected sorting method.
function handles = EnableButtons(handles, hObject)
    set(handles.cmdLoad,'Enable','On');             %Make sure the load button is enabled.
    %If we're using SPC sorting.
    if strcmpi(handles.sort_type,'SPC')
        set(handles.cmdSave,'Enable','Off');        %Disable the save button.
        set(handles.cmdBatch,'Enable','Off');    	%Disable the batch button.
        if exist([handles.fileroot '.dg_01']) & exist([handles.fileroot '.dg_01.lab'])  %If SPC output files exist...
            set(handles.cmdAdjustTemp,'Enable','On');   %Enable the temperature adjust button.
        else
            set(handles.cmdAdjustTemp,'Enable','Off');  %Otherwise keep it off.
        end
    else
        set(handles.cmdAdjustTemp,'Enable','Off');  %Disable the adjust temp button.
    end        
    set(handles.cmdSPCsort,'Enable','On');  %Enable SPC sorting regardless.
    %If the PCA output files exist, enable the define clusters button.
    if strcmpi(handles.sort_type,'PCA')
        set(handles.cmdDefine,'Enable','On');
        if ~isempty(handles.draw)
            set(handles.cmdSavePCA,'Enable','On');
        end
        set(handles.cmdLoadPCA,'Enable','On');
    else
        set(handles.cmdDefine,'Enable','Off');
        set(handles.cmdSavePCA,'Enable','Off');
        set(handles.cmdLoadPCA,'Enable','Off');
    end
    set(handles.cmdPCAsort,'Enable','On'); %Enable PCA sorting regardless.
    %If the Window sort output files exist, enable the set windows button.
    if strcmpi(handles.sort_type,'Window')
        set(handles.cmdSetWindows,'Enable','On');
        if ~isempty(handles.windows)
            set(handles.cmdSaveWindows,'Enable','On');
        end
        set(handles.cmdLoadWindows,'Enable','On');
    else
        set(handles.cmdSetWindows,'Enable','Off');
        set(handles.cmdSaveWindows,'Enable','Off');
        set(handles.cmdLoadWindows,'Enable','Off');
    end
    set(handles.cmdWindowsort,'Enable','On'); %Enable window sorting regardless.
    %If the template sort output files exist, enable the set templates buttons.
    if strcmpi(handles.sort_type,'Template')
        set(handles.cmdSaveTemplates,'Enable','On');
        set(handles.cmdLoadTemplates,'Enable','On');
        set(handles.hscMaxDist,'Enable','On');
        set(handles.hscPointLimit,'Enable','On');
        set(handles.lblMaxDist,'Enable','On');
        set(handles.lblPointLimit,'Enable','On');
        set(handles.cmdSave,'Enable','On');         %Enable the save button.
        set(handles.cmdBatch,'Enable','On');    	%Disable the batch button.
    else
        set(handles.cmdSaveTemplates,'Enable','Off');
        set(handles.cmdLoadTemplates,'Enable','Off');
        set(handles.hscMaxDist,'Enable','Off');
        set(handles.hscPointLimit,'Enable','Off');
        set(handles.lblMaxDist,'Enable','On');
        set(handles.lblPointLimit,'Enable','On');
        if get(handles.hscMaxDist,'Max') < handles.max_radius
            set(handles.hscMaxDist,'Max',handles.max_radius);
        end
        set(handles.hscMaxDist,'Value',handles.max_radius);
        if get(handles.hscPointLimit,'Max') < handles.pointlimit
            set(handles.hscPointLimit,'Max',handles.pointlimit);
        end
        set(handles.hscPointLimit,'Value',handles.pointlimit);
        set(handles.cmdSave,'Enable','Off');         %Enable the save button.
        set(handles.cmdBatch,'Enable','Off');    	%Disable the batch button.
    end
    set(handles.cmdTemplatesort,'Enable','On'); %Enable template sorting regardless.
    set(handles.hscNumPlotSpks,'Enable','On');  %Enable the number of plot spikes slider.
    set(handles.lblNumPlotSpks,'Enable','On');  %Enable the number of plot spikes label.
    set(handles.cmdRethreshold,'Enable','On');  %Enable the Rethresholding button.
    if ~isequal(unique(handles.cluster),[1]); 	%If the cluster assignments aren't already cleared.
        set(handles.cmdClear,'Enable','On');    %Enable the clear all option.
    else
        set(handles.cmdClear,'Enable','Off');    %Enable the clear all option.
    end
    guidata(hObject, handles);                  %Update the handles structure to the GUI.
    
    
%**************************************************************************
%FUNCTION DisableButtons --- Disable all buttons during saving functions.
function handles = DisableButtons(handles, hObject)
    set(handles.cmdLoad,'Enable','Off');
    set(handles.cmdSave,'Enable','Off');
    set(handles.cmdBatch,'Enable','Off');
    set(handles.cmdAdjustTemp,'Enable','Off');
    set(handles.cmdSPCsort,'Enable','Off');
    set(handles.cmdDefine,'Enable','Off');
    set(handles.cmdSavePCA,'Enable','Off');
    set(handles.cmdLoadPCA,'Enable','Off');
    set(handles.cmdPCAsort,'Enable','Off');
    set(handles.cmdSetWindows,'Enable','Off');
    set(handles.cmdSaveWindows,'Enable','Off');
    set(handles.cmdLoadWindows,'Enable','Off');
    set(handles.cmdWindowsort,'Enable','Off');
    set(handles.cmdSaveTemplates,'Enable','Off');
    set(handles.cmdLoadTemplates,'Enable','Off');
    set(handles.hscMaxDist,'Enable','Off');
    set(handles.hscPointLimit,'Enable','Off');
    set(handles.lblMaxDist,'Enable','Off');
    set(handles.lblPointLimit,'Enable','Off');
    set(handles.cmdTemplatesort,'Enable','Off');
    set(handles.hscNumPlotSpks,'Enable','Off');
    set(handles.lblNumPlotSpks,'Enable','Off');
    set(handles.cmdRethreshold,'Enable','Off');
    set(handles.cmdClear,'Enable','Off');
    guidata(hObject, handles);                  %Update the handles structure to the GUI.


%**************************************************************************
%SLIDER MOVEMENT on hscMaxDist --- Executes when user changes the value of the slider.
function hscMaxDist_Callback(hObject, eventdata, handles)
    %Grab the overall and point-by-point maximum distances for each
    %template and divide by maximum radius to find the standard deviation.
    ssize = size(handles.spikes,2);     %Grab the spike shape sample size.
    stdevs = handles.templates(:,ssize+1)/handles.max_radius;  
    pointdist = handles.templates(:,ssize+2:2*ssize+1)/handles.max_radius;
    handles.max_radius = get(hObject,'Value');     %The new maximum radius, in standard deviations, is the value of the slider.
    %Reset the maximum distance by multiplying standard deviations by the maximum radius.
    handles.templates(:,ssize+1) = stdevs*handles.max_radius;   
    handles.templates(:,ssize+2:2*ssize+1) = pointdist*handles.max_radius;
    handles = TemplateSortSpikes(handles, hObject);     %Sort the spikes using the loaded templates.
    handles = PlotSpikes(handles, hObject);     %Plot the spikeshapes in the main window
    handles = PlotClusters(handles, hObject);       %Plot the Templates, PSTHs, and ISIs.
    handles = PlotSecondary(handles, hObject);	%Plot the templates in the secondary plot.
    guidata(hObject, handles);                  %Update the handles structure to the GUI.
    
    
%**************************************************************************
%SLIDER MOVEMENT on hscPointLimit --- Executes when user changes the value of the slider.
function hscPointLimit_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
    temp = get(hObject,'Value');     %The new point limit is the round value of the slider.
    handles.templates(:,size(handles.templates,2)) = repmat(temp,handles.num_clusters,1);   %Reset the point limit.
    handles.pointlimit = temp;
    handles = TemplateSortSpikes(handles, hObject);     %Sort the spikes using the loaded templates.
    handles = PlotSpikes(handles, hObject);     %Plot the spikeshapes in the main window
    handles = PlotClusters(handles, hObject);       %Plot the Templates, PSTHs, and ISIs.
    handles = PlotSecondary(handles, hObject);	%Plot the templates in the secondary plot.
    guidata(hObject, handles);                  %Update the handles structure to the GUI.
    
    
%**************************************************************************
%OUTPUT  NEL_Spike_Sorter --- Return the output arguments, if there are any.
function varargout = NEL_Spike_Sorter_OutputFcn(hObject, eventdata, handles) 
    guidata(hObject, handles);  %Update handles structure
    
    
%THE FOLLOWING FUNCTIONS CONTAIN NO CODE, BUT ARE NECESSARY TO RUN THE GUI.  
%DON'T DELETE!
%**************************************************************************
%BUTTON PRESS ON picShapes --- Executes on button press in picShapes.
function picShapes_ButtonDownFcn(hObject, eventdata, handles)
%**************************************************************************
%BUTTON PRESS ON picSecondary --- Executes on button press in picSecondary.
function picSecondary_ButtonDownFcn(hObject, eventdata, handles)
%**************************************************************************
%CREATE hscNumPlotSpks --- Executes on creation of  press in hscNumPlotSpks.
function hscNumPlotSpks_CreateFcn(hObject, eventdata, handles)
%**************************************************************************
%CREATE hscMaxDist --- Executes on creation of  press in hscNumPlotSpks.
function hscMaxDist_CreateFcn(hObject, eventdata, handles)
%**************************************************************************
%CREATE hscPointLimit --- Executes on creation of  press in hscNumPlotSpks.
function hscPointLimit_CreateFcn(hObject, eventdata, handles)