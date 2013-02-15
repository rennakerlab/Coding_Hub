function f32Combiner

%This program works by having the user select one f32 file, then it
%automatically goes into that folder and combines all the speech sound data
%for each electrode channel.

%The user starts by picking one file in a folder.
[file path] = uigetfile('*.f32');
cd(path);

%The program then looks for all possible channels by checking how many
%files there are that match the selected file apart from the initial three
%character electrode designator.
temp = find(file == '_');
temp = ['*' file(4:length(file))];
startfiles = dir(temp);

%Now the program goes through the files channel by channel, taking the
%channel number from the three character designator at the beginning of the
%filename.
for currentfile = 1:length(startfiles);
    
    %If a combined f32 file already exists we've got to kill it off so that
    %we don't end up repeating the same data in a combined *.f32 file.
    temp = find(startfiles(currentfile).name == '_');
    temp = [startfiles(currentfile).name(1:temp(2)) 'C' startfiles(currentfile).name(temp(3):length(file))];
    delete(temp);
    
    %The program uses the "dir" function to pull up all the files that have
    %the same electrode number and the same file anme apart from the run
    %number.
    temp = find(startfiles(currentfile).name == '_');
    temp = [startfiles(currentfile).name(1:temp(2)) '*' startfiles(currentfile).name(temp(3):length(file))];
    disp(['Finding: ' temp]);
    channelfiles = dir(temp);
    
    %Windows will order the files alphabetically, but will put double digit
    %run numbers like "..._12_..." before similar single digit run numbers
    %like "..._1_..."  So this next section is a simple algorithm that
    %orders the filenames correctly.
    checker = 1;
    while checker == 1
        checker = 0;
        for j = 1:(length(channelfiles)-1)
            a = find(channelfiles(j).name == '_');
            a = str2num(channelfiles(j).name((a(2)+1):(a(3)-1)));
            b = find(channelfiles(j+1).name == '_');
            b = str2num(channelfiles(j+1).name((b(2)+1):(b(3)-1)));
            if a > b
                temp = channelfiles(j).name;
                channelfiles(j).name = channelfiles(j+1).name;
                channelfiles(j+1).name = temp;
                checker = 1;
            end
        end
    end
    
    %Next, the data is read into a structure called f with the spikedataf
    %function.
    for j = 1:length(channelfiles)
        disp(channelfiles(j).name);
        f(j).data = spikedataf(channelfiles(j).name);
    end
    
    %Finally, the spike data is stuck back into an f32 file with the
    %original format, but only if the original files match in terms of
    %number of parameters.
    for i = 1:length(f)
        a(i) = length(f(i).data);
    end
    for j = 1:length(f(1).data)
        temp = [];
        for i = 1:length(f)
            temp = [temp, f(i).data(j).stim];
        end
        b(j,:) = sum(std(temp'));
    end
    if length(unique(a)) > 1 | any(find(b ~= 0));
        disp(' ');
        disp('The stimulus parameters in these files do not match.');
    else
        %We'll delete the original f32 files.  We can always export them
        %again if we need them.
        for i = 1:length(channelfiles)
            delete(channelfiles(i).name);
        end
        %The new f32 file is given the run "number" of C, meaning the file
        %is combined.
        temp = find(startfiles(currentfile).name == '_');
        temp = [startfiles(currentfile).name(1:temp(2)) 'C' startfiles(currentfile).name(temp(3):length(file))];
        disp(['Writing: ' temp]);
        disp(' ');
        fid = fopen(temp,'w');
        for i = 1:length(f(1).data)
            fwrite(fid, -2,' float32');
            fwrite(fid, f(1).data(i).sweeplength, 'float32');
            fwrite(fid, length(f(1).data(i).stim), 'float32');
            fwrite(fid, f(1).data(i).stim, 'float32');
            for j = 1:length(f)
                for k = 1:length(f(j).data(i).sweep)
                    fwrite(fid, -1, 'float32');
                    fwrite(fid, f(j).data(i).sweep(k).spikes', 'float32');
                end
            end
        end
        fclose(fid);
    end
end
fclose('all');

delete('f32Data.mat');
delete('f32param.mat');
