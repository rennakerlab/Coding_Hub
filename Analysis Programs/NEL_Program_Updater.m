function NEL_Program_Updater

%NEL_Program_Updater.m - UTD Neural Engineering Lab, 2009
%
%   NEL_Program_Updater synchronizes standard programs and files that the 
%   OU-NEL lab uses between the network drivespace (the Z:\ drive) and 
%   local folders on the desktop of NEL computers.  As a rule, programs and
%   files on the Z:\ drive are considered to be the "master" copies and
%   will override local copies on the desktop, unless those files show that
%   they have been modified more recently than the "master" copies, in
%   which case this program copies the newer program to the network drive
%   and saves a backup copy of the old program in the "Old Versions"
%   subfolder of every network drive folder.
%
%   Last updated November 20, 2009, by Drew Sloan.

%First, we'll grab the current directory name so that we can come back to
%it after this program is run.
startdir = cd;

%We'll turn off redundant alerts from the mkdir function.
warning off MATLAB:MKDIR:DirectoryExists;

%What follows is a list of essential folders on the network drive that
%should be copied with contents onto the local desktop.
folder(1) = {'Analysis Programs'};
folder(2) = {'Attending VNS'};
folder(3) = {'Calibration'};
folder(4) = {'Gap Detection Startle'};
folder(5) = {'High-Low'};
folder(6) = {'Jaw Pain Study'};
folder(7) = {'Motor VNS'};
folder(8) = {'NEL Sounds (n_s)'};
folder(9) = {'Odor Discrimination'};
folder(10) = {'Pitch Discrimination'};
folder(11) = {'RPvds Circuits'};
folder(12) = {'Recording'};
folder(13) = {'SON Library'};
folder(14) = {'Speech Discrimination'};
folder(15) = {'Speech Sounds'};
folder(16) = {'Spike Sorting'};
folder(17) = {'PLP Therapy'};
folder(18) = {'TCExplorer'};
folder(19) = {'Olfactometer'};
folder(20) = {'Behavior'};
folder(21) = {'Unilateral Neglect/UnilateralNeglectRepository/Client'};

%We don't want to bother copying every file, since some are just temporary
%or unimportant, so here we list those file types worth copying.
files(1) = {'*.m'};             %MatLab functions.
files(2) = {'*.mat'};           %MatLab data files.
files(3) = {'*.fig'};           %MatLab figure files.
files(4) = {'*.rcx'};           %RPvds circuits.
files(5) = {'*.jpg'};           %JPEG pictures.
files(6) = {'*.bmp'};           %Bitmap pictures.
files(7) = {'*.xls'};           %Excel spreadsheets.
files(8) = {'*.n_s'};           %NEL Sound Files.
files(9) = {'*.txt'};           %Text (ASCII data) files.
files(10) = {'*.exe'};          %Stand-alone programs.
files(11) = {'*.class'};        %Java class files.
files(12) = {'*.java'};         %Java function files.
files(13) = {'*.32'};           %Speech sound files.
files(14) = {'*.wav'};          %Wave Files.

%The desktop path on each computer differs according to that computer's username.
if exist('C:\Documents and Settings\All Users\Desktop','dir')   %If there's an "All Users" desktop on this computer, use that as the desktop path.
    desktop = 'C:\Documents and Settings\All Users\Desktop';    %Set the Desktop path.
