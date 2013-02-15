
%UNTITLED Summary of this function goes here
%   This function randomly presents startles of multiple intensities and
%   obtains the associated startle response. Um, yes....the code probably
%   doesn't make much sense because it's a mauled version of the Rennaker
%   Lab startle testing code that was slapped together in a rush by someone
%   learning to run the TDT for the first time.

%Get subject and setting variables
clear all
savepath = 'Z:\Gap Detection Startle\Behavior Data\';

ratname = input('Enter subject name: ', 's');                               %get the ratname from the user
intensities = [0, 40, 45, 50, 55, 57, 59, 60];                                                   %set the gap fill intensities to be tested as a range using min:max
startleint = 110;            %set the startle intensity
backint = 60;        %Background noise intensity, in dB.
reps = 15;                                                                  %set how many times you want to test each intensity
pre_reps = 6;
intertrial_interval = [30 35];      %Bounds of the inter-trial interval, in seconds.


randomizedints = zeros(1,reps*length(intensities));                         %preallocate an empty array to hold the ints so we can permutate through them
for i = 1:length(intensities)   
    for j = 1:reps
    randomizedints(1,i*reps-reps+1:i*reps)=intensities(i);                       %replace the zeros with the actual ints, in order.
    end
end

randomizedints = randomizedints(randperm(length(randomizedints)));          %randomize them.
temp=[];
temp(1:pre_reps) = backint;
randomizedints = [temp, randomizedints];



