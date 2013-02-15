function NEL_WorldBook2_Backup

%
%NEL_Backup_Recordings.m - OU Neural Engineering Lab, 2007
%
%   NEL_Backup_Recordings goes through the local drive looking for *.NEL
%   files that haven't been uploaded to the network drive.  When it finds
%   *.NEL files that don't exist on the network drive, it compresses them
%   to *.zip files if they haven't been already and then uploads them.
%
%   Last updated April 8, 2008, by Drew Sloan.


%We'll first check to make sure the network drive is online, and then we'll
%periodically check after that to make sure it is still online.  Also, for
%some reason, the MioNet will occasionally change the drive letter of the
%network drive on fly, so we'll have to keep that updated.
[drives, connected] = verify_network_drive_connection;
if connected
    disp('Network drive connection detected.');
else
    disp('Could not connect to the network drive, automatic processing cancelled');
    return;
end

%We'll turn off the error that tells us when a directory already exists so
%that it won't pop up a million times.
warning off MATLAB:MKDIR:DirectoryExists;

%First, we'll find the folders pertaining to individual rats on the local
%directory and kick out any nonrelevant folders.           
temp = dir([drives(1) ':\Neural Recordings']);       %Find all folders in the Neural Recordings Folder.
numrats = 0;
for i = 1:length(temp)
    if temp(i).isdir && ~strcmp(temp(i).name,'.') && ~strcmp(temp(i).name,'..') && ~strcmpi(temp(i).name,'TEST')
        if strcmp(temp(i).name,upper(temp(i).name)) && ~strcmpi(temp(i).name,'RECYCLER');
            numrats = numrats + 1;
            folder(numrats).name = temp(i).name;        %Kick out any non-subject system folders that pop up from the dir command.
        end
    end
end
if length(folder) < 1
    disp('No relevant folders found in the data path for processing.');
    return;
end
disp('Folders found for the following subjects: ');
for i = 1:length(folder)
    disp(['     ' folder(i).name]);
end

