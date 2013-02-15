function varargout = Test_2D_Control(varargin)

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Test_2D_Control_OpeningFcn, ...
                   'gui_OutputFcn',  @Test_2D_Control_OutputFcn, ...
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


% --- Executes just before Test_2D_Control is made visible.
function Test_2D_Control_OpeningFcn(hObject, eventdata, handles, varargin)

    handles.run = 0;        %This field will control the sound-generating loop.
    handles.freqrange = [200 1000];     %Range of frequencies over which the tones can vary, in Hz.
    handles.intrange = [0.1 0.4];      	%Range of intensities over which the tones will vary, in ~volts.
    handles.dur = 100;                 	%Duration of the tones, in milliseconds.
    handles.iti = 0;                    %Inter-tone interval, in milliseconds (can be set to zero);
    handles.ramp = 5;                   %Duration of the onset and offset cosine ramps, in milliseconds.
    handles.sampling_rate = 97656.25;  	%Sampling rate, in Hz (The TDT RP2 can samples at 97656.0625 Hz when set to 100 kHz).
    handles.tone_samples = round(handles.dur*handles.sampling_rate/1000);   %The number of samples in each tone.
    handles.ramp_samples = round(handles.ramp*handles.sampling_rate/1000);  %The number of samples in the cosine ramp.
    handles.iti_samples = round(handles.iti*handles.sampling_rate/1000);    %The number of samples in the cosine ramp.
    %Set the max, min, and value on the horizontal slider.
    set(handles.hscHoriz,'min',handles.freqrange(1),'max',handles.freqrange(2),'value',mean(handles.freqrange));
    %Set the max, min, and value on the vertical slider.
    set(handles.hscVert,'min',handles.intrange(1),'max',handles.intrange(2),'value',mean(handles.intrange));

    handles.output = hObject;   %Default command line output for Test_2D_Control.
    guidata(hObject, handles);  %Update handles structure.

    
% --- Outputs from this function are returned to the command line.
function varargout = Test_2D_Control_OutputFcn(hObject, eventdata, handles) 
    varargout{1} = handles.output;

% --- Executes on slider movement.
function hscVert_Callback(hObject, eventdata, handles)

