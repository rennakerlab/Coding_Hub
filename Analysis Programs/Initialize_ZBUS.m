function varargout = Initialize_ZBUS(varargin)

%
%Initialize_zBus.m - Rennaker Neural Engineering Lab, 2010
%
%   Initialize_zBus uses the ActiveX controls to form a connection with the
%   Tucker-Davis Technologies (TDT) zBus device interface.
%   
%   zbus = Initialize_zBus connects to the zBus through the default gigabit
%   interface and returns the ActiveX object "zbus".
%
%   zbus = Initialize_zBus(interface) specifies the interface type with 
%   the string input "interface", which must be set to either 'GB' (the 
%`  default), for the gigabit interface, or 'USB', for the USB interface.
%
%   [zbus, checker] = Initialize_zBus(...) returns the optional
%   output "checker", which is a boolean matrix whose first and second 
%   elements indicate whether the zBus connection was successful and 
%   whether the Flush I/O commands were successful, respectively.
%
%   [zbus, checker, devices] = Initialize_zBus(...) returns the 
%   second optional output "devices" which is a structure listing the
%   devices in this particular TDT system along with their rack number,
%   position, and microcode versions.
%
%   Last updated March 22nd, 2011, by Drew Sloan.

interface = 'GB';                   %The default interface is the gigabit.
if length(varargin) == 1            %If the user specified an appropriate interface type...
    if ischar(varargin{1}) && (strcmpi(varargin{1},'GB') || strcmpi(varargin{1},'USB'))
        interface = varargin{1};    %...set the interface type to that which the user specified.
    else                            %Otherwise, show an error.
        error('ZBUS INITIALIZATION ERROR! The input argument must specifiy interface type with either ''GB'' or ''USB''.');
    end
elseif length(varargin) > 1         %If there's too many input arguments, show an error.
    error('ZBUS INITIALIZATION ERROR! Too many input arguments!');
end
zbus = actXcontrol('ZBUS.x',[1 1 1 1]);     %Set up the ActiveX control for the zBus.
checker = zeros(1,2);                       %Keep track of whether the connect and flush commands are successful.
checker(1) = zbus.ConnectZBUS(interface);  	%Connect to the zBus through the specified interface.
ID_numbers = [33,35:38,45:48,50,53];        %These are the ID number for the various TDT devices.
IDs = {'PA5','RP2','RL2','RA16','RV8','RX5','RX6','RX7','RX8','RZ2','RZ5'};   %These are the device names that correspond to the ID numbers.
devices = [];                               %Create a structure to hold device information.
numracks = 0;                               %Count the number of racks in this TDT system.
for i = 1:length(ID_numbers)                %Step through each possible TDT device.
    index = 1;                              %Start at the first device index.
    d = 1;                                  %Make a variable to temporarily hold device information.
    while d ~= 0                            %Loop until no new device is found.
        d = zbus.GetDeviceAddr(ID_numbers(i),index);    %Check for devices of this particular type and index.
        if d ~= 0                           %If a device with this type and index is found...
            rack = ceil((d-1)/2);           %Determine the rack number.
            if rack > numracks              %If this rack is greater than the existing rack count...
                numracks = rack;            %...adjust the rack count.
            end
            pos = d + 1 - 2*rack;           %Determine the position of the device in it's rack.
            ver = zbus.GetDeviceVersion(ID_numbers(i),index);   %Check the version number of the microcode.
            eval(['devices.' IDs{i} '(index,1:3)=[' num2str([rack,pos,ver]) '];']);     %Save the rack number, position, and microcode version.
        end
        index = index + 1;
    end
end
temp = zeros(1,numracks);                   %Make a temporary matrix for checking the flush commands.
for i = 1:numracks                          %Step through each rack...
    temp(i) = zbus.FlushIO(i);           	%Flush the input and output values on each rack to remove bad data from the buffers.
end
checker(2) = all(temp);                     %If all flush commands, indicate the overall flush process was successful.
varargout{1} = zbus;                     	%The first output argument is the RP2 ActiveX handle.
varargout{2} = checker;                     %The second output argument is checker matrix.
varargout{3} = devices;                    	%The third output argument is the structure listing the TDT devices in this system.