function noise_gap_detection_training(handles,hObject)


%% Common stimulus parameters.
%We'll first define common stimulus parameters at the top of the script 
%here so that we can easily change parameter values as we test out the
%behavioral paradigm.
start_intensity = 60;               	%Default starting intensity value for all noisebursts, and the default intensity for background noises.
train_intensity = 50;                   %Default intensity for all training stages.
cal_intensity = 67.5;                 	%Create noises at a well-calibrated intensity, then knock them down with the PA5.
intensities = -20:10:60;              	%Discrete intensity values to test.
dynamic_threshold_shift = 20;           %Set how high over the 50% hearing threshold the dynamic intensity for gap testing should be
stim_duration = 50;                 	%Duration of the noisebursts and gaps, in milliseconds.
post_target_recording = 0.2;            %Duration of recordings taken after the end of the target, in seconds.
block_size = 5;                        %Number of trials in each background noise block.
nosepoke_trials = 100;                  %The number of correct trials a rat must complete to advance past nosepoke training.
transition_trials = 300;                %The number of correct trials a rat must complete to advance past a hold training stage.
transition_alpha = 0.01;                %The significance level of the d' that a rat must achieve to advance past a training stage.
catch_trial_prob = 0.1;                 %The proportion of trials that will be catch trials.
min_test_repeats = 10;                  %The minimum repeats of each stimulus a rat must have to advance past a testing stage.
narrowband_bounds = 1;                  %Enter 0 for linear bandwidths or 1 for octave bandwidths 


