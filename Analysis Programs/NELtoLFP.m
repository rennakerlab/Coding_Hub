function NELtoLFP(file,varargin)

%
%NELtoLFP.m - OU Neural Engineering Lab, 2007
%
%   NELtoLFP takes the raw, unfiltered sweeep traces from neural recordings
%   saved in the *.NEL format and filters the signal to return local field
%   potentials (LFPs).  The LFPs are then saved in the *.LFP file format.
%
%   NELtoLFP(file) filters the input *.NEL to return LFPs using all
%   function defaults.
%
%   NELtoLFP(...,'Property1',PropertyValue1,...) sets the values of any of the
%   following optional filtering properties:
%
%   * 'FilterSettings' - Set the frequency cutoffs for the bandpass filters.
%                        Input value should be a 1 by 2 matrix of frequency
%                        cutoffs (in Hz).  The default value is [1 300].
%
%   * 'Display' - Display plots of the threshold process, set with values 
%                 of 'On' or 'Off'.  Default value is 'Off'.
%
%   Last updated January 2, 2008, by Drew Sloan.


%First, we'll check the input file to make sure it's a *.NEL file.
if ~strcmpi(file(length(file)-3:length(file)),'.NEL');
    error('- Input file is not a *.NEL file.');
end

%We'll start by defining the default terms up front, and then change them
%if the user specifies any different values.
high_pass_cutoff = 1;       %High-pass cutoff for the passband filter, in Hz.
low_pass_cutoff = 300;      %Low-pass cutoff for the passband filter, in Hz.
displayopt = 0;             %Display plots of the LFPs are turned off by default.

