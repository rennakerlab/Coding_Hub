function AnalyzeTC

%Load the f32 data file
[file,path] = uigetfile('*.f32')
file = [path file];
cd(path);


%**************************************************************************
%spikedataf.m is a function which will read Brainware f32 data into a data
%structure.  It has fields: sweeplength, stim, and sweep.  Sweeplength is
%the number of milliseconds of recording for each sound.  Stim is the
%parameters of a particualr stimulus, i.e. frequency and intensity.  Sweep
%denotes which repetition that particular data comes from.  
data = spikedataf(file);


%**************************************************************************
%We'll pull the frequencies and intensities of the stimuli out of the
%structure for later use.
numreps = length(data(1).sweep);
freqs = [];
ints = [];
for i = 1:length(data);
    if isempty(find(freqs==data(i).stim(1)));
        freqs = [freqs; data(i).stim(1)];
    end
    if isempty(find(ints==data(i).stim(2)));
        ints = [ints; data(i).stim(2)];
    end
end
numfreq = length(freqs);
numint = length(ints);


%**************************************************************************
%f32 files contain spike times, and we're going to look at spike rates, so
%this loop will calculate histograms of those spike times to create
%Peri-Stimulus Time Histograms (PSTH) for each repetition of each stimulus.
%This loop also creates a 4-D array of spikerate calculated  each 1 ms
%time-bin for each frequency, intensity, and repetition.  The dimensions of
%the 4-D array are frequency (x), time (y), intensity (z), and
%repetition (r).
for i = 1:length(data);
    x = find(data(i).stim(1)==freqs);
    z = find(data(i).stim(2)==ints);
    temp1 = [];
    for r = 1:numreps;
        try;
            temp2 = histc(data(i).sweep(r).spikes,[0:1:data(i).sweeplength]);
        catch;
            temp2 = zeros(1,data(i).sweeplength+1);
        end;
        temp1 = [temp1; temp2];
        for y = 1:length(temp2);
            tc(x,y,z,r) = temp2(y)/0.001;
        end
    end
    data(i).spikerate = temp1/0.001;
end


%**************************************************************************
%At this point we can do a quick test to see if it's worth it to continue
%analyzing this file by running a 2-way ANOVA on the data for the highest
%intensity.  We'll average the "tc" data across repetitions and across 5 ms
%bins to reduce the computation time.  If there are significant neural
%responses that change according to frequency and time, then this will show
%up as a signficant interaction effect between groups.
[a,b,c,d] = size(tc);
test_data = [];
for i = 1:a
    rows = [];
    for j = 5:5:b
        obs = [];
        for r = 1:d
            obs = [obs; mean(tc(i,(j-4):j,numint,r))];
        end
        rows = [rows, obs];
    end
    test_data = [test_data; rows];
end
p = anova2(test_data,d,'off');
if p(3) < 0.05
    disp(['Significant interaction in the 2-way ANOVA for the highest intensity, p = ' num2str(p(3))]);
else
    disp(['Interaction in 2-way ANOVA for the highest intensity is not significant, p = ' num2str(p(3))]);
end


