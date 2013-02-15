function Behav_LFP_STRF

[file path] = uigetfile('*.LFP');
channel = file(1:3);
cd(path);
data = LFPFileRead(file);

figure(1);
temp = [];
for i = 1:length(data.stim)
    temp = [temp; data.stim(i).lfp(1:2200)];
end
plot(mean(temp));

numfreq = 20;                   %The number of reference frequencies we'll use.
lower_freq_bound = 2000;        %Lower frequency bound, in Hertz.
upper_freq_bound = 32000;       %Upper frequency bound, in Hertz.
standard_frequency_set = pow2(log2(lower_freq_bound):((log2(upper_freq_bound)-log2(lower_freq_bound))/(numfreq-1)):log2(upper_freq_bound));
freqs = 100*round(standard_frequency_set/100);

strf1 = zeros(18,400);
strf2 = zeros(18,400);
N = zeros(18,1);
for i = 1:length(data.stim)
    f = 100*round(data.param(2).value(i)/100);
    f = find(freqs == f) - 1;
    strf1(f,:) = strf1(f,:) + data.stim(i).lfp(101:500);
    strf2(f,:) = strf2(f,:) + data.stim(i).lfp(1001:1400);
    N(f) = N(f) + 1;
end
for i = 1:length(N)
    strf1(i,:) = boxsmooth(strf1(i,:)/N(i),10);
    strf2(i,:) = boxsmooth(strf2(i,:)/N(i),10);
end
strf1 = [strf1; zeros(1,size(strf1,2))];
strf2 = [strf2; zeros(1,size(strf2,2))];
figure(2);
surf(-boxsmooth(strf1,3),'edgecolor','none');
axis tight;
view(0,90);
set(gca,'xtick',[100:300:2100]);
set(gca,'ytick',[1.5:1:19],'yticklabel',[2:19]);
colorbar;
figure(3);
surf(-boxsmooth(strf2,3),'edgecolor','none');
axis tight;
view(0,90);
set(gca,'xtick',[100:300:2100]);
set(gca,'ytick',[1.5:1:19],'yticklabel',[2:19]);
colorbar;