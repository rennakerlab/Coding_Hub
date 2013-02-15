function SPKtoF32(file, varargin)

%
%SPKtoF32.m - OU Neural Engineering Lab, 2007
%
%   SPKtoF32 takes spike times and cluster assignments from neural
%   recordings stored in the *.SPK format and creates Brainware format
%   *.f32 spike time files for each cluster.
%
%   SPKtoF32(file) exports spike times and cluster assignments from a *.SPK
%   file using all function defaults.
%
%   SPKtoF32(...,'Property1',PropertyValue1,...) sets the values of any of 
%   the following optional export properties:
%
%   * 'Noise' - An option to export a *.f32 file for spikes classified as
%               noise with a cluster assignment of zero, set with input
%               values of 'On' or 'Off'.  The default value is 'On'.
%
%   Last updated Sept 9, 2008 by Drew Sloan.


%The new file will have the same name, but with the *.f32 file extension.
newfile = [file(1:length(file)-4) '.f32'];
disp(['Exporting spike times from "' file '"']);

%Before we export the spike times from the *.SPK file, we'll delete all
%previous *.f32 files to avoid mixing the results of spike-sorting
%sessions.
rootfile = file(1:length(file)-4);
trashfiles = dir([rootfile '*.f32']);
for i = 1:length(trashfiles)
    delete(trashfiles(i).name);
end

%We'll use SPKFileRead to open the input file.
data = SPKFileRead(file);


%First, we need to find out how many clusters we need to make separate
%*.f32 files for.
clusters = 0;       %Always include a noise spike file.
for i = 1:length(data.stim)
    for j = 1:length(data.stim(i).spikes)
        %We'll step through the data and check how many different clusters there are.
        clusters = unique([clusters; data.stim(i).spikes(j).cluster]);
    end
end
if length(clusters) == 1
    disp(['-----> Only a noise cluster.']);
elseif length(clusters) == 2
    disp(['-----> ' num2str(length(clusters)-1) ' cluster.']);
else
    disp(['-----> ' num2str(length(clusters)-1) ' clusters.']);
end

%Now we'll go through any changes to the optional properties the user might
%have entered.
export_noise = 0;       %The default setting is not to export noise spikes.
for i = 1:2:length(varargin)
    if length(varargin) <= i    %Input arguments must come in pairs, the property name and it's specified value.
        error(['- No corresponding input argument for ''' cell2mat(varargin(i)) '''.']);
    else
        if strcmpi(cell2mat(varargin(i)),'Noise')	%Setting the 'Noise' property.
            if ~ischar(cell2mat(varargin(i+1))) || ...    %If the input value is not one of the two 'Noise' options, then indicate error.
                    ~(strcmpi(cell2mat(varargin(i+1)),'On') ||  strcmpi(cell2mat(varargin(i+1)),'Off'))
                error('- The ''Noise'' property must set to ''On'' or ''Off''.');
            else
                if strcmpi(cell2mat(varargin(i+1)),'On')   %If the user selects to export noise spikes...
                    export_noise = 1;	%Change the export noise setting.
                end
            end
        else        %If the input argument is not one of the options.
            error(['- ' '' cell2mat(varargin(i)) ' is not a recognized input argument.']);    %Return an error.
        end
    end
end
            
%By default, we won't export noise spikes, but if the user specifies that
%they'd like to, we will.
if ~export_noise   %If the user selects not to export noise spikes...
    clusters(find(clusters == 0)) = [];     %Remove the noise cluster from the export list.
end
                
%Finally, we'll go through the data and export a separate *.f32 file for
%each cluster.
for c = clusters'
	newfile = [file(1:length(file)-4) '_' char(65+c) '.f32'];
    fid = fopen(newfile,'w');
    for i = 1:length(data.stim)
        fwrite(fid, -2, 'float32');                                 %New dataset indicator.
        fwrite(fid, 1000*data.stim(i).sweeplength, 'float32');      %Sweeplength (in milliseconds).
        fwrite(fid, length(data.param) + 1, 'float32');             %Number of stimulus parameters to follow.
        for j = 1:length(data.param)
            fwrite(fid, data.param(j).value(i), 'float32');     %jth stimulus parameter.
        end
        fwrite(fid, data.spont_delay, 'float32');               %Spontaneous recording delay.
        for j = 1:length(data.stim(i).spikes)
            fwrite(fid, -1, 'float32');                             %New sweep indicator.
            spikes = find(data.stim(i).spikes(j).cluster == c);     %Finding all spike times for this cluster.
            fwrite(fid, data.stim(i).spikes(j).times(spikes), 'float32');   %Spike times (in milliseconds).
        end
    end
    fclose(fid);
end