function quick_crosscorr(varargin)

%
%QUICK_CROSSCORR.m - Rennaker Neural Engineering Lab, 2010
%
%   QUICK_CROSSCORR has the user select two *.f32 files and then creates a 
%   cross correlation graph from the spike timings of each file, by electrode for now.
%
%   QUICK_CROSSCORR(file,...) creates a cross-coincidence histogram from the files specified.  
%   The variable "file" can either be a single string or a cell array of 
%   strings containing file names.
%
%   Last updated April 26, 2010, by Mary K. Reagor.
%   NOT READY for release

% Read in two electrodes for comparison. 
% Probably need some error checking to make sure the two files selected are
% from the same rat and from the same day?

%***** Pre-defined, modifiable variables *****%
binsize = 5;                        %Set the smoothing bin size to 5 ms.
%*****

if length(varargin) > 2             %If the user entered too many arguments, show an error.
    error('Too many input arguments. You need two files to run the cross-coincidence histogram, no more.');
end
for i = 1:length(varargin)
    temp = varargin{i};                 %Pull the variable out of the input argument.
    if ischar(temp)                     %If the argument is a string...
        files(1).name = temp;           %Save the filename as a string.
    elseif iscell(temp)                	%If the argument is a cell...
        for j = 1:length(temp)          %Step through the filenames....
            files(j).name = cell2mat(temp(j));  %And save the filenames in a structure.
        end
    end
end
if ~exist('files','var')      %If the user hasn't specified an input file...
    [temp path] = uigetfile('*.f32','multiselect','on');   %Have the user pick an input file or files.
    cd(path);                         	%Change the current directory to the folder that file is in.
    if iscell(temp)                     %If the user's picked multiple files...
        for i = 1:length(temp)          %Step through each selected file.
            files(i).name = [path temp{i}];     %Save the file names in a structure.
        end
    elseif ischar(temp)                	%If only one file is selected...
        files(1).name = [path temp];    %Add the path to the filename and get another
        disp('Please select another electrode file')
        [temp path] = uigetfile('*.f32','multiselect','on');   
        files(2).name = [path temp];    %Add the path to the filename 
    elseif isempty(temp)                %If no file is selected...
        error('No file selected!');     %Show an error message.
    end
end
for i = 1:length(files)
    if ~exist(files(i).name,'file')
        error([files(i).name ' doesn''t exist!']);
    end
    if ~any(strfind(files(i).name,'.f32'));
        error([files(i).name ' is not an *.f32 file!']);
    end
end  
if (files(1).name == files(2).name)
    error('It is suggested that you choose different files to compare')
end

data1 = f32FileRead(files(1).name);

data2 = f32FileRead(files(2).name);
data = [data1; data2];   %Now we want to look at pairs of electrodes


% %** See what the original data looks like
% sweeplength = data1(10).sweeplength; % this should be 1000. Change 10 to i
% figure()
% hist(data3(10).sweep(10).spikes,1:sweeplength)
% 
% %** Need to transform the discreted spike data into continuous, so try moving
% %** average
% span = 5; % Size of the averaging window, could try 10 or 25
% window = ones(span,1)/span; 
% smoothed_data3 = convn(data3(10).sweep(10).spikes,window,'same');
% 
% figure()
% h = plot(smoothed_data3,'ro-');
% legend('Data','Smoothed Data')
% 
% %** Or bin the data
% bin = 25; % bins of 5, 10 or 25 ms - to get a bin of 1, just use histc
% count = 0;
% lessthan=[];
% for i=1:1000/bin
%     lessthan(i)=count+bin;
%     count=count+bin;
% end
% 
% % Get a count for how many spikes there were in each bin
% countspike1=[];
% countspike1=histc(data3(10).sweep(10).spikes,lessthan,2);
% 
% countspike2=[];
% countspike2=histc(data4(10).sweep(10).spikes,lessthan,2);
% 
% %** Get the cross correlation
% C=xcorr(countspike1,countspike2);
% 
% figure()
% plot(1:size(countspike,2),C(:,size(countspike,2)))

