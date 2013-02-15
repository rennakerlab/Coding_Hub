function New_Habituation_Test

%I like my figures nice and big, so here's a trick that will let us set the
%figure size to about 80% of the screensize.
scrnsize = get(0,'ScreenSize');
pos = [scrnsize(3)/20 scrnsize(4)/16 (scrnsize(3)-2*(scrnsize(3)/20)) (scrnsize(4)-3*(scrnsize(4)/16))];

[file path] = uigetfile('*.f32');
cd(path);
channel = file(1:4);

files = dir([channel '*.f32']);
for i = 1:length(files);
    if length(find(files(i).name((length(files(i).name)-8):(length(files(i).name)-4)) == 'Post1')) == 5
        post = i;
    elseif length((find(files(i).name((length(files(i).name)-7):(length(files(i).name)-4)) == 'Pre1'))) == 4
        pre = i;
    elseif length(find(files(i).name(4:10) == '_Hab_1_')) == 7
        hab = i;
    end
end


%PRE***********************************************************************
data = spikedataf(files(pre).name);

numreps = length(data(1).sweep);
numfreq = length([data(:).stim]);
temp = [data(:).stim]';
freqs= temp(:,1);
int = temp(1,2);
onsets = temp(:,3) - 35;

for i = 1:numfreq;
    temp = [];
    for j = 1:numreps; 
        try;
            temp = [temp; histc(data(i).sweep(j).spikes,[0:data(1).sweeplength])];
        catch;
            temp = [temp; zeros(1,data(1).sweeplength + 1)];
        end;
    end;
    data(i).spikerate = temp(:,1:(length(temp)))/(0.001);
end;

clear pre;
for i = 1:numfreq
    pre(i).spikerate = data(i).spikerate(:,(onsets(i)+1):(onsets(i)+200));
end

%POST**********************************************************************
data = spikedataf(files(post).name);

for i = 1:numfreq;
    temp = [];
    for j = 1:numreps; 
        try;
            temp = [temp; histc(data(i).sweep(j).spikes,[0:data(1).sweeplength])];
        catch;
            temp = [temp; zeros(1,data(1).sweeplength + 1)];
        end;
    end;
    data(i).spikerate = temp(:,1:(length(temp)))/(0.001);
end;

clear post;
for i = 1:numfreq
    post(i).spikerate = data(i).spikerate(:,(onsets(i)+1):(onsets(i)+200));
end


%HAB***********************************************************************
data = spikedataf(files(hab).name);

numreps = length(data(1).sweep);
temp = [data(:).stim]';
habfreq = temp(1,1);
hf = find(round(freqs) == round(habfreq));
int = temp(1,2);
[a,b] = size(temp);
if b == 3
    onsets = temp(:,3) - 35;
    for i = 1:length(onsets);
		temp = [];
		for j = 1:numreps; 
            try;
                temp = [temp; histc(data(i).sweep(j).spikes,[0:data(1).sweeplength])];
            catch;
                temp = [temp; zeros(1,data(1).sweeplength + 1)];
            end;
		end;
		data(i).spikerate = temp(:,1:(length(temp)))/(0.001);
	end
    hab = [];
	for i = 1:length(onsets);
        hab = [hab; data(i).spikerate(:,(onsets(i)+1):(onsets(i)+200))];
	end
else
	temp = [];
	for j = 1:numreps; 
        try;
            temp = [temp; histc(data(1).sweep(j).spikes,[0:data(1).sweeplength])];
        catch;
            temp = [temp; zeros(1,data(1).sweeplength + 1)];
        end;
	end;
	data(1).spikerate = temp(:,1:(length(temp)))/(0.001);
    hab = data(1).spikerate;
end


%PRE STRF***********************************************************
[a,b] = size(pre(1).spikerate);
strf = zeros(numfreq,b);
for i = 1:numfreq;
    strf(i,:)=mean(pre(i).spikerate);
