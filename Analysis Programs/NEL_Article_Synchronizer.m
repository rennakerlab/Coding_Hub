function NEL_Article_Synchronizer

%NEL_Article_Synchronizer.m - OU Neural Engineering Lab, 2008
%
%   NEL_Program_Updater looks to see that all the articles contained in teh
%   "Articles" folder on the network drive are also in the "Articles"
%   folder on the desktop of the local computer and vice versa.  Articles
%   that are missing from the opposite folder are copied over.
%
%   Last updated September 30, 2008, by Drew Sloan.

%The desktop path is different for different computers depending on the
%username, this section should cover all those already in use at the
%OU-NEL, but just add an extra "elseif" with your desktop path if it's not
%already on there.
if exist('C:\Documents and Settings\user\Desktop','dir') == 7;
    desktop = 'C:\Documents and Settings\user\Desktop';             %Desktop path.
elseif exist('C:\Documents and Settings\Owner\Desktop','dir') == 7
    desktop = 'C:\Documents and Settings\Owner\Desktop';            %Desktop path.
elseif exist('C:\Documents and Settings\NEL_students\Desktop','dir') == 7
    desktop = 'C:\Documents and Settings\NEL_students\Desktop';     %Desktop path.
elseif exist('C:\Documents and Settings\Administrator\Desktop','dir') == 7
    desktop = 'C:\Documents and Settings\Administrator\Desktop';    %Desktop path.
elseif exist('C:\Documents and Settings\Drew\Desktop','dir') == 7
    desktop = 'C:\Documents and Settings\Drew\Desktop';             %Desktop path.
elseif exist('C:\Users\user\Desktop','dir') == 7
    desktop = 'C:\Users\user\Desktop';                              %Desktop path.
end
deskpath = [desktop '\Articles'];
    
%Here we'll set the network drive path.
ypath = 'Y:\';      %The NEL lab Worldbook drive.
netpath = [ypath 'Articles'];

%Here we'll grab all the files on the desktop path, and delete any we think
%might be corrupted by looking for filenames that only contain lowercase
%letters.  As an NEL standard, the first letter of the author's name and the first
%letter of the article title should be capitalized.
cd(deskpath);
files = dir('*.pdf');   %Grab all *.pdf files.
for i = 1:length(files)
    if strcmp(files(i).name,lower(files(i).name)) %#ok<STCI>
        disp(['Deleting because likely corrupted: ' files(i).name]);
        delete(files(i).name);  %If the file name is all lowercase, delete it.
    end
end
files = dir('*.pdf');

%We'll go through the desktop folder and see which articles are there
%that aren't on the network drive and copy those files over.
for i = 1:length(files)
    if ~exist([netpath '\' files(i).name],'file')  %If it doesn't exist on the network drive, copy it.
        disp(['Copying to Network Drive: ' files(i).name]);
        copyfile([deskpath '\' files(i).name], [netpath '\' files(i).name]);
    end
end

%Next, we'll go through and clear any files out of the desktop folder that
%don't conform to the NEL file name standard, since they may be corrupted.
for i = 1:length(files)
    if length(strfind(files(i).name, ' - ')) < 2
        disp(['Deleting because of bad format: ' files(i).name]);
        delete(files(i).name);  %If the file name doesn't contain a ' - ', then it is not standard.
    else
        temp = strfind(files(i).name, ' - ');
        if temp(2) - temp(1) ~= 7 || str2num(files(i).name(temp(1)+3:temp(1)+6)) < 1700 || ...
                str2num(files(i).name(temp(1)+3:temp(1)+6)) > 2100 %#ok<ST2NM,ST2NM>
            disp(['Deleting because of bad format: ' files(i).name]);
            delete(files(i).name);  %If the file name doesn't contain a ' - ', then it is not standard.
        end
    end
end
        
%Finally, we'll go through the articles on the network drive and copy any
%that aren't on the local computer to the desktop "Articles" folder.  We
%won't include any files that don't fit the NEL file name standard, though,
%since they may be corrupted.
cd(netpath);
files = dir('*.pdf');
for i = 1:length(files)
    if length(strfind(files(i).name, ' - ')) >= 2 && ~strcmp(files(i).name,lower(files(i).name)) && ~exist([deskpath '\' files(i).name],'file') %#ok<STCI>
        temp = strfind(files(i).name, ' - ');
        if temp(2) - temp(1) == 7 && str2num(files(i).name(temp(1)+3:temp(1)+6)) > 1700 && ...
                str2num(files(i).name(temp(1)+3:temp(1)+6)) < 2100 %#ok<ST2NM,ST2NM>
            disp(['Copying to Desktop: ' files(i).name]);
            copyfile([netpath '\' files(i).name], [deskpath '\' files(i).name]);
        end
    end
end        