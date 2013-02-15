function data = NELFileRead(file)

%
%NELFileRead.m - OU Neural Engineering Lab, 2007
%
%   NELFileRead reads in raw, unfiltered sweep traves from neural recording
%   sessions saved to the *.NEL format.  The data is organized into a
%   MatLab structure for easy analysis.
%
%   data = NELFileRead(file) reads from the *.NEL file specified by
%   "file" into the output "data" structure.
%
%   Last updated May 29, 2008, by Drew Sloan.

data = [];

fid = fopen(file,'r');
order = 0;
data.daycode = fread(fid,1,'int8');             %DayCode.
numchar = fread(fid,1,'int8');                  %Number of characters in the rat's name.
data.rat = char(fread(fid,numchar,'uchar'))';   %Rat name.
data.spont_delay = fread(fid,1,'int16');        %Spontaneous rate measurement delay (ms).
data.sampling_rate = fread(fid,1,'float32');    %Sampling rate, in Hz.	<---Implemented 4/4/2007.
numparams = fread(fid,1,'int8');                %Number of stimulus parameters.
for i = 1:numparams
    numchar = fread(fid,1,'int16');                             %Number of characters in a parameter name.
    data.param(i).name = char(fread(fid,numchar,'uchar'))';     %Parameter name.
end

while ~feof(fid)
    order = order + 1;              %We'll keep track of what order the stimuli were played in.
    i = fread(fid,1,'int16');       %Stimulus index
    if ~isempty(i) && i > 0
        if ~isfield(data,'stim') || length(data.stim) < i;
            data.stim(i).order = [];
        end
        data.stim(i).order = [data.stim(i).order; order];    %Order in presentation.
        if ~isfield(data.stim, 'timestamp')
            data.stim(i).timestamp = [];
        end
        data.stim(i).timestamp = [data.stim(i).timestamp; fread(fid,1,'float64')];    %Timestamp.
        for j = 1:numparams
            data.param(j).value(i) = fread(fid,1,'float32');    %Parameter values.
        end
        if ~isfield(data.stim, 'sweeplength')
            data.stim(i).sweeplength = [];
        end
        data.stim(i).sweeplength = [data.stim(i).sweeplength; fread(fid,1,'float32')];      %Sweeplength, in seconds.   <---Implemented 4/4/2007.
        numsamples = fread(fid,1,'uint32');         %Number of samples.         <---Changed int32 to uint32, 4/4/2007.
        if ~isfield(data.stim, 'signal')
            data.stim(i).signal = [];
        end
        temp = single(fread(fid,numsamples,'float32')');	%Sweep trace.
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
                disp(['NEL read error: Abrupt file end on sweep #' num2str(i) ', likely memory shortage during recording, terminating data read.']);
                break;  %Since the file is corrupt, we'll stop reading it in.
            else    %If the sweep is corrupt, but there's data after it, report the bad sweep.
                disp(['NEL read error: Corrupted sweep #' num2str(i) ', sweep will not be loaded.']);   %Report the corrupted sweep.
            end
        elseif length(temp) >= size(data.stim(i).signal,2)      %We won't count any cut-off sweeps.
            data.stim(i).signal = [data.stim(i).signal; temp];     
        elseif length(temp) < size(data.stim(i).signal,2)       %WReport the truncated sweep.
            disp(['NEL read error: Truncated sweep #' num2str(i) ', sweep will not be loaded.']);
        end
    elseif i < 0
        %If the index comes back as negative, there must be an error in the
        %*.NEL file and we'll stop loading there.  Such errors can be
        %caused by running out of disk space during recording.
        disp('NEL file error: Negative sweep index, terminating data read.');
        break;
    end
end
fclose(fid);

%Some *.NEL files may record stimulus sweeplengths multiple times, so here we'll trim any redundancy.
if isfield(data,'stim');
    for i = 1:length(data.stim)
        data.stim(i).sweeplength = unique(data.stim(i).sweeplength);    %There should only be one unique sweeplength per stimulus.
    end
end

%zBus drop-outs during recording will cause the *.NEL file to skip the
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
        disp(['NEL file error: zBus drop-outs ruined ' num2str(length(temp)) ' sweeps.']);
    end
    data.stim(temp) = [];
    for i = 1:length(data.param)
        data.param(i).value(temp) = [];
    end
end