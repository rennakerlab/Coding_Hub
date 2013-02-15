function Behav_STRF

cd('E:\');
file1 = 'E02_BDT_1_FRODO_163_Stage8_A.f32';
file2 = 'E02_PDT_1_FRODO_163_SP17_200ms_60dB_FreeMove_A.f32'

figure(1);
hold on;

psth = [];
data = spikedataf(file1);
for i = 1:length(data)
    for j = 1:length(data(i).sweep)
        if isempty(data(i).sweep(j).spikes);
            temp = zeros(1,2100);
        else
            temp = histc(data(i).sweep(j).spikes, 0:data(1).sweeplength);
        end
        psth = [psth; 1000*temp(1:2100)];
    end
end
plot(boxsmooth(mean(psth),10),'linewidth',2,'color','b');
psth = [];
data = spikedataf(file2);
for i = 1:length(data)
    for j = 1:length(data(i).sweep)
        if isempty(data(i).sweep(j).spikes);
            temp = zeros(1,2100);
        else
            temp = histc(data(i).sweep(j).spikes, 0:data(1).sweeplength);
        end
        psth = [psth; 1000*temp(1:2100)];
    end
end
plot(boxsmooth(mean(psth),10),'linewidth',2,'color','r');
title('Effect of Attention: Subject F, MUC02, \itf\rm_{REF} = 20.7 kHz', 'fontsize',16);
ylabel('Spikerate (spikes/s)','fontsize',14');
xlabel('Time (ms)','fontsize',14');
set(gca,'fontsize',12,'xtick',[200:300:2100],'xticklabel',[0:300:2100],'xlim',[0,1950]);
for i = 200:300:2100
    rectangle('position',[i,50,200,10],'facecolor',[0 0.5 0]);
    text(i+100,55,'Tone','verticalalignment','middle','horizontalalignment','center','color','w','fontsize',8);
end
legend('Behaving','Passive');


data = spikedataf(uigetfile('*.f32'));
targets = [];
for i = 1:length(data)
    targets = [targets; data(i).stim(3)];
end
targets = unique(targets)';
disp(['Targets: ' num2str(length(targets))]);

figure(2);
strf = [];
for i = targets
    psth = [];
    for j = 1:length(data)
        if data(j).stim(3) == i
            hold_time = 1000*data(j).stim(4);
            psth = [psth; histc(data(j).sweep.spikes, [(hold_time-400):(hold_time+400)]+200)];
        end
    end
    strf = [strf; boxsmooth(mean(psth,1),25)];
end
strf = [strf; zeros(1,size(strf,2))];
surf(strf,'edgecolor','none');
view(0,90);
axis tight;
set(gca,'xtick',[100:300:800],'xticklabel',[-300:300:300]);
set(gca,'ytick',[1.5:5:32],'yticklabel',[-15:5:15]);

strf = [];
for i = targets
    psth = [];
    for j = 1:length(data)
        if data(j).stim(3) == i
            hold_time = 1000*data(j).stim(4);
            psth = [psth; histc(data(j).sweep.spikes, [(hold_time-400):(hold_time+400)]+200)];
        end
    end
    strf = [strf; mean(psth,1)];
end
temp = 1000*[mean(strf(:,101:300),2), mean(strf(:,401:600),2)];
plot([-15:15]',temp(:,1),'b',[-15:15]',temp(:,2),'r');







line(get(gca,'xlim'),repmat(mean(mean(psth(:,1:100))),1,2),'color','r','linestyle','--');
set(gca,'xtick',[200:300:2100]);



[file path] = uigetfile('*.f32');
cd(path);

psth = [];
data = spikedataf(file);
for i = 1:length(data)
    for j = 1:length(data(i).sweep)
        if isempty(data(i).sweep(j).spikes);
            temp = zeros(1,2100);
        else
            temp = histc(data(i).sweep(j).spikes, 0:data(1).sweeplength);
        end
        psth = [psth; 1000*temp(1:2100)];
    end
end
figure(1);
plot(boxsmooth(mean(psth),10),'linewidth',2);
axis tight;
line(get(gca,'xlim'),repmat(mean(mean(psth(:,1:100))),1,2),'color','r','linestyle','--');
set(gca,'xtick',[200:300:2100]);

targets = [];
for i = 1:length(data)
    targets = [targets; data(i).stim(3)];
end
targets = unique(targets)';
disp(['Targets: ' num2str(length(targets))]);

figure;
strf = [];
for i = targets
    psth = [];
    for j = 1:length(data)
        if data(j).stim(3) == i
            hold_time = 1000*data(j).stim(4);
            psth = [psth; histc(data(j).sweep.spikes, [(hold_time-400):(hold_time+400)]+200)];
        end
    end
    strf = [strf; boxsmooth(mean(psth,1),25)];
end
strf = [strf; zeros(1,size(strf,2))];
surf(strf,'edgecolor','none');
view(0,90);
axis tight;
set(gca,'xtick',[100:300:800],'xticklabel',[-300:300:300]);
set(gca,'ytick',[1.5:5:32],'yticklabel',[-15:5:15]);

strf = [];
for i = targets
    psth = [];
    for j = 1:length(data)
        if data(j).stim(3) == i
            hold_time = 1000*data(j).stim(4);
            psth = [psth; histc(data(j).sweep.spikes, [(hold_time-400):(hold_time+400)]+200)];
        end
    end
    strf = [strf; mean(psth,1)];
end
temp = 1000*[mean(strf(:,101:300),2), mean(strf(:,401:600),2)];
plot([-15:15]',temp(:,1),'b',[-15:15]',temp(:,2),'r');





numfreq = 20;                   %The number of reference frequencies we'll use.
lower_freq_bound = 2000;        %Lower frequency bound, in Hertz.
upper_freq_bound = 32000;       %Upper frequency bound, in Hertz.
standard_frequency_set = pow2(log2(lower_freq_bound):((log2(upper_freq_bound)-log2(lower_freq_bound))/(numfreq-1)):log2(upper_freq_bound));
freqs = 100*round(standard_frequency_set/100);

strf = zeros(18,2100);
N = zeros(18,1);
data = spikedataf(uigetfile('*.f32'));
for i = 1:length(data)
    if any(data(i).stim(1:length(data(i).stim)-1) ~= 0)
        f = 100*round(data(i).stim(2)/100);
        f = find(freqs == f) - 1;
        if ~isempty(data(i).sweep.spikes)
            temp = histc(data(i).sweep.spikes,[0:2100]);
        else
            temp = zeros(1,2100);
        end
        strf(f,:) = strf(f,:) + temp(1:2100);
        N(f) = N(f) + 1;
    end
end
for i = 1:length(N)
    strf(i,:) = boxsmooth(strf(i,:)/N(i),8);
end
strf = [strf; zeros(1,size(strf,2))];
figure(2);
surf(strf,'edgecolor','none');
axis tight;
view(0,90);
set(gca,'xtick',[100:300:2100]);
set(gca,'ytick',[1.5:1:19],'yticklabel',[2:19]);
colorbar;