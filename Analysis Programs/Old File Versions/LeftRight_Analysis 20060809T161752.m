function LeftRight_Analysis

%When we get around to doing significance tests, it helps to define alpha
%at the beginning as a variable, so that if we ever want to change the
%significance level of our tests, we only have to change one line of code.
alpha = 0.05;
disp(['alpha = ' num2str(alpha)]);

mwsize = 20;

%This line keeps the t-test from freaking out when you hand it a column of
%zeros.
warning off MATLAB:divideByZero;

%I like my figures nice and big, so here's a trick that will let us set the
%figure size to about 80% of the screensize.
scrnsize = get(0,'ScreenSize');
pos = [scrnsize(3)/20 scrnsize(4)/16 (scrnsize(3)-2*(scrnsize(3)/20)) (scrnsize(4)-3*(scrnsize(4)/16))];

%We'll use a common dialog box to select which file we'd like to take a
%look at.  We'll also change the current directory to the folder that file
%is in.
[file path] = uigetfile('*.f32');
cd(path);

files = dir(['*' file(5:length(file))]);

for currente = 1:length(files)
    data = spikedataf(files(currente).name);
    stimuli = [data(:).stim]';
    numstim = length(stimuli);
    sweeplength = data(1).sweeplength;
    numreps = length(data(1).sweep);
    temp = [];
    for i = 1:length(data);
        for j = 1:numreps;
            try;
                temp(j,:) = histc(data(i).sweep(j).spikes,[0:1:sweeplength]);
            catch;
                temp(j,:) = zeros(1,sweeplength + 1);
            end;
            data(i).spikerate = 1000*temp;
        end
    end
    e(currente).data = data;
end

clear data temp;
    
