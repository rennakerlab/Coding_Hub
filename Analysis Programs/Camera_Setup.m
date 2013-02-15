function vid = Camera_Setup(varargin)

if nargin == 0                                                              %If no file name was handed to the function...
    file = [];                                                              %Set the calibration filename to zero.
else                                                                        %Otherwise...
    file = varargin{1};                                                     %Set the cailbration filename to the first input argumnet.
end

imaqreset;                                                                  %Disconnect and delete all image acquisition objects.
info = imaqhwinfo;                                                          %Grab information about the available image acquisition hardware.
index = 0;                                                                  %Create a variable to index the various cameras.
camera = [];                                                                %Create a structure to hold the camera input properties.
for a = info.InstalledAdaptors                                              %Step through all installed video adaptors.
    temp = imaqhwinfo(a{1});                                                %Check for cameras with each video adaptor.
    for i = 1:length(temp.DeviceIDs)                                        %Step through each camera with this video adaptor.
        index = index + 1;                                                  %Advance the camera index.
        camera(index).name = a{1};                                          %Save the adaptor name for this camera.
        camera(index).id = temp.DeviceIDs{i};                               %Save the camera's device ID.
        if any(strcmpi('RGB24_320x240',...
                temp.DeviceInfo(i).SupportedFormats))                       %If the camera doesn't support a 320x240 resolution...
            camera(index).res = 'RGB24_320x240';                            %Set the input resolution to 320x240.
        else                                                                %Otherwise, if the camera does support a 320x240 resolution...
            camera(index).res = temp.DeviceInfo(i).SupportedFormats{end};   %Set the input resolution to the last listed allowable resolution for each camera.
        end
        
    end
end
if ~isempty(file)                                                           %If a calibration file was passed to this function.
    i = find(file == '-');                                                  %Find all of the hyphens in the filename.
    j = find(file == '_',1,'last');                                         %Find the last underscore in the filename.
    if length(i) > 1 && ~isempty(j)                                         %If there's at least two hyphens and an underscore in the filename...
        name = file(i(end-1)+1:i(end)-1);                                   %Grab the video adaptor name out of the calibration file name.
        id = str2double(file(i(end)+1:j-1));                                %Grab the video adaptor ID out of the calibration file name.
        i = strcmpi(name,{camera.name}) & id == [camera.id];                %Check to see if any of the video adaptors match the calibration file.
        if any(i == 1)                                                      %If any of the video adaptors match the calibration file.
            i = find(i == 1,1,'first');                                     %Grab the index for the first video adaptor that matches.
            camera = camera(i);                                             %Kick out all camera adaptors but the one that matches.
        end
    end
