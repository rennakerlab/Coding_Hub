function data = LFPFileRead(file)

%
%LFPFileRead.m - OU Neural Engineering Lab, 2007
%
%   LFPFileRead reads in local field potentials, pseudo-sampled at 1000 Hz,
%   from neural recording sessions saved to the *.LFP format.  The data is 
%   organized into a MatLab structure for easy analysis.
%
%   data = LFPFileRead(file) reads from the *.LFP file specified by
%   "file" into the output "data" structure.
%
%   Last updated July 13, 2007, by Drew Sloan.

%First, we'll check the input file to make sure it's a *.LFP file.
if ~strcmpi(file(length(file)-3:length(file)),'.LFP');
    error('- Input file is not a *.LFP file.');
end

data = [];

fid = fopen(file,'r');
data.daycode = int8(fread(fid,1,'int8'));               %DayCode.
numchar = fread(fid,1,'int8');                          %Number of characters in the rat's name.
data.rat = char(fread(fid,numchar,'uchar'))';           %Rat name.
data.spont_delay = int16(fread(fid,1,'int16'));         %Spontaneous rate measurement delay (ms).
numparams = fread(fid,1,'int8');                        %Number of stimulus parameters.
for i = 1:numparams
    numchar = fread(fid,1,'int16');                             %Number of characters in a parameter name.
    data.param(i).name = char(fread(fid,numchar,'uchar'))';     %Parameter name.
end

while ~feof(fid)
    i = fread(fid,1,'int16');       %Stimulus index
    if ~isempty(i)
        data.stim(i).sweeplength = single(fread(fid,1,'float32'));    %Sweeplength, in seconds.
        for j = 1:numparams
            data.param(j).value(i) = single(fread(fid,1,'float32'));    %Parameter values.
        end
        numsweeps = uint16(fread(fid,1,'uint16'));      %Number of sweeps to follow.
        for j = 1:numsweeps
            if ~isfield(data.stim, 'timestamp')
                data.stim(i).timestamp = [];
            end
            data.stim(i).timestamp = [data.stim(i).timestamp; fread(fid,1,'float64')];	%Timestamp.
            if ~isfield(data.stim,'order');
                data.stim(i).order = [];
            end
            data.stim(i).order = [data.stim(i).order; uint16(fread(fid,1,'uint16'))];	%Order in presentation.
            if ~isfield(data.stim,'lfp');
                data.stim(i).lfp = [];
            end
            data.stim(i).lfp = [data.stim(i).lfp; fread(fid,double(round(1000*data.stim(i).sweeplength)),'float32')'];     %LFP trace, pseudo-sampled at 1000 Hz.
        end
    end
end
fclose(fid);    %Close the input file.