a = figure(1);
set(a,'position',pos);
for currente = 1:length(files)
    subplot(4,4,currente)
    rf = zeros(numstim,sweeplength - mwsize + 1);
    for i = 1:numstim
        spont = mean(e(currente).data(i).spikerate(:,1:45)')';
        for j = 1:(sweeplength - mwsize + 1)
            temp = mean(e(currente).data(i).spikerate(:,j:(j+mwsize-1))')';
            [p,h] = signrank(spont,temp,alpha);
            if mean(temp) - mean(spont) > 0
                rf(i,j) = h;
            else
                rf(i,j) = -h;
            end
        end
    end
    e(currente).rf = rf;
    v = [-1.5,-0.5,0.5];
    contourf(rf,v);
    [a,b] = size(rf);
    view(0,90);
    xlim([1,b]);
    ylim([1,a]);
    set(gca,'YTick', [2 6],'YTickLabel', {'Left','Right'},'FontWeight','Bold');
    set(gca,'XTick', [-150:200:sweeplength],'XTickLabel',[-200:200:(sweeplength-50)]);
    xlabel('Time (ms)');
    line([50 50],[1 a],[10000 10000],'Color','w','LineStyle', '--','linewidth',2);
    line([1 b],[10 10],[10000 10000],'Color','w','LineStyle', '--','linewidth',2);
    title([files(currente).name(1:3)]);
end

counter = 4;
for i = 1:numstim
    temp = [];
    for currente = 1:length(files)
        temp = [temp; e(currente).rf(i,:)];
    end
    if counter == 4
        counter = 1;
        figure('position',pos);
    else
        counter = counter + 1;
    end
    subplot(2,2,counter);
    temp = [temp; zeros(1,length(temp))];
    surf(temp,'edgecolor','none');
    view(0,90);
    [a,b] = size(temp);
    view(0,90);
    xlim([1,b]);
    ylim([1,a]);
    set(gca,'YTick', [1:16]+ 0.5,'YTickLabel', [1:16],'FontWeight','Bold');
    set(gca,'XTick', [-150:200:sweeplength],'XTickLabel',[-200:200:(sweeplength-50)]);
    xlabel('Time (ms)');
    ylabel('Channel');
    line([50 50],[1 a],[10000 10000],'Color','k','LineStyle', '--','linewidth',2);
    title(['Stimulus ' num2str(i)]);
end

close all;

for currente = 1:length(files)
    for i = 1:numstim
        a = figure(2);
        set(a,'position',pos);
        spont = mean(e(currente).data(i).spikerate(:,1:50)')';
        [h,p,spont_ci] = ttest(mean(e(currente).data(i).spikerate(:,1:50)')',0,alpha);
        bar(smoothts(mean(e(currente).data(i).spikerate),'b',10));
        xlim([1,length(e(currente).data(i).spikerate)]);
        hold on;
        line(get(gca,'xlim'),[spont_ci(1) spont_ci(1)],'color','b','linestyle','--');
        line(get(gca,'xlim'),[spont_ci(2) spont_ci(2)],'color','b','linestyle','--');
        temp = smoothts(mean(e(currente).data(i).spikerate),'b',10);
        temp(find(temp < spont_ci(2))) = NaN;
        allowables = temp;
        plot(allowables,'r');
        allowables = find(~isnan(allowables));
        allowables = union(allowables,allowables+1);
        temp = [];
        for j = 1:numreps
            temp = [temp; j, length(e(currente).data(i).sweep(j).spikes)];
        end
        a = temp(:,1);
        b = find(temp(:,2) >= median(temp(:,2)));
        c = find(temp(:,2) <= median(temp(:,2)));
        if ~isempty(intersect(b,c))
            a = intersect(b,c);
        else
            [a,d] = min(temp(b,2));
            b = b(d);
            [a,d] = max(temp(c,2));
            c = c(d);
            a = [b,c];
        end
        spikes = flipud(sortrows(temp,2));
        counter = -30;
        for j = spikes(:,1)'
            x = e(currente).data(i).sweep(j).spikes;
            y = counter*ones(1,length(x));
            if any(j == a)
                plot(x,y,'g.');
            else
                b = plot(x,y,'k.');
                set(b,'color',[0.95,0.95,0.95]);
            end
            [temp, ia, ib] = intersect(allowables,round(x));
            temp = x(ib);
            y = counter*ones(1,length(temp));
            plot(temp,y,'k.');
            counter = counter - 15;
        end
        temp = get(gca,'ytick');
        temp(find(temp < 0)) = [];
        set(gca,'ytick',temp,'fontweight','bold');
        axis tight;
        ylabel('Spikerate (spikes/s)','fontweight','bold','fontsize',16);
        xlabel('Time (ms)','fontweight','bold','fontsize',16);
        set(gca,'XTick', [-150:200:sweeplength],'XTickLabel',[-200:200:(sweeplength-50)]);      
        title([files(currente).name(1:3), ': Stimulus ' num2str(i)],'fontweight','bold','fontsize',20);
        temp = get(gca,'ylim');
        text(20, 4*temp(2)/5, 'Do Not Use','fontweight','bold','color','r','fontsize',16);
        [x,y] = ginput(1);
        if y < 0
            y = round((y-(-15))/-15);
            e(currente).stim(i).bestsweep = spikes(y,1);
            x = e(currente).data(i).sweep(spikes(y,1)).spikes;
            [temp, ia, ib] = intersect(allowables,round(x));
            temp = x(ib);
            e(currente).stim(i).bestsweep = temp;
            x = x(find(x > 50));
            y = (y*(-15)-15)*ones(1,length(x));
            plot(x,y,'r.');
            pause(0.1);
        else
            e(currente).stim(i).bestsweep = [];
        end
        hold off;
    end
end

save('Piledriver_Stim','e');

% cd(uigetdir);
% load('Piledriver_Stim');

 files = {'Left Aaron','Left Dave','Left Sandi','Left Sarah','Right Aaron','Right Dave','Right Sandi','Right Sarah'};

for i = 1:8
    filename = [cell2mat(files(i)) '.17'];
    fid = fopen(filename,'w');
    temp = [];
    for currente = 2:16
        fwrite(fid,-currente,'float32');
        temp = [temp; -currente];
        if ~isempty(e(currente).stim)
            if length(e(currente).stim) >= i
                if length(e(currente).stim(i).bestsweep) == 1 & e(currente).stim(i).bestsweep == 0
                    e(currente).stim(i).bestsweep = [];
                end
                fwrite(fid,e(currente).stim(i).bestsweep','float32');
                temp = [temp; e(currente).stim(i).bestsweep'];
            end
        end
    end
    fclose(fid);
    disp(['File output for ' filename]);
    disp(temp);
end

        
        
    



    
    