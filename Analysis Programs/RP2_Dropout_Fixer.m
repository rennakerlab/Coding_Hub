function RP2_Dropout_Fixer

datapath = 'E:\BACKHOE\BACKHOE_BDT\213';    %Select a directory for processing.
cd(datapath);               %Change to the specified directory.
files = dir('*.NEL*');      %Find all *.NEL or *.NEL.zip files.
if isempty(files)           %If there are no *.NEL or *.NEL.zip files, then indicate so.
    disp('There are not *.NEL or *.NEL.zip files in the specified directory.');
end

for i = 1:length(files);        %Stepping through file by file.
    disp(['Processing: ' files(i).name]);
    if strcmpi(files(i).name(length(files(i).name)-3:end),'.zip')   %If this file is zipped, look into unzipping it.
        if ~exist(files(i).name(1:length(files(i).name)-4))         %If no unzipped version already exists, then unzip.
            disp('-Unzipping...');
            unzip(files(i).name);
        end
        delete(files(i).name);
        files(i).name = files(i).name(1:length(files(i).name)-4);   %Remove the *.zip tail from the file name.
    end
    data = NELFileRead(files(i).name);
    if data.spont_delay == 200
        numsamples = round(0.1*data.sampling_rate);
        for j = 1:229
            data.stim(j).signal = data.stim(j).signal(numsamples + 1:end);
            data.stim(j).sweeplength = data.stim(j).sweeplength - 0.1;
        end
        delete(files(i).name);
        data.spont_delay = 100;
        fid = fopen(files(i).name,'w');
        fwrite(fid,data.daycode,'int8');                %Daycode.
        fwrite(fid,length(data.rat),'int8');            %Number of characters in the rat's name.
        fwrite(fid,data.rat,'uchar');                   %Characters of the rat's name.
        fwrite(fid,data.spont_delay,'int16');           %Spontaneous measurement delay.
        fwrite(fid,data.sampling_rate,'float32');       %Sampling rate, in Hz.
        numparams = length(data.param);                 %Number of stimulus parameters.
        fwrite(fid,numparams,'int8');                
        for j = 1:numparams
            numchar = length(data.param(j).name);       %Number of characters in a parameter name.
            fwrite(fid,numchar,'int16');
            fwrite(fid,data.param(j).name,'uchar');
        end
        for j = 1:length(data.stim)
            fwrite(fid,data.stim(j).order,'int16');
            fwrite(fid,data.stim(j).timestamp,'float64');
            for k = 1:numparams
                fwrite(fid,data.param(k).value(j),'float32');
            end
            fwrite(fid,data.stim(j).sweeplength,'float32');         %Sweeplength, in seconds
            fwrite(fid,length(data.stim(j).signal),'uint32');
            fwrite(fid,data.stim(j).signal,'float32');
        end
        fclose(fid);
    end
end