%Now we'll go through any changes to the optional properties the user might
%have entered.
for i = 1:2:length(varargin)
    if length(varargin) <= i    %Input arguments must come in pairs, the property name and it's specified value.
        error(['- No corresponding input argument for ''' cell2mat(varargin(i)) '''.']);
    else
        if strcmpi(cell2mat(varargin(i)),'Display');    %Turn FLP filtering plot displays on or off.
            if strcmpi(cell2mat(varargin(i+1)),'On')
                displayopt = 1;     %Turn displays on.
            elseif strcmpi(cell2mat(varargin(i+1)),'Off')
                displayopt = 0;     %Turn displays off.
            else    %If the input value is neither 'On' or 'Off', then indicate error.
                error('- The ''Display'' property must set to either ''On'' or ''Off''.');
            end
        elseif strcmpi(cell2mat(varargin(i)),'FilterSettings');     %Setting the passband filter settings.
            temp = cell2mat(varargin(i+1));
            if isstr(temp) || ~all(size(temp) == [1 2]) || any(temp < 0)  %Filter settings must be non-zero and numeric.
                error('- The ''FilterSettings'' property must be a 1 by 2 matrix of positive, non-zero frequency values (in Hz).');
            else
                low_pass_cutoff = max(temp);    %Setting the low-pass cutoff.
                high_pass_cutoff = min(temp);   %Setting the high-pass cutoff.
            end
        else
            error(['- ''' cell2mat(temp) ''' is not a recognized input argument.']);
        end
    end
end

%The output file will have the same name as the input file, but with the *.LFP file extension.
newfile = [file(1:length(file)-4) '.LFP'];
disp(['LFP Filtering "' file '" to "' newfile '"']);

%We'll use NELFileRead to open the data file.
data = NELFileRead(file);

%Here we'll generate the filter coefficients for the bandpass filters.
[b,a] = butter(2,2*low_pass_cutoff/data.sampling_rate,'low');       
lowpass = [b; a];
[b,a] = butter(2,2*high_pass_cutoff/data.sampling_rate,'high');       
highpass = [b; a];

%If this is a microstimulation-recording file, the first thing we need to
%do is to "blank" out the microstimulation pulse so that artefacts don't
%show up from filtering.  We'll do that by cutting out the microstimulation
%sections, and filling the gap with a straight line.
% if strcmpi(file(5:8),'STIM')
%     disp('This is a microstimulation-recording file, cutting out microstimulation artefact...');
%     for i = 1:length(data.stim)
%         phasedur = data.param(2).value(i);      %Pull out the phase duration, in milliseconds.
%         ipp = data.param(4).value(i);           %Pull out the interpulse-period, in milliseconds.
%         numpulse = data.param(5).value(i);      %Pull out the number of pulses.
%         for j = 1:size(data.stim(i).signal,1)
%             for k = 1:numpulse
%                 a = data.spont_delay + ipp*(k-1) + 0.25;   %Find the onset time of the microstimulation.
%                 b = a + 2*phasedur + 2;                     %We'll blank out the 2 ms following the microstimulation.
%                 a = fix(data.sampling_rate*a/1000);     %Change onset time to number of samples, rounding down.
%                 b = ceil(data.sampling_rate*b/1000);	%Change offset time to number of samples, rounding up.
%                 temp = [data.stim(i).signal(j,a); data.stim(i).signal(j,b)];    %Find the signal values at the gap endpoints.
%                 temp = [ones(2,1), [a; b]]\temp;                                %Create a regression matrix.
%                 temp = [ones(length([a:b]),1), [a:b]']*temp;                    %Find points on a straight line connecting the gap.
%                 data.stim(i).signal(j,a:b) = temp;                              %Replace artefact with the straight line points.
%             end
%         end
%     end
% end    

%Now we'll create the *.LFP file to write LFPs to and enter in the session 
%parameters.
fid = fopen(newfile,'w');
if fid == -1
    pause(180);
    fid = fopen(newfile,'w');
end
fwrite(fid,data.daycode,'int8');                %DayCode.
fwrite(fid,length(data.rat),'int8');            %Number of characters in the rat's name.
fwrite(fid,data.rat,'uchar');                   %Characters of the rat's name.
fwrite(fid,data.spont_delay,'int16');           %Spontaneous measurement delay.
fwrite(fid,length(data.param),'int8');          %Number of parameters.
for j = 1:length(data.param)
    fwrite(fid,length(data.param(j).name),'int16');     %Number of characters in each parameter name.
    fwrite(fid,data.param(j).name,'uchar');             %Characters of each parameter name.
end    

%Now we'll go through and filter each sweep to return LFPs.
if displayopt   %If the display option is on, we'll open a figure.
    a = figure(1);
    pos = get(0,'ScreenSize');  %We'll make the figure large because it's going to have many subplots.
    pos = [0.1*pos(3),0.1*pos(4),0.8*pos(3),0.8*pos(4)];
    set(a,'Position',pos,'MenuBar','none');
    set(gca,'Position',[0 0 1 1]);
    set(gca,'xtick',[],'ytick',[]);
    surfdata = [];
end
for i = 1:length(data.stim)         %New Stimulus.
    fwrite(fid,i,'uint16');                                 %Stimulus index.
    fwrite(fid,data.stim(i).sweeplength,'float32');         %Sweeplength, in seconds.
    for k = 1:length(data.param)
        fwrite(fid,data.param(k).value(i),'float32');	%Parameter values.
    end
    numsweeps = size(data.stim(i).signal,1);
    fwrite(fid,numsweeps,'uint16');             %The number of sweeps to follow.
    for j = 1:size(data.stim(i).signal,1)       %New Sweep.
        if ~isnan(data.stim(i).signal(j,1));     %Continue only if this is a valid sweep.
            fwrite(fid,data.stim(i).timestamp(j),'float64');    %Timestamp.
            fwrite(fid,data.stim(i).order(j),'uint16');         %Order of presentation (trial number).
            signal = data.stim(i).signal(j,:);      %Grab the unfiltered signal.
            signal = [repmat(signal(1),1,500), signal, repmat(signal(end),1,500)];   %Add tails to prevent edge effects in the filter.
            signal = filtfilt(lowpass(1,:),lowpass(2,:),double(signal));	%Applying the lowpass filter.
            signal = filtfilt(highpass(1,:),highpass(2,:),signal);          %Applying the highpass filter.
            signal = single(signal(501:(end-500)));            	%Cut off tails.
            a = length(signal)/(1000*data.stim(i).sweeplength);             %Find the number of samples per millisecond.
            a = 1:a:length(signal);     %Identify ideal 1000 Hz sample points, possibly non-integer.
            trace = [];
            for k = a
                x1 = fix(k);    %Find previous actual integer sample point.
                x2 = ceil(k);   %Find next actual integer sample point.
                if x1 ~= x2     %If the ideal point is between two sample points, interpolate.
                    trace = [trace, (k - x1)*signal(x2) + (x2 - k)*signal(x1)];
                else            %If not, just grab that sample.
                    trace = [trace, signal(k)];
                end
            end
            fwrite(fid,trace,'float32');       %Writing in the LFP trace.
            if displayopt       %If the display option is turned on, we can watch the signals being filtered.
                if isempty(surfdata)    %If plot data is empty, create the first line.
                    surfdata = [1, trace];
                elseif size(surfdata,1) < i     %If this is a new stimulus, create a new line.
                    if length(trace) > size(surfdata,2)
                        trace = [1 trace];
                        surfdata = [surfdata, zeros(size(surfdata,1),length(trace)-size(surfdata,2))];
                    else
                        trace = [1 trace zeros(1,size(surfdata,2)-length(trace)-1)];
                    end
                    surfdata = [surfdata; trace];
                else                    %If this is another repetition of a previous stimulus, average the new trace with the previous.
                    surfdata(i,2:end) = surfdata(i,1)*surfdata(i,2:end)/(surfdata(i,1)+1) + trace/surfdata(i,1);
                    surfdata(i,1) = surfdata(i,1) + 1;
                end
                surf(double([surfdata(:,2:end); zeros(1,size(surfdata,2)-1)]),'edgecolor','none');  %Create a surface plot with y-values of stimulus index.
                view(0,90);
                axis tight;     %Tighten the axes.
                colormap(gray);
                drawnow;        %Refresh the plot.
            end
        end
    end
end
fclose(fid);     %Finally, we'll close the *.LFP file.
if displayopt
    pause(1);       %If we're plotting LFPs, we'll pause for one second to let the user look at the figures.
    close(1);
end