end
n = length(camera);                                                         %Grab the number of available cameras.
if n > 1                                                                    %If there's more than one camera attached to this computer.
    set(0,'units','centimeters');                                           %Set the screensize units to centimeters.
    pos = get(0,'ScreenSize');                                              %Grab the screensize.
    i = pos(3)/2;                                                           %Set the width of the camera selection figure to half the screen width.
    j = 0.75*i/n;                                                           %Set the height of the camera selection figure based on how many cameras there are.
    pos = [pos(3)/2 - i/2,pos(4)/2 - j/2,i,j];                              %Scale a figure position relative to the screensize.
    fig1 = figure;                                                          %Make a figure to ask the user which serial port they'd like to connect to.
    set(fig1,'units','centimeters',...
        'Position',pos,...
        'MenuBar','none',...
        'name','Select A Camera',...
        'numbertitle','off');                                               %Set the properties of the figure.
    set(fig1,'CloseRequestFcn',@Prevent_Close);                             %Disable the figure's ability to be closed.
    connected = zeros(1,n);                                                 %Make a matrix to check which cameras connected successfully.
    for i = 1:n                                                             %Step through each available camera...
        ax(i) = axes('parent',fig1,...
            'units','normalized',...
            'position',[(i-1)/n + 0.05,0.05,1/n - 0.1,0.9],...
            'box','on',...
            'xtick',[],...
            'ytick',[]);
        temp = text(mean(xlim),mean(ylim),'Fetching camera snapshot...',...
            'backgroundcolor','y',...
            'color','k',...
            'edgecolor','k',...
            'horizontalalignment','center',...
            'verticalalignment','middle',...
            'fontsize',12,...
            'fontweight','bold',...
            'margin',5);                                                    %Create a text object on the axes to show that the camera image is being fetched.
        drawnow;                                                            %Show the text object.
        try                                                                 %Use a try statement to keep bad video drivers from bombing the program.
            vid = videoinput(camera(i).name, camera(i).id, camera(i).res);  %Create a video input object for each camera.
            frame = getsnapshot(vid);                                       %Grab a single frame from the video feed.
            delete(temp);                                                   %Delete the temporary text object.
            axes(ax(i));                                                    %Force focus on the intended axes.
            image(frame);                                                   %Show that frame in the left-hand axes.
            axis tight;                                                     %Square up the axes.
            set(gca,'xtick',[],'ytick',[]);                                 %Remove all of the ticks on the 
            delete(vid);                                                    %Delete the video input object.
            connected(i) = 1;                                               %Indicate that this camera connected successfully.
        catch                                                               %If a frame can't be grabbed from the video feed...
            set(temp,'string',{'Couldn''t connect to',...
                [camera(i).name '-' num2str(camera(i).id)]},...
                'backgroundcolor',[1 0.5 0.5]);                             %Change the text label to show that the camera couldn't be connected.
        end
    end
    set(fig1,'WindowButtonDownFcn','uiresume(gcbf);');                      %Set the callback for mouse clicks anywhere on the figure.
    n = 0;                                                                  %Set the chosen video input to none by default.
    connected = find(connected ~= 0);                                       %Change the connected matrix to a list of available video inputs.
    if length(connected) == 1                                               %If only one video input could be connected...
        n = connected == 1;                                                 %Set the video input number to the functional input.
        drawnow;                                                            %Update the figures before continuing.
    elseif length(connected) > 1                                            %If multiple video inputs could be connected...
        while n == 0 && ishandle(fig1)                                      %Loop until the user selects a camera or closes the selection window.
            uiwait(fig1);                                                   %Wait for the user to click a camera image on the figure.
            xy = get(gca,'CurrentPoint');                                   %Find the current point in the current axes.
            xy = xy(1,1:2);                                                 %Pare down the point to just the x- and y-coordinates.
            temp = [xlim,ylim];                                             %Grab the x- and y-axis limits for the current axes.
            if xy(1) > temp(1) && xy(1) < temp(2) && ...
                    xy(2) > temp(3) && xy(2) < temp(4)                      %If the user clicked inside of the axes.
                n = find(gca == ax);                                        %Find the index of the axes that the user clicked.
                if ~any(n == connected)                                     %If the clicked axes were for a non-functioning video input...
                    n = 0;                                                  %Reset the chosen video input to a default of none.
                end
            end
        end
        drawnow;                                                            %Update the figures before continuing.
    end
    if n ~= 0                                                               %If a camera feed was chosen...
        set(ax(n),'linewidth',5,'xcolor','g','ycolor','g');                 %Highlight the axes for that camera feed.
        drawnow;                                                            %Immediately update the axes.
    end
    if ishandle(fig1)                                                       %If the figure is still open...
        set(fig1,'CloseRequestFcn','closereq');                             %Enable the figure's ability to be closed.
        close(fig1);                                                        %Close the figure.
    end
end
if n ~= 0                                                                   %If a camera was found an selected...
    vid = videoinput(camera(n).name, camera(n).id, camera(n).res);          %Create a video input object for the chosen camera.
else                                                                        %Otherwise...
    vid = [];                                                               %Return an empty matrix.
end


%% This function is called when the user attempts to close the camera selection window without selecting a camera.
function Prevent_Close(~,~)
warndlg('You must select a camera first!','Select Camera');                 %Warn the user that they have to choose a camera.