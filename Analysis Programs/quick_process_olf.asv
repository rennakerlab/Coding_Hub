function quick_process_olf(varargin)

%
%QUICK_PROCESS.m - Rennaker Neural Engineering Lab, 2010
%
%   QUICK_PROCESS quickly takes the raw, unfiltered sweep traces from 
%   neural recordings saved in the *.NEL format and filters that signal to 
%   output local field potentials (LFPs) and thresholds the filtered signal
%   to pull out action potentials using all default parameters on the
%   processing programs.  The results will be unsorted, multi-unit
%   activity.
%
%   Last updated January 28, 2010, by Drew Sloan.


if length(varargin) > 1             %If the user entered too many arguments, show an error.
    error('Too many input arguments for QUICK_PROCESS!  Inputs should be a filename string or cell array of filename strings.');
end
if ~isempty(varargin)
    temp = varargin{1};                 %Pull the variable out of the input argument.
    if ischar(temp)                     %If the argument is a string...
        files(1).name = temp;           %Save the filename as a string.
    elseif iscell(temp)                	%If the argument is a cell...
        for j = 1:length(temp)          %Step through the filenames....
            files(j).name = cell2mat(temp(j));  %And save the filenames in a structure.
        end
    else            %If the input isn't a cell or a string, show an error.
        error('Wrong input type for QUICK_PROCESS!  Inputs should be a filename string or cell array of filename strings.');
    end
end
if ~exist('files','var')      %If the user hasn't specified an input file...
    [temp path] = uigetfile('*.NEL','multiselect','on');   %Have the user pick an input file or files.
    cd(path);                         	%Change the current directory to the folder that file is in.
    if iscell(temp)                     %If the user's picked multiple files...
        for i = 1:length(temp)          %Step through each selected file.
            files(i).name = [path temp{i}];     %Save the file names in a structure.
        end
    elseif ischar(temp)                  %If only one file is selected...
        files(1).name = [path temp];    %Add the path to the filename.
    elseif isempty(temp)                %If no file is selected...
        error('No file selected!');     %Show an error message.
    end
end

for i = 1:length(files)                         %Step through all root filenames.
    if ~exist(files(i).name,'file')             %Check first to see if the *.NEL file exists.
        error(['Error in QUICK_PROCESS!  ' files(i).name ' doesn''t exist in the specified directory!']);
    end
    a = find(files(i).name == '.',1,'last');    %Find the beginning of the file extension.
    root = files(i).name(1:a-1);                %Find the extensionless file root.
    NELtoSPKolf(files(i).name);                    %Filter and threshold for spikes.
    NELtoLFP(files(i).name);                    %Filter for LFPs.
    SPKtoF32([root '.SPK']);                    %Export spike times from the *.SPK files.
end
text2speech('Quick process complete.');
disp('Quick process complete.');