end;
strf = strf - mean(mean(strf(:,1:30))');
a = figure(1);
set(a,'Position',pos);
subplot(2,2,1);
temp = [strf; zeros(1,length(strf))];
surf(smoothts(smoothts(temp)')','EdgeColor','none');
view(0,90);
[a,b] = size(strf);
xlim([1,b+1]);
ylim([1,a+1]);
set(gca,'YTick',get(gca,'YTick')+0.5,'FontWeight','Bold');
set(gca,'YTickLabel',round(freqs(5:5:20)/10)/100);
xlabel('Time (ms)','FontWeight','Bold');
ylabel('Frequency (kHz)','FontWeight','Bold');
temp = get(gca,'XTickLabel');
temp = str2num(temp) - 35;
set(gca,'XTick',get(gca,'XTick')+0.5);
set(gca,'XTickLabel',temp);
title('PRE','FontWeight','Bold','FontSize',12);
a = colorbar;
set(a,'FontWeight','Bold');

subplot(2,2,2);
temp = mean(pre(hf).spikerate);
plot(smoothts(smoothts(temp)),'Color','b','LineWidth',2)
hold on;
temp = mean(hab);
plot(smoothts(smoothts(temp)),'Color','r','LineWidth',2)
temp = mean(post(hf).spikerate);
plot(smoothts(smoothts(temp)),'Color','g','LineWidth',2)
hold off;
xlim([1,b+1]);
xlabel('Time (ms)','FontWeight','Bold');
ylabel('Spikerate (spikes/s)','FontWeight','Bold');
temp = get(gca,'XTickLabel');
temp = str2num(temp) - 35;
set(gca,'XTick',get(gca,'XTick')+0.5,'FontWeight','Bold');
set(gca,'XTickLabel',temp);
title('HF Response','FontWeight','Bold','FontSize',12);
legend('PRE','HAB','POST');

subplot(2,2,[3 4]);
[a,b] = size(pre(hf).spikerate);
temp = [];
temp_ci = [];
for i = 1:a
    temp = [temp; mean(mean(pre(hf).spikerate(1:i,46:75)')')];
    [h, p, ci] = ttest(mean(pre(hf).spikerate(1:i,46:75)')');
    temp_ci = [temp_ci; mean(mean(pre(hf).spikerate(1:i,46:75)')') - ci(1)];
end
b = errorbar([1:a]', temp, temp_ci);
set(b,'LineWidth',2,'Color','b');
hold on;
plot([1:a]', temp, 'Color' ,'k','LineWidth',2)
[c,d] = size(hab);
temp = [];
temp_ci = [];
for i = 1:c
    temp = [temp; mean(mean(hab(1:i,46:75)')')];
    [h, p, ci] = ttest(mean(hab(1:i,46:75)')');
    temp_ci = [temp_ci; mean(mean(hab(1:i,46:75)')') - ci(1)];
end
b = errorbar([(a+1):0.25:(a+c/4+0.75)]', temp, temp_ci);
set(b,'LineWidth',2,'Color','r');
plot([(a+1):0.25:(a+c/4+0.75)]', temp, 'Color' ,'k','LineWidth',2)
[e,f] = size(post(hf).spikerate);
temp = [];
temp_ci = [];
for i = 1:e
    temp = [temp; mean(mean(post(hf).spikerate(1:i,46:75)')')];
    [h, p, ci] = ttest(mean(post(hf).spikerate(1:i,46:75)')');
    temp_ci = [temp_ci; mean(mean(post(hf).spikerate(1:i,46:75)')') - ci(1)];
end
b = errorbar([(a+c/4+1.75):(a+c/4+0.75+e)]', temp, temp_ci);
set(b,'LineWidth',2,'Color','g');
plot([(a+c/4+1.75):(a+c/4+0.75+e)]', temp, 'Color' ,'k','LineWidth',2)
ylabel('Spikerate (spikes/s)','FontWeight','Bold');
temp = {'PRE','HAB','POST'};
set(gca,'XTick',[ 3, a+3, a+c/4+3.75],'XTickLabel',temp,'FontWeight','Bold');
temp = mean(mean(pre(hf).spikerate(:,1:30)));
a = get(gca,'XLim');
line(a,[temp,temp],'Color','k','LineStyle',':');
[a,b] = size(pre(hf).spikerate);
temp = [];
temp_ci = [];
for i = 1:a
    temp = [temp; mean(mean(pre(hf).spikerate(1:i,44:59)')')];
    [h, p, ci] = ttest(mean(pre(hf).spikerate(1:i,44:59)')');
    temp_ci = [temp_ci; mean(mean(pre(hf).spikerate(1:i,44:59)')') - ci(1)];
end
ylim([0,3*max(temp)/2]);
hold off;


