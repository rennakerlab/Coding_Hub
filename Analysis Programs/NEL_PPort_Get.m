function value = NEL_PPort_Get(parport,channel)

%
%NEL_PPort_Get.m - OU Neural Engineering Lab, 2010
%
%   NEL_PPort_Get returns the logical value of digital input channels on 
%   the parallel port.  You'll first need to initialize the parallel port 
%   with the "NEL_Initialize_PPort" function.
%   
%   value = NEL_PPort_Get(parport,channel) returns the logical value on the
%   input channel specified by "channel" to the "value" output.  The 
%   "parport" input is the handle for the parallel port returned by the 
%   "NEL_Initialize_PPort" function.  The "channel" input can be a vector 
%   specifying multiple channels, in which case the "value" output will be
%   a vector of 0's and 1's of matching size.
%
%   Last updated May 13, 2010, by Drew Sloan.

%Check to make sure there's enough input arguments.
if nargin ~= 2
    error('NEL_PPort_Get: Not enough input arguments!');
end

%Check to make sure the channel numbers are between 1 and 8.
if any(channel < 1 || channel > 8)
    error('NEL_PPort_Get: Bad channel number, channels are numbered 1 through 8!');
end

%Now step through every specified channel and get the logical value.
value = zeros(size(channel));       %Preallocate a vector of zeros to hold logical values.
for i = 1:length(channel)
    value(i) = getvalue(handles.parport.Line(channel(i)+8));     %The inputs are lines 9-16 on the parallel port.
    if any(channel(i) == [2,5,8])   %Channels 2, 5, and 8 (pins 11, 14, and 17) have inverted logic.
        value(i) = ~value(i);       %Invert the read logic value to make it true.
    end
end