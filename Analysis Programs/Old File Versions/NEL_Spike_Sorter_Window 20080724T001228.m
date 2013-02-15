function varargout = NEL_Spike_Sorter_Window(varargin)

%
%NEL_Spike_Sorter_Window.m - OU Neural Engineering Lab, 2008
%
%   NEL_Spike_Sorter_Window is a GUI used by the NEL_Spike_Sorter program to
%   visualize and identify spike clusters through principal components and
%   spike features.  The principal components and spike features are
%   actually defined and calculated in NEL_Spike_Sorter.m and are just
%   passed to this program.  Users can visualize the PCA or spike features
%   in 2-D or 3-D and can assign any component or spike feature to
%   whichever axis they choose.  Clusters are defined by either the user
%   manually selecting vertices for an encircling polygon or by identifying
%   the number of clusters to input into an automatic k-means clustering
%   function.  The cluster assignments and the principal components used to
%   define them are then passed back to NEL_Spike_Sorter.
%
%   [outputPCs, output_clusters] = ...
%   NEL_Spike_Sorter_Window(input_clusters,PCs,inputPCs,PClabels) sets up the
%   GUI for user input using the variables input_clusters, a single-column
%   matrix containing the current cluster assignments, PCs, an N-column
%   matrix containing columns of N spike components with each row
%   corresponding to the spike in input_clusters, inputPCs, a 1-by-3 matrix
%   containing the columns currently being used as the x,y,z distances, and
%   PClabels, a cell containing N titles for N components in PCs.  The
%   outputs are outputPCs, a 1-by-3 matrix containing the columns that were
%   selected by the user to use as the x,y,z distances, and
%   output_clusters, the new user-defined cluster assigments.
%
%   Last updated July 10, 2008, by Drew Sloan.

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @NEL_Spike_Sorter_Window_OpeningFcn, ...
                   'gui_OutputFcn',  @NEL_Spike_Sorter_Window_OutputFcn, ...
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
%OPEN NEL_SPIKE_SORTER_WINDOW --- Executes just before NEL_Spike_Sorter_Window is made visible.
function NEL_Spike_Sorter_Window_OpeningFcn(hObject, eventdata, handles, varargin)
    %We'll define several variables right up front, as well as pull out the input arguments.
    handles.cluster = varargin{1};      %The cluster assignments are the 1st argument in.
    handles.spikes = varargin{2};       %The spikeshapes are the 2nd argument in.
    handles.windows = varargin{3};      %Any pre-existing windows are the 3rd argument in.
    handles.subthreshold = varargin{4};	%The indices of subthreshold spikes following rethresholding are the 4th argument in.
    handles.numspikes = length(handles.cluster);    %The number of total spikes.
    handles.num_clusters = max(handles.cluster);    %The number of pre-existing clusters.
    handles.numplotspks = 500;        	%The default number of spikeshapes allowed in plotting.
    handles.maxplotspks = 2000;         %The maximum number of spikeshapes allowed in plotting.
    if handles.numspikes < handles.maxplotspks                  %If there's less than the maximum allowable spikeshapes for plotting...
        set(handles.hscNumPlotSpks,'Max',handles.numspikes);    %Set the slider limit to the total number of spikes.
    else        %Otherwise...
        set(handles.hscNumPlotSpks,'Max',handles.maxplotspks);  %Set the slider limit to the maximum.
    end
    set(handles.lblNumPlotSpks,'String',['Showing ' num2str(handles.numplotspks) ' Spikes']);     %Set the slider label to show the number of displayed spikes.
    set(handles.hscNumPlotSpks,'Max',handles.maxplotspks);      %Set the maximum of the plotted spikeshapes slider.
    set(handles.hscNumPlotSpks,'Value',handles.numplotspks);	%Set the slider to the maximum number of plotted spikeshapes.
    colors = lines(10);     %Create a good mix of colors for plotting different clusters.
    for i = 1:10            %Set the button foregrounds for each cluster to the matching color.
        eval(['set(handles.lbl' num2str(i) ',''ForegroundColor'',colors(i,:))']);
        eval(['set(handles.cmdAdd' num2str(i) ',''ForegroundColor'',colors(i,:))']);
        eval(['set(handles.cmdRemove' num2str(i) ',''ForegroundColor'',colors(i,:))']);
    end
    handles.max_radius = 3;    %The maximum radius of a cluster in standard deviations.
    handles.near_neigh = 10;   %The number of nearest neighbors.
    handles.min_nn = 10;       %The minimum number of nearest neighbors required for a vote.
    axes(handles.picSpikes);        %Set the current axes to the large plot.
    set(gca,'color','k','xcolor','w','ycolor','w','yscale','linear');   %Set the axes properties.
    axes(handles.picTemplates);     %Set axes to the secondary plot.
    set(gca,'color','k','xcolor','w','ycolor','w','yscale','linear','xscale','linear');   %Set the axes properties.
    handles = EnableButtons(handles, hObject);  %This function decides which buttons to enable.
    if ~isempty(handles.windows)    %If there are any pre-existing windows, run the spikes through them.
        handles = ClusterByWindow(handles, hObject)
    end
    handles = PlotWindows(handles, hObject);        %This function plots the selected spike components.
    guidata(hObject, handles);      %Update the GUI handles structure.
    uiwait(handles.WindowSorting);     %Make the NEL_Spike_Sorter_Window program wait for user input before returning an output to NEL_Spike_Sorter.


