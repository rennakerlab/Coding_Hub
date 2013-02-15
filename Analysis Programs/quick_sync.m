function [t,p] = quick_sync(varargin)

%
%QUICK_SYNC.m - Rennaker Neural Engineering Lab, 2010
%
%   QUICK_SYNC has the user select an *.f32 file and then creates a pooled 
%   PSTH from those spike times.
%
%   QUICK_SYNC(file,...) creates a pooled PSTH for each file specified.  The 
%   variable "file" can either be a single string or a cell array of 
%   strings containing file names.
%
%   QUICK_SYNC(binsize,...) creates a pooled PSTH smoothing with a longer
%   time bin specified by "binsize", an integer number of milliseconds.
%
%   Last updated November 22, 2010, by Drew Sloan.


smoothsize = 10;                                                            %Set the smoothing bin size to 10 ms.
max_dist = 100;                                                             %The maximum time between spikes to bother checking.
if length(varargin) > 2                                                     %If the user entered too many arguments, show an error.
    error('Too many input arguments for QUICK_SYNC!  Inputs should be a filename string, or cell array of filename strings, and/or an integer bin size.');
end
for i = 1:length(varargin)
    temp = varargin{i};                                                     %Pull the variable out of the input argument.
    if ischar(temp)                                                         %If the argument is a string...
        files(1).name = temp;                                               %Save the filename as a string.
    elseif iscell(temp)                                                     %If the argument is a cell...
        for j = 1:length(temp)                                              %Step through the filenames....
            files(j).name = cell2mat(temp(j));                              %And save the filenames in a structure.
        end
    elseif isnumeric(temp)                                                  %If the argument is a number...
        binsize = temp;                                                     %The user has specified a binsize.
        if length(binsize) > 1 || binsize < 1                               %If the bin size isn't a single integer or is less than 1, show an error.
            error('Bin size input must be a single integer greater than or equal to 1!');
        end
    else                                                                    %If the input isn't a cell, string, or number, show an error.
        error(['Input argument #' num2str(i) ' is not recognized in QUICK_SYNC!  Inputs should be a filename string, or cell array of filename strings, and/or an integer bin size.']);
    end
end
if ~exist('files','var')                                                    %If the user hasn't specified an input file...
    [temp path] = uigetfile('*.f32','multiselect','on');                    %Have the user pick an input file or files.
    cd(path);                                                               %Change the current directory to the folder that file is in.
    if iscell(temp)                                                         %If the user's picked multiple files...
        for i = 1:length(temp)                                              %Step through each selected file.
            files(i).name = [path temp{i}];                                 %Save the file names in a structure.
        end
    elseif ischar(temp)                                                     %If only one file is selected...
        files(1).name = [path temp];                                        %Add the path to the filename.
    elseif isempty(temp)                                                    %If no file is selected...
        error('No file selected!');                                         %Show an error message.
    end
end

comps = [];                                                                 %Make a matrix to hold all of the file-to-file comparison indices.
for i = 1:length(files)                                                     %Step through each of the files.
    for j = (i+1):length(files)                                             %Step through each of the files after the current file.
        comps(:,end+1) = [i;j];                                             %Add the two indices for comparison to the comparison list.
    end
end

