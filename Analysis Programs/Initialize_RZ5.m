function varargout = Initialize_RZ5(varargin)

%
%Initialize_RZ5.m - Rennaker Neural Engineering Lab, 2010
%
%   Initialize_RZ5 uses the ActiveX controls to form a connection with the
%   Tucker-Davis Technologies (TDT) RZ5 processor.
%   
%   rz5 = Initialize_RZ5(...,rcxfile,...) loads the RCX file
%   specified by "rcx_file" to the RZ5.  The RCX filename is a required
%   input.
%
%   [rz5, checker] = Initialize_RZ5(...,rcxfile,...) returns the optional
%   output "checker", which is a boolean matrix whose first, second, and 
%   third element indicate whether the RZ5 connection was successful, the 
%   RCX file successfully loaded, and the RCX file is successfully running, 
%   respectively.
%
%   [rz5, checker, samprate] = Initialize_RZ5(...,rcxfile,...) returns the 
%   second optional output "samprate" which returns the exact sampling rate
%   of the RZ5 processor with the current RCX file.
%
%   [rz5, checker, samprate, cycusage] = Initialize_RZ5(...,rcxfile,...) 
%   returns the third optional output "cycusage" which returns the percent
%   usage of the RZ5 main processor.
%
%   [...] = Initialize_RZ5(...,rcxfile,index,...) further specifies the RZ5 
%   device index that will be connected with the numeric input "index".  If
%   no device index is specified, the function connects to device #1 by
%   default.
%
%   [...] = Initialize_RZ5(...,rcxfile,interface,...) further specifies the
%   interface type with the string input "interface".  "interface" must be
%   set to either 'GB', for the gigabit interface, or 'USB', for the 'USB'
%   interface.  If the interface isn't specified, the function will attempt
%   to connect through the gigabit interface.
%
%   Last updated November 15, 2010, by Drew Sloan.


rcx_file = [];                  %Create a matrix to hold the RCX file.
interface = 'GB';            	%The default interface is the gigabit.
index = 1;                      %The default RZ5device index is 1.
for i = 1:length(varargin)      %Step through the variable input arguments.
    %If the argument is a string specifying the interface type...
    if ischar(varargin{i}) && (strcmpi(varargin{i},'GB') || strcmpi(varargin{i},'USB'))
        interface = varargin{i};    %...set the interface type to that which the user specified.
    %If the argument is a string that doesn't specify an interface type...
    elseif ischar(varargin{i})
        rcx_file = varargin{i};     %...set the rcx filename to the string input.
        if ~exist(rcx_file,'file')      %First, make sure the RCX file exists.
            error(['RZ5 INITIALIZATION ERROR! RCX file "' rcx_file '" does not exist!']);
        end
    %If the input argument is numeric, it must specify the device index.
    elseif isnumeric(varargin{i})   
        index = varargin{i};
    end
end
if isempty(rcx_file)    %If the user didn't specify an RCX file, show an error.
    error('RZ5 INITIALIZATION ERROR! You didn''t specify an RCX file!');
end
checker = zeros(1,3);	%Keep track of whether the connect, load, and run commands are successful.
rz5 = actxcontrol('RPco.x', [5 5 26 26]);       %Set up the ActiveX control for the RZ5.
checker(1) = rz5.ConnectRZ5(interface,index);  	%Connect to the RX5 through the specified interface.
checker(2) = rz5.LoadCOF(rcx_file);             %Load the RCX circuit to the RZ5.
checker(3) = rz5.Run;                           %Set the RCX file to run.
varargout{1} = rz5;                             %The first output argument is the RZ5 ActiveX handle.
varargout{2} = checker;                         %The second output argument is checker matrix.
varargout{3} = rz5.GetSFreq;                    %The thrid output argument is the exact sampling rate.
varargout{4} = rz5.GetCycUse;                   %The first output argument is the percent processor usage.