%**************************************************************************
%BUTTON PRESS ON cmdSet --- Executes on button press in cmdSet.
function cmdSet_Callback(hObject, eventdata, handles)
    uiresume(handles.WindowSorting);   %Let's NEL_Spike_Sorter close and return an output.
    
    
%**************************************************************************
%CLOSE WindowSorting --- Executes when user attempts to close the WindowSorting form.
function set_WindowSorting_CloseRequestFcn(hObject, eventdata, handles)
    if isequal(get(handles.WindowSorting, 'waitstatus'), 'waiting')    
        uiresume(handles.WindowSorting);   %If we're waiting for user input, cancel waiting.
    else
        delete(handles.WindowSorting);     %If the GUI isn't waiting, just close it.
    end

    
%**************************************************************************
%FUNCTION EnableButtons --- Enables add/remove window buttons and sets string and color properties.
function handles = EnableButtons(handles, hObject)
    for i = 1:10                %Disable all add and remove buttons.
        eval(['set(handles.cmdAdd' num2str(i) ',''Enable'',''Off'',''Visible'',''Off'')']);
        eval(['set(handles.cmdRemove' num2str(i) ',''Enable'',''Off'',''Visible'',''Off'')']);
        eval(['set(handles.lbl' num2str(i) ',''Enable'',''Off'',''Visible'',''Off'')']);
    end
    for i = 1:length(handles.windows)   %Enable all add and remove buttons for set clusters.
        eval(['set(handles.cmdAdd' num2str(i) ',''Enable'',''On'',''Visible'',''On'')']);
        eval(['set(handles.cmdRemove' num2str(i) ',''Enable'',''On'',''Visible'',''On'')']);
        eval(['set(handles.lbl' num2str(i) ',''Enable'',''On'',''Visible'',''On'')']);
    end
    %Enable the next cluster window add button.
    eval(['set(handles.cmdAdd' num2str(length(handles.windows)+1) ',''Enable'',''On'',''Visible'',''On'')']);
    eval(['set(handles.lbl' num2str(length(handles.windows)+1) ',''Enable'',''On'',''Visible'',''On'')']);
    guidata(hObject, handles);
    
    
