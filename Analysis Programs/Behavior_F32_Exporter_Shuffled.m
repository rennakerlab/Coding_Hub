function Behavior_F32_Exporter_Shuffled

% mainpath = 'Y:\Attention Study\Spike MAT Files\';                           %Set the folder containing the spike *.mat files.
mainpath = 'C:\Documents and Settings\ams091000\Desktop\Attention Study\Spike MAT Files\';
files = dir([mainpath '*spikes.mat']);                                      %Grab all the spike *.mat files in the folder.
for f = 1:length(files)                                                     %Step through each of the *.mat files.
    files(f).fullpath = [mainpath files(f).name];                           %Add the main path name to the file name.
end
warning off MATLAB:MKDIR:DirectoryExists;                                   %Turn off the "directory already exists" warning for the mkdir function.

% destpath = 'Y:\Attention Study\EZClassifier Files\';                        %Set the path where EZClassifier files will go.
destpath = 'C:\Documents and Settings\ams091000\Desktop\Attention Study\Shuffled EZClassifier Files\';   %Set the path where EZClassifier files will go.

for f = length(files):-1:1                                                    %Step through each of the spike *.mat files.
    load(files(f).fullpath);                                                %Load the spike data.
    rootfile = files(f).name(1:length(files(f).name)-11);                   %Find the root file name in the data file.
    mkdir([destpath rootfile]);                                             %Make a folder to hold the EZClassifier files for this session.
    
    for c = data.channels'                                                  %Step through each channel in the session.
        
