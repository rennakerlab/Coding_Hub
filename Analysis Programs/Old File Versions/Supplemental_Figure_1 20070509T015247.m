function Supplemental_Figure_1

[file path] = uigetfile('*.NEL');
cd(path);

trial = input('Which trial do you want to show?: ');

data = NELFileRead(file);

numstim = length(data.stim);
sampling_rate = 24414.0625;

noise_ceiling = 0.0005;         %Maximum allowable voltage to be considered a spike.
low_pass_cutoff = 4500;         %Low-pass cut-off of the passband filter, in Hz.
high_pass_cutoff = 825;         %High-pass cut-off of the passband filter, in Hz.
min_thresh = 4;                 %Minimum threshold for detection, in standard deviations of the noise.
pre_pts = 19;                   %The number of sample points to grab before a threshold crossing.
post_pts = 44;                  %The number of sample points to grab after a threshold crossing.
int_fact = 100;                 %Interpolation factor for fitting splines to spikeshapes.

%Setting up a passband filter for spikes;
low_pass_cutoff = 3000;         %Low-pass cut-off of the passband filter, in Hz.
high_pass_cutoff = 500;         %High-pass cut-off of the passband filter, in Hz.
[b,a] = ellip(2,0.1,40,[high_pass_cutoff low_pass_cutoff]*2/sampling_rate);       
spike_coefs = [b; a];

trial = find(data.param(1).value == trial);

a = figure(1);
set(a,'position',[26,241,1059,706]);
%LFP plot
subplot(3,2,[1 2]);
signal = data.stim(trial).signal;
plot(signal,'color',[0 0 0.5]);
axis tight;
xlim([1,(data.spont_delay/1000 + 0.1)*sampling_rate+sampling_rate*data.param(4).value(trial)+sampling_rate*data.param(5).value(trial)]);
a = get(gca,'ylim');
ylim(1.05*[-max(abs(a)), max(abs(a))]);
set(gca,'xtick',[(data.spont_delay/1000)*sampling_rate:sampling_rate/2:length(data.stim(trial).signal)],'xticklabel',[]);
set(gca,'yticklabel',1000000*get(gca,'ytick'),'fontweight','normal');
ylabel('Voltage (\muV)','fontweight','normal','fontsize',12);
line([(data.spont_delay/1000)*sampling_rate,(data.spont_delay/1000)*sampling_rate],get(gca,'ylim'),'color','b','linestyle',':');
title(['Subject RRC, Day 12, Trial #' num2str(data.param(1).value(trial)) ', \itf\rm_{reference} = ' num2str(round(data.param(2).value(trial)/100)/10)...
    ' kHz, \itf\rm_{target} = ' num2str(round(data.param(3).value(trial)/100)/10) ' kHz, \Delta\itf\rm = '...
    num2str(data.param(6).value(trial)) '%'], 'fontweight','normal','fontsize',14);

%Spikes
subplot(3,2,[3 4]);
signal = data.stim(trial).signal;
signal = [repmat(signal(1),1,500), signal, repmat(signal(length(signal)),1,500)];
signal = filtfilt(spike_coefs(1,:),spike_coefs(2,:),signal);      %Applying the passband filter.
signal = signal(501:(length(signal)-500));
plot(signal,'color',[0 0.5 0]);
axis tight;
xlim([1,(data.spont_delay/1000 + 0.1)*sampling_rate+sampling_rate*data.param(4).value(trial)+sampling_rate*data.param(5).value(trial)]);
a = get(gca,'ylim');
ylim(1.2*[-max(abs(a)), max(abs(a))]);
set(gca,'xtick',[(data.spont_delay/1000)*sampling_rate:sampling_rate/2:length(data.stim(trial).signal)],'xticklabel',[0:0.5:20]);
xlabel('Time (s)','fontweight','normal','fontsize',12);
set(gca,'yticklabel',1000000*get(gca,'ytick'),'fontweight','normal');
ylabel('Voltage (\muV)','fontweight','normal','fontsize',12);
line([(data.spont_delay/1000)*sampling_rate,(data.spont_delay/1000)*sampling_rate],get(gca,'ylim'),'color','b','linestyle',':');
rectangle('Position',[(data.spont_delay/1000)*sampling_rate, -1.15*max(abs(a)),sampling_rate*data.param(4).value(trial),0.05*max(abs(a))],'facecolor',[0.5 0 0.5]);
rectangle('Position',[(data.spont_delay/1000)*sampling_rate+sampling_rate*data.param(4).value(trial), -1.15*max(abs(a)),...
    sampling_rate*data.param(5).value(trial),0.05*max(abs(a))],'facecolor',[0 0.5 0.5]);
rectangle('Position',[0.88*sampling_rate, -1*max(abs(a)),0.03*sampling_rate,2*max(abs(a))],'linestyle','-','edgecolor','r');

%Close-up
subplot(3,2,5);
signal = signal(0.88*sampling_rate:0.91*sampling_rate+1);
plot(signal,'color',[0 0.5 0]);
axis tight;
ylim(1.1*get(gca,'ylim'));
set(gca,'yticklabel',round(1000000*get(gca,'ytick')),'fontweight','normal');
ylabel('Voltage (\muV)','fontweight','normal','fontsize',12);
set(gca,'xtick',[1:sampling_rate/100:length(data.stim(trial).signal)],'xticklabel',1000*[0:0.01:20]);
xlabel('Time (ms)','fontweight','normal','fontsize',12);
text(20,-0.0002,'Close-Up','fontsize',12,'horizontalalignment','left');

