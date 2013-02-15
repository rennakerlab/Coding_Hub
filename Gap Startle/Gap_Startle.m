function varargout = Gap_Startle(varargin)

%change handles.datapath back to z:, restore booth.txt loading



% GAP_STARTLE M-file for Gap_Startle.fig
%      GAP_STARTLE, by itself, creates a new GAP_STARTLE or raises the existing
%      singleton*.
%
%      H = GAP_STARTLE returns the handle to a new GAP_STARTLE or the handle to
%      the existing singleton*.
%
%      GAP_STARTLE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GAP_STARTLE.M with the given input arguments.
%
%      GAP_STARTLE('Property','Value',...) creates a new GAP_STARTLE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Gap_Startle_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Gap_Startle_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Gap_Startle

% Last Modified by GUIDE v2.5 07-Apr-2010 10:14:19

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Gap_Startle_OpeningFcn, ...
                   'gui_OutputFcn',  @Gap_Startle_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


%% LOAD GUI
%**************************************************************************
%This function is called when the GUI is first loaded.
function Gap_Startle_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject;   %The default command line output for Gap_Startle

%Define paths and filenames the program will use.
handles.rootpath = 'Z:';                                               	%Root path for NEL common programs.
handles.programpath = [handles.rootpath '\Z:\Gap Detection Startle\'];	%Path that contains the startle m-files.
handles.rcxpath = [handles.rootpath '\RPvds Circuits\'];                %Path that contains the RCX files.
% handles.rcxpath = 'C:\RPvds Circuits\';                 %Path that contains the RCX files.
warning off MATLAB:MKDIR:DirectoryExists;               %Turn off the "directory already exists" warning.
handles.localpath = 'C:\Neural Recordings\';            %Local computer folder to write the data files to.
mkdir(handles.localpath);                             	%Make the local folder if it doesn't already exist.
handles.datapath = 'Y:\Startle Data\';                 	%Folder on the lab server to copy the data to at the end of the session.
if exist('D:\','dir')                                   %If there's a second hard drive on this computer...
    handles.recordingpath = 'D:\';                  	%...write the neural recording files to that drive.
else                                                    %Otherwise...
    handles.recordingpath = 'C:\Neural Recordings\';	%...write the neural recording files to a folder on the C: drive.
    mkdir(handles.recordingpath);                    	%Make a C: drive folder to hold neural recordings.
end
handles.rp2_RCX_filename = [handles.rcxpath 'Gap_In_Loaded_Background_Sound.rcx']; 	%Name of the RP2 RCX file.
handles.rxn_RCX_filename = [handles.rcxpath 'RZ5_Use_As_Monitor.rcx'];              %Name of the RZ5 RCX file.
    
%Set the default parameter values for testing.
handles.habituate = 1;      %Habituate before testing (0 = no, 1 = yes).
handles.habtime = 2;        %Habituation time, in minutes.
handles.iti = [30 35];      %Bounds of the inter-trial interval, in seconds.
handles.cueprob = 0.5;      %Probability of any trial being a cued trial.
handles.numtrials = 30;     %Total number of trials.
handles.gapdur = 50;        %Gap cue duration, in milliseconds.
handles.gapdelay = 100;     %Time between the gap and the startler, in milliseconds.
handles.backint = 60;       %Background noise intensity, in dB.
handles.startleint = 115;   %Startler intensity, in dB.
handles.sweeplength = 3000; %Sweeplength for recording startle responses, in milliseconds.
handles.waittime = 300;     %Time to wait in between testing with different background noises, in seconds.
handles.daycode = daycode;  %Find today's daycode.
handles.ratname = [];       %Make an empty placeholder for the rat's name.

%%%%%%Start Patrick's altered code that allows grabbing Booth 6's
%%%%%%calibration values
userinput = questdlg('Are you using Booth 6? If so, double-check connections.')

if strcmpi(userinput, 'Yes') == 1
    handles.booth = 6;
elseif strcmpi(userinput, 'No') == 1
    handles.booth = load('C:\Booth_Number.txt');	%The number of the booth for this computer is in a text file on the C: drive.
end
%handles.booth = 701;
%%%%%%End Patrick's altered code.

handles.recording = 0;      %Neural recordings are off by default.

%Create noise parameters for testing.
center_freqs = [0,1,2,4,8,10,12,16,24,32]';         %The user can pick between these center frequencies.
handles.noises = zeros(length(center_freqs),3);     %Pre-allocate a matrix to hold noise_parameters.
handles.noises(:,1) = center_freqs;                 %The first column will be center frequency (in kHz).
handles.noises(2:size(handles.noises,1),2) = 1/3; 	%The second column will be bandwidth (in kHz).
handles.noises(2:size(handles.noises,1),3) = 2;    	%The third column will be the filter order.
handles.noisetags{1} = 'Broadband Noise';           %The first option will be broadband noise.
for i = 2:size(handles.noises,1)                  	%Step through all other noises.
    handles.noisetags{i} = ['NB: cf = ' num2str(handles.noises(i,1)) ...
        'kHz, BW = ' num2str(roundn(handles.noises(i,2),-2)) 'oct'];    	%Create a string describing the noise.
end
handles.selected_noises = [1,5,6,8];                %Default selected background noises.
for i = 2:size(handles.noises)
    temp = pow2(log2(handles.noises(i,1))+(1/3)*[-0.5,0.5]);
    handles.noises(i,1) = mean(temp);
    handles.noises(i,2) = range(temp);
end

%Set the string properties of the GUI inputs to the default values.
set(handles.chkHabituate,'value',handles.habituate);                %Habituation checkbox.
set(handles.txtHabtime,'string',num2str(handles.habtime))           %Habituation time textbox.
set(handles.txtITI1,'string',num2str(handles.iti(1)));              %Inter-trial interval lower bound textbox.
set(handles.txtITI2,'string',num2str(handles.iti(2)));              %Inter-trial interval upper bound textbox.
set(handles.txtCuepercent,'string',num2str(100*handles.cueprob));	%Cue probability percent textbox.
set(handles.txtTrials,'string',num2str(handles.numtrials));         %Number of trials textbox.
set(handles.txtCuedur,'string',num2str(handles.gapdur));            %Gap duration textbox
set(handles.txtCuedelay,'string',num2str(handles.gapdelay));        %Gap delay textbox.
set(handles.txtBackint,'string',num2str(handles.backint));          %Background intensity textbox.
set(handles.txtStartleint,'string',num2str(handles.startleint));	%Startler intensity textbox.
set(handles.lstNoises,'max',length(handles.noisetags));            	%Background noises listbox.
set(handles.lstNoises,'string',handles.noisetags);                  %Background noises listbox.
set(handles.lstNoises,'value',handles.selected_noises);            	%Background noises listbox.
set(handles.cmdRecord,'foregroundcolor',[0.5 0 0]);                 %Neural Recordings button.

%Initialize the zBus.
handles.zbus = actxcontrol('ZBUS.x',[1 1 1 1]);     %Set up the zBus ActiveX control.
if handles.zbus.ConnectZBUS('GB');                  %Connect to the zBus.
    disp('Connected to zBus.');
else
    error(['Could not connect to the zBus: ' invoke(handles.zbus,'GetError') '.']);
end
    
%Initialize the PA5.
handles.pa5 = actxcontrol('PA5.x',[5 5 26 26]);     %Set up the PA5 ActiveX control.
if handles.pa5.ConnectPA5('GB',1);                  %Connect to the PA5.
    disp('Connected to PA5.');
else
    disp('Could not connect to the PA5.');
end
if ~handles.pa5.SetAtten(0);                     	%Set the PA5 attenuation to zero.
    disp('Could not set the PA5 to zero attenuation.');
end

%Initialize the RP2.
handles.rp2 = actxcontrol('RPco.X', [5 5 26 26]);   %Set up the RP2 ActiveX control.
handles.rp2.ConnectRP2('GB',1);                     %Connect to the RP2.
a = handles.rp2.ClearCOF;                           %Clear the RP2 of any old control object files.
b = handles.rp2.LoadCOF(handles.rp2_RCX_filename); 	%Load up the neural recording RCX files.
c = handles.rp2.Run;                                %Set the RCX file to run.
if a && b && c       %If there was an error in any of the three previous lines, we'll report it.
    disp(['"' handles.rp2_RCX_filename '" loaded to the RP2.']);            
else
    error('Error in initialization: Could not load RCX file to the RP2');
end
handles.rp2_sampling_rate = handles.rp2.GetSFreq; 	%We'll grab the RP2 sampling rate for later use.
disp(['RP2 sampling at ' num2str(handles.rp2_sampling_rate) ' Hz.']);
handles.rp2.SetTagVal('cue_delay',1000-handles.gapdelay);	%Set the gap duration on the RP2.
handles.rp2.SetTagVal('cue_dur',handles.gapdur);            %Set the gap delay on the RP2.
handles.rp2.SetTagVal('startle_dur',20);                    %Set the startle duration to 20 ms on the RP2.
handles.rp2.SetTagVal('startle_delay',1000);                %Set the startle delay to 1000 milliseconds.
handles.rp2.SetTagVal('back_amp',0);                        %Zero the background amplitude until testing begins.
handles.rp2.SetTagVal('sweeplength',handles.sweeplength); 	%Set the sweeplength for recording sweeps.
handles.rp2.SetTagVal('cue_enable',0);                    	%Disable gaps until testing begins.

%Set the seed for the random number generator using the clock time.
RandStream.setDefaultStream(RandStream('mt19937ar','seed',sum(100*clock)));
     
guidata(hObject, handles);  %Update the handles structure.


% --- Outputs from this function are returned to the command line.
function varargout = Gap_Startle_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


%txtRatname TEXT ENTRY
%**************************************************************************
%This function is called when an user enters text into the Ratname textbox.
function txtRatname_Callback(hObject, eventdata, handles)
handles.ratname = upper(get(hObject,'string'));                     %Save the rat's name in the handles structure.
if ~isempty(handles.selected_noises) && ~isempty(handles.ratname)   %If a rat's name is entered and no background noises are selected...
    set(handles.cmdStart,'enable','on');                            %...enable the start button.
else                                                                %Otherwise...
    set(handles.cmdStart,'enable','off');                           %...disable the start button.
end
set(handles.txtRatname,'string',upper(handles.ratname));            %Make the ratname string uppercase if it isn't already.
guidata(hObject, handles);                                          %Update the handles structure.


%LOAD txtRatname
%**************************************************************************
%This function is called when txtRatname is first created.
function txtRatname_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


%LOAD txtDaycode
%**************************************************************************
%This function is called when txtDaycode is first created.
function txtDaycode_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
temp = num2str(daycode,'%03d');     %Grab the daycode string.
set(hObject,'string',temp);         %Set the daycode in the textbox.


%chkHabituate TEXT ENTRY
%**************************************************************************
%This function is called when an user checks or unchecks the Habituation checkbox.
function chkHabituate_Callback(hObject, eventdata, handles)
handles.habituate = get(hObject,'value');    %Save teh habituate boolean option in the handles structure.
if handles.habituate                            %If habituating...
    set(handles.txtHabtime,'enable','on');      %...enable the habituation time textbox.
else                                            %Otherwise...
    set(handles.txtHabtime,'enable','off');     %...disable the habituation time textbox.
end
guidata(hObject, handles);                  	%Update the handles structure.


%txtHabtime TEXT ENTRY
%**************************************************************************
%This function is called when an user enters text into the Habituation time textbox.
function txtHabtime_Callback(hObject, eventdata, handles)
handles.habtime = str2double(get(hObject,'string'));	%Save the habituation time, in minutes.
guidata(hObject, handles);                            	%Update the handles structure.


%LOAD txtHabtime
%**************************************************************************
%This function is called when txtHabtime is first created.
function txtHabtime_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


%txtITI1 TEXT ENTRY
%**************************************************************************
%This function is called when an user enters text into the ITI lower bound textbox.
function txtITI1_Callback(hObject, eventdata, handles)
temp = str2double(get(hObject,'String'));       %Grab the value of the input.
if temp >= 0                                 	%Only proceed if the use's set the ITI lower bound to a positive value.
    handles.iti(1) = temp;              %Save the new lower bound in the handles structure.
    if temp > handles.iti(2)            %If the user tries to set the lower bound higher than the upper bound...
        handles.iti(2) = temp;        %...set the upper bound higher as well.
        set(handles.txtITI2,'string',num2str(handles.iti(2)));     %Set the upper bound textbox string.
    end
end
set(hObject,'string',num2str(handles.iti(1))); 	%Reset the lower bound in the textbox.
guidata(hObject, handles);                  	%Update the handles structure.


%LOAD txtITI1
%**************************************************************************
%This function is called when txtHabtime is first created.
function txtITI1_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


%txtITI2 TEXT ENTRY
%**************************************************************************
%This function is called when an user enters text into the ITI upper bound textbox.
function txtITI2_Callback(hObject, eventdata, handles)
temp = str2double(get(hObject,'String'));       %Grab the value of the input.
if temp >= 0                                 	%Only proceed if the use's set the ITI lower bound to a positive value.
    handles.iti(2) = temp;              %Save the new lower bound in the handles structure.
    if temp < handles.iti(1)            %If the user tries to set the lower bound higher than the upper bound...
        handles.iti(1) = temp;          %...set the upper bound higher as well.
        set(handles.txtITI1,'string',num2str(handles.iti(1)));     %Set the upper bound textbox string.
    end
end
set(hObject,'string',num2str(handles.iti(2))); 	%Reset the lower bound in the textbox.
guidata(hObject, handles);                  	%Update the handles structure.


%LOAD txtITI2
%**************************************************************************
%This function is called when txtITI2 is first created.
function txtITI2_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


%txtCuepercent TEXT ENTRY
%**************************************************************************
%This function is called when an user enters text into the cue probability textbox.
function txtCuepercent_Callback(hObject, eventdata, handles)
temp = str2double(get(hObject,'String'));	%Grab the value of the input.
if temp > 0 && temp < 100                   %Only proceed if the input probability is between 0 and 1.
    handles.cueprob = temp/100;           	%Save the new cue probability.
end
set(hObject,'string',num2str(100*handles.cueprob));     %Reset the cue probability in the textbox.
guidata(hObject, handles);                              %Update the handles structure.


%LOAD txtCuepercent
%**************************************************************************
%This function is called when txtCuepercent is first created.
function txtCuepercent_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


%txtTrials TEXT ENTRY
%**************************************************************************
%This function is called when an user enters text into the number of trials textbox.
function txtTrials_Callback(hObject, eventdata, handles)
temp = str2double(get(hObject,'String'));	%Grab the value of the input.
if temp > 0                                	%Only proceed if the input number of trials is greater than 0.
    handles.numtrials = temp;           	%Save the new number of trials.
end
set(hObject,'string',num2str(handles.numtrials));	%Reset the number of trials in the textbox.
guidata(hObject, handles);                         	%Update the handles structure.


%LOAD txtTrials
%**************************************************************************
%This function is called when txtTrials is first created.
function txtTrials_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


%txtCuedur TEXT ENTRY
%**************************************************************************
%This function is called when an user enters text into the cue duration textbox.
function txtCuedur_Callback(hObject, eventdata, handles)
temp = str2double(get(hObject,'String'));	%Grab the value of the input.
if temp > 0                                	%Only proceed if the input gap duration is greater than 0.
    handles.gapdur = temp;                  %Save the new gap duration.
    if ~handles.rp2.SetTagVal('cue_dur',handles.gapdur);	%Set the gap delay on the RP2.
    	error('RP2 ERROR: Could not set the cue duration!');    
    end
end
set(hObject,'string',num2str(handles.gapdur));      %Reset the gap duration in the textbox.
guidata(hObject, handles);                         	%Update the handles structure.


%LOAD txtCuedur
%**************************************************************************
%This function is called when txtCuedur is first created.
function txtCuedur_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


%txtCuedelay TEXT ENTRY
%**************************************************************************
%This function is called when an user enters text into the cue delay textbox.
function txtCuedelay_Callback(hObject, eventdata, handles)
temp = str2double(get(hObject,'String'));	%Grab the value of the input.
if temp > 0                                	%Only proceed if the input gap delay is greater than 0.
    handles.gapdelay = temp;            	%Save the new gap delay.
    if ~handles.rp2.SetTagVal('cue_delay',1000-handles.gapdelay);	%Set the gap duration on the RP2.
        error('RP2 ERROR: Could not set the cue delay!');
    end
end
set(hObject,'string',num2str(handles.gapdelay));  	%Reset the gap delay in the textbox.
guidata(hObject, handles);                         	%Update the handles structure.


%LOAD txtCuedelay
%**************************************************************************
%This function is called when txtCuedelay is first created.
function txtCuedelay_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


%txtBackint TEXT ENTRY
%**************************************************************************
%This function is called when an user enters text into the background intensity textbox.
function txtBackint_Callback(hObject, eventdata, handles)
temp = str2double(get(hObject,'String'));	%Grab the value of the input.
if temp < 80                              	%Only proceed if the input background noise is less than 80 dB.
    handles.backint = temp;                 %Save the new background intensity.
end
set(hObject,'string',num2str(handles.backint));  	%Reset the background intensity in the textbox.
guidata(hObject, handles);                         	%Update the handles structure.


%LOAD txtBackint
%**************************************************************************
%This function is called when txtBackint is first created.
function txtBackint_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


%txtStartleint TEXT ENTRY
%**************************************************************************
%This function is called when an user enters text into the startle intensity textbox.
function txtStartleint_Callback(hObject, eventdata, handles)
temp = str2double(get(hObject,'String'));	%Grab the value of the input.
handles.startleint = temp;                  %Save the new startle intensity.
set(hObject,'string',num2str(handles.startleint)); 	%Reset the startle intensity in the textbox.
guidata(hObject, handles);                         	%Update the handles structure.


%LOAD txtCuepercent
%**************************************************************************
%This function is called when txtCuepercent is first created.
function txtStartleint_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


%cmdStart BUTTON PRESS
%**************************************************************************
%This function is called when the uses pushes "Start."
function cmdStart_Callback(hObject, eventdata, handles)

%Disable all GUI controls except the "Pause" and "Stop" buttons.
set(handles.chkHabituate,'enable','off');   	%Habituation checkbox.
set(handles.txtHabtime,'enable','off')        	%Habituation time textbox.
set(handles.txtITI1,'enable','off');         	%Inter-trial interval lower bound textbox.
set(handles.txtITI2,'enable','off');        	%Inter-trial interval upper bound textbox.
set(handles.txtCuepercent,'enable','off');      %Cue probability percent textbox.
set(handles.txtTrials,'enable','off');          %Number of trials textbox.
set(handles.txtCuedur,'enable','off');        	%Gap duration textbox
set(handles.txtCuedelay,'enable','off');        %Gap delay textbox.
set(handles.txtBackint,'enable','off');        	%Background intensity textbox.
set(handles.txtStartleint,'enable','off');      %Startler intensity textbox.
set(handles.lstNoises,'enable','off');         	%Background noises listbox.
set(handles.txtRatname,'enable','off');        	%Rat name listbox.
set(handles.cmdRecord,'enable','off');         	%Neural recordings button.
set(handles.cmdStop,'enable','on');             %Stop button.
set(handles.cmdPause,'enable','on');        	%Pause button.
set(handles.cmdStart,'enable','off');        	%Start button.
set(handles.lblRun,'String',1);                 %Set the run label string to 1.

%Initialize the *.STARTLE data file.
params = {'Predictor Duration (ms)','Background Center Frequency (kHz)','Background Bandwidth (Hz)',...
    'Background Intensity (dB)','Startler Duration (ms)','Startler Intensity (dB)'};    %Parameter list.
warning off MATLAB:MKDIR:DirectoryExists;           %Turn off the "directory already exists" warning.
mkdir([handles.datapath handles.ratname]);        	%Make a folder for this rat's data.
ratpath = [handles.datapath handles.ratname '\'];	%Save the path.
for i = 1:100                                      	%Step through possible recording indices.
    %Check to see if this recording index exists.
    if ~exist([ratpath 'TINNITUS_' num2str(i) '_' handles.ratname '_' num2str(daycode,'%03d') '.STARTLE'],'file');
        break;	%Break out of the for loop when a new recording index is found.
    end
end
filename = ['TINNITUS_' num2str(i) '_' handles.ratname '_' num2str(daycode,'%03d')];    %Save the root filename.
fid = fopen([ratpath filename '.STARTLE'],'w');     %Open a binary file for writing.
fwrite(fid,daycode,'uint16');                     	%DayCode.
fwrite(fid,length(handles.ratname),'int8');       	%Number of characters in the rat's name.
fwrite(fid,handles.ratname,'uchar');              	%Characters of the rat's name.
fwrite(fid,1000-handles.gapdelay,'int16');        	%Predictor delay, in milliseconds
fwrite(fid,1000,'int16');                          	%Startler delay, in milliseconds
fwrite(fid,97656.25/100,'float32');               	%Sampling rate, in Hz.
fwrite(fid,length(params),'int8');                 	%Number of parameters.
for j = 1:length(params)                  	%Step through the reported paramters.
    fwrite(fid,length(params{j}),'int16');        	%Number of characters in each reported parameter name.
    fwrite(fid,params{j},'uchar');                   %Characters of each reported parameter name.
end
    
%% Load the noise calibration data for this booth.
load([handles.rootpath '\Calibration\Booth_#' num2str(handles.booth) '_Noise_Calibration_Data']);	%Load the calibration data.

%Initialize startle loop variables.
run = 1;        %The run variable will be linked to the run label to allow pausing and stopping.
set(handles.lblRun,'String','1');   %Set the run label to "1".
data = NaN(handles.numtrials,length(handles.selected_noises),2);     %Make a 3-D matrix of NaNs to hold startle amplitude data.
index = 1;      %Keep track of the order of the background sounds in the data file.
plotdata = NaN(5,length(handles.selected_noises));          %Preallocate an array to hold session plot data.
plotlabels = {};                                            %Create an empty matrix to hold x-axis labels for the bottom plot.
for i = handles.selected_noises                             %Step through all stimuli.
    if handles.noises(i,1) == 0                             %If the sound is a broadband noise.
        plotlabels{i == handles.selected_noises} = 'BBN';	%...mark it as such.
    else                                                    %Otherwise...
        plotlabels{i == handles.selected_noises} = [num2str(handles.noises(i,1)) 'kHz'];	%...indicate the center frequency.
    end
end

%Set the startler intensity.
a = cal(~cal(:,1) & ~cal(:,2) & ~cal(:,3),4:5); 	%Find the calibration curve for white noise.
volt = exp((handles.startleint - a(1))/a(2));       %Find the required voltage to make the startler noise intensity.
actualint = a(2)*log(10)+a(1);                      %Calculate the output intensity that is possible at 10 volts

if volt > 10                                        %If the voltage of the startler is greater than the RP2 can handle...
    desiredvolt = volt;
    volt = 10;                                      %...set the voltage as high as the RP2 will go.
    actualint = round(a(2)*log(10)+a(1));                  %Calculate the output intensity that is possible at 10 volts
    warndlg(['The startler intensity will probably be less than the '...
        'specified intensity of ' num2str(handles.startleint) ' dB. Actual intensity is: ', num2str(actualint), ' To get desired startle, must pass these volts: ', num2str(desiredvolt)],...
        'Startler Intensity');                                              %Warn the user that the startle intensity will won't be correct.
end
handles.rp2.SetTagVal('startle_amp',volt);          %Set the startler amplitude.

%% If we're recording, initialize the RZ5 and the recordings window.
rxn = actxcontrol('RPco.x', [5 5 26 26]);	%Set up the ActiveX control for the RZ5.
if rxn.ConnectRZ5('GB',1);                 	%Connect to the RZ5.
    disp('Connected to the RZ5.');
else
    if ~recording                       %If we're not recording...
        disp('Could not connect to the RZ5.');  %...show a non-canceling error message.
    else                                        %If we are recording
        error('Could not connect to the RZ5!');	%...show a canceling error message.
    end
end
rxn.ClearCOF;                               %Clear the RZ5 of any old RCX circuits.
rxn.LoadCOF(handles.rxn_RCX_filename);      %Load the RCX circuit to the RZ5.
rxn.Run;                                    %Set the RCX file to run.
if handles.recording
    fig1 = figure(1);
    pos = get(0,'ScreenSize');  %We'll make the figure large because it's going to have many subplots.
    pos = [0.1*pos(3),0.1*pos(4),0.8*pos(3),0.8*pos(4)];    %Scale the recording figure to the screensize.
    if pos(4) > pos(3)          %If the figure is wider than it is tall...
        pos(4) = pos(3);        ...square it up.
    end
    set(fig1,'Position',pos,'MenuBar','none','color','w','name',filename);	%Set the position and color of the recoding figure.
    recplot = gca;                                              %Save the axes handle for later reference.
    set(recplot,'yticklabel','','xticklabel','','xtick',1:3, 'ytick',-3:1:-1,'xlim',[0,4],'ylim',[-4 0]);     %Clear any x- or y-ticks off the plot.
    set(recplot,'box','on');     %Box in the plot and put a grid on it.
    grid on;
    set(recplot,'position',[0,0,1,1]);                          %Maximize the plot within the figure.
    recording_channels = edit_recording_channels(1:16, 2:15);	%Use the checkbox GUI to select channels.
    if isempty(recording_channels)    %If no channels are selected...
        disp('No channels selected for recording! Turning off neural recordings!');   %...show an error message...
        handles.recording = 0;	%...and cancel neural recordings.
    end
    reroute = 1:16;             %Start off assuming no channels are to be rerouted.
    for i = [1,16]              %Check channels #1 and #16 for possible rerouting
        if any(recording_channels == i) && any(setdiff(2:15,reroute(recording_channels)))	%If channel #1 or #16 is selected and a reroute channel is free...
            temp = edit_recording_channels(setdiff(2:15,reroute(recording_channels)),[],i);  %...have the user pick a reroute channel.
            reroute(temp) = i;  %Set the reroute-selected channel to channel #1 input.
            reroute(i) = temp;  %Set channel #1's input to the reroute-selected channel.
        elseif any(recording_channels == i)                   	%If there's no disabled channels available...
            recording_channels(recording_channels == i) = [];   %...we can't reroute the channel.
            disp(['No disabled channel available to reroute channel ' num2str(i) '!']);   %Show an error message.
        end
    end
    temp = zeros(1,16);     %Check to make sure all channels are set correctly.
    for i = 1:16            %Step through the channels...
        temp(i) = rxn.SetTagVal(['ch_' num2str(i)], reroute(i));    %And set the channel numbers in the RCX circuit.
    end
    if ~all(a)      %If it couldn't set the channel numbers, show an error.
        error('Could not set the channel numbers on the RZ5!');
    end
    if ~rxn.SetTagVal('mon_chan',-15);     %Set the monitor channel to play the background sounds.
        disp('Could not set the monitor channel on the RZ5.');  %If the monitor channel can't be set, don't error, but show a message.
    end
    rxn_sampling_rate = rxn.GetSFreq;	%Grab the recording device sampling rate for later use.
    a = rxn.SetTagVal('hp_cutoff',1);	%Set the high-pass monitor filter to pass everything above 5 Hz.
    b = rxn.SetTagVal('lp_cutoff',rxn_sampling_rate/2);	%Set the low-pass monitor filter to half the sampling rate.
    if ~a || ~b     %If we can't set the monitor filters, don't error, but show a message.
        disp('Could not set the high- and low-pass monitor filters on the RZ5.');
    end
    [b,a] = ellip(2,0.1,40,[825 4500]*2/rxn_sampling_rate);     %Make filter coefficients for a display filter.
    recfilter = [b; a];                                        	%Save the filter coefficients.
    params{length(params)+1} = 'Predictor Delay (ms)';          %Add the predictor delay to the parameters.
    params{length(params)+1} = 'Startler Delay (ms)';           %Add the startler delay to the parameters.
    predictor_delay = 1000-handles.gapdelay;                    %Save the predictor delay.
    startler_delay = 1000;                                      %Save the startler delay.
	mkdir([handles.recordingpath handles.ratname]);             %Make a recordings folder for this rat.
    mkdir([handles.recordingpath handles.ratname '\' handles.ratname '_TINNITUS']);         %Make a recordings folder for tinnitus files.
    temp = num2str(daycode,'%03d');     %Grab the daycode a 3-character string.
    mkdir([handles.recordingpath handles.ratname '\' handles.ratname '_TINNITUS\' temp]);	%Make a folder for this daycode.
    recpath = [handles.recordingpath handles.ratname '\' handles.ratname '_TINNITUS\' temp '\'];    %Save the recording path.
    disp(['Neural recording data will be saved to E**_' filename '.NEL.']);
    recfid = zeros(1,max(recording_channels)); 	%Preallocate a matrix to hold file identifiers.
    for i = recording_channels                  %For each channel we're recording from...
        temp = ['E' num2str(i,'%02d') '_'];   	%Each channel has its own file with a "E**" prefix indicating the number.
        recfid(i) = fopen([recpath temp filename '.NEL'],'w');	%Open a binary file for write access for each channel.
        fwrite(recfid(i),daycode,'int8');                       %DayCode.
        fwrite(recfid(i),length(handles.ratname),'int8');       %Number of characters in the rat's name.
        fwrite(recfid(i),handles.ratname,'uchar');              %Characters of the rat's name.
        fwrite(recfid(i),predictor_delay,'int16');           	%Spontaneous measurement delay, in milliseconds.
        fwrite(recfid(i),rxn_sampling_rate,'float32');          %Sampling rate, in Hz.
        fwrite(recfid(i),length(params),'int8');              	%Number of parameters.
        for j = 1:length(params)                             
            fwrite(recfid(i),length(params{j}),'int16'); 	%Number of characters in each parameter name.
            fwrite(recfid(i),params{j},'uchar');          	%Characters of each parameter name.
        end    
    end
    rxn.SetTagVal('bufforder',1);           %Set the buffer to only hold one sweep at a time.
    buffsize = ceil(rxn_sampling_rate*handles.sweeplength/1000);    %Find the buffer size, in number of samples.
    if ~rxn.SetTagVal('buffsize',buffsize);                 %Set the buffer size on the RZ5.
        error('Could not set the buffer size on the RZ5!');	%If the buffer size can't be set, show an error.
    end
   	colors = 0.5*ones(16,3);            	%Blank out all recording channel colors.
    colors(recording_channels,[1,3]) = 0;	%Set the color of all enabled channels to green.
    x = repmat(0.05:1:3.05,4,1);            %Make a matrix with y-coordinates for plotting signals.
    y = repmat((-0.5:-1:-3.5)',1,4);        %Make a matrix with y-coordinates for plotting signals.
end

%Randomize the order of the sounds and step through each one.
soundorder = handles.selected_noises(randperm(length(handles.selected_noises)));
tested_freqs = 0;                      %initialize a boolean that will indicate whether this is the first frequency tested or not

soundcounter = 1;       %set a counter to keep track of how many freqs have been tested
for s = soundorder
    handles.rp2.SetTagVal('back_amp',0);    %Set the background amplitude to zero before switching noises.
    cf = 1000*handles.noises(s,1);          %Change the center frequency to hertz.
    bw = 1000*handles.noises(s,2);          %Change the bandwidth to hertz.
    fn = handles.noises(s,3);               %Grab the desired filter order.
    temp = cal(floor(cal(:,2)) == floor(bw) & cal(:,3) == fn,[1,4:5]);     %Pare down the calibration list to include only this bandwidth and filter order.
    l_freq = find(roundn(cf,-2) >= roundn(temp(:,1),-2),1,'last');      %Find the closest calibrated center frequency lower than the desired center frequency.
    h_freq = find(roundn(cf,-2) <= roundn(temp(:,1),-2),1,'first');     %Find the closest calibrated center frequency higher than the desired center frequency.
    l_volt = exp((handles.backint - temp(l_freq,2))/temp(l_freq,3));	%Find the required voltage to make a noise at the lower calibration center frequency.
    h_volt = exp((handles.backint - temp(h_freq,2))/temp(h_freq,3));	%Find the required voltage to make a noise at the higher calibration center frequency.
    if l_volt == h_volt         %If this exact center frequency was calibrated for...
        volt = l_volt;          %...just use either value.
    else                        %Otherwise...
        volt = (h_volt - l_volt)*(cf - temp(l_freq,1))/(temp(h_freq,1) - temp(l_freq,1)) + l_volt;   %...linearly interpolate to find the voltage for the desired frequency.
    end
    signal = 1-2*rand(1,1000000);                                  	%Create a 10-second random noise signal.
    if cf ~= 0                                                   	%If this noise isn't white noise...
        cutoffs = cf + [-0.5,0.5]*bw;                             	%Find the high- and low-pass cutoffs.
        [b, a] = butter(fn/2,cutoffs*2/handles.rp2_sampling_rate); 	%Calculate Nth-order Butterworth filter coefficients.
        signal = filter(b,a,signal);                              	%Bandpass filter the random noise signal.
    end
    signal = signal/max(abs(signal));                             	%Scale the signal by it's absolute maximum.
    handles.rp2.SetTagVal('back_size',length(signal));           	%Set the length of the serial buffer in the RCX circuit.
    handles.rp2.WriteTagV('back_signal',0,signal);                	%Load the bandpass noise to the serial buffer.
    pause(0.1);                                                     %Pause to allow the signal to load.
    handles.rp2.SetTagVal('back_amp',volt);                         %Set the amplitude on the background noise.
    temp = length(soundorder)-find(s==soundorder)+1;                %Find the number of background noises left to be tested.
    temp = (temp*(handles.numtrials*mean(handles.iti)+handles.waittime)-handles.waittime)/86400;  %Calculate how long, in days, the session is expected to last.
    if cf == 0                                                      %If this is broadband noise...
        set(handles.figure1,'name',['Tinnitus Startle Testing: Broadband Noise (Runs Until ' datestr(now+temp,15) ')']);	%...set the figure title to say "broadband noise".
    else                                                            %Otherwise...
        set(handles.figure1,'name',['Tinnitus Startle Testing: ' num2str(cf/1000) 'kHz Narrowband Noise (Runs Until ' datestr(now+temp,15) ')']);	%%...set the figure title to say "narrowband noise".
    end
    if handles.habituate                                            %If we're habituating with the background noise before testing...
        tic;                                                        %Start a timer to track habituation time.
        while toc < 60*handles.habtime                              %Wait through the habituation time.
            run = str2double(get(handles.lblRun,'String'));         %Check the run label for user-specified pauses or stops.
            if run == 2                                             %If the user's paused the program...
                handles.rp2.SetTagVal('back_amp',0);                %...zero the amplitude during the pause...
                while run == 2                                      %...and wait until the user unpauses the program.
                    pause(0.05);                                   	%Every 50 ms...
                    run = str2double(get(handles.lblRun,'String'));    	%...check the run label for an unpause or a stop.
                end
                if run == 1                                         %If the user's unpaused the program...
                    handles.rp2.SetTagVal('back_amp',volt);       	%Reset the amplitude on the background noise.
                end
            end
            if run == 0                                             %If the user's stopped the program...
                fclose(fid);                                        %Close the *.STARTLE data file.
                if s == soundorder(1)                               %If we're on the first sound of the session...
                    delete(filename);                               %...just delete the data file, since there's no data in it.
                end
                handles.rp2.SetTagVal('back_amp',0);                %...zero the background noise amplitude.
                break;                                           	%Break out of the while loop.
            end
            pause(0.05);                                             %Pause for 50 ms before the next loop.
        end
    end
    if run == 0     %If the user's stopped the session...
        break;      %...break out of the while loop.
    end
    cueorder = zeros(1,handles.numtrials);                          %Create a matrix to hold the cued/uncued parameter.
    cueorder(1:round(handles.cueprob*handles.numtrials)) = 1;       %Make a proportion of the trials cued based on the cue probability.
    cueorder = cueorder(randperm(handles.numtrials));               %Randomize the cued/uncued parameter across all trials.
    
%%%%%%Practice Trial Code
    if tested_freqs == 0;        %if this is the first tested frequency
        pretrials = [0 0 0 0 1 1 1 1];      %do 4 uncued and cued trials
    else                                    %If this is not the first tested frequency
        pretrials = [0 0 1 1];              %just do 2 uncued and cued trials
    end
    
    for i = 1:length(pretrials)
        handles.zbus.zBusTrigB(0,0,10);                             %Reset the recording buffers with the zBus B trigger.
        set(0,'currentfigure',handles.figure1);                     %Set the currentfigure to the GUI.
        set(handles.figure1,'CurrentAxes',handles.axes1);         	%Plot the signal as it comes in in the top plot of the GUI.
        cla;                                                        %Clear the current plot.
        axis auto;                                                  %Set the axes back to auto-scaling.
        xlim([0,handles.rp2_sampling_rate*handles.sweeplength/1000]);  %Set the x-axis limits of the signal plot.
        set(gca,'xtick',(0:0.5:handles.sweeplength)*handles.rp2_sampling_rate,'xticklabel',0:0.5:handles.sweeplength);  %Set the x-axis tick labels.
        set(gca,'fontweight','bold','fontsize',10);                 %Set the fontweight and fontsize of the tick labels.
        xlabel('time (s)','fontweight','bold','fontsize',10);       %Label the x-axis.
        ylabel('startle (mV)','fontweight','bold','fontsize',10);  	%Label the y-axis.
        hold on;                                                    %Hold for multiple plots.
        buffer = [0 0];                                            	%Keep track of the buffer indices.
        trial_start = now;                                          %Save the timestamp at the start of the trial.
        if i < length(pretrials)        %If this isn't the last practice trials
            iti = 7 + rand*7;	%Create a random inter-trial interval between 7 and 14 seconds.
        else
            iti = handles.iti(1) + rand*(handles.iti(2)-handles.iti(1));    %use the real trial iti
        end
        tic;                                                        %Start the trial timer.
        handles.rp2.SetTagVal('cue_enable',pretrials(i));           	%Enable/disable the gap.
        handles.zbus.zBusTrigA(0,0,10);                             %Trigger stimulus presentation and startle recording.
        while toc < handles.sweeplength/1000                        %Wait while the stimuli are presented and the startle responses is recorded.
            pause(0.01);                                            %Pause for 10 milliseconds.
            buffer(2) = handles.rp2.GetTagVal('input_index');     	%Find the current buffer index.
            signal = handles.rp2.ReadTagV('input_signal', buffer(1), buffer(2)-buffer(1));	%Read in the last signal snippet.
            plot(buffer(1):buffer(2)-1,1000*signal,'color',[0 0.5 0]);  %Plot the signal snippet.
            buffer(1) = buffer(2)+1;                                %Set the next buffer start at the end of the last buffer.
        end
        hold off;                                                   %Release the plot hold.
        buffer(2) = handles.rp2.GetTagVal('input_index');              	%Find the current buffer index.
        signal = handles.rp2.ReadTagV('input_signal', 0, buffer(2));   	%This time grab the entire signal.
        signal = signal - mean(signal);                                 %Set the middle of the signal down to zero.
        signal = signal(1:100:length(signal));                        	%Downsample the signal to ~1000 Hz.
        scale_factor = max(abs(signal))/128;                           	%Find the scaling factor to turn the signal to 8-bit precision.
        temp = round(signal/scale_factor);  
        cla;                                                        	%Clear the plot.
        hold on;                                                        %Hold for multiple plots.
        set(gca,'xtick',(0:0.5:handles.sweeplength)*handles.rp2_sampling_rate/100,'xticklabel',-1:0.5:handles.sweeplength);  %Set the x-axis tick labels.
        a = ceil(handles.rp2_sampling_rate*([1, 1.3])/100);             %Find the samples in the startled snippet of the signal.
        temp = signal(a(1):a(2));                                       %Grab the startled snippet.
        plot(0:length(signal)-1,1000*signal,'color',[0 0.5 0]);       	%Plot the full signal in dark green.
        plot((a(1):a(2))-1,1000*temp,'color','r','linewidth',2);      	%Plot the startle snippet in wide, bright red.
        axis tight;                                                     %Tighten the axes.
        temp = 1000*temp;                                               %Change the startle snippet amplitude to millivolts.
        line([a(1),a(2)],[1,1]*min(temp),'color','b','linewidth',2);    %Show the lower amplitude of the startle.
        line([a(1),a(2)],[1,1]*max(temp),'color','b','linewidth',2);    %Show the upper amplitude of the startle.
        line([1,1]*mean(a),[min(temp),max(temp)],'color','b','linewidth',2,'linestyle','--');	%Connect the endpoints with a dashed line.
        text(a(2)+0.05*(max(a)-min(a)),max(temp),[num2str(max(temp)-min(temp),'%-3.2f') ' mV'],...
            'color','b','fontweight','bold','fontsize',12,'horizontalalignment',...
            'left','verticalalignment','top');      %Display the startle signal amplitude in millivolts.
        temp = max(abs(get(gca,'ylim')));         	%Grab the y-axis limits.
        set(gca,'ylim',[-1.4,1.1]*temp);            %Add a little room to the y axes.
        
        a = ((1000-handles.gapdelay)+[0,handles.gapdur])*handles.rp2_sampling_rate/100000;	%Find the onset and offset samples of the cue.
        if pretrials(i)                              %If this trial was cued...
            rectangle('position',[a(1),-1.3*temp,a(2)-a(1),0.2*temp],'facecolor','k',...
                'linewidth',2,'linestyle','-','edgecolor','k');             %Plot a rectangle to mark the cue.
            text(a(1),-1.2*temp,'Cue ','horizontalalignment','right','fontweight','bold',...
                'verticalalignment','middle','fontsize',12,'color','k');    %Indicate it as the cue.
        else                                        %If this trial was uncued...
            rectangle('position',[a(1),-1.3*temp,a(2)-a(1),0.2*temp],'facecolor','w',...
                'linewidth',2,'linestyle','--','edgecolor','k');            %Plot a rectangle to mark where the cue would be.
            text(a(1),-1.2*temp,'No Cue ','horizontalalignment','right','fontweight','bold',...
                'verticalalignment','middle','fontsize',12,'color','k');    %Indicate it as "No Cue".
        end
        a = [1, 1.02]*handles.rp2_sampling_rate/100;                	%Find the onset and offset samples of the startler.
        rectangle('position',[a(1),-1.3*temp,a(2)-a(1),0.2*temp],'facecolor','k',...
            'linewidth',2,'linestyle','-','edgecolor','k');             %Plot a rectangle to mark the startler.
        text(a(2),-1.2*temp,' Startler','horizontalalignment','left','fontweight','bold',...
            'verticalalignment','middle','fontsize',12,'color','k');    %Indicate it as the startler.
        a = text(min(get(gca,'xlim')),max(get(gca,'ylim')),['  Practice Trial #' num2str(i) '/' num2str(length(pretrials))],...
            'horizontalalignment','left','fontweight','bold','verticalalignment','top','fontsize',10,'color','k');    %Indicate the trial number.
        a = get(a,'extent');                    %Find the lower bound of the trial indicator text.
        a = max(get(gca,'ylim'))-1.1*a(4);  	%Find the y-value to set an underlying line of text.
        text(min(get(gca,'xlim')),a,['  Noise #' num2str(find(s==soundorder)) '/' num2str(length(soundorder))],...
            'horizontalalignment','left','fontweight','bold','verticalalignment','top','fontsize',10,'color','k');    %Indicate which noise was played.
        drawnow;        	%Draw the plot before continuing on.
        while toc < iti                                             %Wait through the inter-trial interval.
            run = str2double(get(handles.lblRun,'String'));         %Check the run label for user-specified pauses or stops.
            if run == 2                                             %If the user's paused the program...
                handles.rp2.SetTagVal('back_amp',0);                %...zero the amplitude during the pause...
                while run == 2                                      %...and wait until the user unpauses the program.
                    pause(0.1);                                         %Every 100 ms...
                    run = str2double(get(handles.lblRun,'String'));    	%Check the run label for an unpause or a stop.
                end
                if iti-toc < 60*handles.habtime && handles.habituate   	%If we're habituating...
                    iti = toc + 60*handles.habtime;                     %...rehabituate the rat before continuing.
                end
                if run == 1                                         %If the user's unpaused the program...
                    handles.rp2.SetTagVal('back_amp',volt);       	%Reset the amplitude on the background noise.
                end
            end
            if run == 0                                             %If the user's stopped the program...
                handles.rp2.SetTagVal('back_amp',0);                %...zero the background noise amplitude.
                break;                                           	%Break out of the wait loop.
            end
            pause(0.05);                                            %Pause for 50 ms before re-looping.
        end
        if run == 0               	%If the user's stopped the program...
            break;                	%Break out of the for loop.
        end
    end
        
    tested_freqs = 1;   %set the Boolean value to indicate that subsequent freqs are not the first tested
%%%%%Startle Trial Code
    
    for i = 1:handles.numtrials                                     %Step through each trial.
        handles.zbus.zBusTrigB(0,0,10);                             %Reset the recording buffers with the zBus B trigger.
        set(0,'currentfigure',handles.figure1);                     %Set the currentfigure to the GUI.
        set(handles.figure1,'CurrentAxes',handles.axes1);         	%Plot the signal as it comes in in the top plot of the GUI.
        cla;                                                        %Clear the current plot.
        axis auto;                                                  %Set the axes back to auto-scaling.
        xlim([0,handles.rp2_sampling_rate*handles.sweeplength/1000]);  %Set the x-axis limits of the signal plot.
        set(gca,'xtick',(0:0.5:handles.sweeplength)*handles.rp2_sampling_rate,'xticklabel',0:0.5:handles.sweeplength);  %Set the x-axis tick labels.
        set(gca,'fontweight','bold','fontsize',10);                 %Set the fontweight and fontsize of the tick labels.
        xlabel('time (s)','fontweight','bold','fontsize',10);       %Label the x-axis.
        ylabel('startle (mV)','fontweight','bold','fontsize',10);  	%Label the y-axis.
        hold on;                                                    %Hold for multiple plots.
        buffer = [0 0];                                            	%Keep track of the buffer indices.
        trial_start = now;                                          %Save the timestamp at the start of the trial.
        iti = handles.iti(1) + rand*(handles.iti(2)-handles.iti(1));	%Create a random inter-trial interval within the specified range.
        tic;                                                        %Start the trial timer.
        handles.rp2.SetTagVal('cue_enable',cueorder(i));           	%Enable/disable the gap.
        handles.zbus.zBusTrigA(0,0,10);                             %Trigger stimulus presentation and startle recording.
        while toc < handles.sweeplength/1000                        %Wait while the stimuli are presented and the startle responses is recorded.
            pause(0.01);                                            %Pause for 10 milliseconds.
            buffer(2) = handles.rp2.GetTagVal('input_index');     	%Find the current buffer index.
            signal = handles.rp2.ReadTagV('input_signal', buffer(1), buffer(2)-buffer(1));	%Read in the last signal snippet.
            plot(buffer(1):buffer(2)-1,1000*signal,'color',[0 0.5 0]);  %Plot the signal snippet.
            buffer(1) = buffer(2)+1;                                %Set the next buffer start at the end of the last buffer.
        end
        hold off;                                                   %Release the plot hold.
        buffer(2) = handles.rp2.GetTagVal('input_index');              	%Find the current buffer index.
        signal = handles.rp2.ReadTagV('input_signal', 0, buffer(2));   	%This time grab the entire signal.
        signal = signal - mean(signal);                                 %Set the middle of the signal down to zero.
        signal = signal(1:100:length(signal));                        	%Downsample the signal to ~1000 Hz.
        fwrite(fid,index,'int16');                                     	%Stimulus index.
        fwrite(fid,trial_start,'float64');                             	%Timestamp.
        fwrite(fid,cueorder(i),'uint8');                               	%Predicted or unpredicted startler.
        fwrite(fid,handles.gapdur,'float32');                          	%Parameter value #1 (Predictor Duration (ms)).
        fwrite(fid,cf/1000,'float32');                                 	%Parameter value #2 (Background Center Frequency (kHz)).
        fwrite(fid,bw,'float32');                                      	%Parameter value #3 (Background Bandwidth (Hz)).
        fwrite(fid,handles.backint,'float32');                         	%Parameter value #4 (Background Intensity (dB)).
        fwrite(fid,20,'float32');                                     	%Parameter value #5 (Startler Duration (ms)).
        fwrite(fid,handles.startleint,'float32');                      	%Parameter value #6 (Startler Intensity (dB)).
        scale_factor = max(abs(signal))/128;                           	%Find the scaling factor to turn the signal to 8-bit precision.
        temp = round(signal/scale_factor);                          	%Change the signal to 8-bit precision.
        fwrite(fid,handles.sweeplength/1000,'float32');                	%Sweeplength, in seconds.
        fwrite(fid,length(signal),'uint32');                         	%Number of samples in the data sweep.
        fwrite(fid,scale_factor,'float32');                            	%Scale factor to return signal to real voltage values.
        fwrite(fid,temp,'int8');                                     	%Sweep data;
        cla;                                                        	%Clear the plot.
        hold on;                                                        %Hold for multiple plots.
        set(gca,'xtick',(0:0.5:handles.sweeplength)*handles.rp2_sampling_rate/100,'xticklabel',-1:0.5:handles.sweeplength);  %Set the x-axis tick labels.
        a = ceil(handles.rp2_sampling_rate*([1, 1.3])/100);             %Find the samples in the startled snippet of the signal.
        temp = signal(a(1):a(2));                                       %Grab the startled snippet.
        plot(0:length(signal)-1,1000*signal,'color',[0 0.5 0]);       	%Plot the full signal in dark green.
        plot((a(1):a(2))-1,1000*temp,'color','r','linewidth',2);      	%Plot the startle snippet in wide, bright red.
        axis tight;                                                     %Tighten the axes.
        data(i,s==soundorder,2) = cueorder(i);                          %Save whether this was cued or uncued in the plot data.
        data(i,s==soundorder,1) = max(temp) - min(temp);              	%Save the startle amplitude for this trial.
        temp = 1000*temp;                                               %Change the startle snippet amplitude to millivolts.
        line([a(1),a(2)],[1,1]*min(temp),'color','b','linewidth',2);    %Show the lower amplitude of the startle.
        line([a(1),a(2)],[1,1]*max(temp),'color','b','linewidth',2);    %Show the upper amplitude of the startle.
        line([1,1]*mean(a),[min(temp),max(temp)],'color','b','linewidth',2,'linestyle','--');	%Connect the endpoints with a dashed line.
        text(a(2)+0.05*(max(a)-min(a)),max(temp),[num2str(max(temp)-min(temp),'%-3.2f') ' mV'],...
            'color','b','fontweight','bold','fontsize',12,'horizontalalignment',...
            'left','verticalalignment','top');      %Display the startle signal amplitude in millivolts.
        temp = max(abs(get(gca,'ylim')));         	%Grab the y-axis limits.
        set(gca,'ylim',[-1.4,1.1]*temp);            %Add a little room to the y axes.
        a = ((1000-handles.gapdelay)+[0,handles.gapdur])*handles.rp2_sampling_rate/100000;	%Find the onset and offset samples of the cue.
        if cueorder(i)                              %If this trial was cued...
            rectangle('position',[a(1),-1.3*temp,a(2)-a(1),0.2*temp],'facecolor','k',...
                'linewidth',2,'linestyle','-','edgecolor','k');             %Plot a rectangle to mark the cue.
            text(a(1),-1.2*temp,'Cue ','horizontalalignment','right','fontweight','bold',...
                'verticalalignment','middle','fontsize',12,'color','k');    %Indicate it as the cue.
        else                                        %If this trial was uncued...
            rectangle('position',[a(1),-1.3*temp,a(2)-a(1),0.2*temp],'facecolor','w',...
                'linewidth',2,'linestyle','--','edgecolor','k');            %Plot a rectangle to mark where the cue would be.
            text(a(1),-1.2*temp,'No Cue ','horizontalalignment','right','fontweight','bold',...
                'verticalalignment','middle','fontsize',12,'color','k');    %Indicate it as "No Cue".
        end
        a = [1, 1.02]*handles.rp2_sampling_rate/100;                	%Find the onset and offset samples of the startler.
        rectangle('position',[a(1),-1.3*temp,a(2)-a(1),0.2*temp],'facecolor','k',...
            'linewidth',2,'linestyle','-','edgecolor','k');             %Plot a rectangle to mark the startler.
        text(a(2),-1.2*temp,' Startler','horizontalalignment','left','fontweight','bold',...
            'verticalalignment','middle','fontsize',12,'color','k');    %Indicate it as the startler.
        a = text(min(get(gca,'xlim')),max(get(gca,'ylim')),['  Trial #' num2str(i) '/' num2str(handles.numtrials)],...
            'horizontalalignment','left','fontweight','bold','verticalalignment','top','fontsize',10,'color','k');    %Indicate the trial number.
        a = get(a,'extent');                    %Find the lower bound of the trial indicator text.
        a = max(get(gca,'ylim'))-1.1*a(4);  	%Find the y-value to set an underlying line of text.
        text(min(get(gca,'xlim')),a,['  Noise #' num2str(find(s==soundorder)) '/' num2str(length(soundorder))],...
            'horizontalalignment','left','fontweight','bold','verticalalignment','top','fontsize',10,'color','k');    %Indicate which noise was played.
        drawnow;        	%Draw the plot before continuing on.
        if handles.recording    %If we're recording...
            set(0,'currentfigure',fig1);        %Set the currentfigure to figure #1.
            set(fig1,'CurrentAxes',recplot);	%Set the current axes to the recording plot.
            set(recplot,'yticklabel','','xticklabel','','xtick',1:3, 'ytick',-3:1:-1,'xlim',[0,4],'ylim',[-4 0]);	%Clear any x- or y-ticks off the plot.
            cla;            %Clear the plot.
            hold on;        %Hold for multiple plots.
            for j = 1:16    %Step through all channels, even disabled channels.
                signal = rxn.ReadTagV(['data_' num2str(j)], 0, buffsize);  	%Read in the previous sweep's data from the buffer.
                if any(j == recording_channels)                           	%If recording is enabled for this channel...
                 	fwrite(recfid(j),index,'int16');                    	%Stimulus index.
                    fwrite(recfid(j),trial_start,'float64');                %Timestamp.
                    fwrite(recfid(j),handles.gapdur,'float32');          	%Parameter value #1 (Predictor Duration (ms)).
                    fwrite(recfid(j),cf/1000,'float32');                 	%Parameter value #2 (Background Center Frequency (kHz)).
                    fwrite(recfid(j),bw,'float32');                        	%Parameter value #3 (Background Bandwidth (Hz)).
                    fwrite(recfid(j),handles.backint,'float32');          	%Parameter value #4 (Background Intensity (dB)).
                    fwrite(recfid(j),20,'float32');                        	%Parameter value #5 (Startler Duration (ms)).
                    fwrite(recfid(j),handles.startleint,'float32');        	%Parameter value #6 (Startler Intensity (dB)).
                    fwrite(recfid(j),predictor_delay,'float32');           	%Parameter value #7 (Predictor Delay (ms)).
                    fwrite(recfid(j),startler_delay,'float32');            	%Parameter value #8 (Startler Delay (dB)).
                    fwrite(recfid(j),handles.sweeplength/1000,'float32'); 	%Sweeplength, in seconds.
                    fwrite(recfid(j),length(signal),'uint32');            	%Number of samples in the data sweep.
                    fwrite(recfid(j),signal','float32');                  	%Sweep data;
                end
                signal = filtfilt(recfilter(1,:),recfilter(2,:),signal);  	%Run the data through the bandpass filter.
                signal = y(j) + 0.45*signal/max(abs(signal));             	%Auto-scale the data to fit in the plot.
                plot(x(j):0.9/(length(signal)-1):(x(j)+0.9),signal,'color',colors(j,:));    %Plot the signal in the appropriate color.
                text(x(j)+0.025,y(j),num2str(j),'color','k','fontweight','bold','fontsize',14); 	%Plot the channel number on the signal.
            end
            drawnow;
        end
        plotdata(1,s==handles.selected_noises) = 1000*nanmean(data(data(:,s==soundorder,2) == 1,s==soundorder,1));    %Recalculate the mean cued startle amplitude.
        plotdata(2,s==handles.selected_noises) = 1000*nanmean(data(data(:,s==soundorder,2) == 0,s==soundorder,1));    %Recalculate the mean uncued startle amplitude.
        plotdata(3,s==handles.selected_noises) = 1000*simple_ci(data(data(:,s==soundorder,2) == 1,s==soundorder,1)); 	%Recalculate the cued startle amplitude confidence interval.
        plotdata(4,s==handles.selected_noises) = 1000*simple_ci(data(data(:,s==soundorder,2) == 0,s==soundorder,1)); 	%Recalculate the uncued startle amplitude confidence interval.
        if sum(data(:,s==soundorder,2) == 1) == sum(data(:,s==soundorder,2) == 0)                   %If the sample sizes for cued and uncued responses are the same...
            plotdata(5,s==handles.selected_noises) = signrank(data(data(:,s==soundorder,2) == 1,s==soundorder,1),...
                data(data(:,s==soundorder,2) == 0,s==soundorder,1));	%...use an MPSR test to find significance.
        else                                                            %Otherwise...
            [h,a] = ttest2(data(data(:,s==soundorder,2) == 1,s==soundorder,1),...
                data(data(:,s==soundorder,2) == 0,s==soundorder,1));   	%...use a two-sample t-test to find signifance...
            plotdata(5,s==handles.selected_noises) = a;                           	%...and save the p-value.
        end
        set(0,'currentfigure',handles.figure1);                     %Set the currentfigure to the GUI.
        set(handles.figure1,'CurrentAxes',handles.axes2);         	%Plot the session data in the bottom plot of the GUI.
        cla;                                                        %Clear the current plot.
        hold on;                                                    %Hold for multiple plots.
        if length(soundorder) ~= 1                                  %If we've got more than one sound...
            errorbar((1:length(soundorder))'*[1 1],plotdata(1:2,:)',plotdata(3:4,:)','linewidth',2); 	%Plot the startle response means as error bars.
        else                                                        %Otherwise, we'll have to plot cued and uncued separately.
            errorbar(1,plotdata(1),plotdata(3),'linewidth',2,'color','b');          %Plot the cued startle response means as error bars.
            errorbar(1,plotdata(2),plotdata(4),'linewidth',2,'color',[0 0.5 0]); 	%Plot the uncuedstartle response means as error bars.
        end
        box on;         %Put a boz around the plot.
        axis tight;     %Tighten the axes.
        grid on;        %Overlay the plot on a grid.
        xlim([0.5,size(plotdata,2)+0.5]);           %Set the x-axis limits.
        temp = get(gca,'ylim');                     %Grab the current y-axis limits.
        ylim(temp + [-0.05,0.1]*(max(temp)-min(temp)));       %Slightly widen the y-axis limits.
        set(gca,'xtick',1:size(plotdata,2),'xticklabel',plotlabels,'fontweight','bold','fontsize',10);
        a = find(plotdata(5,:) < 0.05);   	%Find all significant comparisons.
        plot(a,repmat(temp(2) + 0.05*(max(temp)-min(temp)),length(a)),'markerfacecolor','r','marker','*','markersize',10,'linestyle','none');  %Plot significance markers.
        hold off;                           %Release the plot.
        ylabel('Startle (mV)','fontweight','bold','fontsize',10); %Label the y-axis.
        legend('Cued','Uncued','location','best','orientation','horizontal');   %Make a legend.
        while toc < iti                                             %Wait through the inter-trial interval.
            run = str2double(get(handles.lblRun,'String'));         %Check the run label for user-specified pauses or stops.
            if run == 2                                             %If the user's paused the program...
                handles.rp2.SetTagVal('back_amp',0);                %...zero the amplitude during the pause...
                while run == 2                                      %...and wait until the user unpauses the program.
                    pause(0.1);                                         %Every 100 ms...
                    run = str2double(get(handles.lblRun,'String'));    	%Check the run label for an unpause or a stop.
                end
                if iti-toc < 60*handles.habtime && handles.habituate   	%If we're habituating...
                    iti = toc + 60*handles.habtime;                     %...rehabituate the rat before continuing.
                end
                if run == 1                                         %If the user's unpaused the program...
                    handles.rp2.SetTagVal('back_amp',volt);       	%Reset the amplitude on the background noise.
                end
            end
            if run == 0                                             %If the user's stopped the program...
                handles.rp2.SetTagVal('back_amp',0);                %...zero the background noise amplitude.
                break;                                           	%Break out of the wait loop.
            end
            pause(0.05);                                            %Pause for 50 ms before re-looping.
        end
        if run == 0               	%If the user's stopped the program...
            break;                	%Break out of the for loop.
        end
    end
    handles.rp2.SetTagVal('back_amp',0);	%Zero the background noise amplitude.
    index = index + 1;                      %Advance the stimulus index.
    tic;        %Reset the timer.
    %disp(['s is ', num2str(s)])
    if soundcounter < length(soundorder)            %If there's more background noises to be tested
    %if s < soundorder(length(soundorder))   %(This doesn't work because s indicates the position of the tested frequency in the list, not it's order in the permutated set of freqs to be tested)If there's more background noises to be tested...
        disp(['Frequency Session #', num2str(soundcounter), ' completed. Countdown Initiated'])
        soundcounter = soundcounter + 1;            %increment the counter to indicate next freq
        temp = length(soundorder)-find(s==soundorder)+1;                %Find the number of background noises left to be tested.
        temp = (temp*(handles.numtrials*mean(handles.iti)+handles.waittime)-handles.waittime)/86400;  %Calculate how long, in days, the session is expected to last.
        set(handles.figure1,'name',['Pausing Before Next Background Noise (Runs Until ' datestr(now+temp,15) ')']);     %...set the figure title to say "broadband noise".
        countdowntimer = toc;
        %disp(['toc at wait is ', num2str(toc)])
        while toc < handles.waittime                                	%Wait for a specified pause between background sounds.
            if toc - countdowntimer >= 10
            disp('Countdown')
            disp(handles.waittime - toc)
            countdowntimer = toc;
            end
            run = str2double(get(handles.lblRun,'String'));          	%Check the run label for user-specified pauses or stops.
            if run == 2                                              	%If the user's paused the program...
                while run == 2                                        	%...and wait until the user unpauses the program.
                    pause(0.1);                                         %Every 100 ms...
                    run = str2double(get(handles.lblRun,'String'));    	%Check the run label for an unpause or a stop.
                end
            end
            if run == 0                                             %If the user's stopped the program...
                break;                                           	%...break out of the wait loop.
            end
            pause(0.1);                                            %Pause for 100 ms before re-looping.
        end
    end
    if run == 0  || s == soundorder(length(soundorder))     %If the user's stopped the program...
        break;                              %...break out of the for loop.
    end
end
fclose all;     %Close the *.STARTLE data file.

%Enable all GUI controls except the "Pause" and "Stop" buttons.
set(handles.chkHabituate,'enable','on');        %Habituation checkbox.
set(handles.txtHabtime,'enable','on')        	%Habituation time textbox.
set(handles.txtITI1,'enable','on');         	%Inter-trial interval lower bound textbox.
set(handles.txtITI2,'enable','on');             %Inter-trial interval upper bound textbox.
set(handles.txtCuepercent,'enable','on');       %Cue probability percent textbox.
set(handles.txtTrials,'enable','on');           %Number of trials textbox.
set(handles.txtCuedur,'enable','on');        	%Gap duration textbox
set(handles.txtCuedelay,'enable','on');         %Gap delay textbox.
set(handles.txtBackint,'enable','on');        	%Background intensity textbox.
set(handles.txtStartleint,'enable','on');       %Startler intensity textbox.
set(handles.lstNoises,'enable','on');         	%Background noises listbox.
set(handles.txtRatname,'enable','on');        	%Rat name textbox.
set(handles.cmdRecord,'enable','off');         	%Neural recordings button.
set(handles.cmdStop,'enable','off');           	%Stop button.
set(handles.cmdPause,'enable','off');        	%Pause button.
set(handles.cmdStart,'enable','on');        	%Start button.
set(handles.figure1,'name','Tinnitus Startle Testing: Finished');       %%Set the figure title to say "finished".
guidata(hObject, handles);                      %Update the handles structure.


%cmdPause BUTTON PRESS
%**************************************************************************
%This function is called when the uses pushes "Pause."
function cmdPause_Callback(hObject, eventdata, handles)
if strcmp(get(handles.cmdPause,'string'),'Pause')   %If the program's isn't already paused...
    set(handles.cmdPause,'string','Resume');        %...set the button string to "Resume"...
    set(handles.lblRun,'string','2');               %...and set the run label to 2.
else                                                %If the program is currently paused...
    set(handles.cmdPause,'string','Pause');         %...set the button string to "Pause"...
    set(handles.lblRun,'string','1');               %...and set the run label back to 1.
end
guidata(hObject, handles);                          %Update the handles structure.


%cmdStop BUTTON PRESS
%**************************************************************************
%This function is called when the uses pushes "Stop."
function cmdStop_Callback(hObject, eventdata, handles)
set(handles.lblRun,'string','0');  	%Set the run label to zero.
guidata(hObject, handles);        	%Update the handles structure.


%lstNoises SELECTION
%**************************************************************************
%This function is called when an user selects an item in the background noises list.
function lstNoises_Callback(hObject, eventdata, handles)
handles.selected_noises = get(hObject,'value');     %Grab the value of the input and save it to the handles structure.
if ~isempty(handles.selected_noises) && ~isempty(handles.ratname)   %If a rat's name is entered and no background noises are selected...
    set(handles.cmdStart,'enable','on');                            %...enable the start button.
else                                                                %Otherwise...
    set(handles.cmdStart,'enable','off');                           %...disable the start button.
end
guidata(hObject, handles);                         	%Update the handles structure.


%LOAD txtCuepercent
%**************************************************************************
%This function is called when txtCuepercent is first created.
function lstNoises_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


%cmdRecord BUTTON PRESS
%**************************************************************************
%This function is called when the uses pushes the neural recordings button.
function cmdRecord_Callback(hObject, eventdata, handles)
if handles.recording == 0       %If neural recordings were previously turned off...
    handles.recording = 1;      %...turn the neural recordings on.
    set(handles.cmdRecord,'string','Neural Recordings: On','foregroundcolor',[0 0.5 0]);
    handles.rxn_RCX_filename = [handles.rcxpath 'RZ5_A-P.rcx'];             %Name of the RZ5 RCX file.
else                            %Otherwise...
    handles.recording = 0;      %...turn the neural recordings off.
    set(handles.cmdRecord,'string','Neural Recordings: Off','foregroundcolor',[0.5 0 0]);
    handles.rxn_RCX_filename = [handles.rcxpath 'RZ5_Use_As_Monitor.rcx'];	%Name of the RZ5 RCX file.
end
guidata(hObject, handles);        	%Update the handles structure.
