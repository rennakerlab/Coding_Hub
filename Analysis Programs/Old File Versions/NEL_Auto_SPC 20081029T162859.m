function NEL_Auto_SPC(file, varargin)  

%
%NEL_Auto_SPC.m - OU Neural Engineering Lab, 2007
%
%   NEL_Auto_SPC is an unsupervised spike-sorting program that spike sorts
%   NEL format files, primarily using wavelet transformations and
%   super-paramagnetic clustering (SPC).  This code is adapted from Rodrigo
%   Quiroga's freely-available spike-sorting software suite (available at
%   http://www.vis.caltech.edu/~rodri/) based on his method described in
%   Quiroga et al., Neural Computation, 2004.  While the program is designed
%   to be unsupervised, the results of the SPC is saved to allow for manual 
%   adjustment of clustering where needed.
%
%   NEL_Auto_SPC(file) sorts the spikes in the *.SPK input file using
%   all function defaults.
%
%   NEL_Auto_SPC(...,'Property1',PropertyValue1,...) sets the values of
%   any of the following optional thresholding properties:
%
%   * 'SortFeature' - We can transform input spikes for clustering using
%                     either wavelet transformations or principle component
%                     analysis, set with input values of 'WAV' or 'PCA',
%                     respectivly.  The default value is 'WAV'.
%
%   * 'TemplateCutoff' - When there are too many spikes to efficiently sort
%                        using SPC, we can use SPC to sort a portion and
%                        then template-sort the rest based on templates
%                        derived from the SPC.  The 'TemplateCutoff'
%                        property defines the maximum number of spikes sent
%                        to the SPC before sorting the remainder with
%                        template matching.  The input value should be a
%                        positive non-zero integer.  The default value is
%                        25,000 spikes.
%
%   * 'TemplateType' - When reverting to template matching, we can
%                      determine the best matching template to a spike by
%                      one of four distance measures: nearest neighbor,
%                      center, gaussian, or mahalnobis distance, specified
%                      with a value of 'NN', 'CENTER', 'GAUSS', or 'MAHAL',
%                      respectively.  The default measure is 'CENTER'.
%
%   * 'TemplateFeature' - In template matching, we can match spikes
%                         according to voltage waveforms or to wavelet
%                         transformations, specified with input values of
%                         'SPIKE' or 'WAV', respectively.  The default
%                         value is 'WAV'.
%
%   * 'MaximumRadius' - For template sorting, we'll set the maximum radius
%                       of a cluster, and thus the maximum distance of a
%                       spike from that cluster's template, in terms of the
%                       number of standard deviations of distance.  The
%                       input value should be a positive non-zero number.
%                       The default value is 3.
%
%   * 'TemplatePointLimit' - Templates are matched according to the overall
%                            shortest N-dimensional distance from a spike
%                            to a template, but we can also constrain the
%                            matching so that the spike must be within the
%                            cluster radius along most single dimensions.
%                            The 'TemplatePointLimit' sets the maximum
%                            number of points that can fall outside of
%                            their respective single-dimension radii before
%                            a template is excluded.  The default value is
%                            Inf, indicating no limit.
%
%   * 'Display' - Display plots of the spike sorting and template-matching
%                 process, set with values of 'On' or 'Off'.  The default
%                 value is 'Off'.
%
%   Last updated October 29, 2008, by Drew Sloan.

%First, we'll check the input file to make sure it's a *.SPK file.
if ~strcmpi(file(length(file)-3:length(file)),'.SPK');
    error('- Input file is not a *.SPK file.');
end

%We'll time the spike-sorting to better estimate how long future spike-sorting will take.
tic;

%We'll start by defining the default terms up front, and then change them
%if the user specifies any different values.
sort_feature = 'WAV';       %The spike feature used for sorting, either wavelets or PCA.
template.max_radius = 3;    %The maximum radius of a cluster in standard deviations.
template.near_neigh = 10;   %The number of nearest neighbors.
template.min_nn = 10;       %The minimum number of nearest neighbors required for a vote.
template.type = 'CENTER';   %Method used to calculate distance to a template: nearest neighbor ('NN'), center ('CENTER'), gaussian ('GAUSS'), or mahalnobis ('MAHAL').
template.feature = 'WAV';       %Feature to use for template matching: spike shape ('SPIKE') or wavelet coefficients ('WAV').
template.pointlimit = Inf;      %The limit on the number of points that can fall outside of a single dimension limit before excluding a template.    
displayopt = 0;             %Display plots of the spike-sorting processs, 1 = on, 0 = off.