%% Set the pathnames we'll use repeatedly throughout the script.
%The desktop path on each computer differs according to that computer's username.
userpath('reset');            	%Reset the user path to the default MatLab search path.
temp = userpath;                %Grab the default Matlab search path.
a = find(temp == '\');          %Find the folder markers in the search path name.
temp = temp(a(2)+1:a(3)-1);     %Pull the user name out of the search path name.
desktop = ['C:\Documents and Settings\' temp '\Desktop'];   %Set the desktop path for this user name.
    
%Next, we'll see if the Z:\ drive is online.  If not, we'll set the
%relevant MatLab paths to look in the desktop folders.
if exist('Z:\Gap Detection Startle','dir')          %If the Z:\ drive's connected...
    rootpath = 'Z:';                                %The root path is set to the Z:\ drive.
    warning off MATLAB:rmpath:DirNotFound;          %Turn off the warning message for the rmpath function.
    rmpath([desktop '\Gap Detection Startle']);     %Remove the redundant desktop folders.
    rmpath([desktop '\Analysis Programs']);
else                                                %If the Z:\ drive's not connected...
    rootpath = desktop;                             %The desktop becomes the root path.
end
addpath([rootpath '\Gap Detection Startle']);       %Add the pitch discrimination folder to the search path.
addpath([rootpath '\Analysis Programs']);           %Add the general NEL programs folder to the search path.
programpath = [rootpath '\Gap Detection Startle\']; 	%Define the path that contains the behavior m-files.
rcxpath = [rootpath '\RPvds Circuits\']; 	%Define the path that contains the behavior m-files.
% rcxpath = 'C:\RPvds Circuits\'; 	%Define the path that contains the behavior m-files.
datapath = [rootpath '\Gap Detection Startle\Behavior Data\'];  	%Define the general folder for saving behavioral data text files.
backuppath = [desktop '\Gap Detection Startle\Behavior Data\']; 	%Define the backup folder for saving behavioral data text files.
% if exist('D:\','dir') == 7      %If there's a second hard drive on the computer...
%     recordingpath = 'D:\';		%We'll save any neural recordings to that drive.
% else                            %If there's only one hard drive...
    recordingpath = 'C:\Neural Recordings\';	%We'll save the neural recordings to a folder on the C:\ drive.
% end                    


%% Set data, RCX, calibration, HTML, and warning sound file names.
datafile = [datapath '\noise_gap_detection_data.mat'];         %All behavioral data is primarily saved in one large structure in a *.mat file.
%A placeholder file prevents other programs from updating the data file while this program is accesing it.
placeholder = [datapath '\noise_gap_detection_placeholder.temp'];
if exist('C:\Booth_Number.txt','file');
    booth_number = load('C:\Booth_Number.txt');     %The number of the booth for this computer is in a text file on the C: drive.
else
    booth_number = load([desktop '\Booth_Number.txt']);
end
if ~handles.recording                                                           %If we're not recording...
    rz5_rcx_filename = [rcxpath 'RZ5_Use_As_Monitor.rcx'];                     	%...use the RZ5 as a monitor.
else                                                                            %Otherwise...
    rz5_rcx_filename = [rcxpath 'RZ5_A-P.rcx'];                                 %...use the RZ5 for neural recordings.
end
web_status_file = 'BoothStatus.html';                           %Name of the online status update HTML file.
crash_warning_sound = [programpath '\CrashWarning.wav'];        %This is the sound that will play over the speakers if the program crashes.

%If the program crashes we can set it to send alert emails to any addresses
%we list here, including SMS text message addresses assigned to cell phones.
alert_emails = {'drewsloan@gmail.com'};  %'4053268971@tmomail.net', 


%% Neural recording filter settings (for display only, the unfiltered signal is saved to file).
low_pass_cutoff = 4500;     %Low-Pass filter cut-off, in Hz.
high_pass_cutoff = 825;     %High-Pass filter cut-off, in Hz.


%% Save the daycode at the beginning of the session (to avoid confusion on sessions that run through midnight).
handles.daycode = daycode;


%% Initialize the TextPrompt Java program to display text results from each trial.
textbox = TextPrompt;
textbox.show; textbox.printLine('');


%% Determine the training or testing stage.
%Unless an user overrides the program, the training or testing stage for
%the session will be determined based on the subject's previous performance.
textbox.printLine('Noiseburst/Gap Detection Program');
textbox.printLine('');
warning off MATLAB:MKDIR:DirectoryExists;   %Turn off the warning message for the mkdir function.
mkdir(datapath);                            %Make the main behavioral data folder if it doesn't exist.
currentrat = 0;                             %Start off assuming this rat doesn't yet exist in the primary data structure.
if exist(datafile,'file')    %If the primary data file already exists...
    %If some other program is already accessing the data file, we'll wait for it to finish modifying it before we load it.
    if exist(placeholder,'file')            %Check for the placeholder file.   
        textbox.printLine('Central data structure currently in use, please wait...');	%Display a "waiting" message.
        tic;                                                            %Start a timer.
        while exist(placeholder,'file') 	%Keep checking for the placeholder file.
            pause(0.5);                                                 %Pause 0.5 seconds on each loop.
            if toc > 30;	%If the folder is occupied for more than 30 seconds, we'll just grab an un-updated version.
                textbox.printLine('Central data structure is occupied, cannot grab updated data structure.');
                break;      %Break out of the while loop.
            end
        end
        textbox.printLine('');
    end
    load(datafile);             %Load the primary behavioral data structure.
    for i = 1:length(detectdata);    %#ok<NODEF> Step through all the rats in the data structure.
        if strcmpi(handles.ratname,detectdata(i).ratname);   %Check the saved rat's name against the current "handles.ratname".
            currentrat = i;     %If the names match, save the index for this rat.
        end
    end
    if currentrat ~= 0          %If this rat has been run before and is in the data structure.
        currentsession = length(detectdata(currentrat).session) + 1;     %Create a new session for the rat.
        handles.stage = detectdata(currentrat).stage;                    %Pull the rat's current training/testing stage from the structure.
        textbox.printLine(['' handles.ratname ' was  on stage ' num2str(handles.stage) '.']); %Display the current stage.

        %Now we'll step through the training and testing stages until we find a stage the rat hasn't completed.
        checker = 1;        %Checker is a boolean variable we'll use to indicate when the loop has found an incomplete stage.
        while checker
            checker = 0;                %Start off by assuming they haven't completed the present stage.
            a = find([detectdata(currentrat).session(:).stage] == handles.stage);	%We'll find all the sessions done at this stage.
            if ~isempty(a)
                if handles.stage == 1           %Nosepoke training stage
                    outcomes = char(vertcat(detectdata(currentrat).session(a).outcome));	%Grab outcomes.
                    temp = sum(outcomes == 'H');                                            %Count the total number of hits.
                    textbox.printLine([num2str(temp) ' hits in nosepoke training stage 1.']);
                    if temp >= nosepoke_trials                                              %If the rat's gotten enough nosepoke training hits...
                        handles.stage = 2;                  %Move up to stage 2.
                        checker = 1;                        %Set the boolean checker to iterate the while loop.
                    end
                    clear outcomes;                       	%Delete unnecessary variables.     
                elseif any(handles.stage == [2:6,13:14])        %Holdtime training stages.
                    outcomes = char(vertcat(detectdata(currentrat).session(a).outcome));	%Grab outcomes.
                    outcomes(outcomes == 'A') = [];                                         %Kick out all abort trials.
                    numtrials = length(outcomes);                                           %Save the total number of completed trials.
                    if length(outcomes) > transition_trials                                 %If the rat's completed more than the necessary number of trials.
                        outcomes(1:length(outcomes)-transition_trials) = [];                %Shorten the outcome list to only a recent block of trials.
                    end
                    %Use our custom dprime function to calculate d'.
                    disp([sum(outcomes == 'H'), sum(outcomes == 'M'),sum(outcomes == 'F'),sum(outcomes == 'C')])
                    d = dprime(sum(outcomes == 'H'),sum(outcomes == 'M'),sum(outcomes == 'F'),sum(outcomes == 'C'));
                    textbox.printLine([num2str(numtrials) ' completed trials in stage ' num2str(handles.stage) ...
                        ', d-prime(' num2str(min([transition_trials, numtrials])) ') = ' num2str(d,'% 2.2f') '.']);
                    if numtrials >= transition_trials && d >= norminv(1-transition_alpha/2)	%If there's enough trials trials and the d' is significant...
                        handles.stage = handles.stage + 1;  %Move up to the next stage.
                        checker = 1;                        %Set the boolean checker to iterate the while loop.
                    end
                    if any(handles.stage == [4,6,13:14])
                        combos = [floor(vertcat(detectdata(currentrat).session(a).freq)),...
                        vertcat(detectdata(currentrat).session(a).intensity)];              %Make a list of all frequency-intensity combinations.
                    combos(outcomes ~= 'H' & outcomes ~= 'M',:) = [];                      	%Kick out all but the hits and misses.
                    d = unique(combos,'rows');                                              %Find all unique frequency-intensity combinations.
                    temp = zeros(1,size(d,1));                                              %Preallocate a matrix to hold the number of repeats.
                    for i = 1:size(d,1)                                                     %Step through each unique frequency-intensity combination.
                        for j = 1:size(combos,1)                                            %Then step through each completed trial.
                            temp(i) = temp(i) + isequal(combos(j,:),d(i,:));                %If the trial is at this combination, add one to the counter.
                        end
                    end
                    textbox.printLine(['The lowest repeat count for any stimulus is ' num2str(min(temp)) ' repeats.']);
                    end
                    
                    clear outcomes;                         %Delete unnecessary variables.
                else                                      %Testing Stages.
                    outcomes = char(vertcat(detectdata(currentrat).session(a).outcome));	%Grab outcomes.
                    numtrials = sum(outcomes ~= 'A');                                       %Count the number of completed trials.
                    combos = [floor(vertcat(detectdata(currentrat).session(a).freq)),...
                        vertcat(detectdata(currentrat).session(a).intensity)];              %Make a list of all frequency-intensity combinations.
                    combos(outcomes ~= 'H' & outcomes ~= 'M',:) = [];                      	%Kick out all but the hits and misses.
                    d = unique(combos,'rows');                                              %Find all unique frequency-intensity combinations.
                    temp = zeros(1,size(d,1));                                              %Preallocate a matrix to hold the number of repeats.
                    for i = 1:size(d,1)                                                     %Step through each unique frequency-intensity combination.
                        for j = 1:size(combos,1)                                            %Then step through each completed trial.
                            temp(i) = temp(i) + isequal(combos(j,:),d(i,:));                %If the trial is at this combination, add one to the counter.
                        end
                    end
                    textbox.printLine([num2str(numtrials) ' completed trials in stage ' num2str(handles.stage) ...
                        ', the lowest repeat count for any stimulus is ' num2str(min(temp)) ' repeats.']);
                    if min(temp) >= min_test_repeats                                        %If there's enough repeats for each stimulus.
                        handles.stage = handles.stage + 1;                                  %Move up to the next stage.
                        checker = 1;                                                        %Set the boolean checker to iterate the while loop.
                    end
                    clear outcomes combos d temp;                                           %Delete unnecessary variables.
                end
            end
        end
        if handles.stage ~= detectdata(currentrat).stage     %If we've advanced the stage from what was saved in the data structure...
            textbox.printLine(['Advancing to stage ' num2str(handles.stage) '.']);
        end
    else                                        %If this rat isn't in the data structure...
        currentrat = length(detectdata) + 1;	%Create a new rat entry in the data structure.
    end
else                                        %If there is no existing data structure...
    currentrat = 1;                         %This'll be the first rat in new structure.
end
%If this rat isn't in the data structure or there is no data structure...
if ~exist(datafile,'file') || currentrat == length(detectdata) + 1    
    handles.stage = 1;                  %New rats start on stage 1.
    currentsession = 1;                 %This'll be the rat's first session.
    textbox.printLine('New subject, starting on stage 1.');
end
if handles.override     %If we don't want the training stage picked automatically, there's an override option on the GUI.
    %We use an list dialog box to ask the use what training stage they want to run the rat on.
    clear temp;
    temp{1} = 'Stage 1: Nosepoke Training';
    temp{2} = 'Stage 2: Noiseburst Detection, Hold Training #1';
    temp{3} = 'Stage 3: Noiseburst Detection, Hold Training #2';
    temp{4} = 'Stage 4: Noiseburst Detection, Testing';
    temp{5} = 'Stage 5: Noise Gap Detection, Hold Training';
    temp{6} = 'Stage 6: Noise Gap Detection, Testing';
    temp{7} = 'Stage 7: Tone Detection, Hold Training';
    temp{8} = 'Stage 8: Tone Detection, Testing';
    temp{9} = 'Stage 9: Tone Gap Detection, Hold Training';
    temp{10} = 'Stage 10: Tone Gap Detection, Testing';    
    temp{11} = 'Stage 11: 40 dB Noiseburst, Testing';   
    temp{12} = 'Stage 12: 40 dB Noisegap, Testing';   
    temp{13} = 'Stage 13: Static Intensity Gap Detection, Testing';
    temp{14} = 'Stage 14: Dynamic Intensity Gap Detection, Testing';
    temp = listdlg('liststring',temp,'promptstring','Which stage would you like to run this rat on?:',...
        'okstring','Select Stage','cancelstring','Automatic','Name','Stage Select','selectionmode','single',...
        'listsize',[400,300],'uh',30);
    drawnow;        %Give the GUI a chance to update.
    if ~isempty(temp)
        handles.stage = temp;
        textbox.printLine(['Training stage manually set to stage ' num2str(handles.stage) '.']);
    end
end
textbox.printLine('');


%% Update the stage label on the main GUI.
set(handles.lblStage,'String',num2str(handles.stage));
%guidata(hObject, handles);


%% Center frequencies to be tested.
if any(handles.stage ==[1:6,11:14])
    freqs = [2378.41423000544, 40000];                                      %Frequency range of center frequencies to test over.
else
    freqs = [2000, 48000];                                                  %Frequency range of center frequencies to test over.
end
f_step = 0.25;                        	%Frequency step between center frequencies for noise stimuli, in octaves.
bandwidth = 0.5;                     	%Bandwidth of the noises, in octaves.
filter_order = 8;                       %Filter order of the Butterworth filters used to create noises.
lower_freq_bound = log2(min(freqs));  	%Find the lower frequency bound, in power of 2.
upper_freq_bound = log2(max(freqs));   	%Find the upper frequency bound, in power of 2.
freqs = pow2(lower_freq_bound:f_step:upper_freq_bound);     %Generate test noise frequencies with even octave spacing.


%% Load the calibration data for noise or tones, depending on what's being tested.
if any(handles.stage ==[1:6,11:14])   	%If this is a noiseburst or noise gap stage...
    load([rootpath '\Calibration\Booth_#' num2str(booth_number) '_Noise_Calibration_Data']);        %Load the noise calibration for this booth.
    cal(:,1:2) = floor(cal(:,1:2)); %Floor the center frequency and bandwidth columns of the calibration matrix to make matching easier.
    freqs = [0, freqs];             %Add white noise to the frequency list.
else                                %Otherwise, this is a pure tone stage....
    load([rootpath '\Calibration\Booth_#' num2str(booth_number) '_Pure_Tone_Calibration_Data']);	%Load the pure tone calibration for this booth.
    cal(:,1) = floor(cal(:,1));     %Floor the frequency column of the calibration matrix to make matching easier.
end


%% Set the RCX file for the RP2 depending on the stage.
if any(handles.stage == [1:4,11])        %Noiseburst stages.
    rp2_rcx_filename = [rcxpath 'NoiseBurst_Behavior.rcx'];
    stimulus_type = 1;
elseif any(handles.stage == [5:6,12:14])    %Noisegap stages.
    rp2_rcx_filename = [rcxpath 'NoiseGap_Behavior.rcx'];
    stimulus_type = 2;
elseif any(handles.stage == 7:8)    %Toneburst stages.
    rp2_rcx_filename = [rcxpath 'ToneBurst_Behavior.rcx'];
    stimulus_type = 3;
elseif any(handles.stage == 9:10)    %Tonegap stages.
    rp2_rcx_filename = [rcxpath 'ToneGap_Behavior.rcx'];
    stimulus_type = 4;
end


%% Initialize the TDT rack components.
%We'll use the zBus to trigger the tones and also to trigger recordings.
[zbus, checker] = Initialize_ZBUS('GB');                %Connect to the zBus using the Initialize_ZBUS function.
if checker(1)                                       	%If the connection was successful...
    textbox.printLine('Connected to the zBus.');        %...show that in the textbox.
else                                                    %Otherwise...
    error('ERROR IN ZBUS INITIALIZATION: Could not connect to the zBus!');   %...show an error.
end
%The RP2 handles stimulus presentation and nosepoke/feeder monitoring.
[rp2, checker, rp2_sampling_rate, temp] = Initialize_RP2(rp2_rcx_filename);     %Connect to the RP2 using the Initialize_PA5 function.
if all(checker)                                         %If the connection and RCX-loading was successful...
    textbox.printLine(['RP2 connected, "' rp2_rcx_filename '" is loaded and running.']);    %...show that in the textbox.
elseif ~checker(1)                                      %If the RP2 couldn't be connected...
    error('ERROR IN RP2 INITIALIZATION: Could not connect to the RP2!');    %...show an error.
elseif ~checker(2)                                      %If the RCX file couldn't be loaded to the RP2...
    error(['ERROR IN RP2 INITIALIZATION: Could not load "' rp2_rcx_filename '" to the RP2!']);  %...show an error.
elseif ~checker(3)                                      %If the RCX file couldn't be set to run...
    error('ERROR IN RP2 INITIALIZATION: Could not run the RCX file on the RP2!');   %...show an error.
end
textbox.printLine(['RP2 sampling at ' num2str(rp2_sampling_rate) ' Hz, cycle usage at ' num2str(temp) '%.']);   %Show the sampling rate and cycle usage.
%The RZ5 handles neural recordings or can be used as a stimulus monitor.
[rz5, checker, rz5_sampling_rate, temp] = Initialize_RZ5(rz5_rcx_filename);     %Connect to the RZ5 using the Initialize_PA5 function.
if all(checker)                                         %If the connection and RCX-loading was successful...
    textbox.printLine(['RZ5 connected, "' rz5_rcx_filename '" is loaded and running.']);    %...show that in the textbox.
    textbox.printLine(['RZ5 sampling at ' num2str(rz5_sampling_rate) ' Hz, cycle usage at ' num2str(temp) '%.']);   %Show the sampling rate and cycle usage.
elseif ~checker(1) && handles.recording                	%If the RZ5 couldn't be connected...
    error('ERROR IN RZ5 INITIALIZATION: Could not connect to the RZ5!');    %...show an error.
elseif ~checker(2) && handles.recording                	%If the RCX file couldn't be loaded to the RZ5...
    error(['ERROR IN RZ5 INITIALIZATION: Could not load "' rz5_rcx_filename '" to the RZ5!']);  %...show an error.
elseif ~checker(3) && handles.recording                	%If the RCX file couldn't be set to run...
    error('ERROR IN RZ5 INITIALIZATION: Could not run the RCX file on the RZ5!');   %...show an error.
else                                                    %If we're not recording and the connection was unsuccessful...
    textbox.printLine('Could NOT connect to an RZ5!');  %...just show a warning in the textbox.
end
%The PA5 attenuates signals during varying-intensity testing.
[pa5, pa5_connected] = Initialize_PA5('GB');            %Connect to the RZ5 using the Initialize_PA5 function.
if pa5_connected                                      	%If the connection was successful.
    textbox.printLine('PA5 connected.');                %...show that in the textbox.
else                                                    %Otherwise, if the PA5 couldn't be connected...
    textbox.printLine('Could NOT connect to a PA5!');	%...just show a warning in the textbox.
end


%% Set the constant parameters on the RP2 that don't vary between stimulus types.
rp2.SetTagVal('cue_dur',stim_duration);     %Set the stimulus duration (gap or burst) on the RP2.


%% Set the target response window and the debounce time.
if handles.stage == 1               %In nosepoke training, give them a generous response window and a generous debounce time.
    target_response_limit = 1;      %Amount of time the rat has to disengage the nosepoke after a target, in seconds.
    debounce = 0.5;                 %The length of time, in seconds, we'll allow a rat to temporarily exit the nosepoke without declaring it a withdrawal.
else
    target_response_limit = 0.5;	%Amount of time the rat has to disengage the nosepoke after a target, in seconds.
    debounce = 0.1;                 %The length of time, in seconds, we'll allow a rat to temporarily exit the nosepoke without declaring it a withdrawal.
end


%% Set the time-out duration.
if any(handles.stage == [1:3,5,7,9])  	%In training stages...
    time_out_duration = 0.1;           	%...time-outs will only last 1 second.
else                                    %In testing stages...
    time_out_duration = 5;              %...time-outs will last 5 seconds.
end


%% Set Thresholds
if any(handles.stage == [1:3,5,7,9])                    %If this is a training stage...
    intensities = train_intensity;                      %...we'll only use the one easy intensity.
elseif any(handles.stage == [11:13])                      %If this is a single-intensity testing stage...
    intensities = start_intensity;                      %...we'll only use a lower, some-what harder intensity.
elseif handles.stage == 14                              %if this is a dynamic single intensity stage
    [junk junk2 intensities] = noise_detection_audiogram(handles.ratname, 'off')  %we'll pull the threshold values from the audiogram of the last 300 stage 4 trials
    disp(intensities)
    intensities = intensities(7,:) + dynamic_threshold_shift; %Well use the 80% hit rate value and bump it up to target equivalent gap detection performance
    disp(intensities)
end


%% Load the historical performance of the rat on this stage.                                     
prev_perf = zeros(length(freqs),length(intensities),4);     %Create a matrix to hold historical threshold map data.
cur_perf = zeros(length(freqs),length(intensities),4);      %Create a matrix to hold current threshold map data.
intensity_tracker = [];                                     %Create a matrix to keep track of which frequency-intensity combinations have been tested.
if exist('detectdata','var') && currentrat <= length(detectdata)
    a = find([detectdata(currentrat).session(:).stage] == handles.stage);	%Find previous sessions run on this stage.
    if any(a)
        outcomes = vertcat(detectdata(currentrat).session(a).outcome);          %Grab outcomes.
        testfreqs = floor(vertcat(detectdata(currentrat).session(a).freq));    	%Grab tested frequencies.
        testints = vertcat(detectdata(currentrat).session(a).intensity);     	%Grab tested intensities.
        testdurs = vertcat(detectdata(currentrat).session(a).duration);     	%Grab tested burst/gap durations.
        for f = floor(freqs)      	%Step through each tested frequency.
            for i = intensities     %Step through each tested intensity.
                b = find(testfreqs == f & testints == i & testdurs == stim_duration);	%Find all trials with this frequency, intensity, and duration.
                if ~isempty(b)
                    hmfc = [0 0 0 0];	%We'll simply count actual hits, misses, false alarms, and correct rejections, starting from zero.
                    hmfc(1) = sum(outcomes(b) == 'H');      %Add up the number of hits.
                    hmfc(2) = sum(outcomes(b) == 'M');      %Add up the number of misses.
                    hmfc(3) = sum(outcomes(b) == 'F');      %Add up the number of false alarms.
                    hmfc(4) = sum(outcomes(b) == 'C');    	%Add up the number of correct rejections.
                    prev_perf(f == floor(freqs), i == intensities, 1:4) = hmfc;            %Save the performance for this frequency/intensity combination.
                    b = intersect(b, find(outcomes == 'H' | outcomes == 'M'));
                    intensity_tracker = [intensity_tracker; f*ones(length(b),1), i*ones(length(b),1),  outcomes(b) == 'H'];
                end
            end
        end
    end
end
clear detectdata;    %Clear out the behavior data structure for now to save memory.


%% Initialize the plots on the GUI.
%We'll plot the rat's current and historical hit and false alarm rates as
%bar graphs in the top right graph.
axes(handles.picCombo);
Map_Plots(cur_perf, prev_perf, freqs, intensities);


%% Create a spreadsheet-formatted text file to be a backup data record.
warning off MATLAB:MKDIR:DirectoryExists;	%Turn off the "directory already exists" warning.
mkdir(backuppath);                      %Make the back-up data folder if it doesn't already exist.
cd(backuppath);                         %Step into the back-up data folder.
mkdir(handles.ratname);                 %Make a folder for this rat's data if it doesn't already exist.
cd([backuppath '\' handles.ratname]);  	%Step into this rat's data folder.
temp = [handles.ratname ' - Stage ' num2str(handles.stage)];	%Create a folder name containing the rat name and stage number.
mkdir(temp);                           	%Make a folder for this stage's data if it doesn't already exist.
cd([backuppath '\' handles.ratname '\' temp]);          %Step into the stage-specific folder.
prefix = 'DT';                                          %Prefix for noise/gap/tone detection.
temp = num2str(daycode,'%03d');                         %Turn the daycode into a 3-character string.
%Text filenames have a (Prefix)_#_(Ratname)_(Daycode)_(Stage) format.
filename = ['_' handles.ratname '_' temp '_Stage' num2str(handles.stage)]; 
for i = 1:100           %Step through possible session numbers for today...
    if ~exist([prefix '_' num2str(i) filename '.txt'],'file');     %...until we find an unused session number.
        filename = [prefix '_' num2str(i) filename];                %#ok<AGROW> Write the session number into the filename.
        break;
    end
end
%We'll use Tom's Java text file writer to spit out text files.
textbox.printLine(['Data will be saved to  "' filename '.txt".']);
textbox.printLine('');
file = java.lang.String([filename '.txt']);                 %Turn the filename into a java language filename.
writer = java.io.BufferedWriter(java.io.FileWriter(file));  %Initialize the java text-writing function.
t = sprintf('\t');                          %Turn tab spacing into a writeable string.
space = java.lang.String(t);                %Convert the tab spacing to java language.
space = char(space);                        %Save the tab spacing as a character matrix.
writer.write(handles.ratname);          writer.write(space);	%Write the rat's name as the first cell.
writer.write(num2str(daycode,'%03d'));  writer.write(space);	%Write the daycode as a 3-character string.
if any(handles.stage == [1:4,11])        %Noiseburst stages.
    writer.write('NoiseBurst_Detection');       writer.write(space);    %Write the behavior protocol.
elseif any(handles.stage == [5:6,12:14])    %Noisegap stages.
    writer.write('NoiseGap_Detection');         writer.write(space);    %Write the behavior protocol.
elseif any(handles.stage == 7:8)    %Toneburst stages.
    writer.write('ToneBurst_Detection');       	writer.write(space);    %Write the behavior protocol.
elseif any(handles.stage == 9:10)    %Tonegap stages.
    writer.write('ToneGap_Detection');       	writer.write(space);    %Write the behavior protocol.
end
writer.write(['Stage:_' num2str(handles.stage)]); 	writer.write(space);	%Write the stage number.
writer.write(['Booth:_' num2str(booth_number)]);  	writer.write(space);    %Write the booth number.
writer.write(['Target_Response_Limit:_' num2str(target_response_limit) 's']);	writer.write(space);	%Write the target response limit, in seconds.
writer.newLine;     %Start a new line in the text file.
writer.flush;       %Flush the text file writer.
%Now we'll write in headings for the columns of data that will follow.
writer.write('trial_#');                        writer.write(space);	%Column 1
writer.write('clock_reading');                  writer.write(space);  	%Column 2
writer.write('holdtime_(s)');                   writer.write(space);  	%Column 3
writer.write('timeheld_(s)');                   writer.write(space);  	%Column 4
writer.write('outcome');                        writer.write(space);  	%Column 5
writer.write('nosepoke_response_(s)');          writer.write(space);   	%Column 6
writer.write('center_freq_(Hz)');               writer.write(space);    %Column 7
writer.write('bandwidth_(octaves)');            writer.write(space);  	%Column 8
writer.write('duration_(ms)');                  writer.write(space);  	%Column 9
writer.write('intensity_(dB)');                 writer.write(space);	%Column 10
writer.write('correct_trial');                  writer.write(space);   	%Column 11
writer.write('hit');                            writer.write(space);   	%Column 12
writer.write('miss');                           writer.write(space);  	%Column 13
writer.write('false_alarm');                    writer.write(space);  	%Column 14
writer.write('correct_rejection');              writer.write(space);  	%Column 15
writer.write('abort');                          writer.write(space);   	%Column 16
writer.write('catch_trial');                    writer.write(space);   	%Column 17
writer.newLine;     %Start a new line in the text file.
writer.flush;       %Flush the text file writer.


%% Initialize neural recordings.
if handles.recording    %If we're collecting neual data...
    recording_channels = edit_recording_channels(1:16, 2:15);	%Use the checkbox GUI to select channels.
    if isempty(recording_channels)      %If no channels are selected...
        textbox.printLine('No channels selected for recording! Turning off neural recordings!');   %...show an error message...
        handles.recording = 0;          %...and cancel neural recordings.
    else                                %Otherwise...
        textbox.printLine('Neural recordings enabled.');
        reroute = 1:16;             %Start off assuming no channels are to be rerouted.
        for i = [1,16]              %Check channels #1 and #16 for possible rerouting
            if any(recording_channels == i) && any(setdiff(2:15,reroute(recording_channels)))	%If channel #1 or #16 is selected and a reroute channel is free...
                temp = edit_recording_channels(setdiff(2:15,reroute(recording_channels)),[],i);  %...have the user pick a reroute channel.
                reroute(temp) = i;  %Set the reroute-selected channel to channel #1 input.
                reroute(i) = temp;  %Set channel #1's input to the reroute-selected channel.
            elseif any(recording_channels == i)                   	%If there's no disabled channels available...
                recording_channels(recording_channels == i) = [];   %...we can't reroute the channel.
                textbox.printLine(['No disabled channel available to reroute channel ' num2str(i) '!']);   %Show an error message.
            end
        end
        temp = zeros(1,16);     %Check to make sure all channels are set correctly.
        for i = 1:16            %Step through the channels...
            temp(i) = rz5.SetTagVal(['ch_' num2str(i)], reroute(i));    %And set the channel numbers in the RCX circuit.
        end
        if ~all(a)      %If it couldn't set the channel numbers, show an error.
            error('Could not set the channel numbers on the RZ5!');
        end
        if ~rz5.SetTagVal('mon_chan',-15);     %Set the monitor channel to play the background sounds.
            textbox.printLine('Could not set the monitor channel on the RZ5.');  %If the monitor channel can't be set, don't error, but show a message.
        end
      	rz5_sampling_rate = rz5.GetSFreq;	%Grab the recording device sampling rate for later use.
        a = rz5.SetTagVal('hp_cutoff',1);	%Set the high-pass monitor filter to pass everything above 5 Hz.
        b = rz5.SetTagVal('lp_cutoff',rz5_sampling_rate/2);	%Set the low-pass monitor filter to half the sampling rate.
        if ~a || ~b     %If we can't set the monitor filters, don't error, but show a message.
            textbox.printLine('Could not set the high- and low-pass monitor filters on the RZ5.');
        end
        [b,a] = ellip(2,0.1,40,[825 4500]*2/rz5_sampling_rate);     %Make filter coefficients for a display filter.
        recfilter = [b; a];                                        	%Save the filter coefficients.
        buffsize = 10000;                                           %We'll arbitrarily set the buffer to 10000 samples for testing.
        rz5.SetTagVal('bufforder',1);                               %Set the buffer to hold two sweeps at a time.
        if ~rz5.SetTagVal('buffsize',buffsize);                     %Set the buffer size on the RZ5.
            error('Could not set the buffer size on the RZ5!');     %If the buffer size can't be set, show an error.
        end
        axes(handles.picPsycho);    %We'll plot the neural signals on the same axes as the psychometric curves.
        x_limit = get(gca,'xlim');  %We'll have to plot the neural signals onto the figure sized as it is currently.
        textbox.printLine('Testing recording: triggering zBus...');	%We can check to make sure we're recording by acquiring some data.
        zbus.zBusTrigB(0,0,10);                         	%Reset the recording buffers with the zBus B trigger.
        pause(0.01);                                       %Pause for 10 milliseconds.
        zbus.zBusTrigA(0,0,20);                            %Recording and stimulus playing are both triggered by the zBus A trigger.
        run = 1;                    %This boolean variable controls the sampling loop.
        checker = zeros(1,16);      %Use this checker matrix to make sure we're getting signals from all channels.
        colors = 0.5*ones(16,3);            	%Blank out all recording channel colors.
        colors(recording_channels,[1,3]) = 0;	%Set the color of all enabled channels to green.
        while run   %Loop until we get good recordings.
            zbus.zBusTrigA(0,0,10);         %Recording and stimulus playing are both triggered by the zBus.
            pause(buffsize/rz5_sampling_rate);      %Pause to give RA16s a chance to finish recording.
            cla;            %Clear the plot.
            hold on;        %Hold for multiple plots.
            for i = 1:16    %Step through all channels, even disabled channels.
                currentRA16 = fix((i + 3)/4);                       %Finding the correct RA16 for this channel.
                signal = rz5.ReadTagV(['data_' num2str(i)], 0, buffsize);        %Read in the previous sweep's data from the buffer.
                signal = filtfilt(recfilter(1,:),recfilter(2,:),signal);                  %Run the data through the bandpass filter.
                temp = max(abs(signal));                              %Find the maximum absolute voltage of the signal.
                y = 1.125 - 0.25*(i - 4*(currentRA16-1));           %Find a y-value offset for displaying the trace.
                %Find the x values for displaying the trace for this channel.
                x = (x_limit(1)+((x_limit(2) - x_limit(1))/4)*(currentRA16 - 1) + ((x_limit(2) - x_limit(1))/96)):...
                    ((22*(x_limit(2) - x_limit(1))/96)/buffsize):(x_limit(1)+((x_limit(2) - x_limit(1))/4)*(currentRA16)...
                    - ((x_limit(2) - x_limit(1))/96) - ((22*(x_limit(2) - x_limit(1))/96)/buffsize));
                plot(x,0.1*signal/temp + y,'color',colors(i,:));    %...color the trace gray.
                text(x(round(length(x)/20)),y,num2str(i),'color','k','fontweight','bold','fontsize',14);    %Label the trace.
                checker(i) = std(signal);     %Check to see if the signal is flat (i.e. has no standard deviation).
            end
            hold off;       %Let go of the plot.
            drawnow;       	%Draw the signal plots.
            if any(checker == 0)    %If all channels are flat and we've gone through the loop at least once.
                temp = input('NO SIGNALS: Is the Medusa Pre-Amp on? (Y = Yes, Q = Quit): ','s');    %Ask the user if the Medusa's on.
                if strcmpi(temp,'q')    %If the user opts to quit neural recordings...
                    run = 0;            %Cancel the recording test loop.
                    textbox.printLine('Neural recordings cancelled.');
                    handles.recording  = 0;     %Turn off neural recordings.
                end
            elseif any(checker > 0.00025)    %If there's an RZ5 error that returns signals larger than 250 uV...
                error(['PROBABLE RZ5 ERROR, SIGNALS ARE TOO LARGE (' num2str(round(1000000*mean(checker))) ' uV)!']); 
            else                        %If everything checks out...
                run = 0;                %...cancel the recording test loop.
            end
        end
    end
    textbox.printLine('');
end


%% Open binary files to hold the neural recordings.
if handles.recording    %If we're recording...
    spont_delay = 200;
	%Set the parameter names for neural recordings.
    param{1} = 'Trial (#)';
    param{2} = 'Target Sound (1 = noiseburst, 2 = noisegap, 3 = tone, tone';
    param{3} = 'Center Frequency (Hz)';
    param{4} = 'Bandwidth (octaves)';
    param{5} = 'Duration (ms)';
    param{6} = 'Intensity (dB)';
    param{7} = 'Hold Time (s)';
    param{8} = 'Nosepoke Response (s)';
    cd(recordingpath);                  %Move to the neural recording directory.
    mkdir(handles.ratname);      %Make a folder for this rat if it doesn't already exist.
    cd([recordingpath '\' handles.ratname]); %Step into this rat's folder.
    mkdir([handles.ratname '_' prefix]);     %Make a folder for this type of test if it doesn't already exist.
    cd([recordingpath '\' handles.ratname '\' handles.ratname '_' prefix])    %Step into the test-type folder.
    temp = num2str(daycode,'%03d');     %Grab the daycode a 3-cahracter string.
    mkdir(temp);                        %Make a folder for this daycode.
    cd([recordingpath '\' handles.ratname '\' handles.ratname '_' prefix '\' temp]);  %Step into the daycode folder.
    textbox.printLine(['Neural recording data will be saved to E**_' filename '.NEL.']);
    fid = zeros(1,max(recording_channels));     %Preallocate a matrix to hold file identifiers.
    for i = recording_channels                  %For each channel we're recording from...
        temp = ['E' num2str(i,'%02d') '_'];   	%Each channel has its own file with a "E**" prefix indicating the number.
        fid(i) = fopen([temp filename '.NEL'],'w');  	%Open a binary file for write access for each channel.
        fwrite(fid(i),daycode,'int8');                      %DayCode.
        fwrite(fid(i),length(handles.ratname),'int8');      %Number of characters in the rat's name.
        fwrite(fid(i),upper(handles.ratname),'uchar');      %Characters of the rat's name.
        fwrite(fid(i),spont_delay,'int16');                 %Spontaneous measurement delay, in milliseconds.
        fwrite(fid(i),rz5_sampling_rate,'float32');        %Sampling rate, in Hz.
        fwrite(fid(i),length(param),'int8');                %Number of parameters.
        for j = 1:length(param)                             
            fwrite(fid(i),length(param{j}),'int16'); 	%Number of characters in each parameter name.
            fwrite(fid(i),param{j},'uchar');          	%Characters of each parameter name.
        end    
    end
    recording_index = 0;        %Each completed trial will get a new index.
    textbox.printLine('');
else
    spont_delay = 0;
end


%% Connect to the OU network to create the booth status webpage.
try     %Try to connect...
    ftp_server = ftp('apache.utdallas.edu','AMS091000','Princess1');   %Connect to the OU faculty server.
    ftp_connected = 1;                                                  %Keep track of the connection status.
    textbox.printLine('Connected to FTP server for status updates: http://faculty-staff.ou.edu/R/Robert.L.Rennaker-1.II/BoothStatus.html.');
catch       %#ok<CTCH>
    ftp_connected = 0;      %If we can't connect, we'll just not try to update the online status page.
    textbox.printLine('Could not connect to FTP server for online updates.');
end
textbox.printLine('');   
if ftp_connected        %If we're connected to the ftp server, create the status webpage.
    %The "booth" structure will contain information about what's going on
    %in other booths as well as this one.  We'll initialize it here.
    booth(booth_number).rat = handles.ratname;
    booth(booth_number).task = 'Speech Sound Discrimination';
    booth(booth_number).trial = 0;                  
    booth(booth_number).feedings = 0;
    booth(booth_number).start_time = now;
    booth(booth_number).trial_time = now;
    booth(booth_number).stage = handles.stage;
    booth(booth_number).status = 'Running';
    booth(booth_number).dprime = 0;
    [booth, ftp_connected] = Update_Webpage(booth, web_status_file, ftp_server, booth_number);
end
    

%% Generate a stimulus set.
[stim_index, stimset, thresh_index, threshset] = stimset_generator(handles.stage, freqs, block_size, intensities);

    
%% Generate a hold time for the first trial.
hold_step = 1;  %Start each session with one hold step.
hold_set = 1;   %Start each new session on the first hold set.
[holdtime, hold_set, hold_step] = holdtime_generator(hold_step, hold_set, handles.stage); %Randomly generate a hold time.
rp2.SetTagVal('cue_delay',1000*(holdtime+spont_delay));	%Set the hold time on the RP2, in milliseconds.


%% Generate a signal from the parameters in the stimset and load it to the RP2.
if any(handles.stage == [4,6,8])                  %If this is a threshold testing stage...
    if ~isempty(intensity_tracker)              %If the rat has been tested on any intensities so far...
        a = intensity_tracker(floor(stimset(1)) == intensity_tracker(:,1),2);   %Grab all historical intensities checked.
        temp = zeros(1,length(intensities));        %Make a check matrix to determine how many times each intensity has been tested.
        for i = 1:length(intensities)               %Step through each intensity.
            temp(i) = sum(a == intensities(i));     %Find out how many times each intensity has been tested.
        end
        temp = intensities(temp == min(temp));      %Find all intensities that have been tested the least.
        int = temp(ceil(rand*length(temp)));        %Randomly set the intensity to one of the least tested intensities.
    else                                            %Otherwise this must be the first trial at this stage...
        int = max(intensities);                 %Set the intensity to the maximum tested intensity.
    end
elseif any(handles.stage == [10,13])             %If this is a gap detection testing stage.
    int = start_intensity;                      %Set the intensity to the maximum tested intensity.
elseif handles.stage == 14
    int = threshset(thresh_index(1));
else                                            %If this isn't a testing stage...
    int = train_intensity;                          %..set the intensity to the training level.
end
stimulus_maker(rp2, handles.stage, stimset(1), int, bandwidth, filter_order, cal_intensity, cal, rp2_sampling_rate, pa5_connected, narrowband_bounds);   %Set up the stimulus on the RP2.
catch_trial = (rand < catch_trial_prob);        %Randomly determine if this trial is a catch trial.
rp2.SetTagVal('cue_enable',~catch_trial);       %Enable/Disable the burst/gap depending on whether or not this is a catch trial.
atten = cal_intensity-int;                      %Find the attenuation as the difference between the calibrated and desired intensities.
if pa5_connected                                %If the PA5 is connected...
    pa5.SetAtten(atten);                      	%...set the attenuaton on the PA5.
end


%% Adjust the buffers on the RA16s for the first stimulus.
spont_delay = spont_delay/1000;     %We need to change the spontaneous recording delay to seconds.
if handles.recording    %If we're recording...
    buffsize = ceil(rz5_sampling_rate*(spont_delay + holdtime + target_response_limit + post_target_recording));  %Calculate the buffer size.
    if ~rz5.SetTagVal('buffsize',buffsize);                     %Set the buffer size on the RZ5.
        textbox.printLine(' Could set buffers on the RZ5.');
        textbox.printLine('');
    end
    zbus.zBusTrigB(0,0,10);                             %Reset the recording buffers with the zBus B trigger.
end


%% Initialize this session's individual data structure and initialize behavioral loop variables.
run = 1;                %This semi-boolean variable controls the behavior loop.
trial = 0;              %Count the number of trials.
feedings = 0;           %Count the number of feedings.
num_rp2_dropouts = 0;   %Count the number of RP2 drop-outs.

%Initialize the session's data structure.
data.clock_reading = []; 
data.holdtime = [];
data.timeheld = [];
data.outcome = 'X';
data.nosepoke_response = [];
data.freq = [];
data.bandwidth = [];
data.duration = [];
data.intensity = [];
data.correct_trial = [];
data.hits = 0; 
data.misses = 0; 
data.false_alarms = 0; 
data.correct_rejections = 0;
data.aborts = 0;
data.catch_trial = [];


%% Turn on the cage lights to indicate to the rat that the program is running.
invoke(rp2,'SetTagVal','cagelights',1); %turning the lights on
textbox.printLine('Running...');
textbox.printLine('');


%% Main Behavior Loop **************************************************************************************************************************
cd(programpath);    %Change to the main program directory.
while run           %Loop so long as the boolean run variable doesn't equal zero.
    
    %To tie this program to the GUI, we'll check the string value of an
    %invisible label on the GUI that gets changed by button presses.
    run = str2double(get(handles.lblRun,'String'));

    %If the rat is in the nosepoke, we'll kick off a trial.
    if ~rp2.GetTagVal('nosepoke')
        trial = trial + 1;      %Begin a new trial.
        trial_start = now;      %Save time of the trial start.
        textbox.printLine(['Trial: ' num2str(trial) ',  ' datestr(trial_start, 14) '.']);
        if any(handles.stage == [1:4,11])        %Noiseburst stages.
            textbox.printLine(['    NoiseBurst: center frequency = ' num2str(round(stimset(stim_index))) ...
                ' Hz,  bandwidth = ' num2str(bandwidth) ' oct, intensity = ' num2str(int) ' dB.']);
        elseif any(handles.stage == [5:6,12:14])    %Noisegap stages.
            textbox.printLine(['    NoiseGap: center frequency = ' num2str(round(stimset(stim_index))) ...
                ' Hz,  bandwidth = ' num2str(bandwidth) ' oct, intensity = ' num2str(int) ' dB.']);
        elseif any(handles.stage == 7:8)    %Toneburst stages.
            textbox.printLine(['    ToneBurst: frequency = ' num2str(round(stimset(stim_index))) ...
                ' Hz, intensity = ' num2str(int) ' dB.']);
        elseif any(handles.stage == 9:10)    %Tonegap stages.
            textbox.printLine(['    ToneGap: frequency = ' num2str(round(stimset(stim_index))) ...
                ' Hz, intensity = ' num2str(int) ' dB.']);
        end
        textbox.printLine(['    Hold Time: ' num2str(holdtime,'% 2.2f') ' s.']);
        
        %Set default trial result values assuming incorrect responses.
        correct_trial = 0;
        nosepoke_response = NaN;
        
        %The nosepoke response limit is the hold time plus the spontaneous delay plus 600 ms.
        total_nosepoke_limit = (target_response_limit + holdtime);
        
        %Trigger presentation of the stimulus.
        zbus.zBusTrigA(0,0,10);    %...trigger playing of the stimulus.
            
        tic;                                    	%Start the trial timer.
        while toc < holdtime                      	%While the timer shows less than the hold time...
            timeheld = toc;                         %Calculate time held.
            if rp2.GetTagVal('nosepoke')            %If the rat's pulled out of the nosepoke early...
                rp2.SetTagVal('cue_enable',0);      %...disable playing of the cue.
                while toc - timeheld < debounce     %Monitor the nosepoke through the debounce time.
                    if ~rp2.GetTagVal('nosepoke')  	%If the rat re-enters the nosepoke in that time...
                        break;                     	%...break out of the debounce waiting loop.
                    end
                end
                if rp2.GetTagVal('nosepoke')     	%If after the debounce time the rat is still out of the nosepoke...
                    rp2.SetTagVal('cagelights',0); 	%...turn the cage lights off...
                    break;                        	%...and exit the waiting loop.
                else                                %Otherwise...
                    rp2.SetTagVal('cue_enable',1); 	%...re-enable playing of the cue.
                end
            end
        end
        
        %If the rat's still in the nosepoke at the beginning of the stimulus...
        if ~rp2.GetTagVal('nosepoke') && toc >= holdtime
            while toc < total_nosepoke_limit      	%While the time shows less than the nosepoke response limit...
                timeheld = toc;                     %Calculate time held.
                if rp2.GetTagVal('nosepoke')        %If the rat pulls out of the nosepoke...
                    break;                       	%Exit the waiting loop.
                end
            end
            if toc <= total_nosepoke_limit                  %If the rat reacted to the target in time...
                nosepoke_response = timeheld - holdtime;	%Calculate the nosepoke response time.
                if ~catch_trial                             %If this wasn't a catch trial...
                    rp2.SoftTrg(1);                         %Trigger food right.
                    outcome = 'H';                          %Score the trial as a hit.
                    correct_trial = 1;                      %Mark the trial as a correct trial.
                    feedings = feedings + 1;                %Track the number of feedings.
                else                                        %If this was a catch trial...
                    outcome = 'F';                          %...then this trial is scored as a false alarm.
                    rp2.SetTagVal('cagelights',0);          %Turn the cage lights off.
                end
            else                                            %If the rat didn't react to the target.
                if catch_trial                              %If this is a catch trial...
                    outcome = 'C';                          %...it's scored as a correct rejection.
                    correct_trial = 1;                     	%The rat didn't respond to no shift, so this is a correct trial.
                else                                        %If this isn't a catch trial...
                    outcome = 'M';                          %...score the trial as a miss.
                    rp2.SetTagVal('cagelights',0);          %Turn the lights off.
                end
            end       
        else                                                %If the rat got off early, before the target tone...
            outcome = 'A';                                  %...the trial is scored as an abort.
            rp2.SetTagVal('cue_enable',0);                  %Disable playing of the cue.
            rp2.SetTagVal('cagelights',0);                  %Turn the lights off.
        end
                
        %Before saving any data, we're going to check to make sure the RP2 hasn't dropped out.
        counter = 0;            %Count the number of reboot attempts.
        run = 0;                %Start off assuming the RP2 has dropped out to start the check look.
        ruined_trial = 0;       %If there was an RP2 dropout, we need to make sure we don't save this data.
        while run == 0 && counter < 3           %Loop through 3 reboot attempts.
            run = 1;                            %Now assume the RP2 is working fine.
            counter = counter + 1;              %This will be the first reboot attempt, if necessary.
            status = zbus.GetError;             %Check for errors on the zBus.
            if ~isempty(status)                 %If errors exist, display them.
                textbox.printLine(['!!!zBus Error:' status '!!!.']); 
                run = 0;
            end
            if zbus.GetDeviceAddr(35,1) ~= 2    %Check for errors on the RP2.
                textbox.printLine('!!!zBus Error: The RP2 has dropped out of the zBus!!!.'); 
            end
            status = double(rp2.GetStatus);     %Grab the status of the RP2.
            if ~bitget(status,1);               %Check to see if the RP2 is connected.
                textbox.printLine('!!!RP2 Error: The RP2 is not connected!!!.'); 
            end
            if ~bitget(status,2);               %Check to see if the RCX circuit is loaded.
                textbox.printLine('!!!RP2 Error: The RCX circuit is not loaded to the RP2!!!.'); 
            end
            if ~bitget(status,3);               %Check to see that the RCX circuit is running.
                textbox.printLine('!!!RP2 Error: The RCX circuit on the RP2 is not running!!!.'); 
            end
            if ~all(bitget(status,1:3))       	%If any status is bad...
                run = 0;                        %...set run to zero.
            end
            if ~run                             %If we've lost a connection, we'll try to get it back with a hardware reset.
                ruined_trial = 1;                           %If anything's bombed out, this trial was ruined.
                num_rp2_dropouts = num_rp2_dropouts + 1;    %We'll track the number of resets and post it to the webpage.
                booth(booth_number).status = ['RP2 Reset #' num2str(num_rp2_dropouts) ', ' datestr(now,14)];	%List the RP2 dropout on the webpage.
                textbox.printLine(['Attempting hardware reset #' num2str(counter) '...']); 
                zbus.HardwareReset(1);                             	%Reset the zBus.
                zbus = Initialize_ZBUS('GB');               	%Connect to the zBus using the Initialize_ZBUS function.
                [rp2, checker, rp2_sampling_rate] = Initialize_RP2(rp2_rcx_filename,'GB');      %Connect to the RP2 using the Initialize_RP2 function.
                [rz5, checker, rz5_sampling_rate] = Initialize_RZ5(rz5_rcx_filename,'GB');  	%Connect to the RZ5 using the Initialize_RZ5 function.
                pa5 = Initialize_PA5('GB');                     %Connect to the PA5 using the Initialize_PA5 function.
                textbox.printLine('');
            end                
        end
        
        %Show the results of the trial in the textbox display.
        if ~ruined_trial
            temp = {'HIT','MISS','FALSE ALARM','CORRECT REJECTION','ABORT'};    %Create a temporary matrix of outcome strings.
            temp = cell2mat(temp(outcome == 'HMFCA'));                          %Grab the right outcome string.
            if outcome == 'A'
                textbox.printLine(['    ABORT - Time Held: ' num2str(timeheld,'% 2.2f') ' s.']);
            else
                textbox.printLine(['    ' temp ' - Feeding: ' num2str(feedings)...
                    ', Nosepoke Response: ' num2str(1000*nosepoke_response,'% 4.0f') ' ms.']);
            end
            textbox.printLine('');

            %Write the trial data to the text file.
            writer.write(num2str(trial));                   writer.write(space);	%(1) Trial number.
            writer.write(num2str(trial_start,'%10.10f'));  	writer.write(space); 	%(2) Clock reading.
            writer.write(num2str(holdtime));                writer.write(space); 	%(3) Hold time.
            writer.write(num2str(timeheld));                writer.write(space);  	%(4) Time held.
            writer.write(outcome);                          writer.write(space);  	%(5) Outcome.
            writer.write(num2str(nosepoke_response));       writer.write(space);  	%(6) Nosepoke response.
            writer.write(num2str(stimset(stim_index)));  	writer.write(space);  	%(7) Center frequency.
            writer.write(num2str(bandwidth));             	writer.write(space); 	%(8) Bandwidth.
            writer.write(num2str(stim_duration));        	writer.write(space);  	%(9) Duration.
            writer.write(num2str(int));                     writer.write(space);   	%(10) Intensity.
            writer.write(num2str(correct_trial));           writer.write(space);  	%(11) Correct trial.       
            writer.write(num2str(outcome == 'H'));          writer.write(space);   	%(12) Hits.
            writer.write(num2str(outcome == 'M'));          writer.write(space);   	%(13) Misses.
            writer.write(num2str(outcome == 'F'));          writer.write(space);   	%(14) False Alarms.
            writer.write(num2str(outcome == 'C'));          writer.write(space);   	%(15) Correct Rejections.
            writer.write(num2str(outcome == 'A'));          writer.write(space);   	%(16) Aborts.
            writer.write(num2str(catch_trial));             writer.write(space);   	%(17) Catch trials.
            writer.newLine;     %Set to a new line in the text file.
            writer.flush;       %Flush the text tile writer.

            %Save the trial data to the data structue.
            data.clock_reading(trial) = trial_start;
            data.holdtime(trial) = holdtime; 
            data.timeheld(trial) = timeheld;
            data.outcome(trial) = outcome; 
            data.nosepoke_response(trial) = nosepoke_response; 
            data.freq(trial) = stimset(stim_index);
            data.bandwidth(trial) = bandwidth;
            data.duration(trial) = stim_duration;
            data.intensity(trial) = int;
            data.correct_trial(trial) = correct_trial;
            data.hits = data.hits + (outcome == 'H');
            data.misses = data.misses + (outcome == 'M');
            data.false_alarms = data.false_alarms + (outcome == 'F');
            data.correct_rejections = data.correct_rejections + (outcome == 'C');
            data.aborts = data.aborts + (outcome == 'A');
            data.catch_trial(trial) = catch_trial;
            
            %Update the GUI label to let the user know how many feedings the rat has had.
            set(handles.lblFeeding,'String',num2str(feedings));
            %guidata(hObject, handles);

            %Update the current and historical performance for making the graphs.
            cur_perf(floor(stimset(stim_index))==floor(freqs),int == intensities,1) = ...
                cur_perf(floor(stimset(stim_index))==floor(freqs),int == intensities,1) + (outcome == 'H');
            cur_perf(floor(stimset(stim_index))==floor(freqs),int == intensities,2) = ...
                cur_perf(floor(stimset(stim_index))==floor(freqs),int == intensities,2) + (outcome == 'M');
            cur_perf(floor(stimset(stim_index))==floor(freqs),int == intensities,3) = ...
                cur_perf(floor(stimset(stim_index))==floor(freqs),int == intensities,3) + (outcome == 'F');
            cur_perf(floor(stimset(stim_index))==floor(freqs),int == intensities,4) = ...
                cur_perf(floor(stimset(stim_index))==floor(freqs),int == intensities,4) + (outcome == 'C');
            prev_perf(floor(stimset(stim_index))==floor(freqs),int == intensities,1) = ...
                prev_perf(floor(stimset(stim_index))==floor(freqs),int == intensities,1) + (outcome == 'H');
            prev_perf(floor(stimset(stim_index))==floor(freqs),int == intensities,2) = ...
                prev_perf(floor(stimset(stim_index))==floor(freqs),int == intensities,2) + (outcome == 'M');
            prev_perf(floor(stimset(stim_index))==floor(freqs),int == intensities,3) = ...
                prev_perf(floor(stimset(stim_index))==floor(freqs),int == intensities,3) + (outcome == 'F');
            prev_perf(floor(stimset(stim_index))==floor(freqs),int == intensities,4) = ...
                prev_perf(floor(stimset(stim_index))==floor(freqs),int == intensities,4) + (outcome == 'C');
            
            %Update the bar chart of hit and false alarm rates in the top right.
            axes(handles.picCombo);
            Map_Plots(cur_perf, prev_perf, freqs, intensities)

            %If we're taking neural recordings we'll add the data to our binary files here, and plot the data.
            axes(handles.picPsycho);    %Plot neural recordings and psychophysical performance on the lower graph.
            cla;                        %Clear the lower graph.
            ylim([0,max(data.holdtime)+target_response_limit+post_target_recording]);
            if length(data.clock_reading) == 1
                xlim(data.clock_reading + [-1,1]/1440);
            else
                xlim([min(data.clock_reading),max(data.clock_reading)]+[-0.05,0.05]*(max(data.clock_reading)-min(data.clock_reading)));
            end
    
            if handles.recording && any(outcome == 'HMFCTK') && rz5_sampling_rate > 6000;   %Ignore abort trials.
                %We'll first make sure that the RA16s have had enough time to get recordings.
                while toc < (holdtime + target_response_limit + post_target_recording + spont_delay)   
                    pause(0.05);    
                end
                recording_index = recording_index + 1;  %Indicate a new sweep in the binary file.
                x_limit = get(gca,'xlim');              %We'll have to plot the neural signals onto the figure sized as it is currently.
                hold on;        %Hold on to the main plot.
                if any(outcome == 'HF')   %Fetch parameter values for hits and false alarm trials.
                    params = [trial; stimulus_type; stimset(stim_index); bandwidth; stim_duration; int; holdtime; nosepoke_response];
                else                                %Fetch parameter values for all other trials.
                    params = [trial; stimulus_type; stimset(stim_index); bandwidth; stim_duration; int; holdtime; target_response_limit];
                end
                for i = 1:16                    %Step through the recording channels.
                    currentRA16 = fix((i + 3)/4);                       %Finding the correct RA16 for this channel.
                    signal = rz5.ReadTagV(['data_' num2str(i)], 0, buffsize);  	%Read in the previous sweep's data from the buffer.
                    if length(signal) < 2000        %If the recorded signal is less than 200 ms long, an error must have occurred.
                        textbox.printLine(' RECORDING SIGNAL ERROR!');
                        textbox.printLine(' '); 
                        break;                      %Exit the recording loop when an error is detected.
                    end
                    if any(recording_channels == i)             %If we're saving data for this channel.
                        fwrite(fid(i),recording_index,'int16');                     %The stimulus index is not the same thing as the trial.
                        fwrite(fid(i),now,'float64');                               %Timestamp.
                        fwrite(fid(i),params,'float32');                            %Parameter values.
                        fwrite(fid(i),round(1000*length(signal)/rz5_sampling_rate)/1000,'float32');    %Sweeplength, in seconds.
                        fwrite(fid(i),length(signal),'uint32');                     %Number of samples in the data sweep.
                        fwrite(fid(i),signal','float32');                           %Sweep data.
                    end
                    signal = filtfilt(recfilter(1,:),recfilter(2,:),signal(1:2000));	%Bandpass filter the signal after saving it.
                    temp = max(abs(signal));                                                %Find the maximum absolute voltage.
                    y = 1.125 - 0.25*(i - 4*(currentRA16-1));                               %Set the y-axis offset.
                    x = (x_limit(1)+((x_limit(2) - x_limit(1))/4)*(currentRA16 - 1) + ((x_limit(2) - x_limit(1))/96)):...   %Set the x-axis plot points.
                        ((22*(x_limit(2) - x_limit(1))/96)/2000):(x_limit(1)+((x_limit(2) - x_limit(1))/4)*(currentRA16)...
                        - ((x_limit(2) - x_limit(1))/96) - ((22*(x_limit(2) - x_limit(1))/96)/2000));
                    plot(x,0.1*signal/temp + y,'color',colors(i,:));  %...color the trace gray.
                    text(x(round(length(x)/20)),y,num2str(i),'color',[0.75 0.75 0.75],'fontweight','bold','fontsize',14);   %Labe the trace with the channel number.
                end
                hold off;   %Let go of the plot.
                disp(['Neural Recording Handling Time: ' num2str(toc - holdtime - spont_delay - nosepoke_response) ' seconds.']); %Display the neural recording handling time.
            end

            %Plot the psychophysical data on top of the neural data.
            Performance_Plots(data);
        
            %If the trial was completed or if it's an training stage we'll get a new hold time for the next trial.
            temp = hold_set;            %Temporarily save the current hold set.
            if any(outcome == 'HMFC') || handles.stage == 1 || feedings <= 25
                [holdtime, hold_set, hold_step] = holdtime_generator(hold_step, hold_set, handles.stage);
            end
            rp2.SetTagVal('cue_delay',1000*(holdtime+spont_delay));	%Set the hold time on the RP2, in milliseconds.
            if hold_set ~= temp;
                textbox.printLine(['Advancing to hold set ' num2str(hold_set) '.']);
                textbox.printLine('');
            end
            
            %If this the rat didn't abort, consider this a completed trial.
            prev_freq = stimset(stim_index);      	%Temporarily save this last trial's frequency.
            prev_int = int;                         %Temporarily save this last trial's intensity.
            if any(outcome == 'HM')
                intensity_tracker = [intensity_tracker; floor(stimset(stim_index)), int, (outcome == 'H')];	%Save this frequency-intensity combination in the intensity tracker.
                stim_index = stim_index + 1;     	%Move to the next stimulus to be tested.
                if handles.stage == 14
                    thresh_index = thresh_index + 1;
                end
                if stim_index > length(stimset)     %If we're run out of stimuli in the stimset...
                    [stim_index, stimset, thresh_index, threshset] = stimset_generator(handles.stage, freqs, block_size, intensities);    %...generate a new stimset.
                end         
                hold_step = hold_step + 1;  %Increment the hold step.
            end
            
            %Change the intensity during threshold testing.
            if any(handles.stage == [4,6,8]) && any(outcome == 'HM')	%If this is a testing stage...
                if ~isempty(intensity_tracker)              %If the rat has been tested on any intensities so far...
                    a = intensity_tracker(floor(stimset(stim_index)) == intensity_tracker(:,1),2);   %Grab all historical intensities checked.
                    temp = zeros(1,length(intensities));        %Make a check matrix to determine how many times each intensity has been tested.
                    for i = 1:length(intensities)               %Step through each intensity.
                        temp(i) = sum(a == intensities(i));     %Find out how many times each intensity has been tested.
                    end
                    temp = intensities(temp == min(temp));      %Find all intensities that have been tested the least.
                    int = temp(ceil(rand*length(temp)));        %Randomly set the intensity to one of the least tested intensities.
                else                                            %Otherwise this must be the first trial at this stage...
                    int = max(intensities);                 %Set the intensity to the maximum tested intensity.
                end
            elseif any(handles.stage == [10]) && any(outcome == 'HM')	%If this is a gap detection testing stage.
                if ~isempty(intensity_tracker) && any(floor(data.freq) == floor(stimset(stim_index)))	%If the rat has been tested on any intensities so far...
                    a = intensity_tracker(find(floor(stimset(stim_index)) == intensity_tracker(:,1),5,'last'),2:3);   %Grab the last three trial intensities.
                    if length(a) == 5 && std(a(:,1)) == 0  	%If the last five intensities tested were the same intensity...
                        disp('a = ');
                        disp(a);
                        if mean(a(:,2)) < 0.5 && a(end,1) < max(intensities)        %If the the hit rate was below 50% for the last five trials...
                            int = intensities(find(a(end,1) == intensities) + 1); 	%...increase the intensity to the next intensity step.
                        elseif mean(a(:,2)) > 0.5 && a(end,1) > min(intensities)    %If the the hit rate was above 50% for the last five trials...
                            int = intensities(find(a(end,1) == intensities) - 1); 	%...decrease the intensity to the next intensity step.
                        else                                                        %Otherwise...
                            int = a(end,1);                                        	%...leave the intensity at the last setting.
                        end
                    elseif ~isempty(a)                      %Otherwise, if there hasn't been a block of at least five complete trials on this intensity...
                        int = a(end,1);                  	%...use the last intensity tested again.
                    else                                    %If this frequency hasn't ever been tested...
                        int = start_intensity;              %...set the intensity to the maximum tested intensity.
                    end
                elseif ~isempty(intensity_tracker) && ~any(floor(data.freq) == floor(stimset(stim_index)))  %Otherwise, if this frequency hasn't been tested yet this session...
                     a = intensity_tracker(floor(stimset(stim_index)) == intensity_tracker(:,1),2:3);       %Grab all trials for this frequency.
                     int = [];                                          %Make the tested intensity empty to start.
                     if ~isempty(a)                                     %If there's any previous trials with this background frequency...
                         temp = unique(a(:,1))';                        %Make a list of all tested intensities.
                         for i = 1:length(temp)                         %Step up through each intensity.
                             if mean(a(a(:,1) == temp(i),2)) > 0.5      %If the hit rate for an intensity is better than 50%...
                                 int = temp(i);                         %...set the current intensity to this value...
                                 break;                                 %...and break out of the for loop.
                             end
                         end
                     end
                     if isempty(int)                                    %If there were no previous trials or no hit-rates better than 50%...
                         int = start_intensity;                         %Set the intensity to the start intensity.
                     end
                else                                      	%Otherwise this must be the first trial at this stage...
                    int = start_intensity;                  %Set the intensity to the maximum tested intensity.
                end    
%                 if isempty(int)
%                     disp(stim_index);
%                     break;
%                 end
%                 disp(['Intensity: ' num2str(int)]);
            end
            %Generate a new signal from the parameters in the stimset and load it to the RP2.
            if stimset(stim_index) ~= prev_freq || (~pa5_connected && int ~= prev_int)	%If the center frequency's not the same as that used in the previous trial...
                if handles.stage == 14      %if this is the dynamic intensity test
                    int = threshset(thresh_index);      %get the desired intensity for the current frequency
                end
                stimulus_maker(rp2, handles.stage, stimset(stim_index), int,...
                    bandwidth, filter_order, cal_intensity, cal, rp2_sampling_rate, pa5_connected, narrowband_bounds);   %Set up the stimulus on the RP2.
            end
            catch_trial = (rand < catch_trial_prob);        %Randomly determine if the next trial is a catch trial.
            atten = cal_intensity - int;                    %Find the attenuation as the difference between the calibrated and desired intensities.

            if handles.recording    %If we're recording...
                buffsize = ceil(rz5_sampling_rate*(spont_delay + holdtime + target_response_limit + post_target_recording));  %Calculate the buffer size.
                if ~rz5.SetTagVal('buffsize',buffsize);                     %Set the buffer size on the RZ5.
                    textbox.printLine(' Could set buffers on the RA16s.');
                    textbox.printLine('');
                end
                zbus.zBusTrigB(0,0,10);                             %Reset the recording buffers with the zBus B trigger.
            end
        else                        %If this was a ruined trial...
            trial = trial - 1;      %...subtract from the incremented trial number.
        end
                
        %If after resetting the zBus there's still errors on the TDT system, we'll play a warning sound and then end the program.
        if run == 0;
            if exist(crash_warning_sound,'file')
                [signal, Fs] = wavread(crash_warning_sound);   	%Load the crash warning sound
                soundsc(signal,Fs);                            	%Play the crash warning as loud as possible.
            end
            booth(booth_number).status = 'RP2 Disconnected!  Program Aborted!'; %Set the webpage to show the RP2 connection has crashed.
        end
        
        %If we're connected to an ftp server, we can update the status
        %webpage to keep tabs on training away from the lab.
        if ftp_connected
            booth(booth_number).trial = trial;
            booth(booth_number).trial_time = now;
            booth(booth_number).feedings = feedings;
            [booth, ftp_connected] = Update_Webpage(booth, web_status_file, ftp_server, booth_number);
        end
                
        %Last, we'll make sure that we've give incorrect trials a sufficiently long time-out.
        if ~correct_trial && any(outcome == 'AMF');
            while toc < holdtime + spont_delay + time_out_duration
                run = str2double(get(handles.lblRun,'String'));    %We can override time-outs with forced feedings if we want to.
                pause(0.1);
                if run ~= 1
                    break;
                end
            end
            disp(['Time-out: ' num2str(toc - holdtime - spont_delay) ' seconds.']);
        end  
        if pa5_connected
            pa5.SetAtten(atten);          	%Set the attenuaton on the PA5.
        end
        rp2.SetTagVal('cagelights',1);      %Turn the cage lights on.
        
        rp2.SetTagVal('cue_enable',~catch_trial);       %Enable/Disable the burst/gap depending on whether or not the next trial is a catch trial.
        
    elseif run == 2
        %If we want to feed the rat, it's best to play the tones with the
        %feeders so that they begin to associate.
        invoke(rp2,'SetTagVal','cue_enable',1);     %Enable playing of the tones.
        zbus.zBusTrigA(0,0,10);                     %Trigger presentation of the stimulus.
        pause(holdtime);                            %Pause through the hold time.
        invoke(rp2, 'SoftTrg', 1);                  %Trigger food right.
        feedings = feedings + 1;                    %Add 1 to the number of feedings.
        textbox.printLine(['Operator forced feeding: feeding number ' num2str(feedings) '.']);
        if any(handles.stage == [1:4,11])        %Noiseburst stages.
            textbox.printLine(['    NoiseBurst: center frequency = ' num2str(round(stimset(stim_index))) ...
                ' Hz,  bandwidth = ' num2str(bandwidth) ' oct, intensity = ' num2str(int) ' dB.']);
        elseif any(handles.stage == [5:6,12:14])    %Noisegap stages.
            textbox.printLine(['    NoiseGap: center frequency = ' num2str(round(stimset(stim_index))) ...
                ' Hz,  bandwidth = ' num2str(bandwidth) ' oct, intensity = ' num2str(int) ' dB.']);
        elseif any(handles.stage == 7:8)    %Toneburst stages.
            textbox.printLine(['    ToneBurst: frequency = ' num2str(round(stimset(stim_index))) ...
                ' Hz, intensity = ' num2str(int) ' dB.']);
        elseif any(handles.stage == 9:10)    %Tonegap stages.
            textbox.printLine(['    ToneGap: frequency = ' num2str(round(stimset(stim_index))) ...
                ' Hz, intensity = ' num2str(int) ' dB.']);
        end
        textbox.printLine('');
        [holdtime, hold_set, hold_step] = holdtime_generator(hold_step, hold_set, handles.stage);   %Generate a new hold time.
        rp2.SetTagVal('cue_delay',1000*(holdtime+spont_delay));	%Set the hold time on the RP2, in milliseconds.
        catch_trial = (rand < catch_trial_prob);        %Randomly determine if the next trial is a catch trial.
        rp2.SetTagVal('cue_enable',~catch_trial);       %Enable/Disable the burst/gap depending on whether or not this is a catch trial.
        if handles.recording    %If we're recording, we'll
            buffsize = ceil(rz5_sampling_rate*(spont_delay + holdtime + target_response_limit + post_target_recording));  %Calculate the buffer size.
            if ~rz5.SetTagVal('buffsize',buffsize);                     %Set the buffer size on the RZ5.
                textbox.printLine(' Could set buffers on the RA16s.');
                textbox.printLine('');
            end
            zbus.zBusTrigB(0,0,10);                             %Reset the recording buffers with the zBus B trigger.
        end
        
        %Finally, we'll set the run label back to "1".
        set(handles.lblRun,'String','1');
        set(handles.lblFeeding,'String',num2str(feedings));
        %guidata(hObject, handles);
    end
    pause(0.01);
end
% End of the main behavior loop ***************************************************************************************************************

%% Turn off the cage lights and deactivate the RP2 and RA16s.
rp2.SetTagVal('cagelights',0);              %Turns the lights off.
rp2.Halt;                                   %Halt the RCX on the RP2.
rp2.ClearCOF;                               %Clear the RCX off the RP2.
if handles.recording                        %If we were recording....
        rz5.Halt;                           %...halt the RZ5...
        rz5.ClearCOF;                      	%...and clear the RCX file.
end
textbox.printLine('Shutdown of project done.');


textbox.printLine('');


%% Close the java text file writer.
writer.flush;   %Flush the text file writing program.
writer.close;   %Close the text file.


%% Close all neural recording files.
fclose('all');


%% Update the webpage to show the booth as empty.
% if ftp_connected        %If we're connected to the OU network...
%     if ~strcmp(booth(booth_number).status,'RP2 Disconnected!  Program Aborted!')   %If the program crashed, keep that listed on the webpage.
%         booth(booth_number).rat = 'Unoccupied';     %Otherwise, this was a regular shutdown, change the booth status to "Unoccupied".
%     end
%     [booth, ftp_connected] = Update_Webpage(booth, web_status_file, ftp_server, booth_number);  %#ok<NASGU> Update the webpage.
%     close(ftp_server);                          %Close the ftp connection.
%     if exist(['C:\' web_status_file],'file')	%Delete the stored HTML file if it exists.
%         delete(['C:\' web_status_file]);
%     end
%     if exist(['C:\' web_status_file(1:length(web_status_file)-5) '.bin'],'file')	%Delete the stored online binary file if it exists.
%         delete(['C:\' web_status_file(1:length(web_status_file)-5) '.bin']);
%     end
% end
% 
% if strcmp(booth(booth_number).status,'RP2 Disconnected!  Program Aborted!')   %If the program crashed, send email alerts.
%     setpref('Internet','E_mail','ounellab@gmail.com');          %Use the lab address as the sender address.
%     setpref('Internet','SMTP_Server','smtp.gmail.com');         %Set the SMTP Server to Gmail's SMTP server.
%     setpref('Internet','SMTP_Username','ounellab@gmail.com');   %Set the SMTP username to the lab address.
%     setpref('Internet','SMTP_Password','Ratbrain04');           %The lab address password is the standard lab password.
%     props = java.lang.System.getProperties;                     %To set up the SMTP Authentication required by Google, we'll have to mess with Java properties.
%     props.setProperty('mail.smtp.auth','true');                 %Turn on SMTP authentication.
%     props.setProperty('mail.smtp.socketFactory.class', 'javax.net.ssl.SSLSocketFactory');   %Create a Java class for the SMTP port.
%     props.setProperty('mail.smtp.socketFactory.port','465');    %Set the port class to 465.
%     sendmail(alert_emails,'TDT System Crash!',['Booth #' num2str(booth_number) ': ' handles.ratname ' crashed at ' datestr(now,14) '.']);   %Send the alert email.
% end
    
%% Save the behavior data to the main structure if there's been 20 or more trials.
if trial >= 20
    %If some other program is already accessing the data file, we'll wait for it to finish modifying it before we load it.
    cd(datapath);   %Change the directory to the main data path.
    checker = 1;    %This boolean variable controls the loop that looks for the placeholder file.
    if exist(placeholder,'file')    %If a placeholder file exists, the structure is already in use.
        textbox.printLine('Central structure currently in use, please wait...');
        tic;        %Start a wait timer.
        while exist(placeholder,'file')     %Wait while the placeholder file still exists.
            pause(0.5);
            if toc > 120       %If the folder is occupied for more than 60 seconds, we'll just skip the save.
                textbox.printLine('Central structure is occupied, skipping the central save.');
                checker = 0;
                break;
            end
        end
    end
    if checker && ~strcmpi(handles.ratname,'Test')      %If the placeholder doesn't exist and this isn't a test run...
        fid = fopen(placeholder,'w');	%Create the placeholder file.
        fclose(fid);  
        textbox.printLine('Now saving data...');
        if exist(datafile,'file')
            load(datafile);
        end
        %Now save all the sessions results to the main data structure.
        detectdata(currentrat).stage = handles.stage;
        detectdata(currentrat).ratname = handles.ratname;
        detectdata(currentrat).session(currentsession).daycode = handles.daycode;
        detectdata(currentrat).session(currentsession).stage = handles.stage;
        detectdata(currentrat).session(currentsession).booth_number = booth_number;
        detectdata(currentrat).session(currentsession).trials = trial;
        detectdata(currentrat).session(currentsession).clock_reading = data.clock_reading'; 
        detectdata(currentrat).session(currentsession).holdtime = data.holdtime'; 
        detectdata(currentrat).session(currentsession).timeheld = data.timeheld';
        detectdata(currentrat).session(currentsession).outcome = data.outcome'; 
        detectdata(currentrat).session(currentsession).nosepoke_response = data.nosepoke_response';
        detectdata(currentrat).session(currentsession).freq = data.freq';
        detectdata(currentrat).session(currentsession).bandwidth = data.bandwidth';
        detectdata(currentrat).session(currentsession).duration = data.duration';
        detectdata(currentrat).session(currentsession).intensity = data.intensity';
        detectdata(currentrat).session(currentsession).correct_trial = data.correct_trial;
        detectdata(currentrat).session(currentsession).hits = data.hits; 
        detectdata(currentrat).session(currentsession).misses = data.misses; 
        detectdata(currentrat).session(currentsession).false_alarms = data.false_alarms; 
        detectdata(currentrat).session(currentsession).correct_rejections = data.correct_rejections;
        detectdata(currentrat).session(currentsession).aborts = data.aborts;
        detectdata(currentrat).session(currentsession).catch_trial = data.catch_trial';
        detectdata(currentrat).session(currentsession).target_response_limit = target_response_limit;
        save(datafile,'detectdata');          %Resave the central data structure.
        delete(placeholder);    %Delete the placeholder file to allow other programs access.
        
        %Backup the data structure onto the hard drive of the local computer.
        mkdir(backuppath);      %Make a backup path if it doesn't exist.
        cd(backuppath);         %Step into the backup path.
        save('noise_gap_detection_data','detectdata');  %Save the central data structure. 
        
    end
    
%%%%Added in to output dprime at session end
%load(datafile);
a = find([detectdata(currentrat).session(:).stage] == handles.stage);
if any(handles.stage == [2:6, 13:14])        %Holdtime training stages.
                    outcomes = char(vertcat(detectdata(currentrat).session(a).outcome));	%Grab outcomes.
                    outcomes(outcomes == 'A') = [];                                         %Kick out all abort trials.
                    numtrials = length(outcomes);                                           %Save the total number of completed trials.
                    if length(outcomes) > transition_trials                                 %If the rat's completed more than the necessary number of trials.
                        outcomes(1:length(outcomes)-transition_trials) = [];                %Shorten the outcome list to only a recent block of trials.
                    end


            d = dprime(sum(outcomes == 'H'),sum(outcomes == 'M'),sum(outcomes == 'F'),sum(outcomes == 'C'));
                    textbox.printLine([num2str(numtrials) ' completed trials in stage ' num2str(handles.stage) ...
                        ', d-prime(' num2str(min([transition_trials, numtrials])) ') = ' num2str(d,'% 2.2f') '.']);
	
        end
    
    %We'll also copy the text file onto the network drive.
    if exist('Z:\Gap Detection Startle','dir')  
        cd(datapath);                                   %Change to the main data folder.
        mkdir(handles.ratname);                  %Make a folder for this rat if it doesn't yet exist.
        cd([datapath '\' handles.ratname]);      %Step into this rat's folder.
        mkdir([handles.ratname ' - Stage ' num2str(handles.stage)]);     %Make a folder for this stage if it doesn't yet exist.
        cd([datapath '\' handles.ratname '\' handles.ratname ' - Stage ' num2str(handles.stage)]);    %Step into that folder.
        %Copy the backup text file to the network server.
        copyfile([backuppath '\' handles.ratname '\' handles.ratname ' - Stage ' num2str(handles.stage) '\' filename '.txt'],...
            [datapath '\' handles.ratname '\' handles.ratname ' - Stage ' num2str(handles.stage) '\' filename '.txt']);
        textbox.printLine(['Copying ' filename '.txt to the network drive...']);
    end
    textbox.printLine('Data saved.');
    textbox.printLine('');    
else    %If there haven't been 20 trials in this session.
    %Go into the back-up data directory.
    cd([backuppath '\' handles.ratname '\' handles.ratname ' - Stage ' num2str(handles.stage)]); 
    textbox.printLine('Less than 20 trials, trashing the text file.');
    delete([filename '.txt']);      %Delete the text file for this session.
    
    %%%%Added in to output dprime at session end
                    load(datafile);
                    a = find([detectdata(currentrat).session(:).stage] == handles.stage);
                    if any(handles.stage == [2:3,5])        %Holdtime training stages.
                    outcomes = char(vertcat(detectdata(currentrat).session(a).outcome));	%Grab outcomes.
                    outcomes(outcomes == 'A') = [];                                         %Kick out all abort trials.
                    numtrials = length(outcomes);                                           %Save the total number of completed trials.
                    if length(outcomes) > transition_trials                                 %If the rat's completed more than the necessary number of trials.
                        outcomes(1:length(outcomes)-transition_trials) = [];                %Shorten the outcome list to only a recent block of trials.
                    end


                    d = dprime(sum(outcomes == 'H'),sum(outcomes == 'M'),sum(outcomes == 'F'),sum(outcomes == 'C'));
                    textbox.printLine([num2str(numtrials) ' completed trials in stage ' num2str(handles.stage) ...
                        ', d-prime(' num2str(min([transition_trials, numtrials])) ') = ' num2str(d,'% 2.2f') '.']);
            clear detectdata
end
    
end



cd(programpath);    %Return to the main program path.


%SUB FUNCTIONS*************************************************************************************************************************************
%**************************************************************************************************************************************************
%**************************************************************************
%**********************************************************************************************************************************************************************************************************************
function stimulus_maker(rp2, stage, freq, intensity, bandwidth, filter_order, cal_intensity, cal, rp2_sampling_rate, pa5_connected, narrowband_bounds)
if any(stage == [1:6,11:14])                %If this is a noisegap or noiseburst stage...
    rp2.SetTagVal('noise_amp',0);           %Zero the noise amplitude before changing the noise.
    signal = 1-2*rand(1,round(10*rp2_sampling_rate));	%Create a 10-second random noise signal.
    if freq ~= 0                    %If the specified noise isn't bandpass noise....
        if any(stage == [13:14]) && narrowband_bounds == 0;    %If it's stage 13 or 14 and bandwidth is in linear mode
            bandwidth = 1000;     %set the bandwidth to 1000 Hz
            lowcutoff = freq - 0.5*(bandwidth);
            highcutoff = freq + 0.5*(bandwidth);
            cutoffs = [lowcutoff, highcutoff];                              %Find the cut-off frequencies for the noise filter.
        else
            cutoffs = pow2(log2(freq) + [-0.5,0.5]*bandwidth); 	%Find the cut-off frequencies for the noise filter.
        end
        
        [b, a] = butter(filter_order/2,cutoffs*2/rp2_sampling_rate);	%Calculate Nth-order Butterworth filter coefficients.
        signal = filter(b,a,signal);                      	%Bandpass filter the random noise signal.
        freq = floor(mean(cutoffs));                       	%Find the center frequency for the octave band filter.
        bandwidth = floor(cutoffs(2)-cutoffs(1));         	%Find the bandwidth of the octave band filter.
    else                            %If the specified noise is bandpass noise...
        bandwidth = 0;                                      %Set the bandwidth to zero.
        filter_order = 0;                                   %Set the filter order to zero.
    end
    if any(stage == [1:4,11])                               %If this is a noiseburst stage...
        signal = signal(1:round(rp2_sampling_rate));    	%Shorten the signal to 1 second.
    end
    signal = signal/max(abs(signal));                     	%Scale the signal by it's absolute maximum.
    rp2.SetTagVal('noise_size',length(signal));             %Set the buffer size to the length of the signal.
    rp2.WriteTagV('noise_signal',0,signal);                 %Write the signal to the serial output buffer.
    disp(['Frequency = ' num2str(freq) ' Hz']);
    disp(['Bandwidth = ' num2str(bandwidth) ' Hz']);
    temp = cal(:,1:3);                                                      %Grab the first 3 columns of the calibration matrix.
    temp(:,1) = abs(temp(:,1) - freq);                                      %Find the difference with each calibrated frequency.
    temp(:,2) = abs(temp(:,2) - bandwidth);                                 %Find the difference with each calibrated bandwidth.
    temp(:,3) = abs(temp(:,3) - filter_order);                              %Find the difference with each calibrated filter order.
    [temp,i] = sortrows(temp,1:3);                                          %Sort the differences, returning the original indices.
    a = cal(i(1),4:5);                                                      %Find the calibration constants for the specified noise.
    if pa5_connected                                        %If the PA5 is connected...
        a = exp((cal_intensity - a(1))/a(2));               %...calibrate to a fixed calibration intensity and use the PA5 to knock it down.
    else                                                    %Otherwise, if the PA5 isn't connected...
        a = exp((intensity - a(1))/a(2));                   %...calibrate to the desired intensity.
    end
    rp2.SetTagVal('noise_amp',a);                           %Set the noise amplitude to the specified calibration amplitude.
else                            %If this is a tonegap or toneburst stage...
	rp2.SetTagVal('tone_amp',0);          	%Zero the tone amplitude before changing the noise.
    rp2.SetTagVal('tone_freq',freq);        %Set the tone frequency on the tone generator in the RP2.
    freq = floor(freq);                     %Floor the frequency for better matching.
    a = cal(find(freq >= cal(:,1),1,'last'),2:3);	%Find the calibration constants for the specified tone frequency.
    if pa5_connected                                        %If the PA5 is connected...
        a = exp((cal_intensity - a(1))/a(2));               %...calibrate to a fixed calibration intensity and use the PA5 to knock it down.
    else                                                    %Otherwise, if the PA5 isn't connected...
        a = exp((intensity - a(1))/a(2));                   %...calibrate to the desired intensity.
    end
    rp2.SetTagVal('tone_amp',a);          	%Set the tone amplitude to the specified calibration amplitude.
end


%**************************************************************************************************************************************************
%**************************************************************************************************************************************************
function [stim_index, stimset, thresh_index, threshset] = stimset_generator(stage, freqs, block_size, intensities)
stim_index = 1;                	%Start at the beginning of a new stimset.
thresh_index = 1;
if any(stage == [1:4,7:8,11])  	%If the stage is noisburst or tone detection...
    stimset = freqs(randperm(length(freqs)))';          %Randomize the frequency list and use that as the stimulus set.
    threshset = [];
elseif stage == 14  %if the stage is the dynamic intensity noisegap test
    stimset = ones(block_size,1)*(1:length(freqs));     %Create a 2D matrix of frequency indices repeated for the given block size.
    stimset = stimset(:,randperm(size(stimset,2)));     %Randomize the order of the frequencies.
    stimset = stimset(1:size(stimset,1)*size(stimset,2))';	%Vertically concatenate the stimset into a list of frequency indices.
    threshset = stimset;    %catch the indexes so they can also be used to match the intensities with their frequencies
    stimset = freqs(stimset)';
    threshset = intensities(threshset)';
else                            %Otherwise it must be gap detection...
    stimset = ones(block_size,1)*(1:length(freqs));     %Create a 2D matrix of frequency indices repeated for the given block size.
    stimset = stimset(:,randperm(size(stimset,2)));     %Randomize the order of the frequencies.
    stimset = stimset(1:size(stimset,1)*size(stimset,2))';	%Vertically concatenate the stimset into a list of frequency indices.
    stimset = freqs(stimset)';                           %Switch out the frequency indices for the actual frequency values.
    threshset = [];
end
disp('Stimset:');
disp(stimset);


%**************************************************************************************************************************************************
%**************************************************************************************************************************************************
function [holdtime, hold_set, hold_step] = holdtime_generator(hold_step, set, stage)
if stage == 1                   %Nosepoke training.
    sets = 1;
    lower_limit = 0.05;
    upper_limit = 0.1;
    lower_increment = 0;
    upper_increment = 0;
elseif stage == 2               %Hold training #1
    sets = 40;
    lower_limit = 0.1;
    upper_limit = 0.2;
    lower_increment = 0.1;
    upper_increment = 0.3;
elseif any(stage == 3:2:9)      %Hold Training #2
    sets = 40;
    lower_limit = 0.1;
    upper_limit = 1;
    lower_increment = 0.5;
    upper_increment = 0.75;
else                            %Testing
    sets = 5;
    lower_limit = 0.1;
    upper_limit = 1;
    lower_increment = 0.08;
    upper_increment = 1.4;
end       
if hold_step > 15 && set ~= sets
    set = set + 1;
    hold_step = 1;
end
lower_limit = lower_limit + (set-1)*lower_increment;
upper_limit = upper_limit + (set-1)*upper_increment;
holdtime = rand*(upper_limit-lower_limit) + lower_limit;
hold_set = set;


%**************************************************************************************************************************************************
%**************************************************************************************************************************************************
function Map_Plots(cur_perf, prev_perf, freqs, intensities)
cla;            	%Clear the plot.
if length(intensities) == 1                 %If this is a training stage with one intensity...
    hold on;            %Hold the plot.
    colors = jet(length(freqs));                %Grab unique colors for each frequency.
    for i = 1:length(freqs)                 %Step through the target sounds.
        if cur_perf(i,1,1) > 0             	%If there are any current hits at all...
            temp = cur_perf(i,1,1)/sum(cur_perf(i,1,1:2));                      %Find the hit rate.
            rectangle('position',[i-0.4,0,0.4,temp],'facecolor',colors(i,:).^2);  	%Plot a bar for hit rate.
            ci = 1.96*sqrt((temp.*(1-temp))/sum(cur_perf(i,1,1:2)));        	%Find 95% confidence intervals.
            line([i,i]-0.2,temp+[-ci,ci],'linewidth',1,'color','k');               	%Draw the vertical error bars.
            line(i-0.2+[-0.02,0.02],temp(1)+[ci,ci],'linewidth',1,'color','k');    	%Upper error limit.
            line(i-0.2+[-0.02,0.02],temp(1)-[ci,ci],'linewidth',1,'color','k');    	%Lower error limit.
        end
    	if cur_perf(i,1,3) > 0             	%If there are any current false alarms at all...
            temp = cur_perf(i,1,3)/sum(cur_perf(i,1,3:4));                      %Find the false alarm rate.
            rectangle('position',[i,0,0.4,temp],'facecolor',colors(i,:)/1.5);  	%Plot a bar for false alarm rate.
            ci = 1.96*sqrt((temp.*(1-temp))/sum(cur_perf(i,1,3:4)));        	%Find 95% confidence intervals.
            line([i,i]+0.2,temp+[-ci,ci],'linewidth',1,'color','k');               	%Draw the vertical error bars.
            line(i+0.2+[-0.02,0.02],temp(1)+[ci,ci],'linewidth',1,'color','k');    	%Upper error limit.
            line(i+0.2+[-0.02,0.02],temp(1)-[ci,ci],'linewidth',1,'color','k');    	%Lower error limit.
        end
        if prev_perf(i,1,1) > 0             	%If there are any historical hits at all...
            temp = prev_perf(i,1,1)/sum(prev_perf(i,1,1:2));                  	%Find the hit rate.
            line(i+[-0.4,0],[temp,temp],'color',colors(i,:)/2,'linewidth',4); 	%Plot a thick line to show previous performance.
        end
    	if prev_perf(i,1,3) > 0             	%If there are any historical false alarms at all...
            temp = prev_perf(i,1,3)/sum(prev_perf(i,1,3:4));                  	%Find the false alarm rate.
            line(i+[0,0.4],[temp,temp],'color',colors(i,:)/2.5,'linewidth',4); 	%Plot a thick line to show previous performance.
        end
    end
    temp = {};                      %Create an empty cell array to hold sound names for axis labels.
    for i = 1:length(freqs)         %Step through each tested frequency.
        if freqs(i) == 0            %If the frequency is 0...
            temp{i} = 'BBN';        %...label it as broadband noise.
        else                        %Otherwise...
            temp{i} = [num2str(freqs(i)/1000,'% 2.1f') ' kHz']; %...label it by center frequency.
        end
    end
    b = 1:length(temp);      %Set an x-axis tick at each bar.
    set(gca,'xtick',b,'xticklabel',[]);     
    set(gca,'ylim',[0,1.3],'xlim',[0.5,length(temp)+0.5]);              	%Set the y- and x-axis limits.
    set(gca,'ytick',[0:0.2:1,1.2],'yticklabel',{'0%','20%','40%','60%','80%','100%','d'''},'fontsize',12,'fontweight','bold');  %Label the y-axis ticks as percents.
    c=get(gca,'YTick');             %Grab the y-axis ticks.
    %Use the text function to create rotated axis labels.
    text(b,repmat(c(1)-.1*(c(2)-c(1)),length(b),1),temp,'HorizontalAlignment','right','rotation',90,...
        'verticalalignment','middle','interpreter','none','fontweight','bold','fontsize',10);
    ylabel('Hit/False Alarm Rate','fontweight','bold','fontsize',14);                   %Label the y-axis.
    rectangle('position',[0.5,1,length(temp)+1,0.4],'facecolor','w','edgecolor','k'); 	%Make a blank space to write d-primes.
    for i = 1:length(freqs)
        temp = dprime(cur_perf(i,1,1),cur_perf(i,1,2),cur_perf(i,1,3),cur_perf(i,1,4));     %Find the current d' value for this distractor.
        temp(2) = dprime(prev_perf(i,1,1),prev_perf(i,1,2),prev_perf(i,1,3),prev_perf(i,1,4));	%Find the historical d' value for this distractor.
        text(i,1.15,[num2str(temp(1),'% 2.2f') ' (' num2str(temp(2),'% 2.2f') ')'],'verticalalignment',...
            'middle','horizontalalignment','center','fontsize',9,'rotation',90,'fontweight','bold');   %Print the d' value on the graph.
    end
else                                        %If this is a testing stage with multiple intensities...
    temp = 0.5*ones(size(cur_perf,1)+1,size(cur_perf,2));    %Make a temporary matrix to hold a threshold map.
    for i = 1:size(prev_perf,1)              %Step through by frequency.
        for j = 1:size(prev_perf,2)          %Step through by intensity.
            if sum(prev_perf(i,j,1:2))    	%If there's any hits or misses...
                temp(i,j) = prev_perf(i,j,1)/sum(prev_perf(i,j,1:2));     %Find the hit rate.
            end
        end
    end
    prev_perf = temp';                      %Save the previous performance in map format
    temp = 0.5*ones(size(cur_perf,1)+1,size(cur_perf,2));    %Make a temporary matrix to hold a threshold map.
    for i = 1:size(cur_perf,1)              %Step through by frequency.
        for j = 1:size(cur_perf,2)          %Step through by intensity.
            if sum(cur_perf(i,j,1:2))    	%If there's any hits or misses...
                temp(i,j) = cur_perf(i,j,1)/sum(cur_perf(i,j,1:2));     %Find the hit rate.
            end
        end
    end
    temp = [temp'; prev_perf; zeros(1,size(temp,1))];
    surf(temp,'edgecolor','none');	%Plot the map as a surface.
    view(0,90);                   	%Orient the map.
    box on;                        	%Put a box around the plot.
    temp = {};                      %Create an empty cell array to hold sound names for axis labels.
    for i = 1:length(freqs)         %Step through each tested frequency.
        if freqs(i) == 0            %If the frequency is 0...
            temp{i} = 'BBN';        %...label it as broadband noise.
        else                        %Otherwise...
            temp{i} = [num2str(freqs(i)/1000,'% 2.1f') ' kHz']; %...label it by center frequency.
        end
    end
    b = 0.5+(1:length(temp));                               %Set an x-axis tick at each bar.
    set(gca,'xtick',b,'xticklabel',[]);                    
    set(gca,'ylim',[1,2*length(intensities)+1],'xlim',[1,length(freqs)+1]);	%Set the y- and x-axis limits.
    c=get(gca,'ylim');             %Grab the y-axis ticks.
    %Use the text function to create rotated axis labels.
    text(b,repmat(c(1)-0.005*(c(2)-c(1)),length(b),1),temp,'HorizontalAlignment','right','rotation',90,...
        'verticalalignment','middle','interpreter','none','fontweight','bold','fontsize',10);
    set(gca,'ytick',1.5:2:100,'yticklabel',intensities(1:2:length(intensities)),'fontsize',12,'fontweight','bold');  %Label the y-axis ticks as percents.
    line([1,length(freqs)+1],[1,1]*length(intensities)+1,[2 2],'color','k');
    ylabel('Current/Historical Intensity (dB)','fontweight','bold','fontsize',14);                   %Label the y-axis.
end


%**************************************************************************************************************************************************
%**************************************************************************************************************************************************
function Performance_Plots(data)
hold on;                                        %There may already be neural recordings plotted, so hold on and plot psychophysical performance on top.
for i = 1:length(data.clock_reading)            %Step through each trial...
    x = data.clock_reading(i);                  %Use the clock reading for this as the x coordinate.
    text(x,0,[' ' num2str(data.freq(i)/1000,'% 2.2f') ' kHz'],'horizontalalignment','left','verticalalignment','middle','fontsize',6,'color',[0.7 0.7 0.7],'rotation',90);
    text(x,data.holdtime(i),'_','horizontalalignment','center','verticalalignment','bottom','fontsize',8,'color','b','interpreter','none','fontweight','bold');
end
a = find(data.outcome == 'A');  %Find all aborts and plot time held with a red "A".
text(data.clock_reading(a),data.timeheld(a),'A','horizontalalignment','center','verticalalignment','bottom','fontsize',8,'color','r','fontweight','bold');
a = find(data.outcome == 'H');  %Find all hits and plot time held with a green "H".
text(data.clock_reading(a),data.timeheld(a),'H','horizontalalignment','center','verticalalignment','bottom','fontsize',8,'color',[0 0.5 0],'fontweight','bold');
a = find(data.outcome == 'M');  %Find all misses and plot time held with a red "M".
text(data.clock_reading(a),data.timeheld(a),'M','horizontalalignment','center','verticalalignment','bottom','fontsize',8,'color','r','fontweight','bold');
a = find(data.outcome == 'F');  %Find all false alarms and plot time held with a red "F".
text(data.clock_reading(a),data.timeheld(a),'F','horizontalalignment','center','verticalalignment','bottom','fontsize',8,'color','r','fontweight','bold');
a = find(data.outcome == 'C');  %Find all correct rejections and plot time held with a cyan "C".
text(data.clock_reading(a),data.timeheld(a),'C','horizontalalignment','center','verticalalignment','bottom','fontsize',8,'color','c','fontweight','bold');
a = get(gca,'xtick');           %Find the automatically set x-axis ticks.
set(gca,'xticklabel',datestr(a,15),'FontWeight','Bold','FontSize',12);  %Use datestr to find the corresponding times for those tick marks.
xlabel('Session Time','FontWeight','Bold','FontSize',14);               %Label the x-axis as session time.
ylabel('Hold Time (s)','FontWeight','Bold','FontSize',14);              %Label the y-axis as hold time.
hold off;                                                               %Release the hold on the plot.
% ylim([0,1]);





%**************************************************************************************************************************************************
%**************************************************************************************************************************************************
%This subfunction updates the webpage that we use to keep track of training sessions online.
function [booth, ftp_connected] = Update_Webpage(booth, web_status_file, ftp_server, booth_number)
binary_file = [web_status_file(1:length(web_status_file)-5) '.bin'];    %Grab the file name for the binary tracking file.
for i = 1:4     %For all booths other than the one we're connected to, we'll first assume they're unoccupied.
    if i ~= booth_number
        booth(i).rat = 'Unoccupied';
    end
end
curdir = cd;    %We'll grab the current directory so we can get back to it.
cd('C:\');      %We save the HTML file to the C:\ drive so that network problems don't affect it.
try             %#ok<TRYNC>
    mget(ftp_server,binary_file);   %Download the binary tracking file to the C: drive.
end
if exist(curdir,'dir')    %If the previous directory still exists, i.e. the network hasn't crashed, return to it.
    cd(curdir);
end
if exist(['C:\' binary_file],'file');  %If the online binary tracking file exists, we'll read in information from other booths.
    web_fid = fopen(['C:\' binary_file],'r');       %Open the file for reading.
    while ~feof(web_fid)
        i = fread(web_fid, 1, 'uint8');            	%Read booth number.
        if ~isempty(i)
            temp = fread(web_fid, 1, 'uint8');           %Read the number of characters in the rat name.
            rat = char(fread(web_fid, temp, 'char')');        %Read in the rat name.
            if ~strcmp(rat,'Unoccupied') && ~strcmp(rat,'Unknown')       %If the booth isn't "Unoccupied", read in the session information.
                temp = fread(web_fid, 1, 'uint8');              %Read the number of characters in the task type.
                task = char(fread(web_fid, temp, 'char')');    	%Read in the task type.
                stage = fread(web_fid, 1, 'uint8');         	%Read booth number.
                start_time = fread(web_fid, 1, 'float64');      %Read start time.
                trial = fread(web_fid, 1, 'uint16');          	%Read most recent trial number.
                trial_time = fread(web_fid, 1, 'float64');      %Read the most recent trial time.
                feedings = fread(web_fid, 1, 'uint16');        	%Read the number of feedings.
                dprime = fread(web_fid, 1, 'float32');          %Read the current d-prime.
                temp = fread(web_fid, 1, 'uint8');             	%Read the number of characters in the booth status.
                status = char(fread(web_fid, temp, 'char')');   %Read the booth status.
                if i ~= booth_number            %Ignore information about the current booth.
                    booth(i).rat = rat;
                    booth(i).task = task;
                    booth(i).stage = stage;
                    booth(i).start_time = start_time;
                    booth(i).trial = trial;
                    booth(i).trial_time = trial_time;
                    booth(i).feedings = feedings;
                    booth(i).dprime = dprime;
                    booth(i).status = status;
                end
            end
        end
    end
    fclose(web_fid);
end
try
    web_fid = fopen(['C:\' binary_file],'w');                   %Overwrite the downloaded binary tracking file.
    for i = 1:length(booth);                                    %Stepping through "booth", create a new online binary file.
        fwrite(web_fid,i,'uint8');                             	%Write booth number.
        fwrite(web_fid,length(booth(i).rat),'uint8');          	%Write number of characters in rat name.
        fwrite(web_fid, booth(i).rat,'char');                   %Write rat name.
        if ~strcmp(booth(i).rat,'Unoccupied') && ~strcmp(booth(i).rat,'Unknown')
            fwrite(web_fid,length(booth(i).task),'uint8');     	%Write number of characters in task type.
            fwrite(web_fid, booth(i).task,'char');             	%Write the task type.
            fwrite(web_fid, booth(i).stage,'uint8');           	%Write stage.
            fwrite(web_fid, booth(i).start_time, 'float64');    %Write start time.
            fwrite(web_fid, booth(i).trial, 'uint16');          %Write most recent trial number.
            fwrite(web_fid, booth(i).trial_time, 'float64');    %Write most recent trial time.
            fwrite(web_fid, booth(i).feedings, 'uint16');       %Write the number of feedings.
            fwrite(web_fid, booth(i).dprime, 'float32');        %Write the current d-prime of the session.
            fwrite(web_fid, length(booth(i).status), 'uint8');  %Write the number of characters in the booth status.
            fwrite(web_fid, booth(i).status, 'char');           %Write the booth status.
        end
    end
    fclose(web_fid);    %Close the online binary file.
    web_fid = fopen(['C:\' web_status_file],'wt');              %Overwrite the downloaded HTML file.
    fprintf(web_fid,'%s\n','<HEAD><meta http-equiv="refresh" content = "20" ></HEAD><font size = 4>');	%Print HTML header.
    for i = 1:length(booth);                                    %Stepping through "booth", create a new webpage.
        fprintf(web_fid,'%s\n',['<b>Booth ' num2str(i) ': ' booth(i).rat '</b><br>']);   %Print rat name.
        if ~strcmp(booth(i).rat,'Unoccupied') && ~strcmp(booth(i).rat,'Unknown')
            fprintf(web_fid,'Task: %s\n', [booth(i).task '<br>']);                         	%Print task type.
            fprintf(web_fid,'Stage: %s\n', [num2str(booth(i).stage) '<br>']);           	%Print stage.
            fprintf(web_fid,'Start Time: %s\n', [datestr(booth(i).start_time,14) '<br>']); 	%Print program start time.
            fprintf(web_fid,'Trial: %s\n', [num2str(booth(i).trial) ', ' datestr(booth(i).trial_time,14) '<br>']);  %Print most recent trial number and trial time.
            fprintf(web_fid,'Feedings: %s\n', [num2str(booth(i).feedings) '<br>']);         %Print number of feedings.
            fprintf(web_fid,'d'': %s\n', [num2str(booth(i).dprime) '<br>']);                %Print the current d-prime.
            if strcmp(booth(i).status,'Running')            %Print color-coded program status.
                fprintf(web_fid,'Status: %s\n', ['<font color = "#151B8D">' booth(i).status '</font color><br>']);
            elseif strcmp(booth(i).status,'RP2 Disconnected!  Program Aborted!')
                fprintf(web_fid,'Status: %s\n', ['<font color = "#E42217">' booth(i).status '</font color><br>']);
            else
                fprintf(web_fid,'Status: %s\n', ['<font color = "#F87217">' booth(i).status '</font color><br>']);
            end
        end
        fprintf(web_fid,'%s\n', '<br>');        %Print line breaks between booths.
    end
    fprintf(web_fid,'%s\n','</font size>');     %Print HTML footer.
    fclose(web_fid);                            %Close the HTML file.
    mput(ftp_server,['C:\' web_status_file]);   %Upload the new HTML file to the ftp server.
    mput(ftp_server,['C:\' binary_file]);       %Upload the new binary tracking file to the ftp server.
    ftp_connected = 1;
catch   %#ok<CTCH> %If we can't connect to the ftp server, close the connect and cancel further updates.
    close(ftp_server);
    ftp_connected = 0;
end


%**************************************************************************************************************************************************
%**************************************************************************************************************************************************
%This subfunction calculates overall hit/miss/false alarm/correct rejection performance without regard to which distractors are used.
function hmfc = overall_performance(holdtimes, timesheld, outcomes, window)
hmfc = [0 0 0 0];	%We'll simply count actual hits, misses, false alarms, and correct rejections, starting from zero.
hmfc(1) = sum(outcomes == 'H');     %Add up the number of hits.
hmfc(2) = sum(outcomes == 'M');     %Add up the number of misses.
hmfc(3) = sum(outcomes == 'F' | outcomes == 'A');	%Add up the number of false alarms and aborts.
hmfc(4) = sum(outcomes == 'C');    	%Add up the number of correct rejections.
hmfc(4) = hmfc(4) + sum(floor(holdtimes(outcomes ~= 'A')/window));    %Add in the number of virtual correct rejections not from aborts.
hmfc(4) = hmfc(4) + sum(floor(timesheld(outcomes == 'A')/window));    %Add in the number of virtual correct rejections on aborts.