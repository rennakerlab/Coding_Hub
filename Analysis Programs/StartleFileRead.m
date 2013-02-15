function data = StartleFileRead(file)

%
%StartleFileRead.m - OU Neural Engineering Lab, 2010
%
%   StartleFileRead reads in the sweep traces from startle testing sessions
%   saved to the *.STARTLE format.  The data is organized into a Matlab
%   structure for easy analysis.
%
%   data = StartleFileRead(file) reads from the *.STARTLE file specified by
%   "file" into the output "data" structure.
%
%   Last updated March 11, 2010, by Drew Sloan.

data = [];

fid = fopen(file,'r');
order = 0;
data.daycode = fread(fid,1,'uint16');             %DayCode.
numchar = fread(fid,1,'int8');                  %Number of characters in the rat's name.
data.rat = fread(fid,numchar,'*char')';         %Rat name.
data.predictor_delay = fread(fid,1,'int16');   	%Predictor onset delay from the start of the sweep (ms).
data.startler_delay = fread(fid,1,'int16');    	%Startler onset delay from the start of the sweep (ms).
data.sampling_rate = fread(fid,1,'float32');    %Sampling rate, in Hz.
numparams = fread(fid,1,'int8');                %Number of stimulus parameters.
for i = 1:numparams
    numchar = fread(fid,1,'int16');                     	%Number of characters in a parameter name.
    data.param(i).name = fread(fid,numchar,'*char')';      %Parameter name.
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
        data.stim(i).timestamp = [data.stim(i).timestamp; fread(fid,1,'float64')];	%Timestamp.
        if ~isfield(data.stim, 'predicted')
            data.stim(i).predicted = [];
        end
        data.stim(i).predicted = [data.stim(i).predicted; fread(fid,1,'uint8')];  	%Predicted startler (1 = predicted, 0 = unpredicted).
        for j = 1:numparams
            data.param(j).value(i) = fread(fid,1,'float32');                        %Parameter values.
        end
        if ~isfield(data.stim, 'sweeplength')
            data.stim(i).sweeplength = [];
        end
        data.stim(i).sweeplength = [data.stim(i).sweeplength; fread(fid,1,'float32')];      %Sweeplength, in seconds.
        numsamples = fread(fid,1,'uint32');                                                 %Number of samples.
        scalefactor = fread(fid,1,'float32');                                           	%Scale factor.
        if ~isfield(data.stim, 'signal')
            data.stim(i).signal = [];
        end
        temp = scalefactor*single(fread(fid,numsamples,'int8')');                       %Sweep trace.
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
                warning('Startle:StartleFileReadError',...
                    ['Startle read error: Abrupt file end on sweep #' num2str(i) ', likely memory shortage during recording, terminating data read.']);
                break;  %Since the file is corrupt, we'll stop reading it in.
            else    %If the sweep is corrupt, but there's data after it, report the bad sweep.
                warning('Startle:StartleFileReadError',['Startle read error: Corrupted sweep #' num2str(i) ', sweep will not be loaded.']);
            end
        elseif length(temp) >= size(data.stim(i).signal,2)      %We won't count any cut-off sweeps.
            data.stim(i).signal = [data.stim(i).signal; temp];     
        elseif length(temp) < size(data.stim(i).signal,2)       %Report the truncated sweep.
            warning('Startle:StartleFileReadError',['Startle read error: Truncated sweep #' num2str(i) ', sweep will not be loaded.']);
        end
    elseif i < 0
        %If the index comes back as negative, there must be an error in the
        %*.Startle file and we'll stop loading there.  Such errors can be
        %caused by running out of disk space during recording.
        warning('Startle:StartleFileReadError','Startle file error: Negative sweep index, terminating data read.');
        break;
    end
end
fclose(fid);

%Some *.Startle files may record stimulus sweeplengths multiple times, so here we'll trim any redundancy.
if isfield(data,'stim');
    for i = 1:length(data.stim)
        data.stim(i).sweeplength = unique(data.stim(i).sweeplength);    %There should only be one unique sweeplength per stimulus.
    end
end