%**************************************************************************
%FUNCTION PlotWindows --- Plot the selected spike components.
function handles = PlotWindows(handles, hObject)
    axes(handles.picSpikes);    %Set the current axes to the large plot.
    cla;                        %Clear the axes.
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
    ylabel('Voltage (\muV)','fontweight','normal','fontsize',12);   %Set the y axis label.
    set(gca,'xtick',[],'ytick',[-300:50:300]);  %Set the y axis ticks.
    for i = 1:length(handles.windows)   %Step through by cluster.
        for j = 1:size(handles.windows(i).values,1)     %Step through by window.
            xy = handles.windows(i).values(j,:);        %Grab the endpoints for this window.
            %Plot the window as a thick, darker line with circular endpoints.
            plot(xy(1:2),xy(3:4),'color','w','linewidth',4,...
                'marker','o','markerfacecolor',colors(i+1,:),'markersize',5);
            plot(xy(1:2),xy(3:4),'color',colors(i+1,:),'linewidth',2);  
        end
    end
    hold off;                           %Release the plot hold.
    drawnow;                            %Draw this plot before moving on.
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
    handles.templates = [templates, maxdist', pointdist];   %Keep all the template data in one matrix.
    axes(handles.picTemplates);     %Set axes to the secondary plot.
    cla;            %Clear the secondary axes.
    hold on;        %Hold the axes for multiple plots.
    spike_samples = size(handles.spikes,2);
    for i = 1:handles.num_clusters      %Step through by cluster...     
        plot(1000000*handles.templates(i,1:spike_samples),'color',colors(i+1,:),'linewidth',3);   %Plot the templates with a unique color.
        plot(1000000*(handles.templates(i,1:spike_samples) + handles.templates(i,spike_samples+2:2*spike_samples+1)),...
            'color',colors(i+1,:),'linestyle','--','linewidth',2);   %Plot the template point distance limits with a unique color.
        plot(1000000*(handles.templates(i,1:spike_samples) - handles.templates(i,spike_samples+2:2*spike_samples+1)),...
            'color',colors(i+1,:),'linestyle','--','linewidth',2);   %Plot the template point distance limits with a unique color.
    end
    axis tight;     %Tighten up the axes bounds.
    xlim([min(xlim)-1,max(xlim)+1]);    %Set the x axis limits to give some space.
    hold off;                           %Release the plot hold.
    ylabel('');         %Set the y axis label to blank.
    xlabel('');         %Set the x axis label to blank.
    set(gca,'xtick',[],'ytick',[-300:50:300],'yticklabel',[]);      %Set the y axis ticks.
    drawnow;                                        %Draw this plot before moving on.
    guidata(hObject, handles);          %Update handles structure

    
%**************************************************************************
%OUTPUT  NEL_Spike_Sorter_Window --- Return the output arguments to NEL_Spike_Sorter.
function varargout = NEL_Spike_Sorter_Window_OutputFcn(hObject, eventdata, handles) 
    varargout{1} = handles.windows;     %The first output argument is the windows.
    varargout{2} = handles.cluster;     %The second output argument is the new cluster assignments.
    delete(handles.WindowSorting);   	%Close NEL_Spike_Sorting_PCA.
   
    
%**************************************************************************
%SLIDER MOVEMENT on hscNumPlotSpks --- Executes when user changes the value of the slider.
function hscNumPlotSpks_Callback(hObject, eventdata, handles)
    handles.numplotspks = round(get(hObject,'Value'));      %The number of plot spikes is the rounded value of the slider.
    set(handles.lblNumPlotSpks,'String',['Showing ' num2str(handles.numplotspks) ' Spikes']);   %Set the slider label to show the new value.
    handles = PlotWindows(handles, hObject);    %Replot the PCs with the new number of plot spikes.
    guidata(hObject, handles);              %Update the handles structure to the GUI.

    
%**************************************************************************
%CREATE hscNumPlotSpks --- This function is require by the GUI, even though it doesn't do anything.
function hscNumPlotSpks_CreateFcn(hObject, eventdata, handles)


%**************************************************************************
%BUTTON PRESS ON cmdClear --- Executes on button press in cmdClear.
function cmdClear_Callback(hObject, eventdata, handles)
    handles.cluster(1:length(handles.cluster)) = 1;     %Assign all spikes to one cluster.
    handles.num_clusters = 1;                           %Reset the number of clusters.
    handles.cluster(handles.subthreshold) = 0;          %Set any subthreshold spikes to noise.
    handles.windows = [];                               %Clear any drawn windows.
    handles = EnableButtons(handles, hObject);          %This function decides which buttons to enable.
    handles = PlotWindows(handles, hObject);            %Replot the spikeshapes.
    guidata(hObject, handles);                          %Update the handles structure to the GUI.

    
%**************************************************************************
%FUNCTION DrawWindow --- Draws a window on the spikeshape graph for the selected cluster.
function handles = DrawWindow(handles, hObject);
    axes(handles.picSpikes);   %Set the axes to the picBox.
    hold on;                %Hold the plot as it is.
    %Display some text on the top of the plot tell the user how to set windows.
    text(min(get(gca,'xlim')),max(get(gca,'ylim')),...
        ' Select two points to define a window.',...
        'fontsize',12,'verticalalignment','top','horizontalalignment','left','color','w');
    %For multiple clusters, display text telling the user about superceding rules.
    if ~isempty(length(handles.windows))
        text(max(get(gca,'xlim')),min(get(gca,'ylim')),...
            'Previously drawn windows will supercede this window if they overlap. ',...
            'fontsize',12,'verticalalignment','bottom','horizontalalignment','right','color','w');
    end
    cC = handles.currentCluster;             %Use this index to identify the cluster number we're working with.
    color = lines(handles.num_clusters + 1);  %Grab a set of unique colors for each cluster.
    color = color(cC,:);         %The window will be colored according to its cluster.
    xy = [];            %Make an empty matrix to hold the x,y window coordinates.
    for i = 1:2
        [xy(1,i),xy(2,i)] = ginput(1);  %Have the user define window endpoints.
        plot(xy(1,:)',xy(2,:)','color',color,'marker','+','linestyle','--','linewidth',2);  %Plot the window thus far.
    end
    drawnow;    %Draw the window before clustering points.
    if isempty(handles.windows)     %If this is the first window set...
        handles.windows(cC).values = [xy(1,:),xy(2,:)];  %Create a new matrix of endpoints.
    elseif length(handles.windows) < cC     %If this is the first window set for this cluster...
        handles.windows(cC).values = [xy(1,:),xy(2,:)];  %Create a new matrix of endpoints.
    else                            %Otherwise add to a pre-existed set of endpoints
        handles.windows(cC).values = [handles.windows(cC).values; xy(1,:),xy(2,:)];
    end
    guidata(hObject, handles);                      %Update the handles structure to the GUI.

    
%**************************************************************************
%FUNCTION ClusterByWindow --- Calculates cluster assignments according to windows.
function handles = ClusterByWindow(handles, hObject);
    handles.cluster = zeros(handles.numspikes,1);   %Start with all clusters assigned to noise.
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
    handles.num_clusters = max(handles.cluster);	%Reset the number of clusters.
    handles.cluster(handles.subthreshold) = 0;  	%Set any subthreshold spikes to noise.
    guidata(hObject, handles);                      %Update handles structure  
    

%**************************************************************************
%ADD BUTTON CALLBACKS --- Executes on button presses to the add window buttons.
function cmdAdd1_Callback(hObject, eventdata, handles)
    handles.currentCluster = 1;                 %Set the cluster to be edited to #1.
    handles = DrawWindow(handles, hObject);     %Call the window drawing function.
    handles = ClusterByWindow(handles, hObject);    %Cluster spikes according to which windows they cross.
    handles = EnableButtons(handles, hObject);      %Reset the button properties.
    handles = PlotWindows(handles, hObject);        %Replot the PCs.
function cmdAdd2_Callback(hObject, eventdata, handles)
    handles.currentCluster = 2;                 %Set the cluster to be edited to #2.
    handles = DrawWindow(handles, hObject);     %Call the window drawing function.
    handles = ClusterByWindow(handles, hObject);    %Cluster spikes according to which windows they cross.
    handles = EnableButtons(handles, hObject);      %Reset the button properties.
    handles = PlotWindows(handles, hObject);        %Replot the PCs.
function cmdAdd3_Callback(hObject, eventdata, handles)
    handles.currentCluster = 3;                 %Set the cluster to be edited to #3.
    handles = DrawWindow(handles, hObject);     %Call the window drawing function.
    handles = ClusterByWindow(handles, hObject);    %Cluster spikes according to which windows they cross.
    handles = EnableButtons(handles, hObject);      %Reset the button properties.
    handles = PlotWindows(handles, hObject);        %Replot the PCs.
function cmdAdd4_Callback(hObject, eventdata, handles)
    handles.currentCluster = 4;                 %Set the cluster to be edited to #4.
    handles = DrawWindow(handles, hObject);     %Call the window drawing function.
    handles = ClusterByWindow(handles, hObject);    %Cluster spikes according to which windows they cross.
    handles = EnableButtons(handles, hObject);      %Reset the button properties.
    handles = PlotWindows(handles, hObject);        %Replot the PCs.
function cmdAdd5_Callback(hObject, eventdata, handles)
    handles.currentCluster = 5;                 %Set the cluster to be edited to #5.
    handles = DrawWindow(handles, hObject);     %Call the window drawing function.
    handles = ClusterByWindow(handles, hObject);    %Cluster spikes according to which windows they cross.
    handles = EnableButtons(handles, hObject);      %Reset the button properties.
    handles = PlotWindows(handles, hObject);        %Replot the PCs.
function cmdAdd6_Callback(hObject, eventdata, handles)
    handles.currentCluster = 6;                 %Set the cluster to be edited to #6.
    handles = DrawWindow(handles, hObject);     %Call the window drawing function.
    handles = ClusterByWindow(handles, hObject);    %Cluster spikes according to which windows they cross.
    handles = EnableButtons(handles, hObject);      %Reset the button properties.
    handles = PlotWindows(handles, hObject);        %Replot the PCs.
function cmdAdd7_Callback(hObject, eventdata, handles)
    handles.currentCluster = 7;                 %Set the cluster to be edited to #7.
    handles = DrawWindow(handles, hObject);     %Call the window drawing function.
    handles = ClusterByWindow(handles, hObject);    %Cluster spikes according to which windows they cross.
    handles = EnableButtons(handles, hObject);      %Reset the button properties.
    handles = PlotWindows(handles, hObject);        %Replot the PCs.
function cmdAdd8_Callback(hObject, eventdata, handles)
    handles.currentCluster = 8;                 %Set the cluster to be edited to #8.
    handles = DrawWindow(handles, hObject);     %Call the window drawing function.
    handles = ClusterByWindow(handles, hObject);    %Cluster spikes according to which windows they cross.
    handles = EnableButtons(handles, hObject);      %Reset the button properties.
    handles = PlotWindows(handles, hObject);        %Replot the PCs.
function cmdAdd9_Callback(hObject, eventdata, handles)
    handles.currentCluster = 9;                 %Set the cluster to be edited to #9.
    handles = DrawWindow(handles, hObject);     %Call the window drawing function.
    handles = ClusterByWindow(handles, hObject);    %Cluster spikes according to which windows they cross.
    handles = EnableButtons(handles, hObject);      %Reset the button properties.
    handles = PlotWindows(handles, hObject);        %Replot the PCs.
function cmdAdd10_Callback(hObject, eventdata, handles)
    handles.currentCluster = 10;                 %Set the cluster to be edited to #10.
    handles = DrawWindow(handles, hObject);     %Call the window drawing function.
    handles = ClusterByWindow(handles, hObject);    %Cluster spikes according to which windows they cross.
    handles = EnableButtons(handles, hObject);      %Reset the button properties.
    handles = PlotWindows(handles, hObject);        %Replot the PCs.
    
    
%**************************************************************************
%REMOVE BUTTON CALLBACKS --- Executes on button presses to the remove window buttons.
function cmdRemove1_Callback(hObject, eventdata, handles)
    handles.windows(1).values(size(handles.windows(1).values,1),:) = [];  %Clear out the last window set for this cluster.
    if isempty(handles.windows(1).values)     %If no more windows define the cluster, delete the cluster altogether.
        handles.windows(1) = [];
    end
    handles = ClusterByWindow(handles, hObject);    %Cluster spikes according to which windows they cross.
    handles = EnableButtons(handles, hObject);      %Reset the button properties.
    handles = PlotWindows(handles, hObject);        %Replot the PCs.
function cmdRemove2_Callback(hObject, eventdata, handles)
    handles.windows(2).values(size(handles.windows(2).values,1),:) = [];  %Clear out the last window set for this cluster.
    if isempty(handles.windows(2).values)     %If no more windows define the cluster, delete the cluster altogether.
        handles.windows(2) = [];
    end
    handles = ClusterByWindow(handles, hObject);    %Cluster spikes according to which windows they cross.
    handles = EnableButtons(handles, hObject);      %Reset the button properties.
    handles = PlotWindows(handles, hObject);        %Replot the PCs.
function cmdRemove3_Callback(hObject, eventdata, handles)
    handles.windows(3).values(size(handles.windows(3).values,1),:) = [];  %Clear out the last window set for this cluster.
    if isempty(handles.windows(3).values)     %If no more windows define the cluster, delete the cluster altogether.
        handles.windows(3) = [];
    end
    handles = ClusterByWindow(handles, hObject);    %Cluster spikes according to which windows they cross.
    handles = EnableButtons(handles, hObject);      %Reset the button properties.
    handles = PlotWindows(handles, hObject);        %Replot the PCs.
function cmdRemove4_Callback(hObject, eventdata, handles)
    handles.windows(4).values(size(handles.windows(4).values,1),:) = [];  %Clear out the last window set for this cluster.
    if isempty(handles.windows(4).values)     %If no more windows define the cluster, delete the cluster altogether.
        handles.windows(4) = [];
    end
    handles = ClusterByWindow(handles, hObject);    %Cluster spikes according to which windows they cross.
    handles = EnableButtons(handles, hObject);      %Reset the button properties.
    handles = PlotWindows(handles, hObject);        %Replot the PCs.
function cmdRemove5_Callback(hObject, eventdata, handles)
    handles.windows(5).values(size(handles.windows(5).values,1),:) = [];  %Clear out the last window set for this cluster.
    if isempty(handles.windows(5).values)     %If no more windows define the cluster, delete the cluster altogether.
        handles.windows(5) = [];
    end
    handles = ClusterByWindow(handles, hObject);    %Cluster spikes according to which windows they cross.
    handles = EnableButtons(handles, hObject);      %Reset the button properties.
    handles = PlotWindows(handles, hObject);        %Replot the PCs.
function cmdRemove6_Callback(hObject, eventdata, handles)
    handles.windows(6).values(size(handles.windows(6).values,1),:) = [];  %Clear out the last window set for this cluster.
    if isempty(handles.windows(6).values)     %If no more windows define the cluster, delete the cluster altogether.
        handles.windows(6) = [];
    end
    handles = ClusterByWindow(handles, hObject);    %Cluster spikes according to which windows they cross.
    handles = EnableButtons(handles, hObject);      %Reset the button properties.
    handles = PlotWindows(handles, hObject);        %Replot the PCs.
function cmdRemove7_Callback(hObject, eventdata, handles)
    handles.windows(7).values(size(handles.windows(7).values,1),:) = [];  %Clear out the last window set for this cluster.
    if isempty(handles.windows(7).values)     %If no more windows define the cluster, delete the cluster altogether.
        handles.windows(7) = [];
    end
    handles = ClusterByWindow(handles, hObject);    %Cluster spikes according to which windows they cross.
    handles = EnableButtons(handles, hObject);      %Reset the button properties.
    handles = PlotWindows(handles, hObject);        %Replot the PCs.
function cmdRemove8_Callback(hObject, eventdata, handles)
    handles.windows(8).values(size(handles.windows(8).values,1),:) = [];  %Clear out the last window set for this cluster.
    if isempty(handles.windows(8).values)     %If no more windows define the cluster, delete the cluster altogether.
        handles.windows(8) = [];
    end
    handles = ClusterByWindow(handles, hObject);    %Cluster spikes according to which windows they cross.
    handles = EnableButtons(handles, hObject);      %Reset the button properties.
    handles = PlotWindows(handles, hObject);        %Replot the PCs.
function cmdRemove9_Callback(hObject, eventdata, handles)
    handles.windows(9).values(size(handles.windows(9).values,1),:) = [];  %Clear out the last window set for this cluster.
    if isempty(handles.windows(9).values)     %If no more windows define the cluster, delete the cluster altogether.
        handles.windows(9) = [];
    end
    handles = ClusterByWindow(handles, hObject);    %Cluster spikes according to which windows they cross.
    handles = EnableButtons(handles, hObject);      %Reset the button properties.
    handles = PlotWindows(handles, hObject);        %Replot the PCs.
function cmdRemove10_Callback(hObject, eventdata, handles)
    handles.windows(10).values(size(handles.windows(10).values,1),:) = [];  %Clear out the last window set for this cluster.
    if isempty(handles.windows(10).values)     %If no more windows define the cluster, delete the cluster altogether.
        handles.windows(10) = [];
    end
    handles = ClusterByWindow(handles, hObject);    %Cluster spikes according to which windows they cross.
    handles = EnableButtons(handles, hObject);      %Reset the button properties.
    handles = PlotWindows(handles, hObject);        %Replot the PCs.