%Here's some terms we'll define upfront relating to the Super-Paramagnetic Clustering (SPC).
SPC.mintemp = 0.00;             %Minimum temperature for SPC.
SPC.maxtemp = 0.201;            %Maximum temperature for SPC.
SPC.tempstep = 0.01;            %Temperature steps.
SPC.SWCycles = 100;             %Number of Monte Carlo iterations for each temperature.
SPC.KNearNeighb = 11;           %The number of nearest neighbors for SPC.
SPC.num_temp = floor((SPC.maxtemp-SPC.mintemp)/SPC.tempstep);	%Total number of temperatures.
SPC.max_clus = 13;              %Maximum number of clusters allowed.
SPC.randomseed = 0;             %If randomseed = 0, the random seed is taken as the clock value.
SPC.fname_in = 'tmp_data';      %Input filename for interaction with SPC.
SPC.max_spikes = 25000;         %The maximum number of spikes before starting template matching.

%Now we'll go through any changes to the optional properties the user might
%have entered.
threshold_type_override = 0;    %Setting 'ThresholdType' may override the threshold type set by 'SetThreshold'.
method_override = 0;            %Setting the threshold with 'SetThresh' will override any attempt to set 'Method' to 'Auto'.
for i = 1:2:length(varargin)
    if length(varargin) <= i    %Input arguments must come in pairs, the property name and it's specified value.
        error(['- No corresponding input argument for ''' cell2mat(varargin(i)) '''.']);
    else
        if strcmpi(cell2mat(varargin(i)),'SortFeature')      %Set the feature to sort spikes by.
            if ~isstr(cell2mat(varargim(i+1))) | ...    %If the input value is not one of the two 'SortFeature' options, then indicate error.
                    ~(strcmpi(cell2mat(varargin(i+1)),'WAV') |  strcmpi(cell2mat(varargin(i+1)),'PCA'))
                error('- The ''SortFeature'' property must set to ''WAV'' or ''PCA''.');
            else
                sort_feature = cell2mat(varargin(i+1))  %Set the sort feature to that specified.
            end                
        elseif strcmpi(cell2mat(varargin(i)),'TemplateCutoff')    %Set the maximum number of spikes before reverting to template matching.
            if isstr(cell2mat(varargin(i+1))) | ...     %'TemplateCutoff' input must be numeric and positive.
                    any(cell2mat(varargin(i+1)) <= 0) | length(cell2mat(varargin(i+1))) > 1
                error('- The ''TemplateCutoff'' property must be a single, positive integer.');
            else
                SPC.max_spikes = cell2mat(varargin(i+1));    %Set the maximum number of spikes before reverting to template matching.
            end
        elseif strcmpi(cell2mat(varargin(i)),'TemplateType');    %Set the template type.
            if strcmpi(cell2mat(varargin(i+1)),'NN')
                template.type = 'NN';           %Set the template type to nearest neighbor.
            elseif strcmpi(cell2mat(varargin(i+1)),'CENTER')
                template.type = 'CENTER';       %Set template type to center distance.
            elseif strcmpi(cell2mat(varargin(i+1)),'GAUSS')
                template.type = 'GAUSS';        %Set template type to Gaussian.
            elseif strcmpi(cell2mat(varargin(i+1)),'MAHAL')
                template.type = 'MAHAL';        %Set template type to mahalnobis.
            else    %If the input value is none of these options, indicate error.
                error('- The ''TemplateType'' property must set to either ''NN'', ''CENTER'', ''GAUSS'', or ''MAHAL''.');
            end
        elseif strcmpi(cell2mat(varargin(i)),'TemplateFeature');  %Setting the feature to template match by.
            if strcmpi(cell2mat(varargin(i+1)),'SPIKE')
                template.feature = 'SPIKE';         %Set the template feature to spike shape.
            elseif strcmpi(cell2mat(varargin(i+1)),'WAV')
                template.feature = 'WAV';           %Set the template feature to wavelet coefficients.
            else    %If the input value is neither 'SPIKE' or 'WAV', then indicate error.
                error('- The ''TemplateFeature'' property must set to either ''SPIKE'' or ''WAV''.');
            end
        elseif strcmpi(cell2mat(varargin(i)),'MaximumRadius');   %Setting the maximum radius of a cluster, in standard deviations.
            if isstr(cell2mat(varargin(i+1))) | ...     %Maximum cluster radius must be a positive number.
                    any(cell2mat(varargin(i+1)) <= 0) | length(cell2mat(varargin(i+1))) > 1
                error('- The ''MaximumRadius'' property must be a single positive number.');
            else
                template.max_radius = cell2mat(varargin(i+1));
            end
        elseif strcmpi(cell2mat(varargin(i)),'TemplatePointLimit');   %Setting the maximum number of points that can fall outside a template before exclusion.
            if isstr(cell2mat(varargin(i+1))) | ...     %Template point limit must be a positive integer.
                    any(cell2mat(varargin(i+1)) <= 0) | length(cell2mat(varargin(i+1))) > 1
                error('- The ''TemplatePointLimit'' property must be a single positive integer.');
            else
                template.pointlimit = cell2mat(varargin(i+1));  %Setting the template point limit.
            end
        elseif strcmpi(cell2mat(varargin(i)),'Display');    %Turn plot displays on or off.
            if strcmpi(cell2mat(varargin(i+1)),'On')
                displayopt = 1;     %Turn displays on.
            elseif strcmpi(cell2mat(varargin(i+1)),'Off')
                displayopt = 0;     %Turn displays off.
            else    %If the input value is neither 'On' or 'Off', then indicate error.
                error('- The ''Display'' property must set to either ''On'' or ''Off''.');
            end
        else
            error(['- ''' cell2mat(temp) ''' is not a recognized input argument.']);
        end
    end
end

%The input file may not actually be from the current directory, so we'll
%determine the actual data path here.
temp = max(find(file == '\'));  %Find the path in the file name if it's included.
if isempty(temp)    
    workingpath = cd;	%If the path isn't in the file name, the current directory must be the working directory.
else
    workingpath = file(1:temp);     %If the path is in the file name, we'll pull out the working directory.
end

%We'll have different numbers of cluster inputs for the different sort
%feature options.
if strcmpi(sort_feature,'wav');
    clust_inputs = 10;              %The number of inputs to the clustering algorithm for wavelets.
elseif strcmpi(sort_feature,'pca');
    clust_inputs  = 3;              %The number of inputs to the clustering algorithm for PCA.
end
scales = 5;     %The number of scales used in the wavelet decomposition.

%Open the *.SPK file for reading.
disp(['SPC Spike-sorting: ' file]);
fid = fopen(file,'r');
fseek(fid,1,'bof');               	%Skip past the daycode.
numchar = fread(fid,1,'int8');      %Find the number of characters in the rat's name.
fseek(fid,numchar+2 + 4,'cof');    	%Skip the rat's name, spontaneous delay, and the sampling rate.
num_spike_samples = fread(fid,1,'int16');	%The number of spike shape samples.
numparams = fread(fid,1,'int8');         	%Number of stimulus parameters.
for i = 1:numparams                         %Step through the number of parameters.
    numchar = fread(fid,1,'int16');      	%Number of characters in a parameter name.
    fseek(fid,numchar,'cof');               %Skip the parameter name.
end
all_spikes = [];                    %Create a matrix to hold spikeshapes.
totalsweeps = 0;                  	%Keep track of the number of sweeps.
while ~feof(fid)
    i = fread(fid,1,'int16');       %Stimulus index
    try
        if ~isempty(i)
            fseek(fid,4*(1+numparams),'cof');	%Skip the sweeplength and parameter values.  
            numsweeps = uint16(fread(fid,1,'uint16'));      %Number of sweeps to follow.
            for j = 1:numsweeps
                if ~feof(fid)
                    fseek(fid,14,'cof');     %Skip the timestamp, order, and noise estimate.
                    numspikes = fread(fid,1,'uint32');	%Number of spikes.
                    for m = 1:numspikes
                        fseek(fid,5,'cof');     %Skip the spike time and cluster assignment.
                        all_spikes = [all_spikes; single(fread(fid,num_spike_samples,'float32')')];   %Grab the spike shape.
                    end
                    %If we've loaded up enough spikes for spike-sorting,
                    %stop loading.
                    if size(all_spikes,1) > SPC.max_spikes  %Check to see if we're at maximum...
                        fseek(fid,0,'eof');     %Set the file position indicator to the end of the file.
                        break;
                    else        %Otherwise...
                        totalsweeps = totalsweeps + 1;	%Keep track of how many sweeps we've loaded.
                    end
                end
            end
        end
    catch
        warning(['Error in reading sweep ' num2str(i) ' for this file, stopping file read at last complete sweep.']);
    end
end
fclose(fid);    %Close the input file.
numspikes = size(all_spikes,1);     %Pull out the number of spikes.

%If a cluster doesn't spike at least once every two sweeps, we'll classify
%that as a noise cluster and kick it out.
SPC.min_clus = totalsweeps/2;

%If for some reason there are no spikes in this recording, we'll exit this
%function.
if numspikes < 2
    disp('No spikes in this *.SPK file, exiting function.');
    return;
end

%We'll apply either wavelet clustering or PCA to the spike shapes to pull
%out the spike features to be used in clustering.
disp('-Calculating wavelet coefficients...');
if strcmpi(sort_feature,'WAV');         %If we're applying wavelet clustering...
    for i = 1:numspikes
        [c,l] = wavedec(all_spikes(i,:),scales,'haar');
        all_spikes(i,:) = c(1:size(all_spikes,2));
    end
    trace = [];
    for i = 1:size(all_spikes,2)
        %Before identifying which features are most important, we'll kick
        %out any outliers more than 3 standard deviations from the mean.
        dist_min = mean(all_spikes(:,i)) - std(all_spikes(:,i)) * 3;
        dist_max = mean(all_spikes(:,i)) + std(all_spikes(:,i)) * 3;
        temp = all_spikes(find(all_spikes(:,i) > dist_min & all_spikes(:,i) < dist_max),i);
        if length(temp) > 10;
            [y_expcdf,x_expcdf] = cdfcalc(temp);        %Calculates the CDF (expcdf)
            zScores  =  (x_expcdf - mean(temp))./std(temp);   %The theoretical CDF (theocdf) is assumed to be normal with unknown mean and sigma.
            theocdf  =  normcdf(zScores,0,1);
            %We'll compute the maximum distance: max|S(x) - theocdf(x)|.
            delta1    =  y_expcdf(1:end-1) - theocdf;	% Vertical difference at jumps approaching from the LEFT.
            delta2    =  y_expcdf(2:end)   - theocdf;   % Vertical difference at jumps approaching from the RIGHT.
            deltacdf  =  abs([delta1; delta2]);
            trace(i) = max(deltacdf);
        else
            trace(i) = 0;
        end
    end
    [a b] = sort(trace);
    coeffs(1:clust_inputs) = b(size(all_spikes,2):-1:size(all_spikes,2)-clust_inputs+1);
else        %Otherwise we'll apply PCA for clustering...
    [C,S,L] = princomp(all_spikes);
    coeffs(1:clust_inputs) = [1:clust_inputs];
end

%Now we'll create the input matrix for the Super-Paramagnetic Clustering,
%using only those points with the most variance.
input_matrix = zeros(numspikes, clust_inputs);  %We'll create an SPC input matrix containing the coefficients with the most variance.
for i = 1:numspikes;
    for j = 1:clust_inputs
        input_matrix(i,j) = all_spikes(i, coeffs(j));
    end
end

%Here we'll clear out some old variables that are taking up memory.
clear x_expcdf y_expcdf zScores theocdf delta1 delta2 deltacdf trace temp all_spikes;

%Before we run the outside-of-MatLab cluster.exe prgram, we need to
%specify the name of the subsequent output files.  If we save the output
%files, we can come back later without having to re-run cluster.exe.
SPC.fname = file(1:length(file)-4);     %Output filename for interaction with SPC.

%If we're not in the folder containing the *.SPK file, we'll move there now.
cd(workingpath);

%We need to prepare data files to feed to the SPC program outside of
%MatLab.  These terms and the file format agree with those from Quiroga's
%code.
save([SPC.fname_in],'input_matrix','-ascii');       %Input file for SPC
%SPC.fname = [SPC.fname '_wc'];                     %Output filename of SPC
%SPC.fnamespc = SPC.fname;
%SPC.fnamesave = SPC.fnamespc;
% save([SPC.fname '.dg_01.lab'],'clust_inputs','-ASCII');
% delete([SPC.fname '.dg_01.lab']);
% save([SPC.fname '.dg_01'],'clust_inputs','-ASCII');
% delete([SPC.fname '.dg_01']);
fid = fopen(sprintf('%s.run',SPC.fname),'wt');      %Create parameter input file for cluster.exe.
fprintf(fid,'NumberOfPoints: %s\n',num2str(numspikes));             %Parameter: number of spikes.
fprintf(fid,'DataFile: %s\n',SPC.fname_in);                         %Parameter: name of file holding input matrix.
fprintf(fid,'OutFile: %s\n',SPC.fname);                             %Parameter: name for output file.
fprintf(fid,'Dimensions: %s\n',num2str(clust_inputs));              %Parameter: number of cluster inputs.
fprintf(fid,'MinTemp: %s\n',num2str(SPC.mintemp));                  %Parameter: minimum temperature.
fprintf(fid,'MaxTemp: %s\n',num2str(SPC.maxtemp));                  %Parameter: maximum temperature.
fprintf(fid,'TempStep: %s\n',num2str(SPC.tempstep));                %Parameter: temperature step.
fprintf(fid,'SWCycles: %s\n',num2str(SPC.SWCycles));                %Parameter: number of Monte Carlo iterations.
fprintf(fid,'KNearestNeighbours: %s\n',num2str(SPC.KNearNeighb));   %Parameter: number of nearest neighbors.
fprintf(fid,'MSTree|\n');
fprintf(fid,'DirectedGrowth|\n');
fprintf(fid,'SaveSuscept|\n');
fprintf(fid,'WriteLables|\n');
fprintf(fid,'WriteCorFile~\n');
if num2str(SPC.randomseed) ~= 0
    fprintf(fid,'ForceRandomSeed: %s\n',num2str(SPC.randomseed));   %Parameter: random seed.
end    
fclose(fid);

%We'll go looking for the "cluster.exe" program and move it into the working directory.
if exist([pwd '\cluster.exe']) == 0     %If cluster.exe isn't in the current directory.
    directory = which('cluster.exe');   %Find the full path for cluster.exe.
    copyfile(directory,pwd);            %Copy cluster.exe to the working directory.
end

%The SPC program is stand-alone, so that it runs faster.  It uses the text
%files we created as inputs and outputs similar text files that we then
%read in.
disp('-Performing super-paramagnetic clustering...');
status = dos(sprintf('cluster.exe %s.run',SPC.fname));   %Execute cluster.exe in DOS.

disp(status);

%We'll read back in the output of the SPC program.
clusters = load([SPC.fname '.dg_01.lab']);
tree = load([SPC.fname '.dg_01']); 
delete(sprintf('%s.run',SPC.fname));    %Delete input parameters file.
delete *.mag;        %Delete various files associated with cluster.exe.
delete *.edges;
delete *.param;
delete cluster.exe;
delete(SPC.fname_in);   %Delete the text file containing the input matrix.

%This next section deals with the "temperature" of the SPC.
aux = [];
for i = 5:size(tree,2)
    aux = [aux, diff(tree(:,i))];   %Change in the nth cluster size.
end

temp = 1;	%Initial temperature value.

for t = 1:SPC.num_temp - 1
    %Looks for changes in the cluster size of any cluster larger than min_clus.
    if any(aux(t,:) > SPC.min_clus)     
        temp = t + 1;
    end
end

%If the second cluster is too small, then we'll raise the temperature a little bit 
if (temp == 1 && tree(temp,6) < SPC.min_clus)
    temp = 2;
end        
        
%Here we use the temperature to decide assignment to clusters based on the
%temperature, which is really just an index to the larger "cluster" matrix.
if size(clusters,2) - 2 < size(input_matrix,1);
    clusters = clusters(temp,3:end) + 1;
    clusters = [clusters(:)' zeros(1,size(all_spikes,1) - SPC.max_spikes)];
else
    clusters = clusters(temp,3:end) + 1;
end

%We'll clear out the input matrix to free up some memory.
clear input_matrix;

%Noise spikes tend to get assigned to small outlier clusters.  If any
%outlier clusters are less than our minimum cluster size, we'll assign them
%a cluster value of zero to mark them as noise.
num_clusters = max(clusters);
for i = 1:num_clusters
    a = find(clusters == i);
    if length(a) < SPC.min_clus
        clusters(a) = 0;
    end
end

%Now we'll re-number the clusters so that there's no gaps in numbering.
num_clusters = length(unique(clusters)) - 1;
for i = 1:num_clusters
    a = unique(clusters);
    a = a(i+1);
    clusters(find(clusters == a)) = i;
end
clusters = clusters';

%Since we deleted the data structure earlier to free up memory for the SPC,
%we'll reload the data here.
%Open the *.SPK file for reading.
disp(['Spike-sorting: ' file]);
fid = fopen(file,'r');
frewind(fid);
fseek(fid,1,'bof');               	%Skip past the daycode.
numchar = fread(fid,1,'int8');      %Find the number of characters in the rat's name.
fseek(fid,numchar+2 + 4,'cof');    	%Skip the rat's name, spontaneous delay, and the sampling rate.
num_spike_samples = fread(fid,1,'int16');	%The number of spike shape samples.
numparams = fread(fid,1,'int8');         	%Number of stimulus parameters.
for i = 1:numparams                         %Step through the number of parameters.
    numchar = fread(fid,1,'int16');      	%Number of characters in a parameter name.
    fseek(fid,numchar,'cof');               %Skip the parameter name.
end
all_spikes = [];                    %Create a matrix to hold spikeshapes.
while ~feof(fid)
    i = fread(fid,1,'int16');       %Stimulus index
    try
        if ~isempty(i)
            fseek(fid,4*(1+numparams),'cof');	%Skip the sweeplength and parameter values.  
            numsweeps = uint16(fread(fid,1,'uint16'));      %Number of sweeps to follow.
            for j = 1:numsweeps
                if ~feof(fid)
                    fseek(fid,14,'cof');     %Skip the timestamp, order, and noise estimate.
                    numspikes = fread(fid,1,'uint32');	%Number of spikes.
                    for m = 1:numspikes
                        fseek(fid,5,'cof');     %Skip the spike time and cluster assignment.
                        all_spikes = [all_spikes; single(fread(fid,num_spike_samples,'float32')')];   %Grab the spike shape.
                    end
                    %If we've loaded up enough spikes for spike-sorting,
                    %stop loading.
                    if size(all_spikes,1) > SPC.max_spikes  %Check to see if we're at maximum...
                        fseek(fid,0,'eof');     %Set the file position indicator to the end of the file.
                        break;
                    end
                end
            end
        end
    catch
        warning(['Error in reading sweep ' num2str(i) ' for this file, stopping file read at last complete sweep.']);
    end
end
fclose(fid);    %Close the input file.
numspikes = size(all_spikes,1);     %Pull out the number of spikes.

%If the display option is on, we'll grab some spikes for plotting prior to
%any wavelet decomposition used during template matching.
if size(all_spikes,1) < 500 && displayopt
    plotspikes = all_spikes;
elseif displayopt
    plotspikes = all_spikes(1:500,:);
end

%If we're template matching according to the wavelet decomposition, we'll
%recalculate the wavelet coefficients for the SPC sorted spikes here.
if strcmpi(template.feature,'WAV');
    for i = 1:numspikes
        [c,l] = wavedec(all_spikes(i,:),scales,'haar'); %Calculate wavelet coefficients.
        all_spikes(i,:) = c(1:size(all_spikes,2));
    end
end

%If the display option is on, we'll plot the projection of wavelet
%coefficients so that we can visualize any separation.  We'll also plot the
%temperature of possible clusters against cluster size with lines showing
%the decided cluster size.  Lastly, we'll show 500 spike shapes colored
%according to which cluster they were assigned to.  This will all be
%plotted on a single figure and that figure will be saved as a bitmap for
%future reference.
if displayopt
    a = figure(1);
    pos = get(0,'ScreenSize');  %We'll make the figure large because it's going to have many subplots.
    pos = [0.1*pos(3),0.1*pos(4),0.8*pos(3),0.8*pos(4)];
    set(a,'Position',pos,'MenuBar','none');
    
    %Projection plots.
    subplot(clust_inputs-1, clust_inputs-1, clust_inputs + 1);  
    pos = get(gca,'OuterPosition');     %We need to grab the size of a middle subplot so that we can maximize all the subplots.
    h = pos(4);     %We'll have a set height and width for projection plots.
    w = pos(3);
    colors = [0.5 0.5 0.5; lines(num_clusters)];    %We'll grab a set of colors to identify different clusters.
    plot_counter = 0;
    for i = 1:clust_inputs
        for j = (i + 1):clust_inputs
            plot_counter = plot_counter + 1;
            subplot(clust_inputs-1, clust_inputs-1, plot_counter);
            if any(plot_counter == [1:clust_inputs-1:(clust_inputs-1)^2])
                pos = get(gca,'OuterPosition');
                set(gca,'Position',[pos(3) - w, pos(2), w, h]); %If this is a far left subplot, we'll maximize according to the middle subplot 'OuterPosition'.
            else
                pos = get(gca,'OuterPosition');
                set(gca,'Position',[pos(1), pos(2), w, h]);     %We'll maximize the other subplots.
            end
            hold on;    %Hold on while we plot different clusters.
            plot(all_spikes(:,i), all_spikes(:,j),'marker','.','linestyle','none','color','k','markersize',0.5);    %This we plot just to set the xcis limits.
            axis tight;
            for k = 0:num_clusters  %Now we go through and plot the projections for each cluster in a different color.
                a = find(clusters == k);
                plot(all_spikes(a,i), all_spikes(a,j),'marker','.','linestyle','none','color',colors(k+1,:),'markersize',0.5);
                set(gca,'xtick',[],'ytick',[],'xticklabel',[],'yticklabel',[],'color','k');
            end
            if plot_counter == fix(clust_inputs/2);     %We'll add a title to the top, center plot.
                title(file(1:length(file)-4),'fontsize',14,'fontweight','bold','interpreter','none');
            end
        end
    end
    
    %Temperature plot;
    a = [];     %With so many projection plots, it's tricky to find the right subplot indices for a large section.
    for i = 1:(clust_inputs-1)
        a = [a; (1:(clust_inputs-1)) + (i - 1)*(clust_inputs-1)];
    end
    a = a(ceil(clust_inputs/2)+1:clust_inputs-1,1:ceil(clust_inputs/2));    %These are the indices for roughly the bottom left quarter of the plot.
    subplot(clust_inputs-1,clust_inputs-1,unique(a));
    temperature = SPC.mintemp + temp*SPC.tempstep;  %Determine the temperature used for clustering.
    semilogy(SPC.mintemp + (1:SPC.num_temp)*SPC.tempstep, tree(1:SPC.num_temp,5:size(tree,2)),'linewidth',2);   %Plotting cluster temperatures.
    xlim([0 1.05*SPC.maxtemp]);
    line(get(gca,'xlim'),[SPC.min_clus, SPC.min_clus], 'color','w','linestyle','--');   %Plot the minimum cluster size.
    line([temperature temperature], get(gca,'ylim'), 'color','w','linestyle','--');     %Plot the determined best temperature.
    xlim([0 1.05*SPC.maxtemp]);
    ylim([1 max(get(gca,'ylim'))]);
    xlabel('Temperature','fontsize',12,'fontweight','bold');
    ylabel('Clusters Size','fontsize',12,'fontweight','bold');
    pos = get(gca,'OuterPosition');
    set(gca,'color','k','Position', [pos(3) - w*ceil(clust_inputs/2), 0.1*pos(4), w*ceil(clust_inputs/2), 0.85*pos(4)]);    %Maximize the plot size.

    %Spike shape plot.
    a = [];     %Again, with so many projection plots, it's tricky to find the right subplot indices for a large section.
    for i = 1:(clust_inputs-1)
        a = [a; (1:(clust_inputs-1)) + (i - 1)*(clust_inputs-1)];
    end
    a = a(ceil(clust_inputs/2)+1:clust_inputs-1,ceil(clust_inputs/2)+1:clust_inputs-1);    %These are the indices for roughly the bottom right quarter of the plot.
    subplot(clust_inputs-1,clust_inputs-1,unique(a));
    hold on;
    for i = 0:num_clusters  %Plot the first 500 spike shapes, colored according to cluster.
        a = find(clusters == i);
        a = a(find(a <= 500));
        if length(a) >= 2
            plot(plotspikes(a,:)','color',colors(i+1,:));
        end
    end
    axis tight;
    set(gca,'xtick',[],'ytick',[],'xticklabel',[],'yticklabel',[],'color','k');
    pos = get(gca,'Position');
    a = pos(1);
    b = pos(3);
    pos = get(gca,'OuterPosition');
    set(gca,'color','k','Position', [a, 0.1*pos(4), b, 0.85*pos(4)]);   %Maximize the plot size.
    xlabel('Spike Shapes','fontsize',12,'fontweight','bold');
    drawnow;
    a = figure(get(0,'CurrentFigure'));     %Now we'll save this plot as a bitmap in the same folder as the original data.
    temp = [file(1:length(file)-4) '_SPC'];
    saveas(a,temp,'bmp');
    close(a);
end
    
% %If we've got more spikes than the maximum used for SPC, we'll now create
% %templates for sorting the rest of the spikes.
% if numspikes >= SPC.max_spikes
%     switch template.type
%         case 'NN'
%             
%         case 'CENTER'
%             templates = zeros(num_clusters, size(all_spikes,2));    %Create blank templates for each cluster.
%             maxdist = zeros(1,num_clusters);                        %Define a maximum Euclidean distance for a spike to be included.
%             pointdist = zeros(num_clusters, size(all_spikes,2));    %Define the maximum distance at each point for a spike to be included.
%             for i = 1:num_clusters
%                 fi = all_spikes(find(clusters == i),:);
%                 templates(i,:) = mean(fi,1);
%                 maxdist(i) = sqrt(sum(var(fi,1)));  %maxdist is the std dev of the euclidean distance from the mean.
%                 %Here we'll find the standard deviation of the variation along each dimension of
%                 %the spikes in this cluster.  The "1" in the var function means we want sum(x-m)^2/N, not N-1;
%                 pointdist(i,:) = sqrt(var(all_spikes(find(clusters == i),:),1));    %Single dimension standard deviation.
%             end
%             pointdist = pointdist*template.max_radius;	%Multiply point-by-point standard deviation by the maximum radius factor.
%             maxdist = maxdist*template.max_radius;      %Multiply overall standard deviation by the maximum radius factor.
%         case 'GAUSS'
%             
%         case 'MAHAL'
%             
%         otherwise
%             
%     end
% end

disp(['-----> ' num2str(size(all_spikes,1)) ' spikes, ' num2str(toc) ' seconds to spike-sort.']);

%We're done with the spike shape matrix now, so we can trash it to free up memory.
clear all_spikes;

% %Now we'll go back through the data structure matching up cluster
% %assignment to spikeshapes for those spikes that went into the SPC and
% %template sorting the rest with the templates we just made.
% total_number_of_spikes = 0;
% for i = 1:length(data.stim)
%     for j = 1:length(data.stim(i).spikes)
%         if ~isempty(clusters);      %If the spikes in this sweep were sorted by SPC.
%             numspikes = size(data.stim(i).spikes(j).shapes,1);      %Number of spikes in this sweep.
%             total_number_of_spikes = total_number_of_spikes + numspikes;    %Counting the total number of spikes processed.
%             data.stim(i).spikes(j).clusters = clusters(1:numspikes);    %Pull the cluster assignments out of the cluster matrix.
%             clusters(1:numspikes) = [];         %Clear out the cluster assignments just pulled from the cluster matrix.
%         else                        %If the spikes in this sweep need to be template sorted.
%             numspikes = size(data.stim(i).spikes(j).shapes,1);      %Number of spikes in this sweep.
%             total_number_of_spikes = total_number_of_spikes + numspikes;    %Counting the total number of spikes processed.
%             for k = 1:numspikes         %We'll match spikes to templates one at a time.
%                 spikeshape = data.stim(i).spikes(j).shapes(k,:);        %Pull out one spike shape.
%                 if strcmpi(template.feature,'WAV');     %If we're templating with wavelet decomposition.
%                     [c,l] = wavedec(spikeshape,scales,'haar');  %Calculate wavelet coefficients.
%                     spikeshape = c;
%                 end
%                 %Compute the Euclidian distance between the spike shape and the templates.
%                 distances = sqrt(sum((ones(num_clusters,1)*spikeshape - templates).^2,2)');     
%                 conforming = find(distances < maxdist);     %Identify those templates for which the spike is within the maximum distance.
%                 pointwise_conforming = [];
%                 for m = 1:num_clusters
%                     %If more points than our set maximum are outside of N standard deviations
%                     %from their corresponding template points, the template doesn't match.
%                     if sum(abs(spikeshape - templates(m,:)) > pointdist(m,:)) < template.pointlimit    
%                         pointwise_conforming = [pointwise_conforming, m];
%                     end
%                 end
%                 conforming = intersect(conforming, pointwise_conforming);
%                 if length(conforming) == 0  %If no templates match, the spike is considered noise.
%                     data.stim(i).spikes(j).cluster(k) = 0;
%                 else
%                     %The best template match is the one with the smallest Euclidian distance from the spikeshape.
%                     [temp, a] = min(distances(conforming));     
%                     data.stim(i).spikes(j).cluster(k) = conforming(a);
%                 end
%             end
%         end
%     end
% end

% %Now we'll open the input *.SPK file for read write to modify the existing
% %cluster assignments in the *.SPK file.
% fid = fopen(file,'r+');
% fseek(fid,1,'bof');                 %Skip past daycode.
% numchar = fread(fid,1,'int8');      %Read in the number of characters in the rat's name.
% fseek(fid,numchar + 8,'cof');       %Skip past the characters in the rats name, spontaneous delay, sampling rate, and # of spikeshape samples.
% numparam = fread(fid,1,'int8');     %Read in number of parameters.
% for j = 1:numparam
%     numchar = fread(fid,1,'int16');     %Number of characters in each parameter name.
%     fseek(fid,numchar,'cof');           %Skip past characters of each parameter name.         
% end
% for i = 1:length(data.stim)     %New Stimulus.
%     fseek(fid,8 + 4*numparam,'cof');         %Skip the stimulus index, sweeplength, parameter values, and number of sweeps.
%     for j = 1:length(data.stim(i).spikes)
%         fseek(fid,18,'cof');        %Skip the timestamp, trial number, noise estimate, and number of spikes.
%         for k = 1:length(data.stim(i).spikes(j).cluster)    %Go through spike by spike and modify cluster assignments.
%             fseek(fid,4,'cof');     %Skip the spike time.
%             fwrite(fid,data.stim(i).spikes(j).cluster(k),'uint8');  %WRITE IN THE NEW CLUSTER ASSIGNMENT.
%             fseek(fid,4*size(data.stim(i).spikes(j).shapes(k,:),2),'cof');  %Skip the spike shape.
%         end
%     end
% end
% fclose(fid);


% %We've timed the spike-sorting process and now we'll save the number of
% %spikes and how long it took them to sort into a text file for future
% %reference.
% if exist('Z:\Pitch Discrimination','dir')	%If the fileputer's connected.
%     textfilename = 'Z:\Spike Sorting\Cluster_Times.txt';
% else                                        %If the fileputer's not connected.
%     textfilename = 'C:\Documents and Settings\Owner\Desktop\Spike Sorting\Cluster_Times.txt';
% end
% if exist(textfilename)          %If the text file already exists, open the existing list of spike counts and sort times.
%     temp = load(textfilename);
% else                            %If it doesn't exist, build a new list.
%     temp = [];
% end
% temp = [temp; total_number_of_spikes, toc];          %Add the number of spikes and the sort time to the list.
% save(textfilename,'temp','-ascii');     %Re-save the file in text format.