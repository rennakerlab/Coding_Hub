function varargout = NEL_Spike_Sorter_PCA(varargin)

%
%NEL_Spike_Sorter_PCA.m - OU Neural Engineering Lab, 2008
%
%   NEL_Spike_Sorter_PCA is a GUI used by the NEL_Spike_Sorter program to
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
%   NEL_Spike_Sorter_PCA(input_clusters,PCs,inputPCs,PClabels) sets up the
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
                   'gui_OpeningFcn', @NEL_Spike_Sorter_PCA_OpeningFcn, ...
                   'gui_OutputFcn',  @NEL_Spike_Sorter_PCA_OutputFcn, ...
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
%OPEN NEL_SPIKE_SORTER_PCA --- Executes just before NEL_Spike_Sorter_PCA is made visible.
function NEL_Spike_Sorter_PCA_OpeningFcn(hObject, eventdata, handles, varargin)
    %We'll define several variables right up front, as well as pull out the
    %input arguments.
    handles.maxradius = 3;              %The maximum allowable distance between a point and it's cluster centroid, in standard deviations.
    handles.cluster = varargin{1};      %The cluster assignments are the first argument in.
    handles.PCs = varargin{2};          %The principal component scores are the second argument in.
    handles.currentPCs = varargin{3};   %The currently selected PCs are the third argument in.
    handles.PCAlabels = varargin{4};    %The labels for the PC score columns are the fourth argument in.
    handles.subthreshold = varargin{5};	%The indices of subthreshold spikes following rethresholding are the 5th argument in.
    handles.draw = varargin{6};         %Any pre-existing user-drawn boundaries are the 6th argument in.
    handles.numspikes = length(handles.cluster);    %The number of total spikes.
    handles.num_clusters = max(handles.cluster);	%The number of pre-existing clusters.
    for i = 1:size(handles.PCs,2)       %We'll step through the available spike properties and set up axis-control buttons for each.
        eval(['set(handles.cmdx' num2str(i) ',''Enable'',''On'',''Visible'',''On'')']);    %Enable the x axis button.
        eval(['set(handles.cmdy' num2str(i) ',''Enable'',''On'',''Visible'',''On'')']);    %Enable the y axis button.
        eval(['set(handles.cmdz' num2str(i) ',''Enable'',''On'',''Visible'',''On'')']);    %Enable the z axis button.
        eval(['set(handles.cmdx' num2str(i) ',''String'',''' handles.PCAlabels{i} ''')']);  %Set the x axis button string to the property label.
        eval(['set(handles.cmdy' num2str(i) ',''String'',''' handles.PCAlabels{i} ''')']);  %Set the y axis button string to the property label.
        eval(['set(handles.cmdz' num2str(i) ',''String'',''' handles.PCAlabels{i} ''')']);  %Set the z axis button string to the property label.
    end
    set(handles.lblNumPlotSpks,'String',['Showing ' num2str(handles.numspikes) ' Spikes']);     %Set the slider label to show the number of displayed spikes.
    set(handles.hscNumPlotSpks,'Max',handles.numspikes);    %Set the maximum of the plotted spikeshapes slider to the number of spikes.
    set(handles.hscNumPlotSpks,'Value',handles.numspikes);	%Set the slider to the maximum number of plotted spikeshapes.
    handles.numplotspks = handles.numspikes;	%The default plot shown on opening will include all spikes.
    handles = EnableButtons(handles, hObject);  %This function decides which buttons to enable.
    handles = PlotPCA(handles, hObject);        %This function plots the selected spike components.
    guidata(hObject, handles);      %Update the GUI handles structure.
    uiwait(handles.PCASorting);     %Make the NEL_Spike_Sorter_PCA program wait for user input before returning an output to NEL_Spike_Sorter.


%**************************************************************************
%BUTTON PRESS ON cmdSet --- Executes on button press in cmdSet.
function cmdSet_Callback(hObject, eventdata, handles)
    uiresume(handles.PCASorting);   %Let's NEL_Spike_Sorter close and return an output.
    
    
%**************************************************************************
%CLOSE PCASorting --- Executes when user attempts to close the PCASorting form.
function set_PCASorting_CloseRequestFcn(hObject, eventdata, handles)
    if isequal(get(handles.PCASorting, 'waitstatus'), 'waiting')    
        uiresume(handles.PCASorting);   %If we're waiting for user input, cancel waiting.
    else
        delete(handles.PCASorting);     %If the GUI isn't waiting, just close it.
    end

    
%**************************************************************************
%FUNCTION EnableButtons --- Enables axis-control buttons and sets string and color properties.
function handles = EnableButtons(handles, hObject)
    for i = 1:size(handles.PCs,2)   %Set all button foreground colors to white.
        eval(['set(handles.cmdx' num2str(i) ',''ForegroundColor'',''w'')']);    
        eval(['set(handles.cmdy' num2str(i) ',''ForegroundColor'',''w'')']);
        eval(['set(handles.cmdz' num2str(i) ',''ForegroundColor'',''w'')']);
    end
    %Set current component button's foreground colors to blue.
    eval(['set(handles.cmdx' num2str(handles.currentPCs(1)) ',''ForegroundColor'',''b'')']);    
    eval(['set(handles.cmdy' num2str(handles.currentPCs(2)) ',''ForegroundColor'',''b'')']);
    if ~isnan(handles.currentPCs(3))    %If we're doing a 3-D plot...
        eval(['set(handles.cmdz' num2str(handles.currentPCs(3)) ',''ForegroundColor'',''b'')']);
        set(handles.lblZ,'ForegroundColor','w');
    else
        set(handles.lblZ,'ForegroundColor',[0.5 0.5 0.5]);
    end
    guidata(hObject, handles);
    
    
%**************************************************************************
%FUNCTION PlotPCA --- Plot the selected spike components.
function handles = PlotPCA(handles, hObject)
    axes(handles.picBox);   %Set the current axes to the picBox.
    set(gca,'color','k','xcolor','w','ycolor','w','zcolor','w');   %Set the axes colors to white and background to black.
    cla;        %Clear the axes of existing plots.
    hold on;    %Hold the axes for multiple plots.
    colors = [0.5 0.5 0.5; lines(handles.num_clusters)];    %We'll grab a set of colors to identify different clusters.
    temp = randperm(length(handles.cluster))';              %Randomize the spikes for plotting.
    if size(temp,1) > handles.numplotspks                   %Pare down the randomized list to the number of spikes for plotting.
        temp = temp(1:handles.numplotspks,:);
    end
    for i = 0:handles.num_clusters          %Step through by cluster.
        a = find(handles.cluster == i);     %Find all spikes in this cluster.
        a = intersect(a,temp);              %Find all spikes in this cluster also in the randomized list for plotting.
        if ~isempty(a);     %If there are any spikes to plot...
            if ~isnan(handles.currentPCs(3))    %If we're plotting in 3-D...
                plot3(handles.PCs(a,handles.currentPCs(1)),handles.PCs(a,handles.currentPCs(2)),...
                handles.PCs(a,handles.currentPCs(3)),'marker','.','linestyle','none','color',colors(i+1,:));    %Make a 3-D point plot.
            else    %Otherwise we're plotting in 2-D.
                plot(handles.PCs(a,handles.currentPCs(1)),handles.PCs(a,handles.currentPCs(2)),...
                'marker','.','linestyle','none','color',colors(i+1,:));     %Make a 2-D point plot.
                view(0,90);     %Set the view to top down in case it was still rotated from a 3-D plot.
            end
        end
    end
    axis tight;     %Tighten up the axes bounds.
    hold off;       %Turn off the axes hold.
    xlabel(handles.PCAlabels{handles.currentPCs(1)},'fontweight','normal','fontsize',12);       %Set the y axis label.
    ylabel(handles.PCAlabels{handles.currentPCs(2)},'fontweight','normal','fontsize',12);       %Set the y axis label.
    if ~isnan(handles.currentPCs(3))    %If we're plotting in 3-D
        zlabel(handles.PCAlabels{handles.currentPCs(3)},'fontweight','normal','fontsize',12);	%Set the z axis label.
        rotate3d;       %Allow the user to rotate the graph whenever the mouse is over it.
    end
    set(gca,'xtick',[],'ytick',[],'ztick',[]);  %Get rid of the axes ticks, they're irrelevant.
    drawnow;        %Draw this plot before moving on.
    guidata(hObject, handles);

    
%**************************************************************************
%OUTPUT  NEL_Spike_Sorter_PCA --- Return the output arguments to NEL_Spike_Sorter.
function varargout = NEL_Spike_Sorter_PCA_OutputFcn(hObject, eventdata, handles)
    varargout{1} = handles.currentPCs;  %The 1st output argument is the selected PCs.
    varargout{2} = handles.cluster;     %The 2nd output argument is the new cluster assignments.
    varargout{3} = handles.draw;        %The 3rd output argument is the cluster boundaries.
    delete(handles.PCASorting);         %Close NEL_Spike_Sorting_PCA.
   
    
%**************************************************************************
%SLIDER MOVEMENT on hscNumPlotSpks --- Executes when user changes the value of the slider.
function hscNumPlotSpks_Callback(hObject, eventdata, handles)
    handles.numplotspks = round(get(hObject,'Value'));      %The number of plot spikes is the rounded value of the slider.
    set(handles.lblNumPlotSpks,'String',['Showing ' num2str(handles.numplotspks) ' Spikes']);   %Set the slider label to show the new value.
    handles = PlotPCA(handles, hObject);    %Replot the PCs with the new number of plot spikes.
    guidata(hObject, handles);              %Update the handles structure to the GUI.

    
%**************************************************************************
%CREATE hscNumPlotSpks --- This function is require by the GUI, even though it doesn't do anything.
function hscNumPlotSpks_CreateFcn(hObject, eventdata, handles)


%**************************************************************************
%BUTTON PRESS ON cmdClear --- Executes on button press in cmdClear.
function cmdClear_Callback(hObject, eventdata, handles)
    handles.cluster(:) = 1;                             %Assign all spikes to one cluster.
    handles.num_clusters = 1;                           %Reset the number of clusters.
    handles.cluster(handles.subthreshold) = 0;          %Set any subthreshold spikes to noise.
    handles.draw = [];                                  %Clear any drawn boundaries.
    handles = PlotPCA(handles, hObject);                %Replot the PCs.
    guidata(hObject, handles);                          %Update the handles structure to the GUI.
    
    
%**************************************************************************
%BUTTON PRESS ON cmdAuto --- Executes on button press in cmdAuto.
function cmdAuto_Callback(hObject, eventdata, handles)
    %Ask the user how many clusters they want to divide the spikes into.
    numclusters = round(str2num(cell2mat(inputdlg('How many clusters do you see here?', 'Number of Clusters to Identify:'))));
    axes(handles.picBox);	%We'll put a "Clustering..." message in the main spikeshapes window.
    cla;    %Reset the  plot to blank axes.
    set(gca,'xlim',[-1 1],'ylim',[-1,1],'xticklabel',[],'yticklabel',[],'xtick',[],...
        'ytick',[],'color','k','xcolor','w','ycolor','w','yscale','linear');
    text(0,0,['Performing K-means Clustering...'],'interpreter','none','fontweight','bold',...    %Show the "Clustering..." message.
        'color','w','fontsize',16,'horizontalalignment','center','verticalalignment','middle');
    drawnow;    %Refresh the axes before running the rest of the code.
    if ~isnan(handles.currentPCs(3))    %If we're using three PCs, make a 3-column input matrix
        temp = [handles.PCs(:,handles.currentPCs(1)),...
            handles.PCs(:,handles.currentPCs(2)),handles.PCs(:,handles.currentPCs(3))];
    else    %Otherwise, make a 2-column input matrix.
        temp = [handles.PCs(:,handles.currentPCs(1)),handles.PCs(:,handles.currentPCs(2))];
    end
    if numclusters > 1;     %If we ask for more than one cluster, run the k-means function.
        [clustermarkers,centroids] = kmeans(temp,numclusters,'distance','sqEuclidean','replicates',10);
    else    %Otherwise, assign all the spikes to one cluster.
        clustermarkers = ones(size(handles.cluster));
        centroids = mean(temp,1);   %The centroid of that cluster is the mean.
    end
    %Now we'll kick out any outliers in the clusters.
    for i = unique(clustermarkers)'         %Step through by cluster.
        a = find(clustermarkers == i);      %Find all spikes assigned to this cluster.
        b = sqrt(sum((temp(a,:)-repmat(centroids(i,:),length(a),1)).^2,2));	%Find the distance from each point to the centroid.
        clustermarkers(a(find(b/std(b) > handles.maxradius))) = 0;  %Any spikes >3 stds away are reclassified as noise.
    end 
    %We'll check to make sure the cluster assignments numbers are contiguous, i.e. [0,1,2] and not [0,1,3].
    temp = unique(clustermarkers);
    for i = 1:length(temp)      %Stepping through the list of unique cluster numbers.
        if temp(i) ~= min(temp)+i-1     %If the cluster number doesn't line up with it's index, change it to conform.
            clustermarkers(find(clustermarkers == temp(i))) = min(temp)+i-1;
        end
    end
    handles.cluster = clustermarkers;   %Put the cluster assignments back into "handles".
    handles.num_clusters = max(handles.cluster);    %Reset the number of clusters.
    handles.cluster(handles.subthreshold) = 0;  	%Set any subthreshold spikes to noise.
    handles = PlotPCA(handles, hObject);            %Replot the PCs.
    guidata(hObject, handles);                      %Update the handles structure to the GUI.
    
    
%**************************************************************************
%BUTTON PRESS ON cmdDraw --- Executes on button press in cmdDraw.
function cmdDraw_Callback(hObject, eventdata, handles)
    if ~isnan(handles.currentPCs(3))    %If we're plotting in 3-D, switch to a 2-D plot.
        handles.currentPCs(3) = NaN;
        handles = PlotPCA(handles, hObject);        %Replot the PCs.
        handles = EnableButtons(handles, hObject);
    end
    axes(handles.picBox);   %Set the axes to the picBox.
    hold on;                %Hold the plot as it is.
    %Display some text on the top of the plot tell the user how to select clusters.
    text(min(get(gca,'xlim')),max(get(gca,'ylim')),...
        ' Set boundary vertices with left mouse button, right mouse button picks last point before closing the polygon.',...
        'fontsize',12,'verticalalignment','top','horizontalalignment','left','color','w');
    %For multiple clusters, display text telling the user about superceding rules.
    if ~isempty(length(handles.draw))
        text(max(get(gca,'xlim')),min(get(gca,'ylim')),...
            'Previously drawn cluster assignments will supercede this boundary if they overlap. ',...
            'fontsize',12,'verticalalignment','bottom','horizontalalignment','right','color','w');
    end
    color = lines(handles.num_clusters+1);  %Grab a set of unique colors for each cluster.
    color = color(size(color,1),:);         %The new cluster will have a new color.
    xy = [];            %Make an empty matrix to hold the x,y boundary vertice coordinates.
    n = 0;              %Start off with 0 vertices selected.
    temp = 1;           %Here, temp keep track of which mouse button, right or left, was pressed.
    while temp == 1     %While the user continues clicking the left button.
        n = n+1;        %Add a vertex.
        [xy(1,n),xy(2,n),temp] = ginput(1);   %Have the user define a boundary vertex.        
        plot(xy(1,:)',xy(2,:)','color',color,'marker','+','linestyle','--','linewidth',2);  %Plot the boundary thus far.
    end        %Stop when the user clicks the right mouse button.
    xy(:,n+1) = xy(:,1);    %Close the boundary by adding the first vertex also as the last vertex.
    if size(xy,2) > 2       %If the user selected at least 3 points to enclose a cluster.
        plot(xy(1,:),xy(2,:),'color',color,'linestyle','--','linewidth',2);     %Plot the enclosed boundaries.
        drawnow;    %Draw the plot before clustering points.
        i = length(handles.draw)+1;         %Find the new index for this boundary.
        handles.draw(i).values = xy;        %Add the vertice list to the handles structure.
        handles.draw(i).PCs = [handles.currentPCs(1),handles.currentPCs(2)];   %Save the correct PCs for this boundary.
        handles.cluster = zeros(handles.numspikes,1);   %Start with all clusters assigned to noise.
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
    end
    hold off;   %Release the plot.
    handles.num_clusters = max(handles.cluster);    %Reset the number of clusters.
    handles.cluster(handles.subthreshold) = 0;   	%Set any subthreshold spikes to noise.
    handles = PlotPCA(handles, hObject);            %Replot the PCs.
    guidata(hObject, handles);                      %Update the handles structure to the GUI.
    
    
%**************************************************************************
%X AXIS BUTTON CALLBACKS --- Executes on button presses to the x-axis control buttons.
function cmdx1_Callback(hObject, eventdata, handles)
    if handles.currentPCs(1) ~= 1;      %If this PC isn't already selected for the x-axis...
        handles.currentPCs(1) = 1;      %Use the first PC as x-axis values.
        handles = EnableButtons(handles, hObject);  %Reset the buttons.
        handles = PlotPCA(handles, hObject);        %Replot the PCs.
    end
function cmdx2_Callback(hObject, eventdata, handles)
    if handles.currentPCs(1) ~= 2;
        handles.currentPCs(1) = 2;
        handles = EnableButtons(handles, hObject);
        handles = PlotPCA(handles, hObject);
    end
function cmdx3_Callback(hObject, eventdata, handles)
    if handles.currentPCs(1) ~= 3;
        handles.currentPCs(1) = 3;
        handles = EnableButtons(handles, hObject);
        handles = PlotPCA(handles, hObject);
    end
function cmdx4_Callback(hObject, eventdata, handles)
    if handles.currentPCs(1) ~= 4;
        handles.currentPCs(1) = 4;
        handles = EnableButtons(handles, hObject);
        handles = PlotPCA(handles, hObject);
    end
function cmdx5_Callback(hObject, eventdata, handles)
    if handles.currentPCs(1) ~= 5;
        handles.currentPCs(1) = 5;
        handles = EnableButtons(handles, hObject);
        handles = PlotPCA(handles, hObject);
    end
function cmdx6_Callback(hObject, eventdata, handles)
    if handles.currentPCs(1) ~= 6;
        handles.currentPCs(1) = 6;
        handles = EnableButtons(handles, hObject);
        handles = PlotPCA(handles, hObject);
    end
function cmdx7_Callback(hObject, eventdata, handles)
    if handles.currentPCs(1) ~= 7;
        handles.currentPCs(1) = 7;
        handles = EnableButtons(handles, hObject);
        handles = PlotPCA(handles, hObject);
    end
function cmdx8_Callback(hObject, eventdata, handles)
    if handles.currentPCs(1) ~= 8;
        handles.currentPCs(1) = 8;
        handles = EnableButtons(handles, hObject);
        handles = PlotPCA(handles, hObject);
    end
function cmdx9_Callback(hObject, eventdata, handles)
    if handles.currentPCs(1) ~= 9;
        handles.currentPCs(1) = 9;
        handles = EnableButtons(handles, hObject);
        handles = PlotPCA(handles, hObject);
    end
function cmdx10_Callback(hObject, eventdata, handles)
    if handles.currentPCs(1) ~= 10;
        handles.currentPCs(1) = 10;
        handles = EnableButtons(handles, hObject);
        handles = PlotPCA(handles, hObject);
    end
function cmdx11_Callback(hObject, eventdata, handles)
    if handles.currentPCs(1) ~= 11;
        handles.currentPCs(1) = 11;
        handles = EnableButtons(handles, hObject);
        handles = PlotPCA(handles, hObject);
    end
function cmdx12_Callback(hObject, eventdata, handles)
    if handles.currentPCs(1) ~= 12;
        handles.currentPCs(1) = 12;
        handles = EnableButtons(handles, hObject);
        handles = PlotPCA(handles, hObject);
    end
function cmdx13_Callback(hObject, eventdata, handles)
    if handles.currentPCs(1) ~= 13;
        handles.currentPCs(1) = 13;
        handles = EnableButtons(handles, hObject);
        handles = PlotPCA(handles, hObject);
    end
function cmdx14_Callback(hObject, eventdata, handles)
    if handles.currentPCs(1) ~= 14;
        handles.currentPCs(1) = 14;
        handles = EnableButtons(handles, hObject);
        handles = PlotPCA(handles, hObject);
    end
    

%**************************************************************************
%Y AXIS BUTTON CALLBACKS --- Executes on button presses to the y-axis control buttons.
function cmdy1_Callback(hObject, eventdata, handles)
    if handles.currentPCs(2) ~= 1;      %If this PC isn't already selected for the y-axis...
        handles.currentPCs(2) = 1;      %Use the first PC as y-axis values.
        handles = EnableButtons(handles, hObject);  %Reset the buttons.
        handles = PlotPCA(handles, hObject);        %Replot the PCs.
    end
function cmdy2_Callback(hObject, eventdata, handles)
    if handles.currentPCs(2) ~= 2;
        handles.currentPCs(2) = 2;
        handles = EnableButtons(handles, hObject);
        handles = PlotPCA(handles, hObject);
    end
function cmdy3_Callback(hObject, eventdata, handles)
    if handles.currentPCs(2) ~= 3;
        handles.currentPCs(2) = 3;
        handles = EnableButtons(handles, hObject);
        handles = PlotPCA(handles, hObject);
    end
function cmdy4_Callback(hObject, eventdata, handles)
    if handles.currentPCs(2) ~= 4;
        handles.currentPCs(2) = 4;
        handles = EnableButtons(handles, hObject);
        handles = PlotPCA(handles, hObject);
    end
function cmdy5_Callback(hObject, eventdata, handles)
    if handles.currentPCs(2) ~= 5;
        handles.currentPCs(2) = 5;
        handles = EnableButtons(handles, hObject);
        handles = PlotPCA(handles, hObject);
    end
function cmdy6_Callback(hObject, eventdata, handles)
    if handles.currentPCs(2) ~= 6;
        handles.currentPCs(2) = 6;
        handles = EnableButtons(handles, hObject);
        handles = PlotPCA(handles, hObject);
    end
function cmdy7_Callback(hObject, eventdata, handles)
    if handles.currentPCs(2) ~= 7;
        handles.currentPCs(2) = 7;
        handles = EnableButtons(handles, hObject);
        handles = PlotPCA(handles, hObject);
    end
function cmdy8_Callback(hObject, eventdata, handles)
    if handles.currentPCs(2) ~= 8;
        handles.currentPCs(2) = 8;
        handles = EnableButtons(handles, hObject);
        handles = PlotPCA(handles, hObject);
    end
function cmdy9_Callback(hObject, eventdata, handles)
    if handles.currentPCs(2) ~= 9;
        handles.currentPCs(2) = 9;
        handles = EnableButtons(handles, hObject);
        handles = PlotPCA(handles, hObject);
    end
function cmdy10_Callback(hObject, eventdata, handles)
    if handles.currentPCs(2) ~= 10;
        handles.currentPCs(2) = 10;
        handles = EnableButtons(handles, hObject);
        handles = PlotPCA(handles, hObject);
    end
function cmdy11_Callback(hObject, eventdata, handles)
    if handles.currentPCs(2) ~= 11;
        handles.currentPCs(2) = 11;
        handles = EnableButtons(handles, hObject);
        handles = PlotPCA(handles, hObject);
    end
function cmdy12_Callback(hObject, eventdata, handles)
    if handles.currentPCs(2) ~= 12;
        handles.currentPCs(2) = 12;
        handles = EnableButtons(handles, hObject);
        handles = PlotPCA(handles, hObject);
    end
function cmdy13_Callback(hObject, eventdata, handles)
    if handles.currentPCs(2) ~= 13;
        handles.currentPCs(2) = 13;
        handles = EnableButtons(handles, hObject);
        handles = PlotPCA(handles, hObject);
    end
function cmdy14_Callback(hObject, eventdata, handles)
    if handles.currentPCs(2) ~= 14;
        handles.currentPCs(2) = 14;
        handles = EnableButtons(handles, hObject);
        handles = PlotPCA(handles, hObject);
    end
    
    
%**************************************************************************
%Z AXIS BUTTON CALLBACKS --- Executes on button presses to the z-axis control buttons.
function cmdz1_Callback(hObject, eventdata, handles)
    if handles.currentPCs(3) ~= 1;      %If this PC isn't already selected for the z-axis...
        handles.currentPCs(3) = 1;      %Use the first PC as z-axis values.
    else                                %If this PC is already selected for the z-axis...
        handles.currentPCs(3) = NaN;    %Switch to 2-D ploting with only the x and y axes.
    end
    handles = EnableButtons(handles, hObject);  %Reset the buttons.
    handles = PlotPCA(handles, hObject);        %Replot the PCs.
function cmdz2_Callback(hObject, eventdata, handles)
    if handles.currentPCs(3) ~= 2;
        handles.currentPCs(3) = 2;
    else
        handles.currentPCs(3) = NaN;
    end
    handles = EnableButtons(handles, hObject);
    handles = PlotPCA(handles, hObject);
function cmdz3_Callback(hObject, eventdata, handles)
    if handles.currentPCs(3) ~= 3;
        handles.currentPCs(3) = 3;
    else
        handles.currentPCs(3) = NaN;
    end
    handles = EnableButtons(handles, hObject);
    handles = PlotPCA(handles, hObject);
function cmdz4_Callback(hObject, eventdata, handles)
    if handles.currentPCs(3) ~= 4;
        handles.currentPCs(3) = 4;
    else
        handles.currentPCs(3) = NaN;
    end
    handles = EnableButtons(handles, hObject);
    handles = PlotPCA(handles, hObject);
function cmdz5_Callback(hObject, eventdata, handles)
    if handles.currentPCs(3) ~= 5;
        handles.currentPCs(3) = 5;
    else
        handles.currentPCs(3) = NaN;
    end
    handles = EnableButtons(handles, hObject);
    handles = PlotPCA(handles, hObject);
function cmdz6_Callback(hObject, eventdata, handles)
    if handles.currentPCs(3) ~= 6;
        handles.currentPCs(3) = 6;
    else
        handles.currentPCs(3) = NaN;
    end
    handles = EnableButtons(handles, hObject);
    handles = PlotPCA(handles, hObject);
function cmdz7_Callback(hObject, eventdata, handles)
    if handles.currentPCs(3) ~= 7;
        handles.currentPCs(3) = 7;
    else
        handles.currentPCs(3) = NaN;
    end
    handles = EnableButtons(handles, hObject);
    handles = PlotPCA(handles, hObject);
function cmdz8_Callback(hObject, eventdata, handles)
    if handles.currentPCs(3) ~= 8;
        handles.currentPCs(3) = 8;
    else
        handles.currentPCs(3) = NaN;
    end
    handles = EnableButtons(handles, hObject);
    handles = PlotPCA(handles, hObject);
function cmdz9_Callback(hObject, eventdata, handles)
    if handles.currentPCs(3) ~= 9;
        handles.currentPCs(3) = 9;
    else
        handles.currentPCs(3) = NaN;
    end
    handles = EnableButtons(handles, hObject);
    handles = PlotPCA(handles, hObject);
function cmdz10_Callback(hObject, eventdata, handles)
    if handles.currentPCs(3) ~= 10;
        handles.currentPCs(3) = 10;
    else
        handles.currentPCs(3) = NaN;
    end
    handles = EnableButtons(handles, hObject);
    handles = PlotPCA(handles, hObject);
function cmdz11_Callback(hObject, eventdata, handles)
    if handles.currentPCs(3) ~= 11;
        handles.currentPCs(3) = 11;
    else
        handles.currentPCs(3) = NaN;
    end
    handles = EnableButtons(handles, hObject);
    handles = PlotPCA(handles, hObject);
function cmdz12_Callback(hObject, eventdata, handles)
    if handles.currentPCs(3) ~= 12;
        handles.currentPCs(3) = 12;
    else
        handles.currentPCs(3) = NaN;
    end
    handles = EnableButtons(handles, hObject);
    handles = PlotPCA(handles, hObject);
function cmdz13_Callback(hObject, eventdata, handles)
    if handles.currentPCs(3) ~= 13;
        handles.currentPCs(3) = 13;
    else
        handles.currentPCs(3) = NaN;
    end
    handles = EnableButtons(handles, hObject);
    handles = PlotPCA(handles, hObject);
function cmdz14_Callback(hObject, eventdata, handles)
    if handles.currentPCs(3) ~= 14;
        handles.currentPCs(3) = 14;
    else
        handles.currentPCs(3) = NaN;
    end
    handles = EnableButtons(handles, hObject);
    handles = PlotPCA(handles, hObject);