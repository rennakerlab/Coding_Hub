function data = NELFileRead(file)

%
%NELFileIndex.m - OU Neural Engineering Lab, 2008
%
%   NELFileIndex is a less memory intensive version of NELFileRead.
%   Instead of reading in all the raw, unfiltered sweep traces saved in the
%   *.NEL format, this function simply finds and returns the indices and
%   sample lengths of the sweeps, so that they can be read off the hard
%   drive instead of stored in the RAM.  However, while NELFileIndex does 
%   not read in the sweep traces, it will read in all other parameters
%   pertaining to the sweeps into a MatLab structure so that you can
%   compare and verify information contained in the indexed sweeps.  Note
%   that you will need to later close the file with the fclose function.
%
%   data = NELFileIndex(file) indexes the *.NEL file specified by "file" 
%   into the output "data" structure and keeps the file open for reading 
%   with the file identifier ("fid") field in the data structure.
%
%   Last updated May 19, 2008, by Drew Sloan.

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
    a = ftell(fid);
    i = fread(fid,1,'int16');       %Stimulus index
    if ~isempty(i) & i > 0
        if ~isfield(data,'stim') | length(data.stim) < i;
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
        location = ftell(fid);                      %Grab the byte position in the file.
        if ~isfield(data.stim, 'location')
            data.stim(i).location = [];
        end
        temp = single(fread(fid,numsamples,'float32')');	%Read in the sweep trace.
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
            else
                disp(['NEL read error: Truncated sweep #' num2str(i) ', terminating data read.']);
            end
            break;      %Since the file is corrupt, we'll stop reading it in.
        elseif isempty(data.stim(i).location) || length(temp) >= min(data.stim(i).location(:,2))   %We won't count any cut-off sweeps.
            data.stim(i).location = [data.stim(i).location; location, numsamples];     
        end
    elseif i < 0
        %If the index comes back as negative, there must be an error in the
        %*.NEL file and we'll stop loading there.  Such errors can be
        %caused by running out of disk space during recording.
        disp('NEL file error: Negative sweep index, terminating data read.');
        break;
    end
end
data.fid = fid;     %Attach the file identifier to the data structure.
fseek(fid,0,'bof'); %Move the file position indicator back to the beginning of the file.

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
    if isempty(data.stim(i).location)
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