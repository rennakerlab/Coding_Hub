function NEL_PPort_Set(parport,channel,value)

%
%NEL_PPort_Set.m - OU Neural Engineering Lab, 2010
%
%   NEL_PPort_Set sets the value of digital output channels on the parallel
%   port.  You'll first need to initialize the parallel port with the
%   "NEL_Initialize_PPort" function.
%   
%   NEL_PPort_Set(parport,channel,value) sets the channel, 1 through 8, 
%   specified by "channel" to the value, 0 or 1.  The "parport" input is
%   the handle for the parallel port returned by the "NEL_Initialize_PPort"
%   function.  The "channel" input can be a vector specifying multiple
%   channels, so long as "value" is a vector of 0's or 1's of matching
%   size.
%
%   Last updated May 13, 2010, by Drew Sloan.

%Check to make sure there's enough input arguments.
if nargin ~= 3
    error('NEL_PPort_Set: Not enough input arguments!');
end

%Check to make sure the number of channels and the number of values are the same.
if length(channel) ~= length(value)
    error('NEL_PPort_Set: Number of channels doesn''t match the number of values!');
end

%Check to make sure the channel numbers are between 1 and 8.
if any(channel < 1 || channel > 8)
    error('NEL_PPort_Set: Bad channel number, channels are numbered 1 through 8!');
end

%Check to make sure all input values are either 0 or 1.
if any(value ~= 1 && value ~= 0)
    error('NEL_PPort_Set: Bad logical value, logic values should either be 0 or 1!');
end

%Now step through every channel and set the specified logical value.
for i = 1:length(channel)
    putvalue(parport.Line(channel(i)),value(i));
end