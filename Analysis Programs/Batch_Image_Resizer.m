function Batch_Image_Resizer

path = uigetdir;                                                            %Have the user specify a directory.
if path(1) == 0                                                             %If the user didn't select a path...
    return                                                                  %Quit this function.
end
cd(path);                                                                   %Step into the user-specified directory.

checker = 0;                                                                %Create a checking matrix to see if we've looked in all the subfolders.
folders = {path};                                                           %Create a cell array to hold paths to all the subfolders.
while any(checker == 0)                                                     %Keep looking until all subfolders have been checked for *.xls files.
    a = find(checker == 0,1,'first');                                       %Find the next folder that hasn't been checked for subfolders.
    temp = dir(folders{a});                                                 %Grab all the files and folders in the current folder.
    for f = 1:length(temp)                                                  %Step through all of the returned contents.
        if ~any(temp(f).name == '.') && temp(f).isdir == 1                  %If an item is a folder, but not a system folder...
            folders{end+1} = [folders{a} temp(f).name '\'];                 %Add the subfolder to the list of subfolders.
            checker(end+1) = 0;                                             %Add an entry to the checker matrix to check this subfolder for more subfolders.
        end
    end
    checker(a) = 1;                                                         %Mark the last folder as having been checked.
end
files = {};                                                                 %Create an empty cell array to hold *.xlsx filenames.
for f = 1:length(folders)                                                   %Step through every subfolder.
    temp = dir([folders{f} '*.jpg']);                                       %Grab all the *.jpg filenames in the subfolder.
    for i = 1:length(temp)                                                  %Step through every *.jpg file.
        files{end+1} = [folders{f} temp(i).name];                           %Save the filename with it's full path.
    end
end

for i = 1:length(files)                                                     %Step through each file.
    disp(['Resizing image ' num2str(i) '/' num2str(length(files))]);        %Show the user which file is being resized.
    im = imread(files{i});                                                  %Read in the image from the file.
    w = size(im,2);                                                         %Find the pixel width of the in the image.
    if w == 1920                                                            %If the width already equals 1920...
        continue                                                            %Skip to the next file.
    end
    im = imresize(im,1920/w);                                               %Resize the image to HD resolution.
    h = size(im,1);                                                         %Find the number of rows in the image.
    h = fix((h-1080)/2) + (1:1080);                                         %Find the middle 1080 rows.
    filename = files{i}(find(files{i} == '\',1,'last')+1:end);              %Grab the filename after the last forward slash.
    filename = [path filename];                                             %Add the main path to the filename.
    imwrite(im(h,:,:),filename,'jpg');                                      %Resave the image with the new resolution.
    delete(files{i});                                                       %Delete the original file.
end

aviobj = avifile('GoProTest');                                              %Create an AVI file.
aviobj.quality = 100;                                                       %Set the video quality to 100%.
avi.fps = 30;                                                               %Set the video playback to 30 frames per second.
files = dir('*.jpg');                                                       %Grab all of the files in the main directory.
for i = 1:length(files);                                                    %Step through each of the files.
    [im, map] = imread(files(i).name);                                      %Read in the image file.
    F.cdata = im;                                                           %Save the image in the frame structure.
    F.colormap = map;                                                       %Save the colormap in the frame structure.
    aviobj = addframe(aviobj,F);                                            %Add this frame to the AVI file.
end
aviobj = close(aviobj);                                                     %Close the AVI file.