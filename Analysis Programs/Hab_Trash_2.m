function Hab_Trash_2

cd('C:\Documents and Settings\Drew\Desktop\Repetition Suppression\Unsorted SRC Files');
folders = dir;
for i = 14:length(folders)
    if folders(i).isdir
        cd(folders(i).name);
        delete *.f32;
        files = dir('*.SPK');
        for j = 1:length(files)
            SPKtoF32(files(j).name);
        end
    end
    cd('C:\Documents and Settings\Drew\Desktop\Repetition Suppression\Unsorted SRC Files');
end
        
        
        