function SRC_Timestamp_Reader
[file path] = uigetfile('*.src');   %Use a dialog box to grab an SRC file name.
cd(path);                           %Change the path to the path containing the SRC file.
fid = fopen(file,'r');              %Open the SRC file for reading.
temp = [];                          %Create a matrix to hold byte indices.
while ~feof(fid)                    %Step through even-numbered byte indices in the file.
    objId = fread(fid,1,'uint16');  %Grab the object ID as a 16-bit unsigned integer.
    if objId == 29110               %If the object ID indicates the following bits contain a timestamp...
        temp = [temp; ftell(fid)];  %...save that byte index.
    end
end
fseek(fid,1,'bof');                 %Set the file position to step through by odd-numbered byte indices.
while ~feof(fid)                    %Step through odd-numbered byte indices in the file.
    objId = fread(fid,1,'uint16');  %Grab the object ID as a 16-bit unsigned integer.
    if objId == 29110               %If the object ID indicates the following bits contain a timestamp...
        temp = [temp; ftell(fid)];  %...save that byte index.
    end
end
for i = 1:length(temp)                  %Step through each saved byte index.
    fseek(fid,temp(i),'bof');           %Set the file position to that byte index.
    temp(i) = fread(fid,1,'float64');   %Read in the timestamp.
end
temp = temp + datenum('Dec-30-1899 00:00:00');      %Adjust the serial date number to be relative to December 30th, 1899.
disp(['Recording ran on ' datestr(min(temp),1) ' from ' datestr(min(temp),13) ' to ' datestr(max(temp),13) '.']);   %Display the recording time.
a = length(temp)/((max(temp)-min(temp))*86400);     %Calculate the presentation rate in seconds.
disp([num2str(length(temp)) ' stimuli with an average presentation rate of ' num2str(a,'% 2.2f') ' Hz, average onset-to-onset ISI of ' num2str(1000/a,'% 2.0f') ' ms']);    %Display presentation rate and ISI.
disp(' ');
fclose(fid);                        %Close the file.