for c = comps                                                               %Step through each of the listed comparisons.
    for i = 1:2                                                             %Step through the two files to be analyzed in this comparison.
        if ~exist(files(c(i)).name,'file')                                  %If one of the files doesn't exist...
            error([files(c(i)).name ' doesn''t exist!']);                   %Show an error.
        elseif ~any(strfind(files(c(i)).name,'.f32'));                      %If one of the files isn't an *.f32 file...
            error([files(c(i)).name ' is not an *.f32 file!']);             %Show an error.
        end
    end
    data1 = f32FileRead(files(c(1)).name);                                  %Use f32FileRead to read the first *.f32 file.
    data2 = f32FileRead(files(c(2)).name);                                  %Use f32FileRead to read the second *.f32 file.
    if length(data1) ~= length(data2)                                       %If the two files don't have matching numbers of stimuli...
        error([files(c(1)).name ' & ' files(c(2)).name ...
            ' do not have matching numbers of stimuli!']);                  %Show an error.
    end
    sweeplength = data1(1).sweeplength;                                     %Grab the sweeplength (all sweeps should have the same sweeplength).
    stsad = zeros(length(data1),sweeplength);                               %Pre-allocate a matrix to hold the synchrony STSAD.
    psth = zeros(1,sweeplength);                                            %Pre-allocate a matrix to hold the synchrony "PSTH".
    psth_n = 0;                                                             %To find the average synchrony measure, we'll have to keep track of the total number of sweeps.
    cross = zeros(sweeplength,max_dist);                                    %Pre-allocate a matrix to hold the cross-correlogram.
    counts = zeros(sweeplength,max_dist);                                   %Pre-allocate a matrix to hold the sweep counts for each bin of the cross-correlogram.
    temp = zeros(1,max_dist+1);                                             %Pre-allocate a temporary matrix to hold the cross-correlogram for each spike.
    R = zeros(1,sweeplength);                                               %Pre-allocate a matratrix to hold the cross-correlation coefficient.
    smooth_bins = zeros(sweeplength,2);                                     %Make a matrix to hold bin indices for smoothing.
    for i = 1:sweeplength                                                   %Step through the sweeplength in 1 millisecond steps.
        smooth_bins(i,1) = max([1,floor(i-smoothsize/2)]);                  %Calculate the first bin for smoothing each millisecond.
        smooth_bins(i,2) = min([sweeplength,ceil(i+smoothsize/2)]);         %Calculate the last bin for smoothing each millisecond.
    end
    if rem(smoothsize,2) == 0                                               %If the smooth size is an even number of milliseconds...
        smooth_weights = ones(1,smoothsize+1)/smoothsize;                   %Weight all central bins the same for smoothing.
        smooth_weights([1,end]) = 0.5/smoothsize;                           %Set the tail bins to half the weight for smoothing.
    else                                                                    %Otherwise, if the smooth size is an odd number of milliseconds.
        smooth_weights = ones(1,smoothsize)/smoothsize;                     %Weight all bins the same for smoothing.
    end
    for i = 1:length(data1)                                                 %Step through each stimulus.
        numsweeps = length(data1(i).sweep);                                 %Grab the number of sweeps for this stimulus.
        for j = 1:numsweeps                                                 %Step through each sweep for this stimulus.
            spikes2 = data2(i).sweep(j).spikes;                             %Pre-allocate a matrix to hold all of the spikes from the second unit for this sweep.
            for k = data1(i).sweep(j).spikes                                %Step through all of the spikes in the first unit's sweep.
                spikes2(:) = abs(data2(i).sweep(j).spikes - k);             %Subtract the first file's spiketime from all spiketimes in the second file.
%                 spikes2(spikes2 <= 0.15) = NaN;                             %Kick out any spikes that are within 150 us of the first file's spike.
                if isempty(spikes2)                                         %If there's no spikes in the second file's sweep...
                    temp(:) = 0;                                            %Fill the histogram of spikes with zeros.
                else                                                        %Otherwise...
                    temp(:) = histc(spikes2,0:max_dist);                    %Calculate the histogram of spikes within +/- 100 ms.
                end
                cross(ceil(k),:) = cross(ceil(k),:) + temp(1:max_dist);     %Add the histogram to the cross correlation.
                a = min([ceil(k), max_dist]);                               %Find how much a spike could precede the current spike and still be in the sweeplength.
                counts(ceil(k),1:a) = counts(ceil(k),1:a) + 1;              %Add one to the counts for all valid bins.
                a = min([ceil(sweeplength - k), max_dist]);                 %Find how much a spike could follow the current spike and still be in the sweeplength.
                counts(ceil(k),1:a) = counts(ceil(k),1:a) + 1;              %Add one to the counts for all valid bins.
            end
        end
        cross = cross./counts;                                              %Divide each cross-correlogram bin by it's sweep count.
        cross(cross == Inf) = NaN;                                          %Replace an 
        for j = 1:sweeplength                                               %Step through the sweeplength in 1 millisecond steps.
            cross(j,:) = cross(j,:)/nansum(cross(j,:));                     %Normalize each cross-correlogram.
            R(j) = max(cross(j,:)) - 1/sum(~isnan(cross(j,:)));             %Save the correlation coefficient for each 1 millisecond sweep.
        end
        cross(:) = 0;                                                       %Reset the cross-correlogram.
        counts(:) = 0;                                                      %Reset the cross-correlogram counts.
    end
        
