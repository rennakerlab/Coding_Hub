function Initial_Stim_Analysis

[file path] = uigetfile('*.f32');
cd(path);
data = spikedataf(file);
binsize = 10;

disp(file);

stimuli = [data(:).stim];
channels = unique(stimuli(1,:));
pulsewidths = unique(stimuli(2,:));
curamps = unique(stimuli(3,:));
ipps = unique(stimuli(4,:));
numpulses = unique(stimuli(5,:));
anodcaths = unique(stimuli(6,:));

for i = 1:length(data);
    for j = 1:length(data(i).sweep);
        try;
            temp(j,:) = histc(data(i).sweep(j).spikes,[1:data(i).sweeplength]);
        catch;
            temp(j,:) = zeros(1,data(i).sweeplength);
        end;
    end;
   data(i).spikerate = temp/(0.001);
end;

figure(1);
clf;
% figure(2);
% clf;
for i = unique(stimuli(1,:))
    plotdata = [];
    sigdata = [];
    for j = curamps
        disp(j);
        a = find(stimuli(3,:) == j);
        b = find(stimuli(1,:) == i);
        a = intersect(a,b);
        temp = [];
        for k = a
            temp = [temp; data(k).spikerate];
        end
%         plotdata = [plotdata; mean(mean(temp(:,110:140),2)) - mean(mean(temp(:,1:95),2))];
%         [h,p,ci] = ttest(mean(temp(:,110:140),2),mean(temp(:,1:95),2), 0.05);
%         sigdata = [sigdata; mean(mean(temp(:,110:140),2)) - mean(mean(temp(:,1:95),2)) - ci(1)];
        plotdata = [plotdata; boxsmooth(mean(temp),binsize)];
        sigdata = zeros(2,data(1).sweeplength-binsize+1);
        for k = 1:data(1).sweeplength-binsize+1
            [h,p,ci] = ttest(nanmean(temp(:,k:(k+binsize-1)),2), 0, 0.05);
            sigdata(1,k) = nanmean(nanmean(temp(:,k:(k+binsize-1)),2));
            sigdata(2,k) = nanmean(nanmean(temp(:,k:(k+binsize-1)),2)) - ci(1);
%             if nanmean(nanmean(temp(:,k:(k+binsize-1)),2)) > nanmean(nanmean(temp(:,1:95),2))
%                 temp(1,k) = h;
%             else
%                 temp(1,k) = -h;
%             end
        end
%         sigdata = plotdata - sigdata;
%         sigdata = [sigdata; temp(1,1:data(1).sweeplength-binsize+1)];
    end
    figure(1);
    subplot(3,5,17-i);
    a = errorbar(sigdata(1,:)',sigdata(2,:)','linewidth',2);
    set(gca,'xtick',[1:length(curamps)],'xticklabel',curamps);
    line(get(gca,'xlim'),[0,0],'linestyle',':','color','k');
%     set(gca,'yticklabel', mean(mean(temp(:,110:140),2)) + str2num(get(gca,'yticklabel')));
%     plotdata = [plotdata; repmat(nanmean(nanmean(plotdata)),1,length(plotdata))];
%     surf(plotdata,'edgecolor','none');
%     view(0,90);
    axis tight;
    xlim([0,data(1).sweeplength-binsize+1]);
%     title(i);
%     figure(2);
%     subplot(3,5,17-i);
%     contourf(sigdata,[-1.5,-0.5,0.5]);
%     xlim([0,data(i).sweeplength-binsize+1]);
    title(['Stim on Channel #' num2str(i)]);
end