%--- Executes on slider movement.
function hscHoriz_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function hscVert_CreateFcn(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function hscHoriz_CreateFcn(hObject, eventdata, handles)


% --- Executes on button press in cmdOnOff.
function cmdOnOff_Callback(hObject, eventdata, handles)
    run = get(handles.cmdOnOff,'string');       %Get the string for the On-Off button.
    if strcmpi(run,'Start')                     %If we're starting the play loop...

        %Create a reference tone.
        %Generate a random reference frequency within our set frequency range.
        handles.reffreq = rand*(handles.freqrange(2)-handles.freqrange(1)) + handles.freqrange(1);
        %Generate a random intensity within our set range.
        handles.refint = rand*(handles.intrange(2)-handles.intrange(1)) + handles.intrange(1);
        %Create the reference tone as a simple sine wave with amplitude equal to intensity.
        handles.reftone = handles.refint*sin([1:handles.tone_samples]*2*pi/(handles.sampling_rate/handles.reffreq));
        %Use a cosine ramp to smooth the onset and offset.
        handles.reftone(1:handles.ramp_samples) = ...
            handles.reftone(1:handles.ramp_samples).*(1-cos(pi*[1:handles.ramp_samples]/handles.ramp_samples))/2;
        handles.reftone(handles.tone_samples-handles.ramp_samples+1:handles.tone_samples) = ...
            handles.reftone(handles.tone_samples-handles.ramp_samples+1:handles.tone_samples).*(1+cos(pi*[1:handles.ramp_samples]/handles.ramp_samples))/2;

        %Create an initial target tone.
        handles.tarfreq = mean(handles.freqrange);      %Target frequency is initially set to the center of the range.
        handles.tarint = mean(handles.intrange);        %Target intensity is initially set to the center of the range.
        set(handles.hscVert,'value',handles.tarint);    %Set the initial target intensity on the vertical slider.
        set(handles.hscHoriz,'value',handles.tarfreq);  %Set the initial target frequency on the horizontal slider.
        set(handles.cmdOnOff,'string','Stop');          %Set the On-Off button string to "Stop".
        axes(handles.picBox);                           %Grab the GUI axes for plotting.
        cla;                                            %Clear any existing plots.
        %Mark the location of the reference.
        plot(handles.reffreq,handles.refint,'markeredgecolor','r','marker','o','markersize',10);      
        xlabel('Frequency','fontsize',12);              %Label the x axis.  
        ylabel('Intensity','fontsize',12);              %Label the y axis.
        xlim(handles.freqrange);                        %Set the x axis range to the frequency range.
        ylim(handles.intrange);                         %Set the y axis range to the intensity range.
        hold on;                                        %Hold the plot to overlay target information.
        pause(0.2);                                     %Pause to set the plots.
        set(handles.hscHoriz,'enable','on');            %Enable the horizontal slider.
        set(handles.hscVert,'enable','on');             %Enable the vertical slider.
        handles = PlayLoop(handles, hObject);           %Start the tone play loop.
    else    %If we're stopping the play loop...
        set(handles.cmdOnOff,'enable','off');           %Disable the On-Off button so we can't interrupt execution.
        set(handles.cmdOnOff,'string','Start');         %Set the On-Off button string to "Start".
        set(handles.hscHoriz,'enable','off');           %Disable the horizontal slider.
        set(handles.hscVert,'enable','off');            %Disable the vertical slider.
        set(handles.cmdOnOff,'enable','on');            %Re-enable the On-Off button.
    end
    guidata(hObject, handles);                          %Update the handles structure.

    
%**************************************************************************
%FUNCTION PlayLoop --- Plays sounds and adjusts target frequency and
%intensity according to slider values.
function handles = PlayLoop(handles, hObject)
    run = get(handles.cmdOnOff,'string');       %Grab the cmdOnOff string to control the loop.
    tic;                                        %Start the timer to control timing.
    while strcmpi(run,'Stop')
        handles.tarint = get(handles.hscVert,'value');      %Get the target intensity from the vertical slider.
        handles.tarfreq = get(handles.hscHoriz,'value');  	%Get the target frequency from the horizontal slider.
        plot(handles.tarfreq,handles.tarint,'.b');          %Plot the current target location.
        drawnow;                                            %Draw the plot immediately.
        %Create the target tone as a simple sine wave with amplitude equal to intensity.
        handles.tartone = handles.tarint*sin([1:handles.tone_samples]*2*pi/(handles.sampling_rate/handles.tarfreq));
        %Use a cosine ramp to smooth the onset and offset.
        handles.tartone(1:handles.ramp_samples) = ...
            handles.tartone(1:handles.ramp_samples).*(1-cos(pi*[1:handles.ramp_samples]/handles.ramp_samples))/2;
        handles.tartone(handles.tone_samples-handles.ramp_samples+1:handles.tone_samples) = ...
            handles.tartone(handles.tone_samples-handles.ramp_samples+1:handles.tone_samples).*(1+cos(pi*[1:handles.ramp_samples]/handles.ramp_samples))/2;
        signal = [handles.reftone, zeros(1,handles.iti_samples), handles.tartone];     %The full signal is the reference and target tone stuck together.
        run = get(handles.cmdOnOff,'string');           %Grab the cmdOnOff string to see if we should stop the loop.
        pause(2*(handles.dur + handles.iti)/1000-toc);	%Wait for a full period to pass.
        wavplay(signal,handles.sampling_rate,'async');  %Play the tones as wave sounds.
        tic;                                            %Zero the timer.
    end
    guidata(hObject, handles);      %Update the handles structure.