for s = 1:length(data1.sweep)                                               %Step through each sweep in the files.
    spikes2 = data2.sweep(s).spikes;                                        %Pre-allocate a matrix to hold the spike times from the second file.
    for i = data1.sweep(s).spikes                                           %Iterates through each spike time in the first file .f32
        spikes2(:) = data2.sweep(s).spikes - i;                             %Subtract the first file's spiketime from all spiketimes in the second file.
        spikes2(abs(spikes2) <= 0.15) = NaN;                                %Kick out any spikes that are within 150 us of the first file's spike.
        temp(:) = histc(spikes2,edges);                                     %Calculate the histogram of spikes within +/- 100 ms.
        cross = cross + temp(1:binNum);                                     %Add the histogram to the cross correlation.
        a = 101 - min([round(i),100]);                                      %Find the left-most bin that should get a count added.
        b = 100 + min([sweeplength-round(i),100]);                          %Find the right-most bin that should get a count added.
        counts(a:b) = counts(a:b) + 1;                                      %Add one to the bin counts for all possible bins.
    end
end

    
    for j = 1:length(data)      %Step through each stimulus...
        numsweeps = length(data(j).sweep);      %We'll need to know the number of sweeps for plotting.
        for k = 1:numsweeps                     %Step through each sweep...
            if ~isempty(data(j).sweep(k).spikes);                       %If there are any spikes in this sweep...
                temp = histc(data(j).sweep(k).spikes,0:sweeplength);    %Calculate a millisecond-scale histogram for this sweep.
                data(j).sweep(k).spikes = [];               %Pare down the data structure as we work through it to save memory.
                psth = psth + temp(1:sweeplength);                      %Add the histogram to the pooled PSTH.
                stsad(j,1:sweeplength) = stsad(j,1:sweeplength) + temp(1:sweeplength);	%Add the histogram to the STSAD.
            end
            
        end
        psth_n = psth_n + numsweeps;                    %Add a count to the total number of sweeps regardless of if there spikes.
        stsad(j,1:sweeplength) = stsad(j,1:sweeplength)/numsweeps;  %Divide spike count by the number of sweeps to find spikerate.
    end
    
    temp = zeros(1,binNum+1);                                                   %Pre-allocate a temporary matrix to hold the cross-correlogram for each spike.
for s = 1:length(data1.sweep)                                               %Step through each sweep in the files.
    spikes2 = data2.sweep(s).spikes;                                        %Pre-allocate a matrix to hold the spike times from the second file.
    for i = data1.sweep(s).spikes                                           %Iterates through each spike time in the first file .f32
        spikes2(:) = data2.sweep(s).spikes - i;                             %Subtract the first file's spiketime from all spiketimes in the second file.
        spikes2(abs(spikes2) <= 0.15) = NaN;                                %Kick out any spikes that are within 150 us of the first file's spike.
        temp(:) = histc(spikes2,edges);                                     %Calculate the histogram of spikes within +/- 100 ms.
        cross = cross + temp(1:binNum);                                     %Add the histogram to the cross correlation.
        a = 101 - min([round(i),100]);                                      %Find the left-most bin that should get a count added.
        b = 100 + min([sweeplength-round(i),100]);                          %Find the right-most bin that should get a count added.
        counts(a:b) = counts(a:b) + 1;                                      %Add one to the bin counts for all possible bins.
    end
end
    
    
spikerate = zeros(max_dist,files(1).data(1).sweeplength);
counts = zeros(max_dist,files(1).data(1).sweeplength);
for f = 1:length(files)
    for i = 1:length(files(f).data)
        for j = 1:length(files(f).data(i).sweep)
            for k = files(f).data(i).sweep(j).spikes
                a = setdiff(1:length(files),f);
                for m = a
                    temp = histc(files(m).data(i).sweep(j).spikes-k,0:max_dist);
                    if isempty(temp)
                        temp = zeros(max_dist,1);
                    elseif size(temp,2) > size(temp,1)
                        temp = temp';
                    end        
                    spikerate(:,ceil(k)) = spikerate(:,ceil(k)) + temp(1:max_dist);
                    counts(1:min([max_dist,files(f).data(i).sweeplength-ceil(k)+1]),ceil(k)) = ...
                        counts(1:min([max_dist,files(f).data(i).sweeplength-ceil(k)+1]),ceil(k))  + 1;
                end
            end
        end
    end
end
counts(end) = [];
counts = counts - min(counts);
counts = counts/sum(counts);
coeffs = lsqcurvefit(@expdecay,[0,max(counts),max_dist],(1:length(counts))',counts');
t = coeffs(3);
p = zeros(1,length(counts));
for i = 1:length(counts)
    p(i) = sum(counts(1:i))/sum(counts);
end