else                                                            %Otherwise set the desktop path to the desktop for this user.
    temp = userpath;                %Grab the default Matlab search path.
    a = find(temp == '\');          %Find the folder markers in the search path name.
    temp = temp(a(2)+1:a(3)-1);     %Pull the user name out of the search path name.
    desktop = ['C:\Documents and Settings\' temp '\Desktop'];   %Set the desktop path for this user name.
end

%Here we'll set the network drive path.
zpath = 'Z:\';      %The NEL server, which has 8+ TB of storage.

%Now we'll go through each specified folder on the network drive and 
%synchronize it with those on the local desktop.
for i = 1:length(folder);
    programpath = [zpath cell2mat(folder(i))];      %Set the network folder path.
    if exist(programpath,'dir')                     %Proceed so long as this network folder path exists.
        disp(['Checking against desktop: ' programpath]);
        backupprogpath = [desktop '\' cell2mat(folder(i))];   	%Set the local desktop path.
        oldprogpath = [backupprogpath '\Old File Versions'];   	%Set the folder to receive old file versions.
        mkdir(backupprogpath);          %If the local desktop path doesn't exist, create it.
        mkdir(oldprogpath);             %If the old program path doesn't exist, create it.
        for j = 1:length(files);
            filetype = cell2mat(files(j));  %Set the filetype to the current filetype to be copied.
            cd(programpath);                %Change the directory to the network folder path.
            main_files = dir(filetype);     %Find all the files of type in the network folder path.
            cd(backupprogpath);             %Change the direcotry to the local desktop path.
            backup_files = dir(filetype);   %Find all the files of type in the local desktop path.
            filetype = filetype(2:length(filetype));    %Truncate the filetype for later use in naming old programs versions.
            for k = 1:length(main_files)    %Now stepping through file by file...
                if ~exist([backupprogpath '\' main_files(k).name],'file')      %If this file doesn't exist in the desktop path...
                    disp(['Backing up: ' main_files(k).name]);
                    copyfile([programpath '\' main_files(k).name], [backupprogpath '\' main_files(k).name]);    %Copy file.
                else
                    %When a file already exists in the desktop path, we'll decide which version
                    %supercedes the other based on when each was last updated.  The newest file
                    %wins and the older gets saved in the old versions backup folder.
                    a = strmatch(upper(main_files(k).name), upper({backup_files(:).name}), 'exact');
                    if datenum(main_files(k).date) > datenum(backup_files(a).date)
                        %If the network version is newer...
                        disp(['Network version supercedes desktop version: ' main_files(k).name]);
                        temp = [oldprogpath '\' backup_files(a).name(1:(length(backup_files(a).name)-length(filetype)))...
                            ' ' datestr(backup_files(a).date,30) filetype];
                        copyfile([backupprogpath '\' backup_files(a).name], temp);
                        copyfile([programpath '\' main_files(k).name], [backupprogpath '\' main_files(k).name]);
                    elseif datenum(main_files(k).date) < datenum(backup_files(a).date)
                        %If the desktop version is newer...
                        disp(['Desktop version supercedes network version: ' main_files(k).name]);
                        temp = [oldprogpath '\' main_files(k).name(1:(length(main_files(k).name)-length(filetype)))...
                            ' ' datestr(main_files(k).date,30) filetype];
                        copyfile([programpath '\' main_files(k).name], temp);
                        copyfile([backupprogpath '\' backup_files(a).name], [programpath '\' backup_files(a).name]);
                    end
                end
            end
        end
    end
end

%Next, we'll update the MatLab paths for this computer to make sure it's
%using the network drive programs before using local versions of the
%programs.
a = path;                   %List all the search paths in one string.
b = [1, find(path == ';'), length(path) + 1];	%Find the separators in that string.
for i = 2:length(b);        
	paths{i-1} = a(b(i-1)+1:b(i)-1);    %Separating out the individual search paths.
end
for i = 1:length(folder)    %Stepping through, folder by folder...
    if exist([zpath cell2mat(folder(i))],'dir')     %If the folder actually exists on the network drive.
        if any(strmatch([desktop '\' cell2mat(folder(i))],paths,'exact'))
            %If a desktop search path exists, remove it.
            disp(['Removing ' desktop '\' cell2mat(folder(i)) ' from the MatLab path.']);
            rmpath([desktop '\' cell2mat(folder(i))]);      %Removing the search path.
        end
        if isempty(strmatch([zpath cell2mat(folder(i))],paths,'exact'))
            %If a network drive search path doesn't exist, add it.
            disp(['Adding ' zpath cell2mat(folder(i)) ' to the MatLab path.']);
            addpath([zpath cell2mat(folder(i))]);           %Adding the search path.
        end
    end
end
savepath;   %Then we save the set search paths.

cd(startdir);   %Last, we'll set the directory back to where we started.