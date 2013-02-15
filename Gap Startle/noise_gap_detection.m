
function varargout = noise_gap_detection(varargin)
% noise_gap_detection M-file for noise_gap_detection.fig
%      noise_gap_detection, by itself, creates a new noise_gap_detection or raises the existing
%      singleton*.
%
%      H = noise_gap_detection returns the handle to a new noise_gap_detection or the handle to
%      the existing singleton*.
%
%      noise_gap_detection('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in noise_gap_detection.M with the given input arguments.
%
%      noise_gap_detection('Property','Value',...) creates a new noise_gap_detection or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before noise_gap_detection_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property
%      applicationlastasdfasd


%      stop.  All inputs are passed to noise_gap_detection_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Copyright 2002-2003 The MathWorks, Inc.

% Edit the above text to modify the response to help noise_gap_detection

% Last Modified by GUIDE v2.5 13-Apr-2010 09:25:56

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @noise_gap_detection_OpeningFcn, ...
                   'gui_OutputFcn',  @noise_gap_detection_OutputFcn, ...
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


% --- Executes just before noise_gap_detection is made visible.
function noise_gap_detection_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to noise_gap_detection (see VARARGIN)

% Choose default command line output for noise_gap_detection
handles.output = hObject;   

% Update handles structure
guidata(hObject, handles);


initialize_graphs(hObject,handles);
% UIWAIT makes noise_gap_detection wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = noise_gap_detection_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


%CreateFcn functions.
function picCombo_CreateFcn(hObject, eventdata, handles)
function cmdOverride_CreateFcn(hObject, eventdata, handles)
function edit1_CreateFcn(hObject, eventdata, handles)
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end
function edit1_Callback(hObject, eventdata, handles)


% --- Executes on key press over txtRatname with no controls selected.
function txtRatname_KeyPressFcn(hObject, eventdata, handles)
set(handles.cmdAuto,'Enable','on');
set(handles.cmdOverride,'Enable','on');
guidata(hObject, handles);


%Executes whenever txtRatname is queried.
function txtRatname_Callback(hObject, eventdata, handles)
handles.ratname = get(hObject,'String');
handles.ratname(handles.ratname == ' ') = '_';
handles.ratname = upper(handles.ratname);
set(handles.txtRatname,'String',handles.ratname);
guidata(hObject, handles);


% --- Executes on button press in cmdOverride.
function cmdOverride_Callback(hObject, eventdata, handles)
handles.override = 1;
hide_buttons_1(hObject,handles);
guidata(hObject, handles);


% --- Executes on button press in cmdAuto.
function cmdAuto_Callback(hObject, eventdata, handles)
handles.override = 0;
hide_buttons_1(hObject,handles);
guidata(hObject, handles);


% --- Executes on button press in cmdRecord.
function cmdRecord_Callback(hObject, eventdata, handles)
handles.recording = 1;
hide_buttons_2(hObject,handles);
set(handles.lblRun,'String','1');
guidata(hObject, handles);
noise_gap_detection_training(handles,hObject);


% --- Executes on button press in cmdNorecord.
function cmdNorecord_Callback(hObject, eventdata, handles)
handles.recording = 0;
hide_buttons_2(hObject,handles);
set(handles.lblRun,'String','1');
guidata(hObject, handles);
noise_gap_detection_training(handles,hObject);


% --- Executes on button press in cmdStop.
function cmdStop_Callback(hObject, eventdata, handles)
set(handles.lblRun,'String','0');
set(handles.cmdFeedLeft,'visible','off');
set(handles.cmdFeedLeft,'enable','off');
set(handles.lblRatname,'enable','off');
set(handles.lblTesttypetag,'enable','off');
set(handles.lblTesttype,'enable','off');
set(handles.lblStagetag,'enable','off');
set(handles.lblStage,'enable','off');
set(handles.lblFeedingtag,'enable','off');
set(handles.lblFeeding,'enable','off');
set(handles.lblFrequencytag,'enable','off');
set(handles.lblFrequency,'enable','off');
set(handles.lblRatname,'visible','off');
set(handles.lblTesttypetag,'visible','off');
set(handles.lblTesttype,'visible','off');
set(handles.lblStagetag,'visible','off');
set(handles.lblStage,'visible','off');
set(handles.lblFeedingtag,'visible','off');
set(handles.lblFeeding,'visible','off');
set(handles.lblFrequencytag,'visible','off');
set(handles.lblFrequency,'visible','off');
set(handles.lblRun,'enable','on');
set(handles.cmdStop,'enable','off');
set(handles.cmdStop,'visible','off');
set(handles.lblRatnametag,'enable','on');
set(handles.lblRatnametag,'visible','on');
set(handles.cmdAuto,'enable','on');
set(handles.cmdOverride,'enable','on');
set(handles.cmdAuto,'visible','on');
set(handles.cmdOverride,'visible','on');
set(handles.cmdRecord,'visible','on');
set(handles.cmdNorecord,'visible','on');
set(handles.txtRatname,'enable','on');
set(handles.txtRatname,'visible','on');
guidata(hObject, handles);


%SUB FUNCTIONS ************************************************************
%**************************************************************************
function initialize_graphs(hObjects, handles)
axes(handles.picCombo);
cla;
set(gca,'Xlim',[0 1],'YLim',[0 1],'XTick',[],'XTickLabel','','YTick',[],'YTickLabel','');
ylabel('');
box on;
axes(handles.picPsycho);
cla;
xlabel('');
ylabel('');
box on;

function hide_buttons_1(hObject,handles)
%Off
set(handles.lblRatnametag,'enable','off');
set(handles.lblRatnametag,'visible','off');
set(handles.cmdAuto,'enable','off');
set(handles.cmdOverride,'enable','off');
set(handles.txtRatname,'enable','off');
%On
set(handles.cmdAuto,'enable','off');
set(handles.cmdOverride,'enable','off');
set(handles.cmdRecord,'enable','on');
set(handles.cmdNorecord,'enable','on');
guidata(hObject, handles);

function hide_buttons_2(hObject,handles)
%Off
set(handles.cmdAuto,'enable','off');
set(handles.cmdOverride,'enable','off');
set(handles.cmdRecord,'enable','off');
set(handles.cmdNorecord,'enable','off');
set(handles.cmdAuto,'visible','off');
set(handles.cmdOverride,'visible','off');
set(handles.cmdRecord,'visible','off');
set(handles.cmdNorecord,'visible','off');
%On
set(handles.lblRatnametag,'enable','on');
set(handles.lblRatnametag,'visible','on');
set(handles.cmdFeedLeft,'visible','on');
set(handles.cmdFeedLeft,'enable','on');
set(handles.lblRatname,'enable','on');
set(handles.lblTesttypetag,'enable','on');
set(handles.lblTesttype,'enable','on');
set(handles.lblStagetag,'enable','on');
set(handles.lblStage,'enable','on');
set(handles.lblFeedingtag,'enable','on');
set(handles.lblFeeding,'enable','on');
set(handles.lblFrequencytag,'enable','on');
set(handles.lblFrequency,'enable','on');
set(handles.lblRatname,'visible','on');
set(handles.lblTesttypetag,'visible','on');
set(handles.lblTesttype,'visible','on');
set(handles.lblStagetag,'visible','on');
set(handles.lblStage,'visible','on');
set(handles.lblFeedingtag,'visible','on');
set(handles.lblFeeding,'visible','on');
set(handles.lblFrequencytag,'visible','on');
set(handles.lblFrequency,'visible','on');
set(handles.lblRun,'enable','on');
set(handles.cmdStop,'enable','on');
set(handles.cmdStop,'visible','on');
set(handles.lblRatname,'String',handles.ratname);
set(handles.lblFeeding,'String','0');
set(handles.lblFrequency,'String',datestr(now,16));
guidata(hObject, handles);


% --- Executes on button press in cmdFeedLeft.
function cmdFeedLeft_Callback(hObject, eventdata, handles)
set(handles.lblRun,'String','2');
guidata(hObject, handles);
