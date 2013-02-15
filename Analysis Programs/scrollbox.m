function scrollbox(varargin)

txt = varargin{1};                                                          %The first argument will be the text to show in the scrollbox.
props = [];                                                                 %Create a structure to hold any property settings the user entered.
for i = 2:2:length(varargin)                                                %Step through each entered property.
    props(i/2).name = varargin{i};                                          %Save the property name.
    if ~strcmpi(props(i/2).name,'Reset')                                    %If the property name isn't 'Reset'.
        props(i/2).value = varargin{i+1};                                   %Save the property value with the name.
    end
end
fig = findobj('Tag','Scrolling Textbox');                                  	%Check to see if a scrolling textbox figure is already open.
if isempty(fig)                                                             %If there is no scrolling textbox currently open...
    pos = get(0,'ScreenSize');                                              %Grab the screensize.
    pos = [0.2*pos(3),0.1*pos(4),0.6*pos(3),0.8*pos(4)];                    %Scale a figure position relative to the screensize.
    fig = figure(...                                                        %Create a parent figure for an edit box.
        'position',pos,...                                                  %Set the figure position.
        'menubar','none',...                                                %Turn off the menubar on the figure.
        'color','w',...                                                     %Set the background color to white
        'numbertitle','off',...                                             %Turn off the number title.
        'Tag','Scrolling Textbox');                                         %Set the figure tag to "ScrollBox".
    editbox = uicontrol('style','listbox',...                              	%Create an edit box within the figure.
        'string','',...                                                     %Start with the text blank.
        'units','normalized',...                                            %Normalize the position units within the figure.
        'position',[.01 .01 .98 .98],...                                    %Stretch the edit box to take up most of the figure.
        'fontsize',12,...                                                   %Set the default fontsise to 12.
        'Enable','inactive',...                                             %Set the enable property to inactive.
        'HorizontalAlignment','Left',...                                    %Set the horizontal alignment to the left.
        'Min',0,...
        'Max',1,...
        'BackgroundColor','w');
    guidata(fig,editbox);                                                   %Pin the editbox handle to the GUI.
else                                                                        %Otherwise, if a scrolling textbox already exists...
    editbox = guidata(fig);                                                 %Grab the editbox handle from the figure.
end
if ~isempty(txt)                                                            %If the txt argument isn't empty...
    current_txt = get(editbox,'string');                                    %Grab the existing text from the editbox.
    if ischar(txt)                                                          %If the txt argument is a string...
        txt = {txt};                                                        %...make it a cell.
    elseif iscell(txt)                                                      %If the txt argument is already a cell...
        txt = txt(:);                                                       %...make sure it's one-dimensional.
    else                                                                    %Otherwise, if the txt argument is a number matrix...
        temp = txt;                                                         %Move the txt argument over to a temporary matrix.
        txt = {};                                                           %Convert txt to an empty cell to receive lines of converted strings.
        for i = 1:size(temp,1)                                              %Step through each row of the matrix.
            txt{i} = num2str(temp(i,:));                                    %Save each row as a string with the num2str function.
        end
        txt = txt';                                                         %Transpose the new txt cell array to orient it vertically.
    end
    txt = vertcat(current_txt,txt);                                         %Vertically concatenate the existing text with the input text.
    set(editbox,'string',txt,'max',length(txt),'value',length(txt));        %Update the scrollbox with the new text.
end
for i = 1:length(props)                                                     %Now step through each property the user wishes to set.
    if strcmpi(props(i).name,'Reset')                                       %If the property name was 'Reset'...
        set(editbox,'string',[]);                                           %...clear all the existing text from the scrollbox.
    elseif strcmpi(props(i).name,'Title')                                   %If the property name was 'Title'...
        set(fig,'Name',props(i).value);                                     %...set the figure name to the value entered after 'Title'.
    else                                                                    %Otherwise, if the property name wasn't 'Reset'...
        set(editbox,props(i).name,props(i).value);                          %Set the specified property on the editbox.
    end
end