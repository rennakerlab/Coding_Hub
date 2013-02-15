function varargout = NEL_Spiker(varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % NEL(Neural Engineering Lab) Spiker. 
% % Software by Shazafar Khaja
% % shahzafar@gmail.com
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @NEL_Spiker_OpeningFcn, ...
                   'gui_OutputFcn',  @NEL_Spiker_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin & isstr(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before NEL_Spiker is made visible.
function NEL_Spiker_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject;
handles.filename = '*.txt';
handles.methodtype = 1;
handles.principalcomponents = 0;
handles.clusters = 0;
handles.frame = javax.swing.JFrame; %create the JFrame
handles.fc = javax.swing.JFileChooser; %create the JFileChooser
guidata(hObject, handles);


% --- Outputs from this function are returned to the command line.
function varargout = NEL_Spiker_OutputFcn(hObject, eventdata, handles)
varargout{1} = handles.output;


% --- Executes during object creation, after setting all properties.
function edit1_CreateFcn(hObject, eventdata, handles)
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function edit1_Callback(hObject, eventdata, handles)
handles.filename = get(hObject,'String');
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Loading the F32 file into the GUI.
% --- Executes on button press in pushbutton6.
function pushbutton6_Callback(hObject, eventdata, handles)
handles.frame.setVisible(1); %make the frame visible
pause(.999);

%selectionstatus tells us wether or not there's been a selection; usually
%you put the open stuff up function here, but Matlab already pauses the
%program when under a JFileChooser window.

selectionstatus = handles.fc.showOpenDialog(handles.frame); 
		if selectionstatus == handles.fc.APPROVE_OPTION
            
		else 
            
        end
        
filename = handles.fc.getSelectedFile.getName;
directory = handles.fc.getSelectedFile.getParent;
handles.filename = filename.toCharArray;
directory = directory.toCharArray;
directory = rot90(directory);
handles.filename = rot90(handles.filename);
handles.filename = [directory '\' handles.filename];
handles.frame.setVisible(0); %close the underlying JFrame
%set(handles.edit1,'Text',handles.filename);
handles.filename
guidata(hObject, handles);

% --- Reading the F32 file and extracting the Stimparam,Spiketimes etc.,
function pushbutton7_Callback(hObject, eventdata, handles)
    spikedataf(handles.filename);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
handles.frame.setVisible(1); %make the frame visible
pause(.999);

%selectionstatus tells us wether or not there's been a selection; usually
%you put the open stuff up function here, but Matlab already pauses the
%program when under a JFileChooser window.

selectionstatus = handles.fc.showOpenDialog(handles.frame); 
		if selectionstatus == handles.fc.APPROVE_OPTION
            
		else 
            
        end
        
filename = handles.fc.getSelectedFile.getName;
directory = handles.fc.getSelectedFile.getParent;
handles.filename = filename.toCharArray;
directory = directory.toCharArray;
directory = rot90(directory);
handles.filename = rot90(handles.filename);
handles.filename = [directory '\' handles.filename];
handles.frame.setVisible(0); %close the underlying JFrame
%set(handles.edit1,'Text',handles.filename);
handles.filename
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function edit2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function edit2_Callback(hObject, eventdata, handles)
handles.threshold = str2double(get(hObject,'String'));
guidata(hObject, handles);


% --- Reading the 'TEXT' file, (Spike Times saved as ASCII) and extracting
% the Spiketimes and Spike Waveforms. The file 'float.txt' has all the
% spiketimes and the file 'int.txt' has all the spikes.
function pushbutton2_Callback(hObject, eventdata, handles)
    textfilereader(handles.filename);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Performing Principal Component Analysis on the Spikes.
function pushbutton5_Callback(hObject, eventdata, handles)
    PCA(handles);
    
% --- PCA without Noise.
function pushbutton9_Callback(hObject, eventdata, handles)
PCAN(handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Selecting the option for K-Means sorting.
function pushbutton4_Callback(hObject, eventdata, handles)

plotOpt=1;
load PCscore;
switch handles.principalcomponents
    case 1
        data=[PCscore(:,1)]';
    case 2
        data=[PCscore(:,1) PCscore(:,2)]';
    case 3
        data=[PCscore(:,1) PCscore(:,2) PCscore(:,3)]';
    case 4
        data=[PCscore(:,1) PCscore(:,2) PCscore(:,3) PCscore(:,4)]';
end

[center, U, obj_fcn] = Spike_Kmeans(data, handles.clusters, plotOpt);



% --- Executes on button press in radiobutton1.
function radiobutton1_Callback(hObject, eventdata, handles)
handles.methodtype = 1;
off = [handles.radiobutton2,handles.radiobutton3,handles.radiobutton4];
mutual_exclude(off);
guidata(hObject, handles);


% --- Executes on button press in radiobutton2.
function radiobutton2_Callback(hObject, eventdata, handles)
handles.methodtype = 2;
off = [handles.radiobutton1,handles.radiobutton3,handles.radiobutton4];
mutual_exclude(off);
guidata(hObject, handles);


% --- Executes on button press in radiobutton3.
function radiobutton3_Callback(hObject, eventdata, handles)
handles.methodtype = 3;
off = [handles.radiobutton1,handles.radiobutton2,handles.radiobutton4];
mutual_exclude(off);
guidata(hObject, handles);


% --- Executes on button press in radiobutton4.
function radiobutton4_Callback(hObject, eventdata, handles)
handles.methodtype = 4;
off = [handles.radiobutton1,handles.radiobutton2,handles.radiobutton3];
mutual_exclude(off);
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function edit3_CreateFcn(hObject, eventdata, handles)

if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function edit3_Callback(hObject, eventdata, handles)
handles.principalcomponents = str2double(get(hObject,'String'));
guidata(hObject, handles);
handles.clusters = 0;

% Hints: get(hObject,'String') returns contents of edit3 as text
%        str2double(get(hObject,'String')) returns contents of edit3 as a double

% --- Executes during object creation, after setting all properties.
function edit4_CreateFcn(hObject, eventdata, handles)

if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function edit4_Callback(hObject, eventdata, handles)
handles.clusters = str2double(get(hObject,'String'));
guidata(hObject, handles);

function mutual_exclude(off)
set(off,'Value',0);



function edit5_Callback(hObject, eventdata, handles)
% hObject    handle to edit5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit5 as text
%        str2double(get(hObject,'String')) returns contents of edit5 as a double


% --- Executes during object creation, after setting all properties.
function edit5_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% --- Writing the F32 files to the Computer.
function pushbutton8_Callback(hObject, eventdata, handles)
load('Marked_Sorted_SpikeTimes.mat');
f32writer(MSS);