%**************************************************************************
%To better visualize the data, we want to subtract spontaneous activity out
%of the picture.  We'll calculate the spontanteous rate from the average of
%the first 30 ms of data from every sweep, and we'll save the mean,
%standard deviation, and number of samples in case we need them again.
spont = [];
for i = 1:length(data);
    spont = [spont; mean(mean(data(i).spikerate(:,1:30))')];
end
spont = [mean(spont); std(spont); length(spont)];
tc = tc - spont(1);


%**************************************************************************
%We're creating several 2-D color plots first to look at the responses for
%each intensity.  We'll average responses across repetition to get a 3-D
%array called "Ds".
[a,b,c,d] = size(tc);
for i = 1:a
    for j = 1:b
        for k = 1:c
            Ds(i,j,k)=mean(tc(i,j,k,1:d));
        end
    end
end


%**************************************************************************
%The 3-D spikerate data in the array "Ds" is very choppy, so to better see
%the responses shape, we'll smooth the data, but only across the horizontal
%plane.  We don't want to smooth across the intensity axis, because that
%will blur the response threshold.
for k = 1:c
    Ds(:,:,k)=smoothts(smoothts(Ds(:,:,k)')');
end


%**************************************************************************
%On each of the temporal RF plots we're going to make, we want to set the
%colorscales the same so that we can directly compare them.  We'll set the
%maximum and minimum of the colorscale to the maximum and minimum of the
%smoothed data array "Ds".
graphmax = max(max(max(Ds)));
graphmin = min(min(min(Ds)));


%**************************************************************************
%Here we're creating plots of the smoothed temporal receptive field for
%each intensity.  Remember that the tones played in a tuning curve
%experiment vary in frequency and intensity, so these plots show us which
%frequencies each neuron or multineuron cluster responds to for each
%intensity, as well as when that response happens relative to the start of
%the stimulus.  The white line drawn across each plot marks the stimulus
%onset.
scrnsize = get(0,'ScreenSize');
pos = [scrnsize(3)/20 scrnsize(4)/16 (scrnsize(3)-2*(scrnsize(3)/20)) (scrnsize(4)-2*(scrnsize(4)/16))];
disp('Plotting temporal receptive fields for each intensity...');
close all;
counter = 4;
for i = 1:numint
    if counter == 4;            %We'll create large figures broken up into 4 plots each.
        figure('Position',pos);
        counter = 1;
    else
        counter = counter + 1;
    end
    subplot(2,2,counter);
    surf(Ds(:,:,i),'EdgeColor', 'none');
    view(0,90);
    set(gca,'XLim',[1 data(1).sweeplength],'YLim', [1 numfreq]);
    if numfreq<20
        set(gca,'YTick', [1:numfreq],'YTickLabel', round(freqs));
    else
        set(gca,'YTick', [1:5:numfreq],'YTickLabel', round(freqs(1:5:numfreq)));
    end
    zlim([graphmin graphmax]);
    set(gca,'XTick', [10:25:data(1).sweeplength],'XTickLabel',[-25:25:(data(1).sweeplength-35)]);
    set(gca,'CLim',[graphmin graphmax]);
    xlabel('time (ms)','FontWeight','Bold');
    ylabel('frequency (Hz)','FontWeight','Bold');
    line([35 35],[1 numfreq],[graphmax graphmax],'Color','w','LineStyle', '--');
    title(['Intensity: ' num2str(ints(i)) ' dB'],'FontWeight','Bold','FontSize',12);
    
    %We can do a quick test on each temporal receptive field to see if
    %there is a signficant, frequency-selective response by performing a
    %2-way ANOVA on the plotted data, looking for a significant
    %interaction.
    [a,b,c,d] = size(tc);
    testdata = [];
    for r = 1:d
        testdata = [testdata; mean(mean(tc(:,1:30,i,r))), mean(mean(tc(:,45:64,i,r)))];
    end
    [h,p,ci] = ttest2(testdata(:,1),testdata(:,2));
    temp = ['Intensity: ' num2str(ints(i)) ' dB,  p(D) = ' num2str(round(1000*p)/1000)];
	testdata = zeros(d,a);
    for x = 1:a
        for r = 1:d
            testdata(r,x) = mean(tc(x,45:64,i,r));
        end
    end
    p = anova1(testdata,repmat('a',a,1),'off');
    temp = [temp, ',  p(T) = ' num2str(round(1000*p)/1000)];
    test_data = [];
	for x = 1:a
        rows = [];
        for y = 5:5:b
            obs = [];
            for r = 1:d
                obs = [obs; mean(tc(x,(y-4):y,i,r))];
            end
            rows = [rows, obs];
        end
        test_data = [test_data; rows];
	end
	p = anova2(test_data,d,'off');
    title([temp ',  p(2W) = ' num2str(round(1000*p(3))/1000)],'FontWeight','Bold','FontSize',12);
    colorbar;
end


%**************************************************************************
%Next, we'll create a standard Peri-Stimulus Time Histogram (PSTH) by
%averaging the spikerate across all sweeps in 1 ms bins.
disp('Plotting overall PSTH...');
temp = [];
for i = 1:length(data);
    temp = [temp; data(i).spikerate];
end
temp = mean(temp);
if counter == 4;
    figure('Position',pos);
    counter = 1;
else
    counter = counter + 1;
end
subplot(2,2,counter);
bar(temp,1,'k');
set(gca,'XLim',[1 data(1).sweeplength]);
set(gca,'XTick', [10:25:data(1).sweeplength],'XTickLabel',[-25:25:(data(1).sweeplength-35)]);
y = get(gca,'YLim');
line([35 35],y,[10000 10000],'Color','b','LineStyle', ':');
title(['Overall PSTH'],'FontWeight','Bold','FontSize',12);
xlabel('time (ms)','FontWeight','Bold');
ylabel('spikerate (Hz)','FontWeight','Bold');


%**************************************************************************
%The 1 ms windows used to make the 2-D plots are too small to do
%statistical analysis on, so we're going to expand them to 5 ms, but we'll
%use a moving window to keep some of the time resolution.
disp('Calculating moving windows...');
[a,b,c,d] = size(tc);
for i = 1:a
    for k = 1:c
        for l = 1:d
            for j = 1:(b-4)
                S(i,j,k,l)=mean(tc(i,j:(j+4),k,l));
            end
        end
    end
end
D = S;


%**************************************************************************
%To analyze significant frequency selectivity, we'll run ANOVA's across
%frequencies for each time bin and each intensity.  Then we'll plot that as
%a surface plot with axes of intensity and time.
disp('Analyzing frequency-selectivity...');
clear S;
[a,b,c,d]=size(D);
S = zeros(c,b);
for j = 1:b
    for k = 1:c
        test = [];
        for i = 1:a
            temp = [];
            for l = 1:d
                temp = [temp; D(i,j,k,l)];
            end
            test = [test,temp];
        end
        p=anova1(test,repmat('a',numfreq,1),'off');
        S(k,j)= p;
    end
end
freq_wise_anova = S;


%**************************************************************************
%We'll plot the p-values from the ANOVA results as two surface plots, one
%smoothed and one unsmoothed.
if counter == 4;
    figure('Position',pos);
    counter = 1;
else
    counter = counter + 1;
end
subplot(2,2,counter);
surf(S,'EdgeColor', 'none');
view(0,90);
set(gca,'XLim',[1 b],'YLim', [1 c]);
set(gca,'YTick', [1:c],'YTickLabel', ints);
set(gca,'XTick', [10:25:b],'XTickLabel',[-25:25:(data(1).sweeplength-35)]);
xlabel('time (ms)','FontWeight','Bold');
ylabel('Intensity (dB)','FontWeight','Bold');
line([35 35],[1 numfreq],[10000 10000],'Color','w','LineStyle', '--');
title('Unsmoothed ANOVA Results (Side-View)','FontWeight','Bold','FontSize',12);
colorbar;
if counter == 4;
    figure('Position',pos);
    counter = 1;
else
    counter = counter + 1;
end
subplot(2,2,counter);
surf(smoothts(smoothts(S')'),'EdgeColor', 'none');
view(0,90);
set(gca,'XLim',[1 b],'YLim', [1 c]);
set(gca,'YTick', [1:c],'YTickLabel', ints);
set(gca,'XTick', [10:25:b],'XTickLabel',[-25:25:(data(1).sweeplength-35)]);
xlabel('time (ms)','FontWeight','Bold');
ylabel('intensity (dB)','FontWeight','Bold');
line([35 35],[1 numfreq],[10000 10000],'Color','w','LineStyle', '--');
title('Smoothed ANOVA Results (Side-View)','FontWeight','Bold','FontSize',12);
colorbar;


%**************************************************************************
%To get a good look at the tuning we'll also run ANOVAs across time.  This
%will give us a figure like those seen in other studies, but without the
%disadvantages of window analysis.
disp('Analyzing tuning...');
clear S;
[a,b,c,d]=size(D);
S = zeros(a,c);
for i = 1:a
    for k = 1:c
        test = [];
        for j = 1:b
            temp = [];
            for l = 1:d
                temp = [temp; D(i,j,k,l)];
            end
            test = [test,temp];
        end
        p=anova1(test,repmat('a',length(test),1),'off');
        S(i,k)= p;
    end
end
time_wise_anova = S;


%**************************************************************************
%Again, we'll plot the p-values from the ANOVA results as a surface plot,
%both smoothed and unsmoothed.
disp('Plotting tuning results...');
if counter == 4;
    figure('Position',pos);
    counter = 1;
else
    counter = counter + 1;
end
subplot(2,2,counter);
surf(S','EdgeColor', 'none');
view(0,90);
set(gca,'XLim',[1 a],'YLim', [1 c]);
set(gca,'YTick', [1:c],'YTickLabel', ints);
if numfreq<20
    set(gca,'XTick', [1:numfreq],'XTickLabel', round(freqs));
else
    set(gca,'XTick', [1:5:numfreq],'XTickLabel', round(freqs(1:5:numfreq)));
end
xlabel('frequency (Hz)','FontWeight','Bold');
ylabel('intensity (dB)','FontWeight','Bold');
title('Unsmoothed Tuning Results (Front-View)','FontWeight','Bold','FontSize',12);
colorbar;
if counter == 4;
    figure('Position',pos);
    counter = 1;
else
    counter = counter + 1;
end
subplot(2,2,counter);
surf(smoothts(smoothts(S')),'EdgeColor', 'none');
view(0,90);
set(gca,'XLim',[1 a],'YLim', [1 c]);
set(gca,'YTick', [1:c],'YTickLabel', ints);
if numfreq<20
    set(gca,'XTick', [1:numfreq],'XTickLabel', round(freqs));
else
    set(gca,'XTick', [1:5:numfreq],'XTickLabel', round(freqs(1:5:numfreq)));
end
xlabel('frequency (Hz)','FontWeight','Bold');
ylabel('intensity (dB)','FontWeight','Bold');
title('Smoothed Tuning Results(Front-View)','FontWeight','Bold','FontSize',12);
colorbar;


%**************************************************************************
%We'll run one more set of ANOVAs, this time across intensity.  This will
%basically show us the same tuning picture as we might see in a temporal
%receptive field, but it will essentially give us the 3rd side of the cube
%that we will use to triangulate significant response windows within the
%3-D data.
disp('Analyzing frequency-time interaction...');
clear S;
[a,b,c,d]=size(D);
S = zeros(a,b);
for i = 1:a
    for j = 1:b
        test = [];
        for k = 1:c
            temp = [];
            for l = 1:d
                temp = [temp; D(i,j,k,l)];
            end
            test = [test,temp];
        end
        p=anova1(test,repmat('a',k,1),'off');
        S(i,j)= p;
    end
end
intensity_wise_anova = S;


%**************************************************************************
%Once again, the p-values from the intensity-wise ANOVAs will be surface
%plotted, both smoothed and unsmoothed.
disp('Plotting tuning results...');
if counter == 4;
    figure('Position',pos);
    counter = 1;
else
    counter = counter + 1;
end
subplot(2,2,counter);
surf(S,'EdgeColor', 'none');
view(0,90);
set(gca,'YLim',[1 a],'XLim', [1 b]);
set(gca,'XTick', [10:25:b],'XTickLabel', [-25:25:(data(1).sweeplength-35)]);
if numfreq<20
    set(gca,'YTick', [1:numfreqs],'YTickLabel', round(freqs));
else
    set(gca,'YTick', [1:5:numfreq],'YTickLabel', round(freqs(1:5:numfreq)));
end
xlabel('time (ms)','FontWeight','Bold');
ylabel('frequency (Hz)','FontWeight','Bold');
title('Unsmoothed Tuning Results (Top-Side)','FontWeight','Bold','FontSize',12);
colorbar;
if counter == 4;
    figure('Position',pos);
    counter = 1;
else
    counter = counter + 1;
end
subplot(2,2,counter);
surf(smoothts(smoothts(S')'),'EdgeColor', 'none');
view(0,90);
set(gca,'YLim',[1 a],'XLim', [1 b]);
set(gca,'XTick', [10:25:b],'XTickLabel', [-25:25:(data(1).sweeplength-35)]);
if numfreq<20
    set(gca,'YTick', [1:numfreqs],'YTickLabel', round(freqs));
else
    set(gca,'YTick', [1:5:numfreq],'YTickLabel', round(freqs(1:5:numfreq)));
end
xlabel('time (ms)','FontWeight','Bold');
ylabel('frequency (Hz)','FontWeight','Bold');
title('Smoothed Tuning Results (Top-Side)','FontWeight','Bold','FontSize',12);
colorbar;

% 
% temp = questdlg('Plot 3-D graphs?','3-D Visualization','Yes','No','Yes');
% 
% if strcmp(temp,'Yes');
%     
%     %**************************************************************************
%     %We can use the three sets of ANOVAs (frequency-wise, time-wise, and
%     %intensity-wise) to triangulate the signficance of a response at any cell
%     %in our 3-D picture.  We'll take the mean of the 3 p-values corresponding
%     %to 3-D coordinate from each of the 2-D ANOVA results.  This should help to
%     %fix type I errors, essentially making the probability of a type I error
%     %0.05x0.05x0.05 = 0.000125.
%     clear S;
%     [a,b,c,d]=size(D);
%     for i = 1:a
%         for j = 1:b
%             for k = 1:c
%                 S(i,j,k) = mean([time_wise_anova(i,k), freq_wise_anova(k,j), intensity_wise_anova(i,j)]);
%             end
%         end
%     end
% 
%     %**************************************************************************
%     %We'll graph the p-values contained in the 3-D array "S" with an isosurface
%     %set to alpha = 0.05.  We'll also graph a 3D-smoothed version of the data
%     %to clear up the picture if necessary.
%     figure('Position',pos);
%     graph2 = patch(isosurface(S,0.05));
%     set(graph2,'FaceColor','blue','EdgeColor','none');
%     camlight;
%     lightangle(45,145);
%     grid on;
%     view(3); axis tight;
%     top = patch(isocaps(S,0.05,'below'),'FaceColor','interp','EdgeColor','none');
%     set(top,'AmbientStrength',0.2);
%     set(top,'SpecularColorReflectance',0,'SpecularExponent',50);
%     xlim([1 b]);
%     ylim([1 a]);
%     zlim([0 c]);
%     if numfreq<20
%         set(gca,'YTick', [1:numfreq],'YTickLabel', round(freqs));
%     else
%         set(gca,'YTick', [1:5:numfreq],'YTickLabel', round(freqs(1:5:numfreq)));
%     end
%     set(gca,'XTick', [10:25:data(1).sweeplength],'XTickLabel',[-25:25:(data(1).sweeplength-35)]);
%     set(gca,'ZTick', [1:numint],'ZTickLabel',ints);
%     xlabel('time (ms)','FontWeight','Bold');
%     ylabel('frequency (Hz)','FontWeight','Bold');
%     zlabel('intensity (dB)','FontWeight','Bold');
%     title(['Unsmoothed ANOVA Triangulation, Alpha = 0.05'],'FontWeight','Bold','FontSize',12);
%     colorbar;
%     figure('Position',pos);
%     graph2 = patch(isosurface(smooth3(S),0.05));
%     set(graph2,'FaceColor','blue','EdgeColor','none');
%     camlight;
%     lightangle(45,145);
%     grid on;
%     view(3); axis tight;
%     top = patch(isocaps(smooth3(S),0.05,'below'),'FaceColor','interp','EdgeColor','none');
%     set(top,'AmbientStrength',0.2);
%     set(top,'SpecularColorReflectance',0,'SpecularExponent',50);
%     xlim([1 b]);
%     ylim([1 a]);
%     zlim([0 c]);
%     if numfreq<20
%         set(gca,'YTick', [1:numfreq],'YTickLabel', round(freqs));
%     else
%         set(gca,'YTick', [1:5:numfreq],'YTickLabel', round(freqs(1:5:numfreq)));
%     end
%     set(gca,'XTick', [10:25:data(1).sweeplength],'XTickLabel',[-25:25:(data(1).sweeplength-35)]);
%     set(gca,'ZTick', [1:numint],'ZTickLabel',ints);
%     xlabel('time (ms)','FontWeight','Bold');
%     ylabel('frequency (Hz)','FontWeight','Bold');
%     zlabel('intensity (dB)','FontWeight','Bold');
%     title(['Smoothed ANOVA Triangulation, Alpha = 0.05'],'FontWeight','Bold','FontSize',12);
%     colorbar;
% 
% 
%     %**************************************************************************
%     %Since we subtracted spontaneous rate, if the spikerate within a window is
%     %significantly different than zero, then that indicates a significant
%     %response.  We'll create another 3-D array in which all values are zero,
%     %unless the t-test is significant, in which case the value will equal the
%     %value from the smoothed 3-D array "Ds".
%     disp('Analyzing moving-window spikerates...');
%     clear S;
%     [a,b,c,d]=size(D);
%     for i = 1:a
%         for j = 1:b
%             for k = 1:c
%                 temp = [];
%                 for l = 1:numreps
%                     temp = [temp; D(i,j,k,l)];
%                 end
%                 if std(temp)>0;
%                     [h,p,ci] = ttest(temp,0);
%                     if h
%                         S(i,j,k)= Ds(i,j,k);
%                     else
%                         S(i,j,k) = 0;
%                     end
%                     ps(i,j,k)=p;
%                 else
%                     ps(i,j,k) = 1;
%                 end
%             end
%         end
%     end
% 
% 
%     %**************************************************************************
%     %Now we'll plot a series of stacked contour plots for each intensity, with
%     %non-significant response windows left out.
%     figure('Position',pos);
%     graph1 = contourslice(S,[],[],[1:c],8);
%     set(graph1,'LineWidth',2);
%     grid on;
%     view(3); axis tight;
%     xlim([1 b]);
%     ylim([1 a]);
%     zlim([0 c]);
%     if numfreq<20
%         set(gca,'YTick', [1:numfreq],'YTickLabel', round(freqs));
%     else
%         set(gca,'YTick', [1:5:numfreq],'YTickLabel', round(freqs(1:5:numfreq)));
%     end
%     set(gca,'XTick', [10:25:data(1).sweeplength],'XTickLabel',[-25:25:(data(1).sweeplength-35)]);
%     set(gca,'ZTick', [1:numint],'ZTickLabel',ints);
%     xlabel('time (ms)','FontWeight','Bold');
%     ylabel('frequency (Hz)','FontWeight','Bold');
%     zlabel('intensity (dB)','FontWeight','Bold');
%     title(['Significantly Different than Spontaneous, Alpha = ' num2str(0.05/numreps)],'FontWeight','Bold','FontSize',12);
%     colorbar;
% 
% 
%     %**************************************************************************
%     %Next we'll draw an isosurface around all areas with responses that are
%     %significantly different than spontaneous.
%     figure('Position',pos);
%     graph2 = patch(isosurface(ps,0.05));
%     set(graph2,'FaceColor','blue','EdgeColor','none');
%     camlight;
%     lightangle(45,145);
%     grid on;
%     view(3); axis tight;
%     top = patch(isocaps(S,0),'FaceColor','interp','EdgeColor','none');
%     set(top,'AmbientStrength',0.2);
%     set(top,'SpecularColorREflectance',0,'SpecularExponent',50);
%     xlim([1 b]);
%     ylim([1 a]);
%     zlim([0 c]);
%     if numfreq<20
%         set(gca,'YTick', [1:numfreq],'YTickLabel', round(freqs));
%     else
%         set(gca,'YTick', [1:5:numfreq],'YTickLabel', round(freqs(1:5:numfreq)));
%     end
%     set(gca,'XTick', [10:25:data(1).sweeplength],'XTickLabel',[-25:25:(data(1).sweeplength-35)]);
%     set(gca,'ZTick', [1:numint],'ZTickLabel',ints);
%     xlabel('time (ms)','FontWeight','Bold');
%     ylabel('frequency (Hz)','FontWeight','Bold');
%     zlabel('intensity (dB)','FontWeight','Bold');
%     title(['Significantly Different than Spontaneous, Alpha = ' num2str(0.05/numreps)],'FontWeight','Bold','FontSize',12);
% 
% end

%**************************************************************************
%The last plot calculates the significance of the response within the fixed
%onset response window and displays it as a function of frequency and
%intensity.
figure;
disp('Analyzing fixed big-window significance...');
clear S;
[a,b,c,d]=size(tc);
S = zeros(c,a);
for i = 1:a
    for k =1:c
        temp1 = [];
        temp2 = [];
        for l = 1:d
            temp1 = [temp1; tc(i,1:30,k,l)];
            temp2 = [temp2; tc(i,45:64,k,l)];
        end
        temp1 = mean(temp1')';
        temp2 = mean(temp2')';
        [h, sig, ci] = ttest2(temp1,temp2);
        S(k,i) = sig;
    end
end
contourf(S,[0.05,0.01,0.001,0.0001,0.00001]);
caxis([0.00001, 0.05]);
colormap(jet);
xlim([1 a]);
ylim([1 c]);
if numfreq<20
    set(gca,'XTick', [1:numfreq],'XTickLabel', round(freqs),'FontWeight','Bold');
else
    set(gca,'XTick', [1:5:numfreq],'XTickLabel', round(freqs(1:5:numfreq)),'FontWeight','Bold');
end
set(gca,'YTick', [1:numint],'YTickLabel',ints,'FontWeight','Bold');
xlabel('frequency (Hz)','FontWeight','Bold');
ylabel('intensity (dB)','FontWeight','Bold');
title(['Window Analysis Significance'],'FontWeight','Bold','FontSize',12);
a = colorbar;
set(a,'Ylim',[0.00001,0.05],'YScale','log','YTick',fliplr([0.05,0.01,0.001,0.0001,0.00001]));