%Now we'll go through the rat-specific folders one by one.
for rat = 1:numrats
    disp(['Transfering data from subject: ' folder(rat).name]);
    [drives, connected] = verify_network_drive_connection;
    if ~connected   %We'll frequently check to make sure the network drive is connected.
        disp('Could not connect to the network drives.');
        return;
    end
    cd([drives(1) ':\Neural Recordings\' folder(rat).name]);        %Change the directory to this rat's folder.
    mkdir([drives(2) ':\Neural Recordings\' folder(rat).name]);  %Create a corresponding folder in the working directory.
    subfolder = dir;                        %Look for subfolders, separating different types of stimuli.
    temp = [];                  
    for i = 1:length(subfolder)             %Kick out nonrelevant files and directories.
        if ~subfolder(i).isdir || strcmp(subfolder(i).name,'.') || strcmp(subfolder(i).name,'..')
            temp = [temp, i];
        end
    end
    subfolder(temp) = [];
    for current_sub = 1:length(subfolder);  %Then we'll go through the stimulus-specific folders.
        [drives, connected] = verify_network_drive_connection;
        if ~connected   %We'll frequently check to make sure the network drive is connected.
            disp('Could not connect to the network drives.');
            return;
        end
        cd([drives(1) ':\Neural Recordings\' folder(rat).name '\' subfolder(current_sub).name]);
        mkdir([drives(2) ':\Neural Recordings\' folder(rat).name '\' subfolder(current_sub).name]);
        dayfolder = dir;                    %Look for day-specific folders.
        temp = [];
        for i = 1:length(dayfolder)         %Kick out nonrelevant files and directories.
            if ~dayfolder(i).isdir || strcmp(dayfolder(i).name,'.') || strcmp(dayfolder(i).name,'..')
                temp = [temp, i];
            end
        end
        dayfolder(temp) = [];
        for current_day = 1:length(dayfolder)   %Now we'll step through the day folders, one by one.
            [drives, connected] = verify_network_drive_connection;
            if ~connected   %We'll frequently check to make sure the network drive is connected.
                disp('Could not connect to the network drives.');
                return;
            end
            cd([drives(1) ':\Neural Recordings\' folder(rat).name '\' subfolder(current_sub).name '\' dayfolder(current_day).name]);
            mkdir([drives(2) ':\Neural Recordings\' folder(rat).name '\' subfolder(current_sub).name '\' dayfolder(current_day).name]);
            origin_path = cd;   %We'll need to switch between directories several times, so we'll save the origin directory here.
            copy_path = [drives(2) ':\Neural Recordings\' folder(rat).name '\' subfolder(current_sub).name '\' dayfolder(current_day).name];
            disp(['Checking: ' cd]);
            
            %First we'll find out what files already exist in the network
            %directory.
            zip_files = dir('*.NEL.zip');       %Find all compressed *.NEL files.
            temp = [];
            for i = 1:length(zip_files)
                if zip_files(i).isdir           %Kick out any directories included with the files.
                    temp = [temp; i];
                end
            end
            zip_files(temp) = [];              
            nel_files = dir('*.NEL');           %Find all decompressed *.NEL files.
            temp = [];
            for i = 1:length(nel_files)
                if nel_files(i).isdir           %Kick out any directories included with the files.
                    temp = [temp; i];
                end
            end
            nel_files(temp) = [];
                        
            %We'll make sure we're not trying to copy over redundant *.NEL
            %and *.NEL.zip files.
            temp = [];
            for i = 1:length(nel_files)
                for j = 1:length(zip_files);
                    if strcmpi(zip_files(j).name,[nel_files(i).name '.zip'])
                        temp = [temp; i];
                        break;
                    end
                end
            end
            nel_files(temp) = [];
            
            %Before we start copying, we'll put a placeholder on the
            %network drive to let other programs know to wait, so that we
            %don't overload the connection.
            [drives, connected] = verify_network_drive_connection;
            if ~connected   %Again, we'll check to make sure the network drive is connected.
                disp('Could not connect to the network drives.');
                return;
            end
            
            %Then we'll copy any *.NEL* files onto the network drive that aren't
            %already there, check before each copy to make sure the network drive is
            %still connected.
            for i = 1:length(zip_files)
                [drives, connected] = verify_network_drive_connection;
                if ~connected   %Again, we'll check to make sure the network drive is connected.
                    disp('Could not connect to the network drive, automatic processing cancelled');
                    return;
                end
                origin_path(1) = drives(1);
                copy_path(1) = drives(2);
                if ~exist([copy_path '\' zip_files(i).name]) && ~exist([copy_path '\' zip_files(i).name(1:length(zip_files(i).name)-4)])
                    disp(['Copying to ' drives(2) ':\ directory: ' zip_files(i).name]);
                    copyfile([origin_path '\' zip_files(i).name],[copy_path '\' zip_files(i).name]);
                end
            end
            for i = 1:length(nel_files)
                [drives, connected] = verify_network_drive_connection;
                if ~connected   %Again, we'll check to make sure the network drive is connected.
                    disp('Could not connect to the network drive, automatic processing cancelled');
                    return;
                end
                origin_path(1) = drives(1);
                copy_path(1) = drives(2);
                if ~exist([copy_path '\' nel_files(i).name]) && ~exist([copy_path '\' nel_files(i).name '.zip'])
                    disp(['Copying to ' drives(2) ':\ directory: ' nel_files(i).name]);
                    copyfile([origin_path '\' nel_files(i).name],[copy_path '\' nel_files(i).name]);    %Copy file
                end
            end
            
            %Now we'll go through and check to see if files associated with the *.NEL 
            %files already exist on the network drive, such as *.SPK, *.LFP, *.dg_01*,
            %or *.bmp files.
            filetype(1) = {'*.SPK'};        %Spikeshape files.
            filetype(2) = {'*.LFP'};        %Local Field Potential files.
            filetype(3) = {'*.dg_01*'};     %SPC Clustering files.
            filetype(4) = {'*.bmp'};        %Clustering image files.
            for i = 1:length(filetype)
                files = dir(cell2mat(filetype(i)));     %Find all files of this type in the origin folder.
                for j = 1:length(files)
                    [drives, connected] = verify_network_drive_connection;
                    if ~connected   %Again, we'll check to make sure the network drive is connected.
                        disp('Could not connect to the network drive, automatic processing cancelled');
                        return;
                    end
                    origin_path(1) = drives(1);
                    copy_path(1) = drives(2);
                    if ~exist([copy_path '\' files(j).name])    %If the file doesn't exist, copy it.
                        disp(['Copying to ' drives(2) ':\ directory: ' files(j).name]);
                        copyfile([origin_path '\' files(j).name],[copy_path '\' files(j).name]);
                    end
                end
            end
            
        end
        return %****************************************************************************KILL
    end
end


        
%SUB FUNCTIONS*************************************************************************************************************************************
%**************************************************************************************************************************************************
%**************************************************************************************************************************************************
function [drives, connected] = verify_network_drive_connection
connected = 0;
attempts = 0;
while ~connected && attempts < 60
    drives = [];
    for i = 75:89
        if exist([char(i) ':\'],'dir') && exist([char(i+1) ':\'],'dir')
            drives = char(i:i+1);
            break;
        end
    end
    if ~isempty(drives)
        if exist([drives(1) ':\HomeDrive.txt'])
            drives = fliplr(drives);
        end
        connected = 1;
    else
        disp(['Network drives disconnected, no connection detected for ' num2str(attempts) ' minutes.']);
        pause(60);
        attempts = attempts + 1;
    end
end