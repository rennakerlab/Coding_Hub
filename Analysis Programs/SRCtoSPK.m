function SRCtoSPK(file)

%
%SRCtoSPK.m - OU Neural Engineering Lab, 2007
%
%   NELtoSPK takes spike shape and spike time data from Brainware *.src
%   files and converts them to the NEL *.SPK format so that you can use NEL
%   spike sorting software on the waveforms.
%
%   NELtoSPK(file) converts the input *.src file to an *.SPK file with the
%   same root name.
%
%   Last updated August 3, 2008, by Drew Sloan.


%First, we'll check the input file to make sure it's a *.NEL file.
if ~strcmpi(file(length(file)-3:length(file)),'.src');
    error('- Input file is not a *.src file.');
end

%First, we'll read in the data from the *.src file using Jan Schnupp's
%readSRCfile function.
data = readSRCfile(file);

%Next, we'll pull out the timestamp that tells us when this recording was
%started.
temp = data.comments.timeStamp;     %Jan Schnupp's timestamp is a 64 bit number of days since December 30th, 1899.
temp = temp + 693962;              	%We'll switch that to a timestamp numbering the days since January 1, 0000.
data.daycode = daycode(temp);       %Use the daycode function to find the day code for the timestamp.

%We'll pull the rat's name out of the file name.
if any(findstr(file,'\'))                                   %If the path name is in the file name...
    temp = file(find(file == '\',1,'last')+1:length(file)); %Remove the path name.
else                                                        %Otherwise...
    temp = file;                                            %Just copy the file name.
end
a = find(temp == '_');                                      %Find all the underscores in the file name.
if length(a) >= 4                                           %If this file name is in the proper format...
    data.rat = temp(a(3)+1:a(4)-1);                         %The rat's name is between the 3rd and 4th underscore.
else                                                        %Otherwise...
    data.rat = 'Unknown';                                   %Mark the rat's name as unknown.
end   

%The spontaneous delay for Brainware is stored in the SigGen sound files,
%and isn't written into the *.src files in most cases.  However, we tended
%to use 35 ms as a standard for years, so we'll assume that here.
data.spont_delay = 35;      %Spontaneous delay in ms.

%The *.src file holds the A-D period, in microseconds, but we'll convert
%that to sampling rate in Hz.
data.sampling_rate = 1000000/data.ADperiod;

%Next, we'll pull out the stimulus parameters.
for i = 1:data.sets(1).stim.numParams
    data.param(i).name = data.sets(1).stim.paramName{i};
end
    
%We'll grab the spike shape sample size.
spikesize = [];
for i = 1:length(data.sets)     %Step through by stimulus.
    for j = 1:length(data.sets(i).clusters.sweeps)      %Step through by sweep.
        for k = 1:length(data.sets(i).clusters.sweeps(j).spikes)    %Step through by spike.
            spikesize = size(data.sets(i).clusters.sweeps(j).spikes(k).shape,1);    %Grab the sample length of any spike.
            if ~isempty(spikesize); break; end  %If we've found a spikeshape, exit the loop.
        end
        for k = 1:length(data.sets(i).unassignedSpikes(j).spikes)
            if ~isempty(spikesize); break; end  %If we've found a spikeshape, exit the loop.
            spikesize = size(data.sets(i).unassignedSpikes(j).spikes(k).shape,1);    %Grab the sample length of any spike.
        end
        if ~isempty(spikesize); break; end  %If we've found a spikeshape, exit the loop.
    end
    if ~isempty(spikesize); break; end  %If we've found a spikeshape, exit the loop.
end

%We'll want to find the order of the presentation, which we can calculate
%from the timestamps on each sweep.
order = [];
for i = 1:length(data.sets)     %Grab all the time stamps from each sweep for each stimulus.
    order = [order data.sets(i).unassignedSpikes(:).timeStamp];
end
[temp order] = sort(order');    %Use the sort program to find the index order of the time stamps.

%Last, we'll need to know the gain, so that we can save the spike shapes
%in their actual scale voltages.
gain = data.comments.text(find(data.comments.text == ':')+1:length(data.comments.text));
gain = str2num(gain);

%The output file will have the same name as the input file, but with the *.SPK file extension.
newfile = [file(1:length(file)-4) '.SPK'];
disp(['Converting "' file '" to "' newfile '"']);

%Now we'll create the *.SPK file to write spikeshapes to and enter in the
%session parameters.
fid = fopen(newfile,'w');
if fid == -1
    pause(180);
    fid = fopen(newfile,'w');
end
fwrite(fid,data.daycode,'int8');                %DayCode.
fwrite(fid,length(data.rat),'int8');            %Number of characters in the rat's name.
fwrite(fid,data.rat,'uchar');                   %Characters of the rat's name.
fwrite(fid,data.spont_delay,'int16');           %Spontaneous measurement delay.
fwrite(fid,data.sampling_rate,'float32');       %Sampling rate, in Hz.
fwrite(fid,spikesize,'int16');                  %Number of samples in each spikeshape.
fwrite(fid,length(data.param),'int8');          %Number of parameters.
for j = 1:length(data.param)
    fwrite(fid,length(data.param(j).name),'int16');     %Number of characters in each parameter name.
    fwrite(fid,data.param(j).name,'uchar');             %Characters of each parameter name.
end    
        
%Now we'll go back and threshold each sweep and pull out the spike shapes.
numspikes = 0;
for i = 1:length(data.sets)                             %New Stimulus.
    fwrite(fid,i,'uint16');                          	%Stimulus index.
    fwrite(fid,data.sets(i).sweepLen/1000,'float32');	%Sweeplength, in seconds.
    for k = 1:length(data.param)                        %Step through by parameter...
        fwrite(fid,data.sets(i).stim.paramVal(k),'float32');	%Write the parameter values for this stimulus.
    end
    numsweeps = length(data.sets(i).unassignedSpikes);
    fwrite(fid,numsweeps,'uint16');             %The number of sweeps to follow.
    for j = 1:numsweeps
        fwrite(fid,data.sets(i).unassignedSpikes(j).timeStamp + 693962,'float64');    %Timestamp.
        fwrite(fid,order(1),'uint16');      %Write the order of presentation (trial number).
        order(1) = [];                      %Clear the just-written order to advance the list for the next write.
        fwrite(fid,0,'float32');            %It's impossible to guess a noise estimate for *.src files, so we'll just write a zero.
        
        %Now, because *.src files usually contain both cluster-assigned and
        %cluster-unassigned spikes, we'll go through and build matrices fo
        %spike shapes, times, and cluster assignments before writing them
        %to file.
        spikeshapes = [];
        spiketimes = [];
        spikeclusters = [];
        for k = 1:length(data.sets(i).unassignedSpikes(j).spikes)   %Step through the unassigned spikes.
            spikeshapes(k,:) = 5*data.sets(i).unassignedSpikes(j).spikes(k).shape'/(127*gain);  %Spike shape.
            spiketimes(k,:) = data.sets(i).unassignedSpikes(j).spikes(k).time;                    %Spike time.
            spikeclusters(k,:) = 0;   %For unassigned spikes, assume they're noise.
        end
        for c = 1:length(data.sets(i).clusters)     %Step through by cluster.
            for k = 1:length(data.sets(i).clusters(c).sweeps(j).spikes)     %Step through by spike.
                spikeshapes = [spikeshapes; ...
                    5*data.sets(i).clusters(c).sweeps(j).spikes(k).shape'/(127*gain)];          %Spike shape.
                spiketimes = [spiketimes; data.sets(i).clusters(c).sweeps(j).spikes(k).time];	%Spike time.
                spikeclusters = [spikeclusters; c];                                             %Cluster assigment.
            end
        end
        [spiketimes, a] = sort(spiketimes);         %Sort the spikes by spike time.
        spikeshapes = spikeshapes(a,:);             %Reorder the spikeshapes matrix the same way.
        spikeclusters = spikeclusters(a);           %Reorder the spike clusters matrix the same way.
        
        fwrite(fid,length(spiketimes),'uint32');  	%Write the number of spikes.
        for k = 1:length(spiketimes)                %Now stepping through spike by spike.
            fwrite(fid,spiketimes(k),'float32');        %Write the spike time.
            fwrite(fid,spikeclusters(k),'uint8');       %Write the cluster assignment.
            fwrite(fid,spikeshapes(k,:)','float32');   	%Write the spike shape.
        end
        numspikes = numspikes + length(spiketimes);     %Keep track of the number of spikes.
    end
end
fclose(fid);    %Finally, we'll close the *.SPK file and disp how long it took to threshold this file.
disp(['-----> ' num2str(numspikes) ' spikes.']);