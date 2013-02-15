function data = f32FileRead(filename)

%
%f32FileRead.m - Rennaker Lab, 2010
%
%   f32FileRead reads in sweep-based spike timing information written in 
%   Brainware's 32-bit binary format from the *.f32 file specified by 
%   "filename".  The returned data structure is organized first by
%   stimulus, and then by repetition (sweep) of each stimulus, such that,
%   for example, data(3).sweep(10).spikes returns a list of spike times
%   that occured during the 10th repeition of the 3rd stimulus.
%
%   BrainWare 6.1 "File | Save As | Spike Times as Binary" (c) Jan Schnupp,
%   Feb 1999.
%
%   Last updated June 4, 2010, by Drew Sloan.

fid = fopen(filename, 'r');

data = [];
numstim = 0;
numsweeps = 0;
totalsweeps = 0;
totalspikes = 0;
i = fread(fid,1,'float32');     %Read in the first 32-bit float number.
while ~isempty(i)

    switch i
        
    case (-2)       %New stimuli are marked with a -2.
        numstim = numstim + 1;                                  %Add to the stimulus count.
        numsweeps = 0;                                          %Reset the sweep (repetition) count.
        data(numstim).sweeplength = fread(fid,1,'float32');     %Read in the sweeplength for this stimulus.
        numparams = fread(fid,1,'float32');                     %Read in the number of parameters defining this stimulus.
        data(numstim).params = fread(fid,numparams,'float32');  %Read in the parameter values.

    case (-1)       %New sweeps (repetitions) are marked with a -1.
        numsweeps = numsweeps + 1;                              %Add to the sweep (repetition) count.
        totalsweeps = totalsweeps + 1;                      	%Add to the total number of sweeps count.
        data(numstim).sweep(numsweeps).spikes = [];           	%Create a field to hold spike times.
    
    otherwise       %Non-negative numbers are spike times in the current sweep.
        data(numstim).sweep(numsweeps).spikes =...
            [data(numstim).sweep(numsweeps).spikes i];          %Add the spike time (in milliseconds) to the list.
        totalspikes = totalspikes + 1;                       	%Add to the total number of spikes count.
        
    end

    i = fread(fid,1,'float32');     %Read in the next 32-bit float number.

end;
fclose(fid);        %Close the input file.
% disp(['read ' num2str(numstim)  ' sets, ' num2str(totalsweeps)...
%     ' sweeps, ' num2str(totalspikes) ' spikes']);