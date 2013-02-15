function Hab_Trash_1

cd('C:\Documents and Settings\Drew\Desktop\Repetition Suppression\Unsorted SRC Files');
folders = dir;
for i = 1:length(folders)
    if folders(i).isdir
        cd(folders(i).name);
        delete *.f32;
        files = dir('*.SPK');
        for j = 1:length(files)
            SPKtoF32(files(j).name);
        end
%         for j = 1:length(files)
%             try
%             NEL_Auto_SPC(files(j).name);
%             catch
%             end
%         end
%         files = dir('*IsoTC*post1*.SPK');
%         for j = 1:length(files)
%             try
%             NEL_Auto_SPC(files(j).name);
%             catch
%             end
%         end
    end
    cd('C:\Documents and Settings\Drew\Desktop\Repetition Suppression\Unsorted SRC Files');
end
        
        
        