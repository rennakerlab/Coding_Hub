function Replace_Msg(listbox,new_msg)
%
%REPLACE_MSG.m - Rennaker Neural Engineering Lab, 2013
%
%   REPLACE_MSG displays messages in a listbox on a GUI, replacing messages
%   at the bottom of the list with new lines.
%
%   Replace_Msg(listbox,new_msg) replaces the last N entry or entries in
%   the listbox whose handle is specified by the variable "listbox" with
%   the the string or cell array of stringss specified in the variable 
%   "new_msg".
%
%   Last modified January 24, 2013, by Drew Sloan.

messages = get(listbox,'string');                                           %Grab the current string in the messagebox.
if isempty(messages)                                                        %If there's no messages yet in the messagebox...
    messages = {};                                                          %Create an empty cell array to hold messages.
elseif ~iscell(messages)                                                    %If the string property isn't yet a cell array...
    messages = {messages};                                                  %Convert the messages to a cell array.
end
if ~iscell(new_msg)                                                         %If the new message isn't a cell array...
    new_msg = {new_msg};                                                    %Convert the new message to a cell array.
end
messages(end+1-(1:length(new_msg))) = new_msg;                              %Add the new message where the previous last message was.
set(listbox,'string',messages);                                             %Show that the Arduino connection was successful on the messagebox.
set(listbox,'value',length(messages));                                      %Set the value of the listbox to the newest messages.
drawnow;                                                                    %Update the GUI.
a = get(listbox,'listboxtop');                                              %Grab the top-most value of the listbox.
set(listbox,'min',0,'max',2','selectionhighlight','off','value',[],...
    'listboxtop',a);                                                        %Set the properties on the listbox to make it look like a simple messagebox.