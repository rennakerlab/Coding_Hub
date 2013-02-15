function Downsample_NEL(file)

%
%NELFileRead.m - Rennaker Lab, 2007
%
%   NELFileRead reads in raw, unfiltered sweep traves from neural recording
%   sessions saved to the *.NEL format.  The data is organized into a
%   MatLab structure for easy analysis.
%
%   data = NELFileRead(file) reads from the *.NEL file specified by
%   "file" into the output "data" structure.
%
%   Last updated April 13, 2009, by Drew Sloan.

d_factor = 25;                                                              %Set the factor to downsample by.

high_pass_cutoff = 0.5;                                                     %High-pass cutoff for the passband filter, in Hz.
low_pass_cutoff = 1000;                                                     %Low-pass cutoff for the passband filter, in Hz.

oldfid = fopen(file,'r');                                                   %Open the original *.NEL file for reading.
file = [file(1:end-4) '_downsampled.NEL'];                                  %Create a new *.NEL filename for the downsampled version.
newfid = fopen(file,'w');                                                   %Open the new file to receive the downsampled data.
temp = fread(oldfid,1,'uint8');                                             %Read the DayCode.
fwrite(newfid,temp,'uint8');                                                %Write the DayCode.
numchar = fread(oldfid,1,'uint8');                                          %Number of characters in the rat's name.
fwrite(newfid,numchar,'uint8');                                             %Write the number of characters in the rat's name.
temp = fread(oldfid,numchar,'uchar');                                       %Rat name.
fwrite(newfid,temp,'uchar');                                                %Write the rat's name.
temp = fread(oldfid,1,'int16');                                             %Spontaneous rate measurement delay (ms).
fwrite(newfid,temp,'uint16');                                               %Write the spontaneous rate measurement delay (ms).
sample_rate = fread(oldfid,1,'float32');                                    %Sampling rate (Hz).
fwrite(newfid,sample_rate/d_factor,'float32');                              %Write the sampling rate (Hz).
numparams = fread(oldfid,1,'int8');                                         %Number of stimulus parameters.
fwrite(newfid,numparams,'uint8');                                           %Write the number of stimulus parameters.
for i = 1:numparams                                                         %Step through the stimulus parameters.
    numchar = fread(oldfid,1,'int16');                                      %Number of characters in a parameter name.
    fwrite(newfid,numchar,'uint16');                                        %Write the number or characters in the parameter name.
    temp = fread(oldfid,numchar,'uchar');                                   %Parameter name.
    fwrite(newfid,temp,'uchar');                                            %Write the parameter name.
end

[b,a] = ellip(2,0.1,40,[high_pass_cutoff low_pass_cutoff]*2/sample_rate);   %Generate filter coefficients a bandpass filter.

while ~feof(oldfid)                                                         %Loop until the end of the original file.
    i = fread(oldfid,1,'int16');                                            %Stimulus index.
    if ~isempty(i) && i > 0                                                 %If a value was read from the file and we're not at the end of the file...
        fwrite(newfid,i,'uint16');                                          %Write the stimulus index.
        temp = fread(oldfid,1,'float64');                                   %Timestamp.
        fwrite(newfid,temp,'float64');                                      %Write the timestamp.        
        for j = 1:numparams                                                 %Step through the parameters.
            temp = fread(oldfid,1,'float32');                               %Parameter values.
            fwrite(newfid,temp,'float32');                                  %Write the parameter value.
        end
        temp = fread(oldfid,1,'float32');                                   %Sweeplength (s).
        fwrite(newfid,temp,'float32');                                      %Write the sweeplength (s).
        numsamples = fread(oldfid,1,'uint32');                              %Number of samples.        
        signal = double(fread(oldfid,numsamples,'float32')');               %Sweep trace.
        temp = ceil(sample_rate/high_pass_cutoff);                          %Calculate how many samples to put in the "tails" to get rid of transients.
        signal = [signal(1)*ones(1,temp),signal,signal(end)*ones(1,temp)];  %Add "tails" to the ends fo the signal to avoid transients.
        signal = filtfilt(b,a,double(signal));                              %Apply the bandpass filter.
        signal = signal(temp+1:end-temp);                                   %Remove the "tails".
        signal = signal(1:d_factor:end);                                    %Downsample the signal.
        fwrite(newfid,length(signal),'uint32');                             %Write the number of samples.
        fwrite(newfid,signal,'float32');                                    %Write the downsampled signal.
    end
end
fclose(oldfid);                                                             %Close the original file.
fclose(newfid);                                                             %Close the new downsampled file.