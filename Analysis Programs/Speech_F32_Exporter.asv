function Speech_F32_Exporter

mainpath = 'Y:\Speech Study\Spike MAT Files';
cd(mainpath);                                                               %Change the current directory to the pitch/attention study data folder.
[temp path] = uigetfile('*spikes.mat','multiselect','on');                  %Have the user pick an input file or files.
cd(path);                                                                   %Change the current directory to the folder that file is in.
if iscell(temp)                                                             %If the user's picked multiple files...
    for i = 1:length(temp)                                                  %Step through each selected file.
        files(i).name = temp{i};                                            %Save the file names in a structure.
    end
elseif ischar(temp)                                                         %If only one file is selected...
    files(1).name = temp;                                                   %Add the path to the filename.
elseif isempty(temp)                                                        %If no file is selected...
    error('No file selected!');                                             %Show an error message.
end
    
for f = 1:length(files)
    cd(mainpath);
    load(files(f).name);                                    %Load the specified data.
    rootfile = files(f).name(1:length(files(f).name)-11);	%Find the root file name in the data file.
    
    if isfield(data,'driven')
        if any(round(mean(data.driven.manual.behav1,2)))
            mkdir(rootfile);
            cd(rootfile);
        end

        for c = 1:length(data.channels)                         %Step through each channel.
            i = round(mean(data.driven.manual.behav1(c,:)));    %Check the users' ratings for drivenness.
            if i == 1   %If a majority of users said this unit is driven, export a classifier *.f32 file.
                sound = [];                  	%Define an empty structure.
                for i = 1:5                   	%For each sound...
                    for j = 1:2                 %For each compression...
                        sound(i).comp(j).psth = [];       	%Make an empty field to hold PSTHs.
                        sound(i).comp(j).duration = [];    	%Make an empty field to hold sweep durations.
                        sound(i).comp(j).outcome = [];      %Make an empty filed to hold the trial outcome.
                    end
                end 
                for i = 1:length(data.behav)                %Step through each behavioral recording.
                    for j = 1:length(data.behav(i).sweep)   %Step through each trial.
                        t = data.behav(i).sweep(j).trial;   %Grab the trial number.
                        onsets = 1000*cell2mat(data.psych(i).onsets(t));    %Find the onsets of the distractors.
                        onsets = round(onsets);                             %Round the onsets to the nearest millisecond.
                        onsets = onsets(onsets <= round(1000*data.psych(i).holdtime(t)));
                        sequence = data.psych(i).sound_seq{t};              %Grab the sound sequence.
                        sequence = sequence(strfind(sequence,'ad')-1);      %Find the first letter of each sound in the sequence.
                        for k = 2:length(onsets)                            %Step through each sound.
                            s = find(sequence(k) == 'tsgbd');               %Find which sound was played.
                            comp = find(data.psych(i).comp(t) == [50,100]); %Find what the compression level was.
                            a = find(data.channels(c) == data.behav(i).sweep(j).channel);   %Find the index for this channel in the PSTH.
                            if size(data.behav(i).sweep(j).psth,2) > double(data.behav(i).sweep(j).spont_delay) + onsets(k) + 950
                                sound(s).comp(comp).psth = [sound(s).comp(comp).psth; ...
                                    double(data.behav(i).sweep(j).psth(a,double(data.behav(i).sweep(j).spont_delay) + onsets(k) + (-50:950)))];     %Add this PSTH to the structure.
                            else
                                temp = double(data.behav(i).sweep(j).psth(a,(double(data.behav(i).sweep(j).spont_delay) + onsets(k) + -50):size(data.behav(i).sweep(j).psth,2)));
                                temp = [temp, repmat(NaN,1,1001-length(temp))];
                                sound(s).comp(comp).psth = [sound(s).comp(comp).psth; temp];
                            end
                            if onsets(k) == round(1000*data.psych(i).holdtime(t))
                                sound(s).comp(comp).outcome = [sound(s).comp(comp).outcome; data.psych(i).outcome(t)];       
                            else
                                sound(s).comp(comp).outcome = [sound(s).comp(comp).outcome; 'C'];
                            end
                            if k ~= length(onsets)                          %If this isn't the last sound of the sequence...
                                sound(s).comp(comp).duration = [sound(s).comp(comp).duration; ...
                                    onsets(k+1) - onsets(k)];               %Add the sound duration to the structure.
                            end
                        end
                    end
                end
                for i = 1:5             %Step through each distractor.
                    for j = 1:2         %Step through each compression level.
                        if ~isempty(sound(i).comp(j).duration)
                            sound(i).comp(j).duration = nanmedian(sound(i).comp(j).duration);      %Find the median duration.
                        else
                            sound(i).comp(j).duration = find(~isnan(mean(sound(i).comp(j).psth,1)),1,'last');
                        end
                        sound(i).comp(j).psth = sound(i).comp(j).psth(:,1:sound(i).comp(j).duration);  %...trim the PSTH to the duration.
                    end
                end

                f32filename = ['E' num2str(10*c,'%03d') '_EZClassifier_TRACY100_' rootfile '.f32'];	%Make a filename for the new *.f32 file.

                disp(['Writing: ' f32filename]);

                fid = fopen(f32filename,'w');                   %Open the *.f32 file for writing.

                for i = 1:5                                     %Step through each speech sound.
                    for j = 'HMFC'
                        a = find(sound(i).comp(2).outcome == j);
                        if ~isempty(a)
                            fwrite(fid, -2, 'float32');                             %New dataset indicator.
                            fwrite(fid, size(sound(i).comp(2).psth,2), 'float32');	%Sweeplength (in milliseconds).
                            fwrite(fid, 3, 'float32');                              %3 parameter values to follow.
                            fwrite(fid, i, 'float32');                              %Sound number (tsgbd).
                            fwrite(fid, i == 5, 'float32');                         %Distractor = 0, Target = 1;
                            fwrite(fid, find(j == 'HMFC'), 'float32');             	%Outcome.
                            for k = a'
                                fwrite(fid, -1, 'float32');             %New sweep indicator.
                                spikes = [];                            %Make a matrix to hold spike times.
                                for n = 1:25                            %Step through the possible number of spike counts.
                                    b = find(sound(i).comp(2).psth(k,:) == n);          %Check the PSTH for bins with this many spikes.
                                    for m = b                           %Step through each bin.
                                        spikes = [spikes; repmat(m-0.5,n,1)];     %Add the correct number of spike times, in whole milliseconds, to the list.
                                    end
                                end
                                spikes = sort(spikes);                  %Sort the spike times into chronological order.
                                fwrite(fid,spikes,'float32');           %Write the spike times to the *.f32 file.
                            end
                        end
                    end
                end

                fclose(fid);        %Close the *.f32 file.

            end
        end
    end
end