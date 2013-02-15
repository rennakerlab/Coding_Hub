function f32_rewriter_example

%Load an *.f32 file.
[file, path] = uigetfile('*.f32');                                          %Grab a *.f32 file to convert.
cd(path);                                                                   %Step into that file's directory.
data = f32FileRead(file);                                                   %Read in the data from the *.f32 file.

%**************************************************************************
%RE-ORDER THE DATA STRUCTURE HOW YOU WANT IT HERE.
%For example, let's sort the data by it's 2nd parameter instead of the
%first.
params = horzcat(data.params)';                                             %Make a matrix of parameters with a row for each stimulus.
[params, i] = sortrows(params,2);                                           %Sort the parameters by the 2nd column.
data = data(i);                                                             %Resort the whole data structure using the same sorting indices.
%**************************************************************************

%Write a new copy of the file.
new_file = [file(1:end-4) '_new.f32'];                                      %Add the word "new" to the old file name.
fid = fopen(new_file,'w');                                                  %Open a new *.f32 file for writing.                                    
for i = 1:length(data)                                                      %Step through each stimulus.
    fwrite(fid, -2,'float32');                                              %Write a -2 to indicate a new stimulus.
    fwrite(fid, data(i).sweeplength, 'float32');                            %Write the sweeplength for the stimulus.
    fwrite(fid, length(data(i).params), 'float32');                         %Write the number of stimulus parameters to follow.
    fwrite(fid, data(i).params, 'float32');                                 %Write the stimulus parameters for this stimulus.
    for j = 1:length(data(i).sweep)                                         %Step through each sweep for this stimulus.
        fwrite(fid, -1, 'float32');                                         %Write a -1 to indicate a new sweep.
        fwrite(fid, data(i).sweep(j).spikes', 'float32');                   %Write the spike times for this sweep.
    end
end
fclose(fid);                                                                %Close the new *.f32 file.