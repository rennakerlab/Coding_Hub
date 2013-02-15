function F32_File_Finder

look_for = ['*TC*BF*.f32'];

dest = 'C:\Documents and Settings\Owner\Desktop\BF Model Neuron';

cd('F:\Rat Files');
rats = dir;
trash = [];
for i = 1:length(rats) 
	if strcmpi(rats(i).name,'.' ) | strcmpi(rats(i).name,'..') | ~rats(i).isdir 
	    trash = [trash, i];
    end
rats(i).path = [cd '\' rats(i).name]; 
end
rats(trash) = [];

for rat = 1:length(rats)
    disp(['Checking: ' rats(rat).path]);
    checker = 1;
	cd(rats(rat).path);
    folders = dir;
    trash = [];
    for i = 1:length(folders) 
        if strcmpi(folders(i).name,'.' ) | strcmpi(folders(i).name,'..') | ~folders(i).isdir 
            trash = [trash, i];
        end 
    folders(i).name = [cd '\' folders(i).name]; 
    end
    folders(trash) = [];
    for f = 1:length(folders)
        disp(['   ' folders(f).name]);
        cd(folders(f).name);
        subfolders = dir;
        trash = [];
        for i = 1:length(subfolders) 
            if strcmpi(subfolders(i).name,'.' ) | strcmpi(subfolders(i).name,'..') | ~subfolders(i).isdir 
                trash = [trash, i];
            end 
        subfolders(i).name = [cd '\' subfolders(i).name]; 
        end
        subfolders(trash) = [];
        for s = 1:length(subfolders)
            disp(['      ' subfolders(s).name]);
            cd(subfolders(s).name);
            files = dir(look_for); 
            for currentfile = 1:length(files)
                if checker
                    [s,mess,messid] = mkdir([dest '\' rats(rat).name]);
                    checker = 0;
                end
                disp(['         Copying: ' files(currentfile).name]);
                copyfile(files(currentfile).name,[dest '\' rats(rat).name]);
            end
        end
    end
end