%% BDT ************************************************************************************************************************************************
        if any([data.psych(:).stage] < 13)                                  %If the rat was run on a discrete tone target stage in this session.
            vscore = mean(data.driven.manual.behavN(c == data.channels,:)); %Grab the mean users' ratings for drivenness.
            snr = 1000000*range(data.templates(c == data.channels,:));      %Grab the peak-to-peak amplitude of the spike template.
            if data.hooded                                                  %If this is a hooded rat...
                isi = 400;                                                  %Adjust the timing for 400 ms ISIs.
            else                                                            %If this an albino rat...
                isi = 300;                                                  %Adjust the timing for 300 ms ISIs.
            end
            N = 0;                                                          %Make a variable to count the number of PSTH sweeps we'll collect.
            numchannels = 0;                                                %Find the number of channels that should be listed for each sweep.
            for i = 1:length(data.bdt)                                      %Step through the BDT recordings.
                if data.psych(i).stage < 13                                 %If these recordings come from a discrete tone target stage.
                    for j = 1:length(data.bdt(i).sweep)                     %Step through by sweep.
                        if any(data.bdt(i).sweep(j).channel == c)           %If there's a trace for this channel...
                            numchannels = max([numchannels,...
                                length(data.bdt(i).sweep(j).channel)]);     %Update the number of channels that should be listed in each sweep.
                            t = data.bdt(i).sweep(j).trial;                 %Grab the trial number for this sweep.
                            if data.psych(i).duration(t) == 200             %If this trial used a 200 ms tone.
                                if data.bdt(i).sweep(j).spont_delay < 50    %If the spontaneous delay for this trial is less than 50 ms...
                                    minhold = isi/1000;                     %Start grabbing PSTHs from the end of the first ISI.
                                else                                        %Otherwise, if the spontaneous delay for this trial is 50 ms or greater...
                                    minhold = 0;                            %Start grabbing PSTHs from the start of recordings.
                                end
                                for s = data.bdt(i).sweep(j).spont_delay...
                                        + uint16(1000*minhold:isi:...
                                        1000*data.psych(i).hold_time(t)+50) - 49	%Step through each tone up to the first target tone.
                                    N = N + 1;                              %Add one to the sweep count for each tone.
                                end
                            end
                        end
                    end
                end
            end
            psths = nan(N,isi);                                             %Pre-allocate a matrix to hold PSTHs.
            params = nan(N,14);                                             %Pre-allocate a matrix to stimulus paramters.
            N = 0;                                                          %Keep track of the current row in the PSTH matrix.
            for i = 1:length(data.bdt)                                      %Step through the recording blocks.       
                if data.psych(i).stage < 13                                 %If these recordings come from a discrete tone target stage...
                    if N == 0                                               %If we haven't grabbed any PSTHs yet...
                        trial_offset = 0;                                   %Don't add any offset to the trial numbers.
                    else                                                    %Otherwise...
                        trial_offset = trial_offset + ...
                            length(data.psych(i-1).clock_reading);          %Add the previous trial count to the new trial numbers to prevent overlap.
                    end
                    for j = 1:length(data.bdt(i).sweep)                     %Step through by sweep.
                        k = find(data.bdt(i).sweep(j).channel == c);        %Check to see if a trace exists for this channel.
                        if ~isempty(k) && ...
                                length(data.bdt(i).sweep(j).channel) == numchannels                     %If there's a trace for this channel and all channels in the list.
                            t = data.bdt(i).sweep(j).trial;                                             %Grab the trial number for this sweep.
                            if data.psych(i).duration(t) == 200                                         %If this trial used a 200 ms tone.
                                if data.bdt(i).sweep(j).spont_delay < 50                                %If the spontaneous delay for this trial is less than 50 ms...
                                    tone_number_offset = 1;                                             %Skip grabbing the PSTH for the first tone.
                                    minhold = isi/1000;                                                 %Start grabbing PSTHs from the end of the first ISI.
                                else                                                                    %Otherwise, if the spontaneous delay for this trial is 50 ms or greater...
                                    tone_number_offset = 0;                                             %Grab the PSTH for the first tone.
                                    minhold = 0;                                                        %Start grabbing PSTHs from the start of recordings.
                                end                                
                                tone_num = data.bdt(i).sweep(j).spont_delay + ...
                                    uint16(1000*minhold:isi:1000*data.psych(i).hold_time(t)+50)...
                                    - 49;                                                               %Grab the sweep start times for all the tones.
                                for s = tone_num                                                        %Step through each tone.
                                    N = N + 1;                                                          %Add one to the overall sweep counter.
                                    psths(N,:) = data.bdt(i).sweep(j).psth(k,s:(s+isi-1));              %Add the psth to the matrix.
                                    params(N,2) = data.psych(i).ref_freq(t);                            %Add the tone frequency to the parameters list.
                                    params(N,3:4) = 0;                                                  %Assume this row is a 0% reference tone.
                                    params(N,5) = find(s == tone_num) + tone_number_offset;             %Save the tone number.  
                                    params(N,6) = 4;                                                    %Assume the rat didn't react to the reference tone (4 = CR).
                                    params(N,9) = length(tone_num) + tone_number_offset;                %Save the total number of tones in this train.
                                    params(N,10) = trial_offset + t;                                    %Save the trial number.
                                    params(N,11) = 0;                                                   %Save the nosepoke response time.
                                    params(N,12) = data.psych(i).ref_freq(t);                           %Save the reference frequency for the trial.
                                    params(N,13) = find(data.psych(i).outcome(t) == 'HMFC');            %Save the outcome for the trial.
                                    params(N,14) = data.psych(i).stage;                                 %Save the stage number for this recording.
                                end
                                if ~isempty(tone_num)                                                   %If there was at least one tone added from this sequence...
                                    params(N,2) = data.psych(i).tar_freq(t);                            %Switch the tone frequency to the target value.
                                    params(N,3) = data.psych(i).delta_f(t);                             %Switch the delta-f to the target value.
                                    params(N,4) = 1;                                                    %Mark this sweep as a target tone.
                                    params(N,6) = find(data.psych(i).outcome(t) == 'HMFC');             %Mark this sweep with it's real outcome.
                                    if any(data.psych(i).outcome(t) == 'HF')                            %If the trial resulted in a hit or false alarm...
                                        params(N,11) = data.psych(i).nosepoke_response(t);              %Save the nosepoke response time.
                                    end
                                end
                            end
                        end
                    end
                end
            end
            params(:,1) = 100;                                              %Save the parameter set number for this collection of parameters.
            psths(isnan(params(:,2)),:) = [];                               %Pare any NaNs out of the PSTHs matrix.
            params(isnan(params(:,2)),:) = [];                              %Pare any NaNs out of the parameters matrix.
            params(:,7) = vscore;                                           %Save the voter score for this unit.
            params(:,8) = snr;                                              %Save the average spike magnitude (in uV).            

            s = unique(params(params(:,5) >= 3,[2,6]),'rows')';             %Find all the unique combinations of tone frequency and outcome.
            for i = s                                                       %Step through all the unique combinations...
                a = find(params(:,5) >= 3 & params(:,2) == i(1) & ...
                    params(:,6) == i(2))';                                  %Find all the sweeps with this combination of frequency and outcome.
                temp = psths(a,:);                                          %Grab all the PSTHs for these sweeps.
                temp = temp(randperm(size(temp,1)),:);                      %Randomize the sweeps for this combination.
                for j = a                                                   %Step through each of the sweeps for this combination.
                    psths(j,:) = temp(j==a,:);                              %Replace the sweep with the randomized sweep.
                end
            end                              
            
            f32filename = ['E' num2str(10*c,'%03d') '_EZClassifier_BDT_'...
                rootfile '.f32'];                                           %Make a filename for the new *.f32 file.
            if ~isempty(psths)                                              %If there's any sweeps for this channels.
                disp(['Writing: ' f32filename]);                            %Show the user the filename of the new EZClassifier file.
                fid = fopen([destpath rootfile '\' f32filename],'w');       %Open the *.f32 file for writing.
                numparams = size(params,2);                                 %Grab the number of parameters.
                for i = 1:size(params,1)                                    %Step through each sweep.
                    fwrite(fid, -2, 'float32');                             %New dataset indicator.
                    fwrite(fid, isi, 'float32');                            %Sweeplength (in milliseconds).
                    fwrite(fid, numparams, 'float32');                      %Write how many parameters will follow.
                    for j = 1:numparams                                     %Step through each parameter for this sweep.
                        fwrite(fid, params(i,j), 'float32');                %Write the parameter values.
                    end
                    fwrite(fid, -1, 'float32');                             %New sweep indicator.
                    spikes = [];                                            %Make a matrix to hold spike times.
                    for n = 1:25                                            %Step through the possible number of spike counts.
                        b = find(psths(i,:) == n);                          %Check the PSTH for bins with this many spikes.
                        for k = b                                           %Step through each bin.
                            spikes = [spikes; repmat(k-0.5,n,1)];           %Add the correct number of spike times, in whole milliseconds, to the list.
                        end
                    end
                    spikes = sort(spikes);                                  %Sort the spike times into chronological order.
                    fwrite(fid,spikes,'float32');                           %Write the spike times to the *.f32 file.
                end
                fclose(fid);                                                %Close the *.f32 file.
            end
        end

        
%% BBN ************************************************************************************************************************************************
        if any([data.psych(:).stage] == 13)                                 %If the rat was run on a broadband noise target stage in this session.
            vscore = mean(data.driven.manual.behavN(c == data.channels,:)); %Grab the mean users' ratings for drivenness.
            snr = 1000000*range(data.templates(c == data.channels,:));      %Grab the peak-to-peak amplitude of the spike template.
            if data.hooded                                                  %If this is a hooded rat...
                isi = 400;                                                  %Adjust the timing for 400 ms ISIs.
            else                                                            %If this an albino rat...
                isi = 300;                                                  %Adjust the timing for 300 ms ISIs.
            end
            N = 0;                                                          %Make a variable to count the number of PSTH sweeps we'll collect.
            numchannels = 0;                                                %Find the number of channels that should be listed for each sweep.
            for i = 1:length(data.bdt)                                      %Step through the BDT recordings.
                if data.psych(i).stage == 13                                %If these recordings come from a broadband noise target stage.
                    for j = 1:length(data.bdt(i).sweep)                     %Step through by sweep.
                        if any(data.bdt(i).sweep(j).channel == c)           %If there's a trace for this channel...
                            numchannels = max([numchannels,...
                                length(data.bdt(i).sweep(j).channel)]);     %Update the number of channels that should be listed in each sweep.
                            t = data.bdt(i).sweep(j).trial;                 %Grab the trial number for this sweep.
                            if data.psych(i).duration(t) == 200             %If this trial used a 200 ms tone.
                                if data.bdt(i).sweep(j).spont_delay < 50    %If the spontaneous delay for this trial is less than 50 ms...
                                    minhold = isi/1000;                     %Start grabbing PSTHs from the end of the first ISI.
                                else                                        %Otherwise, if the spontaneous delay for this trial is 50 ms or greater...
                                    minhold = 0;                            %Start grabbing PSTHs from the start of recordings.
                                end
                                for s = data.bdt(i).sweep(j).spont_delay...
                                        + uint16(1000*minhold:isi:...
                                        1000*data.psych(i).hold_time(t)+50) - 49  %Step through each tone up to the first target tone.
                                    N = N + 1;                              %Add one to the sweep count for each tone.
                                end
                            end
                        end
                    end
                end
            end
            psths = nan(N,isi);                                             %Pre-allocate a matrix to hold PSTHs.
            params = nan(N,14);                                             %Pre-allocate a matrix to stimulus paramters.
            N = 0;                                                          %Keep track of the current row in the PSTH matrix.
            for i = 1:length(data.bdt)                                      %Step through the recording blocks.       
                if data.psych(i).stage == 13                                %If these recordings come from a broadband noise target stage...
                    if N == 0                                               %If we haven't grabbed any PSTHs yet...
                        trial_offset = 0;                                   %Don't add any offset to the trial numbers.
                    else                                                    %Otherwise...
                        trial_offset = trial_offset + ...
                            length(data.psych(i-1).clock_reading);          %Add the previous trial count to the new trial numbers to prevent overlap.
                    end
                    for j = 1:length(data.bdt(i).sweep)                     %Step through by sweep.
                        k = find(data.bdt(i).sweep(j).channel == c);        %Check to see if a trace exists for this channel.
                        if ~isempty(k) && ...
                                length(data.bdt(i).sweep(j).channel) == numchannels                     %If there's a trace for this channel and all channels in the list.
                            t = data.bdt(i).sweep(j).trial;                                             %Grab the trial number for this sweep.
                            if data.psych(i).duration(t) == 200                                         %If this trial used a 200 ms tone.
                                if data.bdt(i).sweep(j).spont_delay < 50                                %If the spontaneous delay for this trial is less than 50 ms...
                                    tone_number_offset = 1;                                             %Skip grabbing the PSTH for the first tone.
                                    minhold = isi/1000;                                                 %Start grabbing PSTHs from the end of the first ISI.
                                else                                                                    %Otherwise, if the spontaneous delay for this trial is 50 ms or greater...
                                    tone_number_offset = 0;                                             %Grab the PSTH for the first tone.
                                    minhold = 0;                                                        %Start grabbing PSTHs from the start of recordings.
                                end                                
                                tone_num = data.bdt(i).sweep(j).spont_delay + ...
                                    uint16(1000*minhold:isi:1000*data.psych(i).hold_time(t)+50)...
                                    - 49;                                                               %Grab the sweep start times for all the tones.
                                for s = tone_num                                                        %Step through each tone.
                                    N = N + 1;                                                          %Add one to the overall sweep counter.
                                    psths(N,:) = data.bdt(i).sweep(j).psth(k,s:(s+isi-1));              %Add the psth to the matrix.
                                    params(N,2) = data.psych(i).ref_freq(t);                            %Add the tone frequency to the parameters list.
                                    params(N,3:4) = 0;                                                  %Assume this row is a 0% reference tone.
                                    params(N,5) = find(s == tone_num) + tone_number_offset;             %Save the tone number.  
                                    params(N,6) = 4;                                                    %Assume the rat didn't react to the reference tone (4 = CR).
                                    params(N,9) = length(tone_num) + tone_number_offset;                %Save the total number of tones in this train.
                                    params(N,10) = trial_offset + t;                                    %Save the trial number.
                                    params(N,11) = 0;                                                   %Save the nosepoke response time.
                                    params(N,12) = data.psych(i).ref_freq(t);                           %Save the reference frequency for the trial.
                                    params(N,13) = find(data.psych(i).outcome(t) == 'HMFC');            %Save the outcome for the trial.
                                    params(N,14) = data.psych(i).stage;                                 %Save the stage number for this recording.
                                end
                                if ~isempty(tone_num)                                                   %If there was at least one tone added from this sequence...
                                    params(N,2) = 0;                                                    %Mark the tone frequency as zero.
                                    params(N,3) = 1000;                                                 %Mark the delta-f with a huge value.
                                    params(N,4) = 1;                                                    %Mark this sweep as a target tone.
                                    params(N,6) = find(data.psych(i).outcome(t) == 'HMFC');             %Mark this sweep with it's real outcome.
                                    if any(data.psych(i).outcome(t) == 'HF')                            %If the trial resulted in a hit or false alarm...
                                        params(N,11) = data.psych(i).nosepoke_response(t);              %Save the nosepoke response time.
                                    end
                                end
                            end
                        end
                    end
                end
            end
            params(:,1) = 100;                                              %Save the parameter set number for this collection of parameters.
            psths(isnan(params(:,2)),:) = [];                               %Pare any NaNs out of the PSTHs matrix.
            params(isnan(params(:,2)),:) = [];                              %Pare any NaNs out of the parameters matrix.
            params(:,7) = vscore;                                           %Save the voter score for this unit.
            params(:,8) = snr;                                              %Save the average spike magnitude (in uV).          
            
            s = unique(params(params(:,5) >= 3,[2,6]),'rows')';             %Find all the unique combinations of tone frequency and outcome.
            for i = s                                                       %Step through all the unique combinations...
                a = find(params(:,5) >= 3 & params(:,2) == i(1) & ...
                    params(:,6) == i(2))';                                  %Find all the sweeps with this combination of frequency and outcome.
                temp = psths(a,:);                                          %Grab all the PSTHs for these sweeps.
                temp = temp(randperm(size(temp,1)),:);                      %Randomize the sweeps for this combination.
                for j = a                                                   %Step through each of the sweeps for this combination.
                    psths(j,:) = temp(j==a,:);                              %Replace the sweep with the randomized sweep.
                end
            end        

            f32filename = ['E' num2str(10*c,'%03d') '_EZClassifier_BBN_'...
                rootfile '.f32'];                                           %Make a filename for the new *.f32 file.
            if ~isempty(psths)                                              %If there's any sweeps for this channels.
                disp(['Writing: ' f32filename]);                            %Show the user the filename of the new EZClassifier file.
                fid = fopen([destpath rootfile '\' f32filename],'w');   %Open the *.f32 file for writing.
                numparams = size(params,2);                                 %Grab the number of parameters.
                for i = 1:size(params,1)                                    %Step through each sweep.
                    fwrite(fid, -2, 'float32');                             %New dataset indicator.
                    fwrite(fid, isi, 'float32');                            %Sweeplength (in milliseconds).
                    fwrite(fid, numparams, 'float32');                      %Write how many parameters will follow.
                    for j = 1:numparams                                     %Step through each parameter for this sweep.
                        fwrite(fid, params(i,j), 'float32');                %Write the parameter values.
                    end
                    fwrite(fid, -1, 'float32');                             %New sweep indicator.
                    spikes = [];                                            %Make a matrix to hold spike times.
                    for n = 1:25                                            %Step through the possible number of spike counts.
                        b = find(psths(i,:) == n);                          %Check the PSTH for bins with this many spikes.
                        for k = b                                           %Step through each bin.
                            spikes = [spikes; repmat(k-0.5,n,1)];           %Add the correct number of spike times, in whole milliseconds, to the list.
                        end
                    end
                    spikes = sort(spikes);                                  %Sort the spike times into chronological order.
                    fwrite(fid,spikes,'float32');                           %Write the spike times to the *.f32 file.
                end
                fclose(fid);                                                %Close the *.f32 file.
            end
        end
        

%% BMS ************************************************************************************************************************************************
        if any([data.psych(:).stage] == 14)                                 %If the rat was run on a pseudo target stage in this session.
            vscore = mean(data.driven.manual.behavN(c == data.channels,:)); %Grab the mean users' ratings for drivenness.
            snr = 1000000*range(data.templates(c == data.channels,:));      %Grab the peak-to-peak amplitude of the spike template.
            minhold = 0;                                                    %Start grabbing PSTHs from the start of recordings.
            tone_number_offset = 0;                                         %Grab the PSTH for the first tone.
            if data.hooded                                                  %If this is a hooded rat...
                isi = 400;                                                  %Adjust the timing for 400 ms ISIs.
            else                                                            %If this an albino rat...
                isi = 300;                                                  %Adjust the timing for 300 ms ISIs.
            end
            N = 0;                                                          %Make a variable to count the number of PSTH sweeps we'll collect.
            numchannels = 0;                                                %Find the number of channels that should be listed for each sweep.
            for i = 1:length(data.bdt)                                      %Step through the BDT recordings.
                if data.psych(i).stage == 14                                %If these recordings come from a pseudo target stage.
                    for j = 1:length(data.bdt(i).sweep)                     %Step through by sweep.
                        if any(data.bdt(i).sweep(j).channel == c)           %If there's a trace for this channel...
                            numchannels = max([numchannels,...
                                length(data.bdt(i).sweep(j).channel)]);     %Update the number of channels that should be listed in each sweep.
                            t = data.bdt(i).sweep(j).trial;                 %Grab the trial number for this sweep.
                            if data.psych(i).duration(t) == 200             %If this trial used a 200 ms tone.
                                for s = 200 - 49 + uint16(1000*minhold:isi:...
                                        1000*data.psych(i).trans_time(t)+50)    %Step through each tone up to the first target tone.
                                    N = N + 1;                              %Add one to the sweep count for each tone.
                                end
                            end
                        end
                    end
                end
            end
            psths = nan(N,isi);                                             %Pre-allocate a matrix to hold PSTHs.
            params = nan(N,14);                                             %Pre-allocate a matrix to stimulus paramters.
            N = 0;                                                          %Keep track of the current row in the PSTH matrix.
            for i = 1:length(data.bdt)                                      %Step through the recording blocks.       
                if data.psych(i).stage == 14                                %If these recordings come from a pseudo target stage...
                    if N == 0                                               %If we haven't grabbed any PSTHs yet...
                        trial_offset = 0;                                   %Don't add any offset to the trial numbers.
                    else                                                    %Otherwise...
                        trial_offset = trial_offset + ...
                            length(data.psych(i-1).clock_reading);          %Add the previous trial count to the new trial numbers to prevent overlap.
                    end
                    for j = 1:length(data.bdt(i).sweep)                     %Step through by sweep.
                        k = find(data.bdt(i).sweep(j).channel == c);        %Check to see if a trace exists for this channel.
                        if ~isempty(k) && ...
                                length(data.bdt(i).sweep(j).channel) == numchannels                     %If there's a trace for this channel and all channels in the list.
                            t = data.bdt(i).sweep(j).trial;                                             %Grab the trial number for this sweep.
                            if data.psych(i).duration(t) == 200                                         %If this trial used a 200 ms tone.                            
                                tone_num = 200 - 49 + ...
                                    uint16(1000*minhold:isi:1000*data.psych(i).trans_time(t)+50);       %Grab the sweep start times for all the tones.
                                for s = tone_num                                                        %Step through each tone.
                                    N = N + 1;                                                          %Add one to the overall sweep counter.
                                    psths(N,:) = data.bdt(i).sweep(j).psth(k,s:(s+isi-1));              %Add the psth to the matrix.
                                    params(N,2) = data.psych(i).ref_freq(t);                            %Add the tone frequency to the parameters list.
                                    params(N,3:4) = 0;                                                  %Assume this row is a 0% reference tone.
                                    params(N,5) = find(s == tone_num) + tone_number_offset;             %Save the tone number.  
                                    params(N,6) = 4;                                                    %Mark all trials as correct rejections (4 = CR).
                                    params(N,9) = length(tone_num) + tone_number_offset;                %Save the total number of tones in this train.
                                    params(N,10) = trial_offset + t;                                    %Save the trial number.
                                    params(N,11) = 0;                                                   %Save the nosepoke response time.
                                    params(N,12) = data.psych(i).ref_freq(t);                           %Save the reference frequency for the trial.
                                    params(N,13) = find(data.psych(i).outcome(t) == 'HMFC');            %Save the outcome for the trial.
                                    params(N,14) = data.psych(i).stage;                                 %Save the stage number for this recording.
                                end
                                if ~isempty(tone_num)                                                   %If there was at least one tone added from this sequence...
                                    params(N,2) = data.psych(i).tar_freq(t);                            %Switch the tone frequency to the target value.
                                    params(N,3) = data.psych(i).delta_f(t);                             %Switch the delta-f to the target value.
                                    params(N,4) = 1;                                                    %Mark this sweep as a target tone.
                                    if any(data.psych(i).outcome(t) == 'HF')                            %If the trial resulted in a hit or false alarm...
                                        params(N,11) = data.psych(i).nosepoke_response(t);              %Save the nosepoke response time.
                                    end
                                end
                            end
                        end
                    end
                end
            end
            params(:,1) = 100;                                              %Save the parameter set number for this collection of parameters.
            psths(isnan(params(:,2)),:) = [];                               %Pare any NaNs out of the PSTHs matrix.
            params(isnan(params(:,2)),:) = [];                              %Pare any NaNs out of the parameters matrix.
            params(:,7) = vscore;                                           %Save the voter score for this unit.
            params(:,8) = snr;                                              %Save the average spike magnitude (in uV).          
            
            s = unique(params(params(:,5) >= 3,[2,6]),'rows')';             %Find all the unique combinations of tone frequency and outcome.
            for i = s                                                       %Step through all the unique combinations...
                a = find(params(:,5) >= 3 & params(:,2) == i(1) & ...
                    params(:,6) == i(2))';                                  %Find all the sweeps with this combination of frequency and outcome.
                temp = psths(a,:);                                          %Grab all the PSTHs for these sweeps.
                temp = temp(randperm(size(temp,1)),:);                      %Randomize the sweeps for this combination.
                for j = a                                                   %Step through each of the sweeps for this combination.
                    psths(j,:) = temp(j==a,:);                              %Replace the sweep with the randomized sweep.
                end
            end        

            f32filename = ['E' num2str(10*c,'%03d') '_EZClassifier_BMS_'...
                rootfile '.f32'];                                           %Make a filename for the new *.f32 file.
            if ~isempty(psths)                                              %If there's any sweeps for this channels.
                disp(['Writing: ' f32filename]);                            %Show the user the filename of the new EZClassifier file.
                fid = fopen([destpath rootfile '\' f32filename],'w');   %Open the *.f32 file for writing.
                numparams = size(params,2);                                 %Grab the number of parameters.
                for i = 1:size(params,1)                                    %Step through each sweep.
                    fwrite(fid, -2, 'float32');                             %New dataset indicator.
                    fwrite(fid, isi, 'float32');                            %Sweeplength (in milliseconds).
                    fwrite(fid, numparams, 'float32');                      %Write how many parameters will follow.
                    for j = 1:numparams                                     %Step through each parameter for this sweep.
                        fwrite(fid, params(i,j), 'float32');                %Write the parameter values.
                    end
                    fwrite(fid, -1, 'float32');                             %New sweep indicator.
                    spikes = [];                                            %Make a matrix to hold spike times.
                    for n = 1:25                                            %Step through the possible number of spike counts.
                        b = find(psths(i,:) == n);                          %Check the PSTH for bins with this many spikes.
                        for k = b                                           %Step through each bin.
                            spikes = [spikes; repmat(k-0.5,n,1)];           %Add the correct number of spike times, in whole milliseconds, to the list.
                        end
                    end
                    spikes = sort(spikes);                                  %Sort the spike times into chronological order.
                    fwrite(fid,spikes,'float32');                           %Write the spike times to the *.f32 file.
                end
                fclose(fid);                                                %Close the *.f32 file.
            end
        end
        
        
%% PDT ************************************************************************************************************************************************
        if isfield(data,'pdt')                                              %If there's PDT data for this session.
        	vscore = mean(data.driven.manual.pdtN(c == data.channels,:));   %Check the users' ratings for drivenness.
            snr = 1000000*range(data.templates(c == data.channels,:));      %Grab the peak-to-peak amplitude of the spike template.
            if data.hooded                                                  %If this is a hooded rat...
                isi = 400;                                                  %Adjust the timing for 400 ms ISIs.
            else                                                            %If this an albino rat...
                isi = 300;                                                  %Adjust the timing for 300 ms ISIs.
            end
            N = 0;                                                          %Make a variable to count the number of PSTH sweeps we'll collect.
            numchannels = [];                                               %Find the number of channels that should be listed for each sweep.
            if isfield(data,'pdt')                                          %If there's any PDT recordings...
                for i = 1:length(data.pdt)                                  %Step through the PDT recordings.
                    a = find(data.pdt(i).channel == c);                     %Find the index corresponding to this channel.
                    b = [];                                                 %Create a temporary matrix to hold the minimum number of sweeps per channel. 
                    if ~isempty(a)                                          %If we have neural recordings for this channel...
                        for j = 1:length(data.pdt(i).unit)                  %Step through each unit.
                            for k = 1:length(data.pdt(i).unit(j).sweep)     %Step through each stimulus.
                                b(j,k) = size(data.pdt(i).unit(j).sweep(k).psth,1);     %Save the number of sweeps for this unit and stimulus.
                            end
                        end
                        numchannels{i} = min(b,[],1);                                   %Save the number of sweeps to grab for each stimulus.
                        temp = length(data.pdt(i).unit(a).sweep);                       %Find the number of sweeps.
                        temp(2) = size(data.pdt(i).unit(a).sweep(1).psth,1);            %Find the number of repeats.
                        temp(3) = length(int16(data.pdt(i).spont_delay) - 49 + ...
                            int16(0:isi:data.pdt(i).ref_len));              %Find the number of references within a sequence.
                        N = N + temp(1)*temp(2)*temp(3);                    %Add up all the repeats of the reference frequency.
                    end
                end
            end
            psths = nan(N,isi);                                             %Pre-allocate a matrix to hold PSTHs.
            params = nan(N,14);                                             %Pre-allocate a matrix to hold reference frequency.
            N = 0;                                                          %Keep track of the current row in the PSTH matrix.
            sweep = 0;                                                      %Keep track of the sweep number to write it as a "trial" number.
            for i = 1:length(data.pdt)                                      %Step through the PDT recordings.
                if data.pdt(i).tone_dur == 200                              %Check to see if the tone duration is 200 ms.
                    k = find(data.pdt(i).channel == c);                     %Check to see if a psth exists for this channel.
                    if ~isempty(k)                                          %If a psth does exist for this channel...
                        for j = 1:length(data.pdt(i).unit(k).sweep)         %Step through each sweep.
                            tone_num = int16(data.pdt(i).spont_delay) - ...
                                49 + int16(0:isi:data.pdt(i).ref_len);      %Grab the sweep start times for all the tones.
                            for s = tone_num                                %Step through each reference tone.
                                temp = N + numchannels{i}(j);               %Keep track of the current row in the matrix.
                                psths(N+1:temp,:) = ...
                                    data.pdt(i).unit(k).sweep(j).psth(1:numchannels{i}(j),s:(s+isi-1));     %Add the psth to the matrix.
                                if s ~= max(tone_num)                                                       %If this isn't the last tone of the sequence...
                                    params(N+1:temp,2) = data.pdt(i).ref_freqs(j);                         	%Add the tone frequency to the frequency list.
                                    params(N+1:temp,3) = 0;                                                 %The delta f for reference tones is zero.
                                    params(N+1:temp,4) = 0;                                                 %Mark the reference tones.
                                    params(N+1:temp,12) = data.pdt(i).ref_freqs(j);                         %Add the tone frequency to the frequency list.
                                else                                                                        %Otherwise, if this is the last tone of the sequence...
                                    params(N+1:temp,2) = data.pdt(i).tar_freqs(j);                        	%Add the tone frequency to the frequency list.
                                    params(N+1:temp,3) = data.pdt(i).delta_f(j);                           	%Save the delta-f for target tones.
                                    params(N+1:temp,4) = 1;                                                	%Mark the target tones.
                                    params(N+1:temp,12) = data.pdt(i).ref_freqs(j);                         %Add the tone frequency to the frequency list.
                                end
                                params(N+1:temp,5) = find(s == tone_num);                                   %Save the tone number in the sequence.
                                params(N+1:temp,9) = length(tone_num);                                      %Save the total number of tones.
                                params(N+1:temp,10) = sweep + (1:numchannels{i}(j))';                       %Save total number of tones.
                                N = N + numchannels{i}(j);                                                  %Advance the row tracker.
                            end
                            sweep = nanmax(params(:,10));                   %Advance the sweep counter.
                        end
                    end
                end
            end
            params(:,1) = 100;                                              %Save the parameter set number for this collection of parameters.
            psths(isnan(params(:,2)),:) = [];                               %Pare any NaNs out of the PSTHs matrix.
            params(isnan(params(:,2)),:) = [];                              %Pare any NaNs out of the parameters matrix.
            params(:,6) = 0;                                                %Put a zero in to indicate no behavioral response.
            params(:,7) = vscore;                                           %Save the voter score for this unit.
            params(:,8) = snr;                                              %Save the average spike magnitude (in uV).
            params(:,11) = 0;                                               %Save the average spike magnitude (in uV).
            params(:,13) = 0;                                               %Put a zero in column 13 to indicate no behavioral response.
            params(:,14) = 0;                                               %Put a zero in column 14 to indicate there's no behavioral stage.

            s = unique(params(params(:,5) >= 3,[2,6]),'rows')';             %Find all the unique combinations of tone frequency and outcome.
            for i = s                                                       %Step through all the unique combinations...
                a = find(params(:,5) >= 3 & params(:,2) == i(1) & ...
                    params(:,6) == i(2))';                                  %Find all the sweeps with this combination of frequency and outcome.
                temp = psths(a,:);                                          %Grab all the PSTHs for these sweeps.
                temp = temp(randperm(size(temp,1)),:);                      %Randomize the sweeps for this combination.
                for j = a                                                   %Step through each of the sweeps for this combination.
                    psths(j,:) = temp(j==a,:);                              %Replace the sweep with the randomized sweep.
                end
            end        
            
            f32filename = ['E' num2str(10*c,'%03d') '_EZClassifier_PDT_'...
                rootfile '.f32'];                                           %Make a filename for the new *.f32 file.
            if ~isempty(psths)                                              %If there's any sweeps for this channels.
                disp(['Writing: ' f32filename]);                            %Show the user the filename of the new EZClassifier file.
                fid = fopen([destpath rootfile '\' f32filename],'w');   %Open the *.f32 file for writing.
                numparams = size(params,2);                                 %Grab the number of parameters.
                for i = 1:size(params,1)                                    %Step through each sweep.
                    fwrite(fid, -2, 'float32');                             %New dataset indicator.
                    fwrite(fid, isi, 'float32');                            %Sweeplength (in milliseconds).
                    fwrite(fid, numparams, 'float32');                      %Write how many parameters will follow.
                    for j = 1:numparams                                     %Step through each parameter for this sweep.
                        fwrite(fid, params(i,j), 'float32');                %Write the parameter values.
                    end
                    fwrite(fid, -1, 'float32');                             %New sweep indicator.
                    spikes = [];                                            %Make a matrix to hold spike times.
                    for n = 1:25                                            %Step through the possible number of spike counts.
                        b = find(psths(i,:) == n);                          %Check the PSTH for bins with this many spikes.
                        for k = b                                           %Step through each bin.
                            spikes = [spikes; repmat(k-0.5,n,1)];           %Add the correct number of spike times, in whole milliseconds, to the list.
                        end
                    end
                    spikes = sort(spikes);                                  %Sort the spike times into chronological order.
                    fwrite(fid,spikes,'float32');                           %Write the spike times to the *.f32 file.
                end
                fclose(fid);                                                %Close the *.f32 file.
            end
        end
        

%% PBN ************************************************************************************************************************************************
        if isfield(data,'pbn')                                              %If there's PBN data for this session.
        	vscore = mean(data.driven.manual.pdtN(c == data.channels,:));   %Check the users' ratings for drivenness.
            snr = 1000000*range(data.templates(c == data.channels,:));      %Grab the peak-to-peak amplitude of the spike template.
            if data.hooded                                                  %If this is a hooded rat...
                isi = 400;                                                  %Adjust the timing for 400 ms ISIs.
            else                                                            %If this an albino rat...
                isi = 300;                                                  %Adjust the timing for 300 ms ISIs.
            end
            N = 0;                                                          %Make a variable to count the number of PSTH sweeps we'll collect.
            numchannels = [];                                               %Find the number of channels that should be listed for each sweep.
            if isfield(data,'pbn')                                          %If there's any PBN recordings...
                for i = 1:length(data.pbn)                                  %Step through the PBN recordings.
                    a = find(data.pbn(i).channel == c);                     %Find the index corresponding to this channel.
                    b = zeros(length(data.pbn(i).unit),...
                        length(data.pbn(i).unit(1).sweep));                 %Pre-allocate a temporary matrix to hold the minimum number of sweeps per channel. 
                    if ~isempty(a)                                          %If we have neural recordings for this channel...
                        for j = 1:length(data.pbn(i).unit)                  %Step through each unit.
                            for k = 1:length(data.pbn(i).unit(j).sweep)     %Step through each stimulus.
                                b(j,k) = size(data.pbn(i).unit(j).sweep(k).psth,1);     %Save the number of sweeps for this unit and stimulus.
                            end
                        end
                        numchannels{i} = min(b,[],1);                                   %Save the number of sweeps to grab for each stimulus.
                        temp = length(data.pbn(i).unit(a).sweep);                       %Find the number of sweeps.
                        temp(2) = size(data.pbn(i).unit(a).sweep(1).psth,1);            %Find the number of repeats.
                        temp(3) = length(int16(data.pbn(i).spont_delay) - 49 + ...
                            int16(0:isi:data.pbn(i).ref_len));              %Find the number of references within a sequence.
                        N = N + temp(1)*temp(2)*temp(3);                    %Add up all the repeats of the reference frequency.
                    end
                end
            end
            psths = nan(N,isi);                                             %Pre-allocate a matrix to hold PSTHs.
            params = nan(N,14);                                             %Pre-allocate a matrix to hold reference frequency.
            N = 0;                                                          %Keep track of the current row in the PSTH matrix.
            sweep = 0;                                                      %Keep track of the sweep number to write it as a "trial" number.
            for i = 1:length(data.pbn)                                      %Step through the PBN recordings.
                if data.pbn(i).tone_dur == 200                              %Check to see if the tone duration is 200 ms.
                    k = find(data.pbn(i).channel == c);                     %Check to see if a psth exists for this channel.
                    if ~isempty(k)                                          %If a psth does exist for this channel...
                        for j = 1:length(data.pbn(i).unit(k).sweep)         %Step through each sweep.
                            tone_num = int16(data.pbn(i).spont_delay) - ...
                                49 + int16(0:isi:data.pbn(i).ref_len);      %Grab the sweep start times for all the tones.
                            for s = tone_num                                %Step through each reference tone.
                                temp = N + numchannels{i}(j);               %Keep track of the current row in the matrix.
                                psths(N+1:temp,:) = ...
                                    data.pbn(i).unit(k).sweep(j).psth(1:numchannels{i}(j),s:(s+isi-1));     %Add the psth to the matrix.
                                if s ~= max(tone_num)                                                       %If this isn't the last tone of the sequence...
                                    params(N+1:temp,2) = data.pbn(i).ref_freqs(j);                         	%Add the tone frequency to the frequency list.
                                    params(N+1:temp,3) = 0;                                                 %The delta f for reference tones is zero.
                                    params(N+1:temp,4) = 0;                                                 %Mark the reference tones.
                                    params(N+1:temp,12) = data.pbn(i).ref_freqs(j);                         %Add the tone frequency to the frequency list.
                                else                                                                        %Otherwise, if this is the last tone of the sequence...
                                    params(N+1:temp,2) = 0;                                                 %Add the tone frequency to the frequency list.
                                    params(N+1:temp,3) = 1000;                                              %Save the delta-f for target tones.
                                    params(N+1:temp,4) = 1;                                                	%Mark the target tones.
                                    params(N+1:temp,12) = data.pbn(i).ref_freqs(j);                         %Add the tone frequency to the frequency list.
                                end
                                params(N+1:temp,5) = find(s == tone_num);                                   %Save the tone number in the sequence.
                                params(N+1:temp,9) = length(tone_num);                                      %Save the total number of tones.
                                params(N+1:temp,10) = sweep + (1:numchannels{i}(j))';                       %Save total number of tones.
                                N = N + numchannels{i}(j);                                                  %Advance the row tracker.
                            end
                            sweep = nanmax(params(:,10));                   %Advance the sweep counter.
                        end
                    end
                end
            end
            params(:,1) = 100;                                              %Save the parameter set number for this collection of parameters.
            psths(isnan(params(:,2)),:) = [];                               %Pare any NaNs out of the PSTHs matrix.
            params(isnan(params(:,2)),:) = [];                              %Pare any NaNs out of the parameters matrix.
            params(:,6) = 0;                                                %Put a zero in to indicate no behavioral response.
            params(:,7) = vscore;                                           %Save the voter score for this unit.
            params(:,8) = snr;                                              %Save the average spike magnitude (in uV).
            params(:,11) = 0;                                               %Save the average spike magnitude (in uV).
            params(:,13) = 0;                                               %Put a zero in column 13 to indicate no behavioral response.
            params(:,14) = 0;                                               %Put a zero in column 14 to indicate there's no behavioral stage.

            s = unique(params(params(:,5) >= 3,[2,6]),'rows')';             %Find all the unique combinations of tone frequency and outcome.
            for i = s                                                       %Step through all the unique combinations...
                a = find(params(:,5) >= 3 & params(:,2) == i(1) & ...
                    params(:,6) == i(2))';                                  %Find all the sweeps with this combination of frequency and outcome.
                temp = psths(a,:);                                          %Grab all the PSTHs for these sweeps.
                temp = temp(randperm(size(temp,1)),:);                      %Randomize the sweeps for this combination.
                for j = a                                                   %Step through each of the sweeps for this combination.
                    psths(j,:) = temp(j==a,:);                              %Replace the sweep with the randomized sweep.
                end
            end        
            
            f32filename = ['E' num2str(10*c,'%03d') '_EZClassifier_PBN_'...
                rootfile '.f32'];                                           %Make a filename for the new *.f32 file.
            if ~isempty(psths)                                              %If there's any sweeps for this channels.
                disp(['Writing: ' f32filename]);                            %Show the user the filename of the new EZClassifier file.
                fid = fopen([destpath rootfile '\' f32filename],'w');   %Open the *.f32 file for writing.
                numparams = size(params,2);                                 %Grab the number of parameters.
                for i = 1:size(params,1)                                    %Step through each sweep.
                    fwrite(fid, -2, 'float32');                             %New dataset indicator.
                    fwrite(fid, isi, 'float32');                            %Sweeplength (in milliseconds).
                    fwrite(fid, numparams, 'float32');                      %Write how many parameters will follow.
                    for j = 1:numparams                                     %Step through each parameter for this sweep.
                        fwrite(fid, params(i,j), 'float32');                %Write the parameter values.
                    end
                    fwrite(fid, -1, 'float32');                             %New sweep indicator.
                    spikes = [];                                            %Make a matrix to hold spike times.
                    for n = 1:25                                            %Step through the possible number of spike counts.
                        b = find(psths(i,:) == n);                          %Check the PSTH for bins with this many spikes.
                        for k = b                                           %Step through each bin.
                            spikes = [spikes; repmat(k-0.5,n,1)];           %Add the correct number of spike times, in whole milliseconds, to the list.
                        end
                    end
                    spikes = sort(spikes);                                  %Sort the spike times into chronological order.
                    fwrite(fid,spikes,'float32');                           %Write the spike times to the *.f32 file.
                end
                fclose(fid);                                                %Close the *.f32 file.
            end
        end
    end
end