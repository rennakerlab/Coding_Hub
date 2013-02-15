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
%   Last updated October 29, 2008 by Drew Sloan.


%First, we'll go through any changes to the optional properties the user might have entered.
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

%Ideally, we'd read in all the *.SPK data and then just write directly from
%the structure, but some files are so big that they'll bog down MatLab
%severely, so instead we'll just read in values and immediately write them
%without saving into a structure.
spkfid = fopen(file,'r');           %Open the *.SPK file for reading.
fseek(spkfid,1,'bof');              %Skip the daycode.
numchar = fread(spkfid,1,'int8');	%Number of characters in the rat's name.
fseek(spkfid,numchar,'cof');        %Skip the rat name.
spont_delay = int16(fread(spkfid,1,'int16'));	%Read the spontaneous rate measurement delay (ms).
fseek(spkfid,4,'cof');              %Skip the sampling rate.
num_spike_samples = fread(spkfid,1,'int16');	%The number of spike shape samples.
numparams = fread(spkfid,1,'int8');         	%Number of stimulus parameters.
for i = 1:numparams
    numchar = fread(spkfid,1,'int16');	%Number of characters in a parameter name.
    fseek(spkfid,numchar,'cof');        %Skip the parameter name.
end

%First, we need to find out how many clusters we need to make separate *.f32 files for.
clusters = [];      %Keep track of cluster numbers.
numsweeps = [];     %Keep track of how many sweeps there are for each stimulus.
while ~feof(spkfid)
    stim = fread(spkfid,1,'int16');       %Stimulus index
    try
        if ~isempty(stim)
            sweeplength(stim) = single(fread(spkfid,1,'float32'));    %Sweeplength, in seconds.
            for j = 1:numparams
                param(j).value(stim) = single(fread(spkfid,1,'float32'));    %Parameter values.
            end
            param(numparams+1).value(stim) = spont_delay;           %Put the spontaneous delay into the parameter values.
            for c = clusters'           %Step through already-identified clusters.
                if c ~= 0 || export_noise
                    fwrite(f32fid(c+1), -2, 'float32');     %New stimulus indicator.
                    fwrite(f32fid(c+1), 1000*sweeplength(stim), 'float32');	%Sweeplength (in milliseconds).
                    fwrite(f32fid(c+1), length(param), 'float32');      %Number of stimulus parameters to follow.
                    for k = 1:length(param)
                        fwrite(f32fid(c+1), param(k).value(stim), 'float32');	%kth stimulus parameter.
                    end
                end
            end
            numsweeps(stim) = uint16(fread(spkfid,1,'uint16')); 	%Number of sweeps to follow.
            for j = 1:numsweeps(stim)
                for c = clusters'
                    if c ~= 0 || export_noise
                        fwrite(f32fid(c+1), -1, 'float32');     %New sweep indicator.
                    end
                end
                fseek(spkfid,14,'cof');                 %Skip the timestamp, order, and noise estimate.
                numspikes = fread(spkfid,1,'uint32');	%Number of spikes.
                for m = 1:numspikes
                    time = single(fread(spkfid,1,'float32'));   %Grab the spike time.
                    c = uint8(fread(spkfid,1,'uint8'));         %Grab the cluster number.
                    if ~any(c == clusters)                      %If this cluster isn't already included, include it.
                        clusters = [clusters; c];               %Add this cluster to the cluster list.
                        if c ~= 0 || export_noise               %If it's not a noise cluster or we're exporting noise...
                            newfile = [file(1:length(file)-4) '_' char(65+c) '.f32'];   %Make a new file for this cluster.
                            f32fid(c+1) = fopen(newfile,'w');   %Keep track of the file identifiers as an array.
                            for i = 1:stim                      %Step through all the previously loaded stimuli.
                                fwrite(f32fid(c+1), -2, 'float32');     %New dataset indicator.
                                fwrite(f32fid(c+1), 1000*sweeplength(i), 'float32');	%Sweeplength (in milliseconds).
                                fwrite(f32fid(c+1), length(param), 'float32');      %Number of stimulus parameters to follow.
                                for k = 1:length(param)
                                    fwrite(f32fid(c+1), param(k).value(i), 'float32');	%kth stimulus parameter.
                                end
                                if i ~= stim    %For all previous stimuli, fill in all sweeps without spikes.
                                    for k = 1:numsweeps(i)
                                        fwrite(f32fid(c+1), -1, 'float32');     %New sweep indicator.
                                    end
                                else            %For the current stimuli, fill in all previous sweeps without spikes.
                                    for k = 1:j
                                        fwrite(f32fid(c+1), -1, 'float32');     %New sweep indicator.
                                    end
                                end
                            end
                        end
                    end
                    if c ~= 0 || export_noise
                        fwrite(f32fid(c+1), time, 'float32');   %Save the spike times (in milliseconds).
                    end
                    fseek(spkfid,4*num_spike_samples,'cof');	%Skip the spike shape.
                end
            end
        end
    catch
        warning(['Error in reading sweep ' num2str(i) ' for this file, stopping file read at last complete sweep.']); %#ok<WNTAG>
    end
end
if ~any(clusters == 0)      %If there's no noise spikes.
    clusters = [0; clusters];   %Add the noise cluster identifier to the matrix just to keep things square.
end
if length(clusters) == 1
    disp('-----> Only a noise cluster.');
elseif length(clusters) == 2
    disp(['-----> ' num2str(length(clusters)-1) ' cluster.']);
else
    disp(['-----> ' num2str(length(clusters)-1) ' clusters.']);
end

%Finally, close all the binary files, the *.f32 files and the *.SPK file.
for c = clusters'
    if c ~= 0 || export_noise
        fclose(f32fid(c+1));   	%Close the f32 file.
    end
end
fclose(spkfid);                 %Close the *.SPK file.