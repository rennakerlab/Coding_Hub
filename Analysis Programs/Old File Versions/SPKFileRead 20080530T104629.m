function data = SPKFileRead(filename)

%
%SPKFileRead.m - OU Neural Engineering Lab, 2007
%
%   SPKFileRead reads in filtered spike waveforms, spike times, and cluster
%   assignments from neural recording sessions saved to the *.SPK format.
%   The data is organized into a MatLab structure for easy analysis.
%
%   data = SPKFileRead(filename) reads from the *.SPK file specified by
%   "filename" into the output "data" structure.
%
%   Last updated July 3, 2007, by Drew Sloan.

data = [];

fid = fopen(filename,'r');
data.daycode = int8(fread(fid,1,'int8'));             %DayCode.
numchar = fread(fid,1,'int8');                  %Number of characters in the rat's name.
data.rat = char(fread(fid,numchar,'uchar'))';   %Rat name.
data.spont_delay = int16(fread(fid,1,'int16'));        %Spontaneous rate measurement delay (ms).
data.sampling_rate = single(fread(fid,1,'float32'));	%Sampling rate, in Hz.  <--- Implemented 4/7/2007.
num_spike_samples = fread(fid,1,'int16');       %The number of spike shape samples.
numparams = fread(fid,1,'int8');                %Number of stimulus parameters.
for i = 1:numparams
    numchar = fread(fid,1,'int16');                             %Number of characters in a parameter name.
    data.param(i).name = char(fread(fid,numchar,'uchar'))';     %Parameter name.
end

while ~feof(fid)
    i = fread(fid,1,'int16');       %Stimulus index
    try
        if ~isempty(i)
            data.stim(i).sweeplength = single(fread(fid,1,'float32'));    %Sweeplength, in seconds.  <--- Implemented 4/7/2007.
            for j = 1:numparams
                data.param(j).value(i) = single(fread(fid,1,'float32'));    %Parameter values.
            end
            numsweeps = uint16(fread(fid,1,'uint16'));      %Number of sweeps to follow.
            for j = 1:numsweeps
                if ~isfield(data.stim, 'timestamp')
                    data.stim(i).timestamp = [];
                end
                data.stim(i).timestamp = [data.stim(i).timestamp; fread(fid,1,'float64')];	%Timestamp.  <--- Moved to this position 4/7/2007.
                if ~isfield(data.stim,'order');
                    data.stim(i).order = [];
                end
                data.stim(i).order = [data.stim(i).order; uint16(fread(fid,1,'uint16'))];           %Order in presentation.  <--- Moved to this position 4/7/2007.
                if ~isfield(data.stim,'noise');
                    data.stim(i).noise = [];
                end
                data.stim(i).noise = [data.stim(i).noise; single(fread(fid,1,'float32'))];          %Noise estimate ratio, number of noise samples/number of total samples.
                numspikes = fread(fid,1,'uint32');          %Number of spikes.
                if ~isfield(data.stim, 'spikes')        
                    sweep = 1;
                    data.stim(i).spikes(1).times = [];
                    data.stim(i).spikes(1).shapes = [];
                    data.stim(i).spikes(1).cluster = [];
                else
                    sweep = length(data.stim(i).spikes) + 1;
                    data.stim(i).spikes(sweep).times = [];
                    data.stim(i).spikes(sweep).shapes = [];
                    data.stim(i).spikes(sweep).cluster = [];
                end
                for m = 1:numspikes
                    data.stim(i).spikes(sweep).times = [data.stim(i).spikes(sweep).times; single(fread(fid,1,'float32'))];      %Reading spike time.
                    data.stim(i).spikes(sweep).cluster = [data.stim(i).spikes(sweep).cluster; uint8(fread(fid,1,'uint8'))];    %Reading cluster assignment.
                    data.stim(i).spikes(sweep).shapes = [data.stim(i).spikes(sweep).shapes; single(fread(fid,num_spike_samples,'float32')')];   %Reading spike shape.
                end
            end
        end
    catch
        if length(data.stim) == i
            data.stim(i) = [];
        end
        warning(['Error in reading sweep ' num2str(i) ' for this file, stopping file read at last complete sweep.']);
        %break;
    end
end
fclose(fid);    %Close the input file.