% %** Show the cross-coincidence histogram 
% %** No statisical test here yet.
% %** What to do about data across days?
% %** Need to add rat name and electrodes compared
% winsize=401; %go from -200 ms, thru 0 to +200 ms
% stim=size(data1,2);
% corgram=zeros(stim,winsize);
% 
% for t=1:stim  % step across each stimulus condition
%     numsweeps = size(data1(t).sweep,2); % get the number of sweeps
%     for s=1:numsweeps
%         for i=1:length(data1(t).sweep(s).spikes)
%             spike = data1(t).sweep(s).spikes(i); % get the first spike from the first electrode
%             latencies = data2(t).sweep(s).spikes - spike; % find the lantency from that spike to all the other spikes in the second electrode 
%             temp=histc(latencies,-200:200); % get a count of the spike latencies
%             corgram(t,:)=corgram(t,:)+temp; % put each count for each stim on a different row
%         %     plot(-200:200,corgram)
%         %     title('Plot for individual sweep')
%         end
%     end
%  %    corgram(t,:)=corgram(t,:)+temp; % put each count for each stim on a different row
% % figure()
% % plot(-200:200,corgram)
% % title('Plot for average across sweeps')
% freq=num2str(round(data1(t).params(1)));
% % figure()
% % plot(-200:200,corgram(t,:))
% % title(['Cross Coincidence histogram, average across sweeps at ' freq ' Hz frequency'])
% [Y,I]=max(corgram,[],1);
% 
% end

% Need to make a moving window with variable parameters, default = 100ms
% also try 50 or 200
%Now step through each filename and create a STSAD for each.
for i = 1:length(files)-1
%     spont_delay = data(1).stim(length(data(1).stim));   %The spontaneous
%     delay is always the last parameter.
    sweeplength = data(1).sweeplength;                  %All sweeps will have the same sweeplength.
    stsad = zeros(length(files),length(data),sweeplength);            %Pre-allocate a matrix to hold an STSAD. For electrode pairs, there will always be 2 entries
