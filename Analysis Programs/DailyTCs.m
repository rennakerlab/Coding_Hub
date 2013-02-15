%This program will create a plot of the tuning curves for a specific rat 
%during a specific days run.  The MatLAB Current Directory MUST be set to 
%the correct folder containing the .NEL files you wish to see tuning curves
%for.  

files = dir('*.NEL');           %This loop will convert all .NEL files to
for i = 1:length(files)         %.SPK files.
    neltospk(files(i).name)
end

files = dir('*.SPK');           %This loop will convert all .SPK files to
for i = 1:length(files)         %.F32 files.
    spktoF32(files(i).name)
end

plottcs