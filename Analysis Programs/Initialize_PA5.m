function varargout = Initialize_PA5(varargin)

%
%Initialize_PA5.m - Rennaker Neural Engineering Lab, 2010
%
%   Initialize_PA5 uses the ActiveX controls to form a connection with the
%   Tucker-Davis Technologies (TDT) PA5 processor.
%   
%   pa5 = Initialize_PA5 connects to the PA5 on the TDT system and returns
%   the ActiveX control "pa5".
%
%   [pa5, checker] = Initialize_PA5(...,rcxfile,...) returns the optional
%   output "checker", which is a boolean variable indicating whether the
%   PA5 connection was successful.
%
%   [...] = Initialize_PA5(...,index,...)  specifies the PA5 device index
%   with the numeric input "index".  If no device index is specified, the 
%   function connects to device #1 by default.
%
%   [...] = Initialize_PA5(...,interface,...) specifies the interface type 
%   with the string input "interface", which must be set to either 'GB', 
%   for the gigabit interface, or 'USB', for the USB interface.  If the
%   interface isn't specified, the function will attempt to connect through
%   the gigabit interface.
%
%   [...] = Initialize_PA5(...,display,...) allows the user to display text
%   in the PA5's LED display.  The string input "display" will be truncated
%   to 8 characters and then displayed on the LED.  Changes in attenuation
%   on the PA5 after setting this display will replace the specified
%   display text with the new attenuation setting, in dB.
%
%   Last updated March 23rd, 2011, by Drew Sloan.


interface = 'GB';                   %The default interface is the gigabit.
index = 1;                          %The default PA5 device index is 1.
display = [];                       %The user can dispay text on the PA5's LED display if they'd like to.
for i = 1:length(varargin)          %Step through the variable input arguments.
    if ischar(varargin{i}) && (strcmpi(varargin{i},'GB') || strcmpi(varargin{i},'USB'))     %If the argument is a string specifying the interface type...
        interface = varargin{i};    %...set the interface type to that which the user specified.
    elseif ischar(varargin{i})      %If the input argument is any other kind of string...
        display = varargin{i};      %...show that string on the PA5's LED display.
    elseif isnumeric(varargin{i})   %If the input argument is numeric... 
        index = varargin{i};        %...it must specify the device index.
    else    %If the input is neither an interface type or a device index, show an error.
        error(['PA5 INITIALIZATION ERROR! "' varargin{i} '" is not a recognized interface type!']);
    end
end
pa5 = actxcontrol('PA5.x',[5 5 26 26]);         %Set up the ActiveX control for the PA5.
checker = pa5.ConnectPA5(interface,index);  	%Connect to the RX5 through the specified interface.
varargout{1} = pa5;                             %The first output argument is the PA5 ActiveX handle.
varargout{2} = checker;                         %The second output argument is the checker variable.
if ~isempty(display)                            %If the user entered text to display on the LED...
    if length(display) > 8                      %If the length of the text is greater than the maximum 8 characters...
        display(9:end) = [];                    %...truncate the text.
    end
    pa5.Display(display);                       %Display the text on the PA5's LED display.
end