%     psth = zeros(1,sweeplength);                        %Pre-allocate a matrix to hold the PSTH as a sum of spikecounts.
%     psth_n = 0;                                     	%To find average spikerates, we'll have to keep track of the total number of sweeps.
    
   for e = 1:2 % have to rethink for multiple files -- length(files) % for each electrode pair...
    for j = 1:length(data)      %Step through each stimulus...20
        numsweeps = length(data(e,j).sweep);      %We'll need to know the number of sweeps for plotting.50
        for k = 1:numsweeps                     %Step through each sweep...
            if ~isempty(data(e,j).sweep(k).spikes);                       %If there are any spikes in this sweep...
                temp = histc(data(e,j).sweep(k).spikes,0:sweeplength-1);    %Calculate a millisecond-scale histogram for this sweep.
              %  data(e,j).sweep(k).spikes = [];               %Pare down the data structure as we work through it to save memory.
              %  psth = psth + temp(1:sweeplength);                      %Add the histogram to the pooled PSTH.
                stsad(e,j,:) = stsad(e,j,:) + reshape(temp,[1,1,sweeplength]);	%Add the histogram to the STSAD.
            end
        end
       %  psth_n = psth_n + numsweeps;                    %Add a count to the total number of sweeps regardless of if there spikes.
        stsad(e,j,1:sweeplength) = stsad(e,j,1:sweeplength)/numsweeps;  %Divide spike count by the number of sweeps to find spikerate.
    end
    end
    fig = figure;               %Create a new figure for each pair of electrodes. **
    temp = get(fig,'position'); %Find the current position of the figure.
    set(fig,'position',[temp(1),temp(2)-0.5*temp(4),temp(3),1.5*temp(4)]);	%Make the figure 50% taller than the default.
    set(fig,'color','w');       %Set the background color on the figure to white.
    subplot(3,1,1);           %Plot the STSAD as the top 1/3rd of the figure.
    a = find(files(i).name == '\',1,'last');        %Find the last forward slash in the filename.
    b = find(files(i).name == '.',1,'last');        %Find the last period in the filename.
    if isempty(a)                                   %If there's no directory name in this filename...
        set(fig,'name',files(i).name(1:b-1));       %Set the filename as the figure title.
        disp(['Calculating STSAD for and cross-coinsidence for ' files(i).name(1:b-1) '.']);
    else                                            %Otherwise...
        set(fig,'name',files(i).name(a+1:b-1));    	%Set the filename minus the directory as the figure title.
        disp(['Calculating STSAD for and cross-coinsidence for ' files(i).name(a+1:b-1) '.']);
    end
    temp = boxsmooth(squeeze(stsad(1,:,:)),[1 binsize]);   	%Boxsmooth the spikerates in the STSAD by row.
    temp = [[temp, zeros(size(temp,1),1)]; zeros(1,size(temp,2)+1)];    %Pad the edges with zeros so it shows the whole STSAD.
    surf(temp,'edgecolor','none');          %Plot the STSAD as a surface plot.
%     colormap(flipud(gray(500)));            %Color the surface with a flipped grayscale.
    colormap(jet);                          %Color the surface with a jet colorscale.
    view(0,90);                             %Rotate the plot to look straight down at it.
    axis tight;                             %Tighten up the axes.
    xlim([1,sweeplength+1]);                %Set the limits of the x-axis to the sweeplength.
    ylim([1,length(data)+1]);               %Set the limits of the y-axis to the number of stimuli.
    temp = unique(floor(get(gca,'xtick')));         %Grab the auto-set x-ticks.
    set(gca,'xtick',temp+0.5,'xticklabel',temp);    %Shift the x-ticks 0.5 and label with time minus the spontaneous delay.
    temp = unique(floor(get(gca,'ytick')));         %Grab the auto-set y-ticks.
    set(gca,'ytick',temp+0.5,'yticklabel',temp);  	%Shift the y-ticks 0.5 and label with stimulus indices.
    box on;                                 %Put a box around the plot.
    ylabel('stimulus index');               %Label the y-axis.
    a = find(files(i).name == '\',1,'last');        %Find the last forward slash in the filename.
    b = find(files(i).name == '.',1,'last');        %Find the last period in the filename.
    if isempty(a)                                   %If there's no directory name in this filename...
        title(files(i).name(1:b-1),'fontweight','bold','interpreter','none');   %Set the filename as this subplot's title.
    else                                            %Otherwise...
        title(files(i).name(a+1:b-1),'fontweight','bold','interpreter','none'); %Set the filename as this subplot's title.
    end
    %** plot the second electrode below the first
    subplot(3,1,2);           %Plot the 2nd STSAD as the top 2/3rds of the figure.
    a = find(files(i+1).name == '\',1,'last');        %Find the last forward slash in the filename.
    b = find(files(i+1).name == '.',1,'last');        %Find the last period in the filename.
    if isempty(a)                                   %If there's no directory name in this filename...
        set(fig,'name',files(i+1).name(1:b-1));       %Set the filename as the figure title.
        disp(['Calculating STSAD and cross-coinsidence for ' files(i+1).name(1:b-1) '.']);
    else                                            %Otherwise...
        set(fig,'name',files(i+1).name(a+1:b-1));    	%Set the filename minus the directory as the figure title.
        disp(['Calculating STSAD and cross-coinsidence for ' files(i+1).name(a+1:b-1) '.']);
    end
    temp = boxsmooth(squeeze(stsad(2,:,:)),[1 binsize]);   	%Boxsmooth the spikerates in the STSAD by row.
    temp = [[temp, zeros(size(temp,1),1)]; zeros(1,size(temp,2)+1)];    %Pad the edges with zeros so it shows the whole STSAD.
    surf(temp,'edgecolor','none');          %Plot the STSAD as a surface plot.
%     colormap(flipud(gray(500)));            %Color the surface with a flipped grayscale.
    colormap(jet);                          %Color the surface with a jet colorscale.
    view(0,90);                             %Rotate the plot to look straight down at it.
    axis tight;                             %Tighten up the axes.
    xlim([1,sweeplength+1]);                %Set the limits of the x-axis to the sweeplength.
    ylim([1,length(data)+1]);               %Set the limits of the y-axis to the number of stimuli.
    temp = unique(floor(get(gca,'xtick')));         %Grab the auto-set x-ticks.
    set(gca,'xtick',temp+0.5,'xticklabel',temp);    %Shift the x-ticks 0.5 and label with time minus the spontaneous delay.
    temp = unique(floor(get(gca,'ytick')));         %Grab the auto-set y-ticks.
    set(gca,'ytick',temp+0.5,'yticklabel',temp);  	%Shift the y-ticks 0.5 and label with stimulus indices.
    box on;                                 %Put a box around the plot.
    ylabel('stimulus index');               %Label the y-axis.
    a = find(files(i+1).name == '\',1,'last');        %Find the last forward slash in the filename.
    b = find(files(i+1).name == '.',1,'last');        %Find the last period in the filename.
    if isempty(a)                                   %If there's no directory name in this filename...
        title(files(i+1).name(1:b-1),'fontweight','bold','interpreter','none');   %Set the filename as this subplot's title.
    else                                            %Otherwise...
        title(files(i+1).name(a+1:b-1),'fontweight','bold','interpreter','none'); %Set the filename as this subplot's title.
    end
    
    subplot(3,1,3);                     %Plot the cross-coinsidence in the bottom 1/3rd of the figure.
 %% Create the cross-coincidence histogram multiple windows (sliding)
    %** Not quite working yet
    %** No statisical test here yet.
    %** What to do about data across days?
    window = 100; % change this on the fly
    winsize = 2*window+1; %go from -200 ms, thru 0 to +200 ms
    stim=size(data(1,:),2);
    corgram=zeros(stim,winsize);
    delay = data(1,1).params(4); % assume that all runs have the same delay?
    duration = data(1,1).params(3); % get the duration of the tone
    % Generalize into a function
   % for e=1:length(files)
   for e=1 % need to rethink this index for multiple files
    for t=1:stim  % step across each stimulus condition
        numsweeps = size(data(e,t).sweep,2); % get the number of sweeps
        for s=1:numsweeps
            %if ~isempty(data(e,t).sweep(1,s).spikes); 
            for r=1:length(data(e,t).sweep(s).spikes)
                spike = data(e,t).sweep(s).spikes(r); % get the first spike from the first electrode
                latencies = data(e+1,t).sweep(s).spikes - spike; % find the lantency from that spike to all the other spikes in the second electrode 
                temp=histc(latencies,-window:window); % get a count of the spike latencies
                corgram(t,:)=corgram(t,:)+temp; % put each count for each stim on a different row
            end
%              height = max(corgram(t,:)); % calculate how high the peak is
%              start_index=find(corgram(t,:)==height); % find the index where the hight is - usually 0
%              % find the baseline
%              baseline_left = mean(corgram(t,1:10)); % baseline of the left side
%              baseline_right= mean(corgram(t,winsize-10:winsize)); % baseline of the right side
%              baseline=(baseline_left+baseline_right)/2; % average baseline
%              width=[];
%              value=round(baseline+((height-baseline)/2)); % figure out where the halfway point is in order to calculate the width
%             % while(isempty(width))
%                  for wi=start_index:winsize-start_index % start from the center and move out to the edge
%                      for ii=1:winsize
%                         width = find(corgram(t,wi)==(value+ii-1),1,'first'); % find the width at half the height, starting at the point where the height was max and working out.
%                      end
%                  end
%              %end
        end
    end
   end
 plot(-window:window,corgram); % this plots the cross correlation histogram for all stimuli
                               % need to rethink how to display the plots
                               % for each stimulus, for each pair of
                               % electrodes.

 %%   %** Show the cross-coincidence histogram for each segment of interest
    %** If you don't have the sliding window and just want to look a a
    %**    segment of interest.
    %** No statisical test here yet.
    window = 100; % change this on the fly
    winsize = 2*window+1; %go from -200 ms, thru 0 to +200 ms
    stim=size(data(1,:),2);
    corgram=zeros(stim,winsize);
    delay = data(1,1).params(4); % assume that all runs have the same delay?
    duration = data(1,1).params(3); % get the duration of the tone
    % Generalize into a function
   % for e=1:length(files)
   for e=1 % need to rethink this index for multiple files
    for t=1:stim  % step across each stimulus condition
        numsweeps = size(data(e,t).sweep,2); % get the number of sweeps
        for s=1:numsweeps
            %prestim=find((data(e,t).sweep(1,s).spikes>0) & (data(e,t).sweep(1,s).spikes<delay)); % this gives the spikes in the pre-stim intereval
            %maxspike=find((data(e,t).sweep(1,s).spikes>=delay-20) & (data(e,t).sweep(1,s).spikes<delay+20-1)); 
            inhibition=find((data(e,t).sweep(1,s).spikes>=delay+20) & (data(e,t).sweep(1,s).spikes<delay-20+duration-1)); % inhibition during the tone 220 to
            %offsetact=find((data(e,t).sweep(1,s).spikes>delay-20+duration) & (data(e,t).sweep(1,s).spikes<delay+20+duration+200)); % try a 200 ms window after offset
            for r=inhibition
                spike = data(e,t).sweep(1,s).spikes(r); % get the first spike from the first electrode
                latencies = data(e+1,t).sweep(1,s).spikes - spike; % find the lantency from that spike to all the other spikes in the second electrode 
                temp=histc(latencies,-window:window); % get a count of the spike latencies
                corgram(t,:)=corgram(t,:)+temp; % put each count for each stim on a different row
            end
        end
    end
   end
%   % plot(-window:window,corgram);

% This eats up memory
% Thinking of using this with one of the spike train analysis programs I
% found
% %% Create a long vector of all the possible spike occurances across the
% % sweeps, perhaps to use with the Event_Sync function
% 
%    sweeps_concat=[]; %zeros(length(files),stim,20000);
%    
%     for ee=1:2%length(files)
%         for tt=1%:stim  % step across each stimulus condition
%             numsweeps = size(data(ee,tt).sweep,2); % get the number of sweeps
%             sweepstart=1; %start at 1 every new stim type
%             for ss=1:numsweeps
%                 sweepcount=max(size(data(ee,tt).sweep(ee,ss).spikes,2))+sweepstart-1; % find how many spikes there are in each sweep
%                 sweeps_concat(ee,tt,sweepstart:sweepcount)=data(ee,tt).sweep(ee,ss).spikes; % concatenate the sweeps
%                 sweepstart=sweepstart+sweepcount; % create the next start index
%                % data(ee,tt).sweep(ss).spikes = [];  % pare down the matrix to save memory
%             end
%          end
%     end
% sweeps_concat=sort(sweeps_concat,2); % order the concatenated monster
% 
% %    [es,ed]=Event_Sync(data(1,1).sweep(1,1).spikes,data(2,1).sweep(1,1).spikes)


%      %** Get the cross correlation
%      %** Found this code, works with just one sweep of data, might try
%      %** to get average of sweeps or spike train above.
%       C=xcorr(countspike1,countspike2);
%       figure()
%       plot(1:size(countspike1,2),C(:,size(countspike2,2)))

%% Create a histogram of the sweeps across stim types and files
% This might be useful later...
sweep_hist=[];

    for ee=1:2%length(files)
        for tt=1:stim  % step across each stimulus condition
            numsweeps = size(data(ee,tt).sweep,2); % get the number of sweeps
            for ss=1:numsweeps
                sweep_hist(ee,tt,:)=histc(data(ee,tt).sweep(1,ss).spikes(),1:1000);
                sweep_hist=sweep_hist+sweep_hist;   
            end
        end
        sweep_hist(ee,tt,:) = sweep_hist(ee,tt,:)/numsweeps;
    end
    
% %% This code should work with multiple comparisons if I create a matrix of
% % the spikes that has each sweep on a new row.
%     MVRDmat = vanRossumMNPW(spikes,rsd_tc,cosalpha)
%  
 
% Matlab code for Spike Time Metric
%
% function d=spkd(tli,tlj,cost)
% %
% % d=spkd(tli,tlj,cost) calculates the "spike time" distance
% % (Victor & Purpura 1996) for a single cost
% %
% % tli: vector of spike times for first spike train
% % tlj: vector of spike times for second spike train
% % cost: cost per unit time to move a spike
% %
% %  Copyright (c) 1999 by Daniel Reich and Jonathan Victor.
% %  Translated to Matlab by Daniel Reich from FORTRAN code by Jonathan Victor.
% %
% nspi=length(tli);
% nspj=length(tlj);
% 
% if cost==0
%    d=abs(nspi-nspj);
%    return
% elseif cost==Inf
%    d=nspi+nspj;
%    return
% end
% 
% scr=zeros(nspi+1,nspj+1);
% %
% %     INITIALIZE MARGINS WITH COST OF ADDING A SPIKE
% %
% scr(:,1)=(0:nspi)';
% scr(1,:)=(0:nspj);
% if nspi & nspj
%    for i=2:nspi+1
%       for j=2:nspj+1
%          scr(i,j)=min([scr(i-1,j)+1 scr(i,j-1)+1 scr(i-1,j-1)+cost*abs(tli(i-1)-tlj(j-1))]);
%       end
%    end
% end
% d=scr(nspi+1,nspj+1);


%     sweeps_avg=zeros(2,20,50);
%     for e=1:1:length(files)
%     for t=1:stim  % step across each stimulus condition
%         numsweeps = size(data(e,t).sweep,2); % get the number of sweeps
%         for s=1:numsweeps-1
%            % for r=1:length(data(e,t).sweep(s).spikes)
%                 %spikes = histc(data(e,t).sweep(s).spikes,list);
%                 sweeps_avg(e,t,:)=data(e,t).sweep(s)+data(e,t).sweep(s+1);
%                 %sweeps_avg(e,t,:)=sweeps_avg+spikes;
%             end
%         end
%     end
%     plot(corgram(t,:),prestim)
%     % sliding window
%    % Data, f(x) = yi for x(i) <= x < x(i+1)
% x = cumsum(rand(1,100)); % NOT equidistance
% y = sin(x/5) + 0.1*randn(1,100);
% 
% % g(x) := Integral of f, is linear piecewise
% breaks = [-inf x inf];
% coefs = zeros(length(x)+1,2);
% dx = diff(x);
% coefs(2:end,1) = y;
% coefs(3:end,2) = cumsum(y(1:end-1).*dx);
% pp = mkpp(breaks,coefs);
% g = @(x) ppval(pp,x);
% 
% % Compute the sliding average using g
% xi = linspace(x(1),x(end));
% win = 5; % window size
% left = linspace(x(1),x(end)-win);
% right = left + win;
% ximid = 0.5*(left+right);
% smooth = (g(right)-g(left))/win;
% 
% % Check
% xmid = 0.5*(x(1:end-1)+x(2:end));
% plot(xmid,y(1:end-1),'.r', ...
%      ximid, smooth,'b');
% 
% % Bruno

%     windowWidth = 100; %this could change
%     windowHeight = length(data); % across all the stim (frequency)
% 
% for j = 1:windowHeight
%     for i = 1:sweeplength - windowWidth + 1
%         window = corgram(j:j + windowHeight - 1, i:i + windowWidth - 1, :);
%         % do stuff with subimage
%     end
% end
%     conv_data = conv(data1,data2,'same');
%     plot(conv_data)
% %     %** create bins the data
% %     bin = 100; % bins of 5, 10 or 25 ms - to get a bin of 1, just use histc
% %     count = 0;
% %     lessthan=[];
% %     for i=1:1000/bin
% %         lessthan(i)=count+bin;
% %         count=count+bin;
% %     end
% %     % Get a count for how many spikes there were in each bin
% %       countspike1=[];
% %       countspike2=[];
% %     for t=1:stim
% %         numsweeps = size(data1(t).sweep,2);
% %         for s=1:numsweeps
% %             countspike1=histc(data1(t).sweep(s).spikes,lessthan,2);
% %             countspike2=histc(data2(t).sweep(s).spikes,lessthan,2);
% %         end
% %     end
% %     

    axis tight;                         %Tighten the plot around the PSTH.
    xlim([0,sweeplength]);              %Set the x-axis limits to the sweeplength.
    box off;                            %Turn off the plot box.
    ylabel('spikerate (spks/s)');       %Label the y-axis.
    xlabel('sweep time (ms)');          %Label the x-axis.
    drawnow;                            %Finish drawing the current plot before starting another.
    
% %     % Author: Michael J. Bommarito II
% % % Contact: michael.bommarito@gmail.com
% % % Date: Oct 3, 2010
% % % Provided as-is, informational purposes only, public domain.
% % %
% % % Inputs:
% % %   1. dataMatrix: variables (X1,X2,...,X_M) in the columns
% % %   2. windowSize: number of samples to include in the moving window
% % %   3. indexColumn: the variable X_i against which correlations should be 
% % % returned
% % %
% % % Output:
% % %   1. correlationTS: correlation between X_{indexColumn} and X_j for j !=
% % % indexColumn from windowSize+1 to the number of observations.  The first
% % % windowSize rows are NaN.
% % 
% % function correlationTS = movingCorrelation(dataMatrix, windowSize, indexColumn)
% % 
% % [N,M] = size(dataMatrix);
% % correlationTS = nan(N, M-1);
% % 
% % for t = windowSize+1:N
% %     C = corrcoef(dataMatrix(t-windowSize:t, :));
% %     idx = setdiff(1:M, [indexColumn]);
% %     correlationTS(t, :) = C(indexColumn, idx);
% % end

end