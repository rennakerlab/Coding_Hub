function Behav_Record_Viewer

[file path] = uigetfile('*.NEL');
cd(path);
disp(file);

data = NELFileRead(file);

numstim = length(data.stim);
sampling_rate = 24414.0625;

%Setting up a passband filter for spikes;
low_pass_cutoff = 4500;         %Low-pass cut-off of the passband filter, in Hz.
high_pass_cutoff = 500;         %High-pass cut-off of the passband filter, in Hz.
[b,a] = ellip(2,0.1,40,[high_pass_cutoff low_pass_cutoff]*2/sampling_rate);       
spike_coefs = [b; a];

%Setting up a passband filter for LFPs;
low_pass_cutoff = 500;         %Low-pass cut-off of the passband filter, in Hz.
high_pass_cutoff = 5;         %High-pass cut-off of the passband filter, in Hz.
[b,a] = ellip(2,0.1,40,[high_pass_cutoff low_pass_cutoff]*2/sampling_rate);       
LFP_coefs = [b; a];


figure('Position', [6,44,2535,906]);
for i = 1:numstim

    %Raw Signal
    subplot(3,1,1);
    plot(data.stim(i).signal,'color',[0 0 0]);
    axis tight;
    a = get(gca,'ylim');
    ylim(1.2*[-max(abs(a)), max(abs(a))]);
    set(gca,'xtick',[(data.spont_delay/1000)*sampling_rate:sampling_rate/10:length(data.stim(i).signal)],'xticklabel',[0:0.1:20]);
    xlabel('Time (s)','fontweight','bold','fontsize',12);
    set(gca,'yticklabel',1000*get(gca,'ytick'),'fontweight','bold');
    ylabel('milliVolts','fontweight','bold','fontsize',12);
    line([(data.spont_delay/1000)*sampling_rate,(data.spont_delay/1000)*sampling_rate],get(gca,'ylim'),'color','b','linestyle',':');
    title(['Trial #' num2str(data.param(1).value(i)) ': Raw Signal'], 'fontweight','bold','fontsize',14);
%     title(['Trial #' num2str(data.param(1).value(i)) ', \itf\rm\bf_{ref} = ' num2str(round(data.param(2).value(i)/100)/10)...
%         ' kHz, \itf\rm\bf_{tar} = ' num2str(round(data.param(3).value(i)/100)/10) ' kHz, \Delta\itf\rm\bf = '...
%         num2str(data.param(6).value(i)) '%'], 'fontweight','bold','fontsize',14);
%     rectangle('Position',[0.1*sampling_rate, -1.15*max(abs(a)),sampling_rate*data.param(4).value(i),0.05*max(abs(a))],'facecolor',[0.5 0 0.5]);
%     rectangle('Position',[0.1*sampling_rate+sampling_rate*data.param(4).value(i), -1.15*max(abs(a)),...
%         sampling_rate*data.param(5).value(i),0.05*max(abs(a))],'facecolor',[0 0.5 0.5]);

    %LFPs
    subplot(3,1,2);
    signal = double(data.stim(i).signal);
    signal = [repmat(signal(1),1,500), signal, repmat(signal(length(signal)),1,500)];
    signal = filtfilt(LFP_coefs(1,:),LFP_coefs(2,:),signal);      %Applying the passband filter.
    signal = signal(501:(length(signal)-500));
    plot(signal,'color',[0 0 0.5]);
    axis tight;
    a = get(gca,'ylim');
    ylim(1.2*[-max(abs(a)), max(abs(a))]);
    set(gca,'xtick',[(data.spont_delay/1000)*sampling_rate:sampling_rate/10:length(data.stim(i).signal)],'xticklabel',[0:0.1:20]);
    xlabel('Time (s)','fontweight','bold','fontsize',12);
    set(gca,'yticklabel',1000*get(gca,'ytick'),'fontweight','bold');
    ylabel('milliVolts','fontweight','bold','fontsize',12);
    line([(data.spont_delay/1000)*sampling_rate,(data.spont_delay/1000)*sampling_rate],get(gca,'ylim'),'color','b','linestyle',':');
    title(['Trial #' num2str(data.param(1).value(i)) ': LFP'], 'fontweight','bold','fontsize',14);
%     title(['Trial #' num2str(data.param(1).value(i)) ', \itf\rm\bf_{ref} = ' num2str(round(data.param(2).value(i)/100)/10)...
%         ' kHz, \itf\rm\bf_{tar} = ' num2str(round(data.param(3).value(i)/100)/10) ' kHz, \Delta\itf\rm\bf = '...
%         num2str(data.param(6).value(i)) '%'], 'fontweight','bold','fontsize',14);
%     rectangle('Position',[(data.spont_delay/1000)*sampling_rate, -1.15*max(abs(a)),sampling_rate*data.param(4).value(i),0.05*max(abs(a))],'facecolor',[0.5 0 0.5]);
%     rectangle('Position',[(data.spont_delay/1000)*sampling_rate+sampling_rate*data.param(4).value(i), -1.15*max(abs(a)),...
%         sampling_rate*data.param(5).value(i),0.05*max(abs(a))],'facecolor',[0 0.5 0.5]);
    
    %Spikes
    subplot(3,1,3);
    signal = double(data.stim(i).signal);
    signal = [repmat(signal(1),1,500), signal, repmat(signal(length(signal)),1,500)];
    signal = filtfilt(spike_coefs(1,:),spike_coefs(2,:),signal);      %Applying the passband filter.
    signal = signal(501:(length(signal)-500));
    plot(signal,'color',[0 0.5 0]);
    axis tight;
    ylim([-0.00015,0.00015]);
    a = get(gca,'ylim');
    ylim(1.2*[-max(abs(a)), max(abs(a))]);
    set(gca,'xtick',[(data.spont_delay/1000)*sampling_rate:sampling_rate/10:length(data.stim(i).signal)],'xticklabel',[0:0.1:20]);
    xlabel('Time (s)','fontweight','bold','fontsize',12);
    set(gca,'yticklabel',1000*get(gca,'ytick'),'fontweight','bold');
    ylabel('milliVolts','fontweight','bold','fontsize',12);
    line([(data.spont_delay/1000)*sampling_rate,(data.spont_delay/1000)*sampling_rate],get(gca,'ylim'),'color','b','linestyle',':');
    title(['Trial #' num2str(data.param(1).value(i)) ': spikes'], 'fontweight','bold','fontsize',14);
%     title(['Trial #' num2str(data.param(1).value(i)) ', \itf\rm\bf_{ref} = ' num2str(round(data.param(2).value(i)/100)/10)...
%         ' kHz, \itf\rm\bf_{tar} = ' num2str(round(data.param(3).value(i)/100)/10) ' kHz, \Delta\itf\rm\bf = '...
%         num2str(data.param(6).value(i)) '%'], 'fontweight','bold','fontsize',14);
%     rectangle('Position',[(data.spont_delay/1000)*sampling_rate, -1.15*max(abs(a)),sampling_rate*data.param(4).value(i),0.05*max(abs(a))],'facecolor',[0.5 0 0.5]);
%     rectangle('Position',[(data.spont_delay/1000)*sampling_rate+sampling_rate*data.param(4).value(i), -1.15*max(abs(a)),...
%         sampling_rate*data.param(5).value(i),0.05*max(abs(a))],'facecolor',[0 0.5 0.5]);
    waitforbuttonpress;
end