%Spikes
subplot(3,2,6);
thresh = [];
for i = 1:length(data.stim)
    for j = 1:size(data.stim(i).signal,1)
        signal = data.stim(i).signal(j,:);
        %To avoid transients on the beginning and end of the signal, we'll 
        %add 500 sample disposable "tails" that the transients will appear 
        %on, but not on the saved signal.
        signal = [repmat(signal(1),1,500), signal, repmat(signal(length(signal)),1,500)];
        signal = filtfilt(spike_coefs(1,:),spike_coefs(2,:),signal);      %Applying the passband filter.
        signal = signal(501:(length(signal)-500));                          %Removing the "tails".
        data.stim(i).signal(j,:) = signal;                                  %Overwriting the filtered signal back to the structure.
        signal = abs(data.stim(i).signal(j,:));                             %Finding the absolute value of all sample points.
        signal = signal(find(signal < noise_ceiling));                      %Excluding samples above the noise ceiling.
        thresh = [thresh; median(signal)/0.6745];                           %Finding the median and dividing by Quiroga's standard deviation approximation.
    end
end
thresh = min_thresh*median(thresh);     %The threshold is then a multiple of the median standard deviation estimate.
signal = data.stim(trial).signal;
index = intersect(find(signal <= -thresh),find(signal > -thresh)+1);
index = index(find(index > pre_pts+2 & index < length(signal)-post_pts-2));
for k = 1:length(index);
    trace = signal(index(k)-pre_pts-2:index(k)+post_pts+2);
    if max(abs(trace)) > noise_ceiling
        index(k) = nan;
    end
end
index(isnan(index)) = [];
spike_shapes = [];
peaks = [];
for k = 1:length(index)
    trace = signal(index(k)-pre_pts-2:index(k)+post_pts+2);
    curve_fit = spline(1:length(trace),trace,1/int_fact:1/int_fact:size(trace,2));
    spike_time = intersect(find(curve_fit <= -thresh),find(curve_fit > -thresh)+1)/int_fact;
    spike_time = min(spike_time(find(spike_time >= pre_pts+2 & spike_time <= pre_pts+3)));
    spike_n = spike_time*int_fact;
    trace = curve_fit(spike_n - int_fact*pre_pts:int_fact:spike_n + int_fact*post_pts);
    if ~isempty(trace)
        temp = [];
        for i = pre_pts:length(trace)-1
            if trace(i) < trace(i-1) & trace (i) < trace(i+1)
                temp = [temp; trace(i)];
            end
        end
        neg_peak = min(temp);
        temp = [];
        for i = pre_pts:length(trace)-1
            if trace(i) > trace(i-1) & trace (i) > trace(i+1)
                temp = [temp; trace(i)];
            end
        end
        pos_peak = min(temp);
        peaks = [peaks; neg_peak, pos_peak];
        spike_shapes = [spike_shapes; curve_fit];
        index(k) = index(k)-pre_pts - 3 + spike_time(find(spike_time >= pre_pts+2 & spike_time <= pre_pts+3));
    end
end    
cutoffs = [0, -0.1129, -0.1589]/1000;
spike_shapes = spike_shapes(1:100,:);
peaks = peaks(1:100,:);
hold on;
for i = 1:3
    a = find(peaks(:,1) < cutoffs(i) & peaks(:,1) > -0.0002);
    if i == 1
        plot(spike_shapes(a,:)','color',[0.8 0 0]);
    elseif i == 2
        plot(spike_shapes(a,:)','color',[0 0.8 0]);
    else
        plot(spike_shapes(a,:)','color',[0 0 0.8]);
    end
end
axis tight;
xlim([1,6500]);
ylim(1.1*get(gca,'ylim'));
set(gca,'yticklabel',1000000*get(gca,'ytick'),'fontweight','normal');
ylabel('Voltage (\muV)','fontweight','normal','fontsize',12);
set(gca,'xtick',[1:100*sampling_rate/1000:size(spike_shapes,2)],'xticklabel',[0:1:20]);
xlabel('Time (\mus)','fontweight','normal','fontsize',12);
text(6300,-0.00019,'Separated Spikes','fontsize',12,'horizontalalignment','right');

% %PSTH
% subplot(3,3,9);
% numsweeps = 0;
% times = [];
% for i = 1:length(data.stim)
%     if abs(data.param(2).value(i) - data.param(2).value(trial)) < 2000
%         signal = data.stim(i).signal;
%         index = intersect(find(signal <= -thresh),find(signal > -thresh)+1);
%         index = index(find(index > pre_pts+2 & index < length(signal)-post_pts-2));
%         for k = 1:length(index);
%             trace = signal(index(k)-pre_pts-2:index(k)+post_pts+2);
%             if max(abs(trace)) > noise_ceiling
%                 index(k) = nan;
%             end
%         end
%         index(isnan(index)) = [];
%         for k = 1:length(index)
%             trace = signal(index(k)-pre_pts-2:index(k)+post_pts+2);
%             curve_fit = spline(1:length(trace),trace,1/int_fact:1/int_fact:size(trace,2));
%             spike_time = intersect(find(curve_fit <= -thresh),find(curve_fit > -thresh)+1)/int_fact;
%             spike_time = min(spike_time(find(spike_time >= pre_pts+2 & spike_time <= pre_pts+3)));
%             spike_n = spike_time*int_fact;
%             index(k) = index(k)-pre_pts - 3 + spike_time(find(spike_time >= pre_pts+2 & spike_time <= pre_pts+3));
%             times = [times; 1000*index(k)/data.sampling_rate];
%         end    
%         numsweeps = numsweeps + 1;
%     end
% end
% figure(2);
% plot(histc(times,[1:1:400]),'linewidth',2);