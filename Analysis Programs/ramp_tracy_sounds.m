function ramp_tracy_sounds

ramp_dur = 5;               %Ramp duration in milliseconds.
sampling_rate = 97656.25;	%Sampling rate of the RP2 (Hz);
N = round(sampling_rate*ramp_dur/1000);	%Find the ramp duration, in whole numbers of samples.

ramp = (1 - cos(pi*(1:N)/N))/2;         %Make an normalized cosine curve to use the ramp.

[temp path] = uigetfile('behavior*.32','multiselect','on');     %Select *.32 files to ramp.
cd(path);

if isempty(temp)                            %If no files were selected, then quit.
    return
end

if ~iscell(temp)                            %If only one file was selected...
    files.name = [path temp];               %...save it as a structure.
else                                        %If multiple files were selected...
    for i = 1:length(temp)                  %...step through each...
        files(i).name = [path temp{i}];     %...and add the pathname to the filename.
    end
end

for i = 1:length(files)                  	%Step through each file.
	fid = fopen(files(i).name,'r');        	%Open the 32-bit binary file containing the speech sound.
    signal = fread(fid,'float32')';      	%Read in the sound signal.
    fclose(fid);                         	%Close the binary file.
    signal(1:N) = signal(1:N).*ramp;        %Apply the ramp to the onset of the sound.
    signal(end-N+1:end) = signal(end-N+1:end).*fliplr(ramp);  %Flip the ramp around and apply it to the offset of the sound.
    fid = fopen(files(i).name,'w');        	%Re-open sound filename for writing.
    fwrite(fid,signal,'float32');           %Write the sound signal.
    fclose(fid);                         	%Close the binary file.
end