function data = RESPFileRead(file)

%
%RESPFileRead.m - Rennaker Lab, 2011
%
%   RESPFileRead reads in associated respiration signals from neural
%   recording sessions with olfactory stimuli saved to the *.RESP format.
%   The data is organized into a MatLav structure for easy analysis
%
%   data = RESPFileRead(file) reads from the *.RESP file specified by
%   "file" into the output "data" structure.
%
%   Last updated June 16, 2011, by Drew Sloan.

data = [];                                      %Create an structure to hold the file's data.

fid = fopen(file,'r');                          %Open the file for reading as a binary file.
numchar = fread(fid,1,'uint8');                	%Read in the number of characters in the rat's name.
data.rat = char(fread(fid,numchar,'uchar'))';   %Read in the rat's name.
data.spont_delay = fread(fid,1,'uint16');     	%Read in the spontaneous rate measurement delay (ms).
data.sampling_rate = fread(fid,1,'float32');  	%Read in the sampling rate (Hz).
numparams = fread(fid,1,'uint8');             	%Read in the number of stimulus parameters.
for i = 1:numparams                           	%Step through the stimulus parameters.
    numchar = fread(fid,1,'uint16');                          	%Read in the number of characters in the parameter's name.
    data.param(i).name = char(fread(fid,numchar,'uchar'))';     %Read in the parameter name.
end

order = 0;                                      %Make a counter variable to keep track of the order of presentation.          
while ~feof(fid)                                %Loop until the end of the file.
    order = order + 1;                          %We'll keep track of what order the stimuli were played in.
    i = fread(fid,1,'uint16');                  %Read in the stimulus index.
    if ~isempty(i) && i > 0                     %If any value was read in and it's not zero...
        if ~isfield(data,'stim') || length(data.stim) < i;  %If there's no "stim" field yet or no entry for this stimulus...
            data.stim(i).order = [];            %...make an empty "stim" field for this stimulus.
        end
        data.stim(i).order = [data.stim(i).order; order];    %Save the order in the presentation for this sweep.
        if ~isfield(data.stim, 'timestamp')     %If there's no "timestamp" field yet...
            data.stim(i).timestamp = [];        %...make an empty "timestamp" field for this stimulus.
        end
        data.stim(i).timestamp = [data.stim(i).timestamp; fread(fid,1,'float64')];    %Read in and save this sweep's timestamp.
        for j = 1:numparams                     %Step through each stimulus paramter.
            data.param(j).value(i) = fread(fid,1,'float32');    %Read in the parameter values.
        end
        if ~isfield(data.stim, 'sweeplength')   %If there's no "sweeplength" field yet...
            data.stim(i).sweeplength = [];      %...make an empty "sweeplength" field for this stimulus.
        end
        data.stim(i).sweeplength = [data.stim(i).sweeplength; fread(fid,1,'float32')];	% Read in the sweeplength.
        numsamples = fread(fid,1,'uint32');  	%Read in the number of samples in the following signal.
        if ~isfield(data.stim, 'signal')        %If there's no "signal" field yet...
            data.stim(i).signal = [];           %...create a "signal" field to receive the sweep trace.
        end
        temp = single(fread(fid,numsamples,'float32')');	%Read in the sweep trace in single precision.
        if any(abs(temp) > 10)      
            %If any samples are greater than 10, the maximum range of the 
            %ADC, it's good indicator that the file's corrupted somehow.
            if length(data.stim(i).order) == 1  %If this is a single sweep stimulus, we'll delete it outright.
                data.stim(i) = [];      %Delete this index from the structure.
                for j = 1:numparams
                    data.param(j).value(i) = [];    %Deleting erroneous parameter values.
                end
            else    %If this sweep is just one of many for this stimulus, we'll only delete the sweep.
                data.stim(i).order = data.stim(i).order(1:length(data.stim(i).order)-1);    %Deleting order for this sweep.
                data.stim(i).timestamp = data.stim(i).timestamp(1:length(data.stim(i).timestamp)-1);    %Deleting timestamp for this sweep.
                data.stim(i).sweeplength = data.stim(i).sweeplength(1:length(data.stim(i).sweeplength)-1);  %Deleting the sweeplength for this sweep.
            end
            if feof(fid)
                warning('RESP:RESPFileReadError',...
                    ['RESP read error: Abrupt file end on sweep #' num2str(i) ', likely memory shortage during recording, terminating data read.']);
                break;  %Since the file is corrupt, we'll stop reading it in.
            else    %If the sweep is corrupt, but there's data after it, report the bad sweep.
                warning('RESP:RESPFileReadError',['RESP read error: Corrupted sweep #' num2str(i) ', sweep will not be loaded.']);
            end
        elseif length(temp) >= size(data.stim(i).signal,2)      %We won't count any cut-off sweeps.
            data.stim(i).signal = [data.stim(i).signal; temp];     
        elseif length(temp) < size(data.stim(i).signal,2)       %Report the truncated sweep.
            warning('RESP:RESPFileReadError',['RESP read error: Truncated sweep #' num2str(i) ', sweep will not be loaded.']);
        end
    elseif i < 0
        %If the index comes back as negative, there must be an error in the
        %*.RESP file and we'll stop loading there.  Such errors can be
        %caused by running out of disk space during recording.
        warning('RESP:RESPFileReadError','RESP file error: Negative sweep index, terminating data read.');
        break;
    end
end
fclose(fid);

%Some *.RESP files may record stimulus sweeplengths multiple times, so here we'll trim any redundancy.
if isfield(data,'stim');
    for i = 1:length(data.stim)
        data.stim(i).sweeplength = unique(data.stim(i).sweeplength);    %There should only be one unique sweeplength per stimulus.
    end
end

%zBus drop-outs during recording will cause the *.RESP file to skip the
%affected sweep, leaving a blank index in the data structure.  We'll remove
%those blanks here so that they don't affect further processing.
temp = [];
for i = 1:length(data.stim)
    if isempty(data.stim(i).signal)
        temp = [temp, i];
    end
end
if ~isempty(temp)
    if ~strcmpi(file(5:8),'STIM')
        disp(['RESP file error: zBus drop-outs ruined ' num2str(length(temp)) ' sweeps.']);
    end
    data.stim(temp) = [];
    for i = 1:length(data.param)
        data.param(i).value(temp) = [];
    end
end