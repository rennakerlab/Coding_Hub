function NEL_TC_Viewer

a = figure(1);
set(a,'position',[-3,33,1280,929]);
a = figure(2);
set(a,'position',[1277,5,1280,957]);

[file path] = uigetfile('.NEL');
cd(path);
files = dir(['*' file(4:length(file))]);

for f = 1:length(files);
    chan = str2num(files(f).name(2:3));
    if chan ~= 1
        
        disp(['Analyzing Channel ' num2str(chan) '...']);
        data = nelfileread(files(f).name);
        
        %Setting up a passband filter for spikes;
        low_pass_cutoff = 4500;         %Low-pass cut-off of the passband filter, in Hz.
        high_pass_cutoff = 825;         %High-pass cut-off of the passband filter, in Hz.
        [b,a] = ellip(2,0.1,40,[high_pass_cutoff low_pass_cutoff]*2/data.sampling_rate);       
        spike_coefs = [b; a];

        %Setting up a passband filter for LFPs;
        low_pass_cutoff = 1000;         %Low-pass cut-off of the passband filter, in Hz.
        high_pass_cutoff = 5;         %High-pass cut-off of the passband filter, in Hz.
        [b,a] = ellip(2,0.1,40,[high_pass_cutoff low_pass_cutoff]*2/data.sampling_rate);       
        LFP_coefs = [b; a];

        strf = [];
        rfe = [];
        rfs = [];
        for i = 1:length(data.stim)
            temp = data.stim(i).signal;
            for j = 1:size(data.stim(i).signal);
                signal = temp(j,:);
                signal = [repmat(signal(1),1,500), signal, repmat(signal(length(signal)),1,500)];
                signal = filtfilt(LFP_coefs(1,:),LFP_coefs(2,:),signal);      %Applying the passband filter.
                signal = signal(501:(length(signal)-500));
                temp(j,:) = signal;
            end
            strf = [strf; trimmean(temp, 20)];
            window = data.sampling_rate*([data.spont_delay, data.spont_delay + 30]/1000);
            rfe = [rfe, mean(temp(:,window(1):window(2)),2)];
            window = data.sampling_rate*([data.spont_delay + 30, data.spont_delay + 90]/1000);
            rfs = [rfs, mean(temp(:,window(1):window(2)),2)];
        end
        figure(1);
        subplot(3,5,17 - chan);
        surf(boxsmooth(double(strf),3),'edgecolor','none');
        view(0,90);
        axis tight;
        set(gca,'xticklabel',[],'yticklabel',[]);
        
        figure(2);
        subplot(3,5,17 - chan);
        temp = [mean(rfe); mean(rfs)];
        temp_ci = zeros(2,size(rfe,2));
        for i = 1:size(rfe,2)
            [h,p,ci] = ttest(rfe(:,i));
            temp_ci(1,i) = mean(rfe(:,i)) - ci(1);
            [h,p,ci] = ttest(rfs(:,i));
            temp_ci(2,i) = mean(rfs(:,i)) - ci(1);
        end
        errorbar(temp',temp_ci');
        axis tight;
        set(gca,'xticklabel',[],'yticklabel',[]);
    end
end