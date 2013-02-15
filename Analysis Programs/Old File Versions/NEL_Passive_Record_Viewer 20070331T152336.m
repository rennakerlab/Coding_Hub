function NEL_Passive_Record_Viewer

[file path] = uigetfile('*.NEL');
cd(path);

%We can use either positive or negative thresholds, and we'll define that
%up front.
threshold_type = 'Neg';

%We'll start by defining some terms at the beginning so we can change them
%easily.
noise_ceiling = 0.001;         %Maximum allowable voltage to be considered a spike.
low_pass_cutoff = 4500;         %Low-pass cut-off of the passband filter, in Hz.
high_pass_cutoff = 825;         %High-pass cut-off of the passband filter, in Hz.
min_thresh = 3;                 %Minimum threshold for detection, in standard deviations of the noise.
sampling_rate = 24414.0625;     %The sampling rate of the RA16s.
pre_pts = 19;                   %The number of sample points to grab before a threshold crossing.
post_pts = 44;                  %The number of sample points to grab after a threshold crossing.
int_fact = 100;                 %Interpolation factor for fitting splines to spikeshapes.

%Here we'll generate the filter coefficients for the passband filter.
[b,a] = ellip(2,0.1,40,[high_pass_cutoff low_pass_cutoff]*2/sampling_rate);       
filter_coefs = [b; a];

%We'll use NELFileRead to open the data file.
data = NELFileRead(file);

%We'll grab the sweeplength for later use.
sweeplength = round(1000*size(data.stim(1).signal,2)/sampling_rate);

%First, we'll filter the sweep data.
for i = 1:length(data.stim)
    for j = 1:size(data.stim(i).signal,1)
        signal = data.stim(i).signal(j,:);
        %To avoid transients on the beginning and end of the signal, we'll 
        %add 500 sample disposable "tails" that the transients will appear 
        %on, but not on the saved signal.
        signal = [repmat(signal(1),1,500), signal, repmat(signal(length(signal)),1,500)];
        signal = filtfilt(filter_coefs(1,:),filter_coefs(2,:),signal);      %Applying the passband filter.
        signal = signal(501:(length(signal)-500));                          %Removing the "tails".
        data.stim(i).signal(j,:) = signal;                                 %Overwriting the filtered signal back to the structure.
    end
end

%Next, we'll calculate a threshold for spikes.  Since we're dealing with a
%much larger signal in the long run than Quiroga's system is used to
%dealing with, we'll need to "cheat" to estimate the median amplitude of
%the whole signal by taking the median of the median of each sweep.
thresh = [];
for i = 1:length(data.stim)
    for j = 1:size(data.stim(i).signal,1)
        signal = abs(data.stim(i).signal(j,:));
        signal = signal(find(signal < noise_ceiling));
        thresh = [thresh; median(signal)/0.6745];
    end
end
thresh = min_thresh*median(thresh);

%Now we'll create the *.SPK file to write spikeshapes to and enter in the
%session parameters.
fid = fopen(newfile,'w');
fwrite(fid,data.daycode,'int8');                %DayCode.
fwrite(fid,length(data.rat),'int8');            %Number of characters in the rat's name.
fwrite(fid,data.rat,'uchar');                   %Characters of the rat's name.
fwrite(fid,data.spont_delay,'int16');           %Spontaneous measurement delay.
fwrite(fid,(pre_pts+post_pts+1),'int16');       %Number of samples in each spikeshape.
fwrite(fid,length(data.param),'int8');          %Number of parameters.
for j = 1:length(data.param)
    fwrite(fid,length(data.param(j).name),'int16');     %Number of characters in each parameter name.
    fwrite(fid,data.param(j).name,'uchar');             %Characters of each parameter name.
end    
        
%Now we'll go back and threshold each sweep and pull out the spike shapes.
numspikes = 0;
for i = 1:length(data.stim)
    for j = 1:size(data.stim(i).signal,1)
        fwrite(fid,i,'int16');                              %Stimulus index.
        fwrite(fid,data.stim(i).order(j),'uint16');         %Stimulus order.
        fwrite(fid,data.stim(i).timestamp(j),'float64');    %Timestamp.
        for k = 1:length(data.param)
            fwrite(fid,data.param(k).value(i),'float32');	%Parameter values.
        end
        signal = data.stim(i).signal(j,:);
        if strcmpi(threshold_type,'POS')     %If we're applying a positive threshold.
            index = intersect(find(signal >= thresh),find(signal < thresh)+1);
        else    %Otherwise, we're applying a negative threshold.
            index = intersect(find(signal <= -thresh),find(signal > -thresh)+1);
        end
        index = index(find(index > pre_pts+2 & index < length(signal)-post_pts-2));
        for k = 1:length(index);
            trace = signal(index(k)-pre_pts-2:index(k)+post_pts+2);
            if max(abs(trace)) > noise_ceiling
                index(k) = nan;
            end
        end
        index(isnan(index)) = [];
        numspikes = numspikes + length(index);
        fwrite(fid,length(index),'uint32');       %Number of spikes.
        for k = 1:length(index)
            trace = signal(index(k)-pre_pts-2:index(k)+post_pts+2);
            curve_fit = spline(1:length(trace),trace,1/int_fact:1/int_fact:size(trace,2));
            if strcmpi(threshold_type,'POS')     %Again, if we're applying a positive threshold.
                spike_time = intersect(find(curve_fit >= thresh),find(curve_fit < thresh)+1)/int_fact;
            else
                spike_time = intersect(find(curve_fit <= -thresh),find(curve_fit > -thresh)+1)/int_fact;
            end
            spike_time = min(spike_time(find(spike_time >= pre_pts+2 & spike_time <= pre_pts+3)));
            spike_n = spike_time*int_fact;
            spike_shape = curve_fit(spike_n - int_fact*pre_pts:int_fact:spike_n + int_fact*post_pts);
            index(k) = index(k)-pre_pts+3 + spike_time(find(spike_time >= pre_pts+2 & spike_time <= pre_pts+3));
            fwrite(fid,1000*index(k)/sampling_rate,'float32');      %Spike time.
            fwrite(fid,1,'uint8');                                  %Cluster assignment.
            fwrite(fid,spike_shape','float32');                     %Spike shape.
        end
        disp(numspikes);
    end
    data.stim(i).signal = [];
end
fclose(fid);
disp(['-----> ' num2str(numspikes) ' spikes.']);