%Define paths and filenames the program will use.
rootpath = 'Z:';                                               	%Root path for NEL common programs.
programpath = [rootpath '\Z:\Gap Detection Startle\'];	%Path that contains the startle m-files.
rcxpath = [rootpath '\RPvds Circuits\'];                %Path that contains the RCX files.
% rcxpath = 'C:\RPvds Circuits\';                 %Path that contains the RCX files.
warning off MATLAB:MKDIR:DirectoryExists;               %Turn off the "directory already exists" warning.
localpath = 'C:\Neural Recordings\';            %Local computer folder to write the data files to.
mkdir(localpath);                             	%Make the local folder if it doesn't already exist.
datapath = 'Y:\Startle Data\';                 	%Folder on the lab server to copy the data to at the end of the session.
if exist('D:\','dir')                                   %If there's a second hard drive on this computer...
    recordingpath = 'D:\';                  	%...write the neural recording files to that drive.
else                                                    %Otherwise...
    recordingpath = 'C:\Neural Recordings\';	%...write the neural recording files to a folder on the C: drive.
    mkdir(recordingpath);                    	%Make a C: drive folder to hold neural recordings.
end
rp2_RCX_filename = [rcxpath 'Gap_In_Loaded_Background_Sound_Partial_Fill.rcx']; 	%Name of the RP2 RCX file.
rxn_RCX_filename = [rcxpath 'RZ5_Use_As_Monitor.rcx'];              %Name of the RZ5 RCX file.
    
%Set the default parameter values for testing.
habituate = 0;      %Habituate before testing (0 = no, 1 = yes).
habtime = 0;        %Habituation time, in minutes.
cueprob = 1;      %Probability of any trial being a cued trial.
numtrials = 120;     %Total number of trials.
gapdur = 50;        %Gap cue duration, in milliseconds.
gapdelay = 100;     %Time between the gap and the startler, in milliseconds.


sweeplength = 3000; %Sweeplength for recording startle responses, in milliseconds.
waittime = 600;     %Time to wait in between testing with different background noises, in seconds.
daycodestr = daycode;  %Find today's daycode.


%%%%%%Start Patrick's altered code that allows grabbing Booth 6's
%%%%%%calibration values
userinput = questdlg('Are you using Booth 6? If so, double-check connections.');

if strcmpi(userinput, 'Yes') == 1
    booth = 6;
elseif strcmpi(userinput, 'No') == 1
    booth = load('C:\Booth_Number.txt');	%The number of the booth for this computer is in a text file on the C: drive.
end

%%%%%%End Patrick's altered code.


%Create noise parameters for testing.
center_freqs = 10';         %The user can pick between these center frequencies.
noises = zeros(length(center_freqs),3);     %Pre-allocate a matrix to hold noise_parameters.
noises(:,1) = center_freqs;                 %The first column will be center frequency (in kHz).
noises(1:size(noises,1),2) = 1/3; 	%The second column will be bandwidth (in kHz).
noises(1:size(noises,1),3) = 2;    	%The third column will be the filter order.
%noisetags{1} = 'Broadband Noise';           %The first option will be broadband noise.
for i = 1:size(noises,1)                  	%Step through all other noises.
    noisetags{i} = ['NB: cf = ' num2str(noises(i,1)) ...
        'kHz, BW = ' num2str(roundn(noises(i,2),-2)) 'oct'];    	%Create a string describing the noise.
end

for i = 1:size(noises)
    temp = pow2(log2(noises(i,1))+(1/3)*[-0.5,0.5]);
    noises(i,1) = mean(temp);
    noises(i,2) = range(temp);
end

%Initialize the zBus.
zbus = actxcontrol('ZBUS.x',[1 1 1 1]);     %Set up the zBus ActiveX control.
if zbus.ConnectZBUS('GB');                  %Connect to the zBus.
    disp('Connected to zBus.');
else
    error(['Could not connect to the zBus: ' invoke(zbus,'GetError') '.']);
end
    
%Initialize the PA5.
pa5 = actxcontrol('PA5.x',[5 5 26 26]);     %Set up the PA5 ActiveX control.
if pa5.ConnectPA5('GB',1);                  %Connect to the PA5.
    disp('Connected to PA5.');
else
    disp('Could not connect to the PA5.');
end
if ~pa5.SetAtten(0);                     	%Set the PA5 attenuation to zero.
    disp('Could not set the PA5 to zero attenuation.');
end

%Initialize the RP2.
rp2 = actxcontrol('RPco.X', [5 5 26 26]);   %Set up the RP2 ActiveX control.
rp2.ConnectRP2('GB',1);                     %Connect to the RP2.
a = rp2.ClearCOF;                           %Clear the RP2 of any old control object files.
b = rp2.LoadCOF(rp2_RCX_filename); 	%Load up the neural recording RCX files.
c = rp2.Run;                                %Set the RCX file to run.
if a && b && c       %If there was an error in any of the three previous lines, we'll report it.
    disp(['"' rp2_RCX_filename '" loaded to the RP2.']);            
else
    error('Error in initialization: Could not load RCX file to the RP2');
end
rp2_sampling_rate = rp2.GetSFreq; 	%We'll grab the RP2 sampling rate for later use.
disp(['RP2 sampling at ' num2str(rp2_sampling_rate) ' Hz.']);
rp2.SetTagVal('cue_delay',1000-gapdelay);	%Set the gap duration on the RP2.
rp2.SetTagVal('cue_dur',gapdur);            %Set the gap delay on the RP2.
rp2.SetTagVal('startle_dur',20);                    %Set the startle duration to 20 ms on the RP2.
rp2.SetTagVal('startle_delay',1000);                %Set the startle delay to 1000 milliseconds.
rp2.SetTagVal('back_amp',0);                        %Zero the background amplitude until testing begins.
rp2.SetTagVal('sweeplength',sweeplength); 	%Set the sweeplength for recording sweeps.
rp2.SetTagVal('cue_enable',0);                    	%Disable gaps until testing begins.

%Set the seed for the random number generator using the clock time.
RandStream.setDefaultStream(RandStream('mt19937ar','seed',sum(100*clock)));

%Initialize the *.STARTLE data file.
params = {'Predictor Duration (ms)','Background Center Frequency (kHz)','Background Bandwidth (Hz)',...
    'Background Intensity (dB)','Startler Duration (ms)','Startler Intensity (dB)'};    %Parameter list.
warning off MATLAB:MKDIR:DirectoryExists;           %Turn off the "directory already exists" warning.
mkdir([datapath ratname]);        	%Make a folder for this rat's data.
ratpath = [datapath ratname '\'];	%Save the path.
for i = 1:100                                      	%Step through possible recording indices.
    %Check to see if this recording index exists.
    if ~exist([ratpath 'TINNITUS_' num2str(i) '_' ratname '_' num2str(daycodestr,'%03d') '.STARTLE'],'file');
        break;	%Break out of the for loop when a new recording index is found.
    end
end
filename = ['partialfill_' num2str(i) '_' ratname '_' num2str(daycodestr,'%03d')];    %Save the root filename.
fid = fopen([ratpath filename '.STARTLE'],'w');     %Open a binary file for writing.
fwrite(fid,daycodestr,'uint16');                     	%DayCode.
fwrite(fid,length(ratname),'int8');       	%Number of characters in the rat's name.
fwrite(fid,ratname,'uchar');              	%Characters of the rat's name.
fwrite(fid,1000-gapdelay,'int16');        	%Predictor delay, in milliseconds
fwrite(fid,1000,'int16');                          	%Startler delay, in milliseconds
fwrite(fid,97656.25/100,'float32');               	%Sampling rate, in Hz.
fwrite(fid,length(params),'int8');                 	%Number of parameters.
for j = 1:length(params)                  	%Step through the reported paramters.
    fwrite(fid,length(params{j}),'int16');        	%Number of characters in each reported parameter name.
    fwrite(fid,params{j},'uchar');                   %Characters of each reported parameter name.
end
    
%% Load the noise calibration data for this booth.
load([rootpath '\Calibration\Booth_#' num2str(booth) '_Noise_Calibration_Data']);	%Load the calibration data.



%Initialize startle loop variables.
run = 1;        %The run variable will be linked to the run label to allow pausing and stopping.

selected_noises = 1;    %we're just sticking this here to keep the program from crying
data = NaN(numtrials,length(selected_noises),2);     %Make a 3-D matrix of NaNs to hold startle amplitude data.
index = 1;      %Keep track of the order of the background sounds in the data file.
plotdata = NaN(5,length(selected_noises));          %Preallocate an array to hold session plot data.
                                    
for i = selected_noises                             %Step through all stimuli.
    if noises(i,1) == 0                             %If the sound is a broadband noise.
        plotlabels{i == selected_noises} = 'BBN';	%...mark it as such.
    else                                                    %Otherwise...
        plotlabels{i == selected_noises} = [num2str(noises(i,1)) 'kHz'];	%...indicate the center frequency.
    end
end






%Randomize the order of the sounds and step through each one.
soundorder = selected_noises(randperm(length(selected_noises)));
for s = soundorder
    rp2.SetTagVal('back_amp',0);    %Set the background amplitude to zero before switching noises.
    cf = 1000*noises(s,1);          %Change the center frequency to hertz.
    bw = 1000*noises(s,2);          %Change the bandwidth to hertz.
    fn = noises(s,3);               %Grab the desired filter order.
    temp = cal(floor(cal(:,2)) == floor(bw) & cal(:,3) == fn,[1,4:5]);     %Pare down the calibration list to include only this bandwidth and filter order.
    l_freq = find(roundn(cf,-2) >= roundn(temp(:,1),-2),1,'last');      %Find the closest calibrated center frequency lower than the desired center frequency.
    h_freq = find(roundn(cf,-2) <= roundn(temp(:,1),-2),1,'first');     %Find the closest calibrated center frequency higher than the desired center frequency.
    l_volt = exp((backint - temp(l_freq,2))/temp(l_freq,3));	%Find the required voltage to make a noise at the lower calibration center frequency.
    h_volt = exp((backint - temp(h_freq,2))/temp(h_freq,3));	%Find the required voltage to make a noise at the higher calibration center frequency.
    if l_volt == h_volt         %If this exact center frequency was calibrated for...
        volt = l_volt;          %...just use either value.
    else                        %Otherwise...
        volt = (h_volt - l_volt)*(cf - temp(l_freq,1))/(temp(h_freq,1) - temp(l_freq,1)) + l_volt;   %...linearly interpolate to find the voltage for the desired frequency.
    end
    signal = 1-2*rand(1,1000000);                                  	%Create a 10-second random noise signal.
    if cf ~= 0                                                   	%If this noise isn't white noise...
        cutoffs = cf + [-0.5,0.5]*bw;                             	%Find the high- and low-pass cutoffs.
        [b, a] = butter(fn/2,cutoffs*2/rp2_sampling_rate); 	%Calculate Nth-order Butterworth filter coefficients.
        signal = filter(b,a,signal);                              	%Bandpass filter the random noise signal.
    end
    signal = signal/max(abs(signal));                             	%Scale the signal by it's absolute maximum.
    rp2.SetTagVal('back_size',length(signal));           	%Set the length of the serial buffer in the RCX circuit.
    rp2.WriteTagV('back_signal',0,signal);                	%Load the bandpass noise to the serial buffer.
    pause(0.1);                                                     %Pause to allow the signal to load.
    rp2.SetTagVal('back_amp',volt);                         %Set the amplitude on the background noise.
    %disp(['back_amp voltage: ', num2str(volt)])
    temp = length(soundorder)-find(s==soundorder)+1;                %Find the number of background noises left to be tested.
    temp = (temp*(numtrials*mean(intertrial_interval)+waittime)-waittime)/86400;  %Calculate how long, in days, the session is expected to last.
   
    if habituate                                            %If we're habituating with the background noise before testing...
        tic;                                                        %Start a timer to track habituation time.
        while toc < 60*habtime                              %Wait through the habituation time.
            run = str2double(get(lblRun,'String'));         %Check the run label for user-specified pauses or stops.
            
            
            pause(0.05);                                             %Pause for 50 ms before the next loop.
        end
    end
    
    cueorder = zeros(1,numtrials);                          %Create a matrix to hold the cued/uncued parameter.
    cueorder(1:round(cueprob*numtrials)) = 1;       %Make a proportion of the trials cued based on the cue probability.
    cueorder = cueorder(randperm(numtrials));               %Randomize the cued/uncued parameter across all trials.
    for i = 1:length(randomizedints)                                     %Step through each trial.
        iti = intertrial_interval;
        length(randomizedints)
    %Set the startler intensity.
        a = cal(~cal(:,1) & ~cal(:,2) & ~cal(:,3),4:5); 	%Find the calibration curve for white noise.
        volt = exp((startleint - a(1))/a(2));        %Find the required voltage to make the startler noise intensity.
        %disp(['is setting rp2 to these volts: ', num2str(volt)])                     
        actualint = a(2)*log(10)+a(1);                      %Calculate the output intensity that is possible at 10 volts

        if volt > 10                                        %If the voltage of the startler is greater than the RP2 can handle...
            volt = 10;                                      %...set the voltage as high as the RP2 will go.
            actualint = round(a(2)*log(10)+a(1));                  %Calculate the output intensity that is possible at 10 volts
            disp(['The startler intensity will probably be less than the specified intensity of ' num2str(startleint) ' dB. Actual intensity is: ', num2str(actualint), 'dB.']);                                              %Warn the user that the startle intensity will won't be correct.
        end
        rp2.SetTagVal('startle_amp',volt);          %Set the startler amplitude.
        
        
   %Set the fill sound intensity
   rp2.SetTagVal('partial_amp',0);    %Set the background amplitude to zero before switching noises.
    cf = 1000*noises(s,1);          %Change the center frequency to hertz.
    bw = 1000*noises(s,2);          %Change the bandwidth to hertz.
    fn = noises(s,3);               %Grab the desired filter order.
    temp = cal(floor(cal(:,2)) == floor(bw) & cal(:,3) == fn,[1,4:5]);     %Pare down the calibration list to include only this bandwidth and filter order.
    l_freq = find(roundn(cf,-2) >= roundn(temp(:,1),-2),1,'last');      %Find the closest calibrated center frequency lower than the desired center frequency.
    h_freq = find(roundn(cf,-2) <= roundn(temp(:,1),-2),1,'first');     %Find the closest calibrated center frequency higher than the desired center frequency.
    l_volt = exp((randomizedints(i) - temp(l_freq,2))/temp(l_freq,3));	%Find the required voltage to make a noise at the lower calibration center frequency.
    h_volt = exp((randomizedints(i) - temp(h_freq,2))/temp(h_freq,3));	%Find the required voltage to make a noise at the higher calibration center frequency.
    if l_volt == h_volt         %If this exact center frequency was calibrated for...
        volt = l_volt;          %...just use either value.
    else                        %Otherwise...
        volt = (h_volt - l_volt)*(cf - temp(l_freq,1))/(temp(h_freq,1) - temp(l_freq,1)) + l_volt;   %...linearly interpolate to find the voltage for the desired frequency.
    end
                          %Pause to allow the signal to load.
    rp2.SetTagVal('partial_amp',volt); 
    testybugger = rp2.GetTagVal('partial_amp');
    %disp(['retrieved voltage is: ', num2str(testybugger)]);
    %disp(['partial_amp voltage: ', num2str(volt)])
   %%%%
        
        %disp(randomizedints(i))
        zbus.zBusTrigB(0,0,10);                             %Reset the recording buffers with the zBus B trigger.
                                              
        buffer = [0 0];                                            	%Keep track of the buffer indices.
        trial_start = now;                                          %Save the timestamp at the start of the trial.
        
        iti = iti(1) + rand*(iti(2)-iti(1));	%Create a random inter-trial interval within the specified range.
        %disp(iti);
        tic;                                                        %Start the trial timer.
        rp2.SetTagVal('cue_enable',1);           	%Enable/disable the gap.
        %rp2.SetTagVal('partial_amp',randomizedints(i));        %set the gap fill intensity
        zbus.zBusTrigA(0,0,10);                             %Trigger stimulus presentation and startle recording.
        while toc < sweeplength/1000                        %Wait while the stimuli are presented and the startle responses is recorded.
            %disp('in the while loop')
            pause(0.01);                                            %Pause for 10 milliseconds.
            buffer(2) = rp2.GetTagVal('input_index');     	%Find the current buffer index.
            signal = rp2.ReadTagV('input_signal', buffer(1), buffer(2)-buffer(1));	%Read in the last signal snippet.
            
            buffer(1) = buffer(2)+1;                                %Set the next buffer start at the end of the last buffer.
        end
                                                           
        buffer(2) = rp2.GetTagVal('input_index');              	%Find the current buffer index.
        signal = rp2.ReadTagV('input_signal', 0, buffer(2));   	%This time grab the entire signal.
        signal = signal - mean(signal);                                 %Set the middle of the signal down to zero.
        signal = signal(1:100:length(signal));                        	%Downsample the signal to ~1000 Hz.
        fwrite(fid,index,'int16');                                     	%Stimulus index.
        fwrite(fid,trial_start,'float64');                             	%Timestamp.
        fwrite(fid,cueorder(i),'uint8');                               	%Predicted or unpredicted startler.
        fwrite(fid,gapdur,'float32');                          	%Parameter value #1 (Predictor Duration (ms)).
        fwrite(fid,cf/1000,'float32');                                 	%Parameter value #2 (Background Center Frequency (kHz)).
        fwrite(fid,bw,'float32');                                      	%Parameter value #3 (Background Bandwidth (Hz)).
        fwrite(fid,backint,'float32');                         	%Parameter value #4 (Background Intensity (dB)).
        fwrite(fid,20,'float32');                                     	%Parameter value #5 (Startler Duration (ms)).
        fwrite(fid,startleint,'float32');                      	%Parameter value #6 (Startler Intensity (dB)).
        scale_factor = max(abs(signal))/128;                           	%Find the scaling factor to turn the signal to 8-bit precision.
        temp = round(signal/scale_factor);                          	%Change the signal to 8-bit precision.
        fwrite(fid,sweeplength/1000,'float32');                	%Sweeplength, in seconds.
        fwrite(fid,length(signal),'uint32');                         	%Number of samples in the data sweep.
        fwrite(fid,scale_factor,'float32');                            	%Scale factor to return signal to real voltage values.
        fwrite(fid,temp,'int8');                                     	%Sweep data;
                                                              
        
        a = ceil(rp2_sampling_rate*([1, 1.3])/100);             %Find the samples in the startled snippet of the signal.
        b = ceil(rp2_sampling_rate*([0.3, 0.6])/100);           %Find samples in the pre-startle snippet for finding noise peak-to-peak
        temp = signal(a(1):a(2));                                       %Grab the startled snippet.
        temp2 = signal(b(1):b(2));                                      %Grab an equivalent length pre-startle snippet
        data(i,s==soundorder,2) = cueorder(i);                          %Save whether this was cued or uncued in the plot data.
        data(i,s==soundorder,1) = max(temp) - min(temp);              	%Save the startle amplitude for this trial.
        temp = 1000*temp;                                               %Change the startle snippet amplitude to millivolts.
        temp2 = 1000*temp2;                                             %Change pre-startle snippet to mV.
        startlemv = max(temp)-min(temp);
        noisemv = max(temp2)-min(temp2);
        
       
        
        
        plotdata(1,s==selected_noises) = 1000*nanmean(data(data(:,s==soundorder,2) == 1,s==soundorder,1));    %Recalculate the mean cued startle amplitude.
        plotdata(2,s==selected_noises) = 1000*nanmean(data(data(:,s==soundorder,2) == 0,s==soundorder,1));    %Recalculate the mean uncued startle amplitude.
        plotdata(3,s==selected_noises) = 1000*simple_ci(data(data(:,s==soundorder,2) == 1,s==soundorder,1)); 	%Recalculate the cued startle amplitude confidence interval.
        plotdata(4,s==selected_noises) = 1000*simple_ci(data(data(:,s==soundorder,2) == 0,s==soundorder,1)); 	%Recalculate the uncued startle amplitude confidence interval.
        if sum(data(:,s==soundorder,2) == 1) == sum(data(:,s==soundorder,2) == 0)                   %If the sample sizes for cued and uncued responses are the same...
            plotdata(5,s==selected_noises) = signrank(data(data(:,s==soundorder,2) == 1,s==soundorder,1),...
                data(data(:,s==soundorder,2) == 0,s==soundorder,1));	%...use an MPSR test to find significance.
        else                                                            %Otherwise...
            [h,a] = ttest2(data(data(:,s==soundorder,2) == 1,s==soundorder,1),...
                data(data(:,s==soundorder,2) == 0,s==soundorder,1));   	%...use a two-sample t-test to find signifance...
            plotdata(5,s==selected_noises) = a;                           	%...and save the p-value.
        end
       if i > pre_reps
       startledata(i-pre_reps,:) = [{ratname}, randomizedints(i), startlemv, noisemv, i];
       end
       disp(['Gap ', num2str(i), ' was filled with the power of ', num2str(randomizedints(i)), ' decibels!'])
       pause(iti);
        
    end
    
    
    rp2.SetTagVal('back_amp',0);	%Zero the background noise amplitude.
    index = index + 1;                      %Advance the stimulus index.
    tic;        %Reset the timer.
    if s < soundorder(length(soundorder))   %If there's more background noises to be tested...
        temp = length(soundorder)-find(s==soundorder)+1;                %Find the number of background noises left to be tested.
        temp = (temp*(numtrials*mean(iti)+waittime)-waittime)/86400;  %Calculate how long, in days, the session is expected to last.
        
        
    end
   disp('The gap is filled.')
end
fclose all;     %Close the *.STARTLE data file.

for k = 1:length(intensities)
    thisintind = find(cell2mat(startledata(:,2)) == intensities(k));
    startlemeans(k) = nanmean(cell2mat(startledata(thisintind,3)));
    startlecis(k) = simple_ci(cell2mat(startledata(thisintind,3)));
    noisemeans(k) = nanmean(cell2mat(startledata(thisintind,4)));
    noisecis(k) = nanmean(cell2mat(startledata(thisintind,4)));
end

filldata_meanci = [startlemeans; startlecis; noisemeans; noisecis];
filldata = startledata;

save([savepath ratname, '_partialfill_', datestr(now,'mm-dd-yyyy'), '.mat'], 'filldata_meanci', 'filldata');
figure
errorbar(startlemeans,startlecis)
text2speech('Once upon a time there was a gap. It got filled. THE END!');


