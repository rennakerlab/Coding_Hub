function Plot_Startle_Recordings

alpha = 0.05;
startlepath = 'Y:\Startle Data\';
[file path] = uigetfile('*TINNITUS*.f32');
cd(path);
spikedata = spikedataf(file);
a = find(file == '_');
ratname = file(a(3)+1:a(4)-1);
rootname = file(a(1)+1:a(5)-1);
psychdata = StartleFileRead([startlepath ratname '\' rootname '.STARTLE']);
numbackgrounds = length(spikedata);

%Startle psychophysics plot
fig = figure;
temp = get(fig,'position'); %Find the current position of the figure.
set(fig,'position',[temp(1),temp(2)-(numbackgrounds/2)*temp(4),1.5*temp(3),(numbackgrounds+1)*temp(4)/2]);	%Make the figure 50% taller than the default.
set(fig,'color','w');   %Set the background color on the figure to white.
set(fig,'name',file);       %Set the filename as the figure title.
a = strmatch('Background Center Frequency (kHz)',{psychdata.param(:).name});      %Find the stimuli column for center frequency.
stimuli = vertcat(psychdata.param(:).value)';               %Organize all the stimulus parameters.
[stimuli,j] = sortrows(stimuli,a);                          %Sort the stimuli by rows.
psychdata.stim = psychdata.stim(j);                         %Re-arrange the psychdata structure to reflect the sorting.
cuedpsychdata = zeros(2,length(psychdata.stim));        	%Preallocate an array for cued response psychdata.
uncuedpsychdata = zeros(2,length(psychdata.stim));      	%Preallocate an array for uncued response psychdata.
p = zeros(1,length(psychdata.stim));                        %Preallocate an array to hold significance tests.
b = ceil(psychdata.sampling_rate*(psychdata.startler_delay+(0:300))/1000);	%Find all samples in the 300 ms after the startler onset.
for j = 1:length(psychdata.stim);                   	%Step through the psychdata by stimulus parameters.
    c = psychdata.stim(j).signal(find(psychdata.stim(j).predicted),b);            %Grab all predicted sweeps.
    c = range(c,2);                             %Find the max peak-to-peak excursion in each signal.
    cuedpsychdata(1,j) = mean(c);                    %Save the mean maximum excursion.
    cuedpsychdata(2,j) = simple_ci(c,alpha);        	%Save the confidence interval for excursion size.
    u = psychdata.stim(j).signal(find(~psychdata.stim(j).predicted),b);            %Grab all predicted sweeps.
    u = range(u,2);                             %Find the max peak-to-peak excursion in each signal.
    uncuedpsychdata(1,j) = mean(u);                 	%Save the mean maximum excursion.
    uncuedpsychdata(2,j) = simple_ci(u,alpha);      	%Save the confidence interval for excursion size.
    if length(c) == length(u)                   %If the sample sizes for cued and uncued responses are the same...
        p(j) = signrank(c,u,'alpha',alpha);     %...use an MPSR test to find significance.
    else                                        %Otherwise...
        [u,c] = ttest2(c,u,alpha);             	%...use a two-sample t-test to find signifance...
        p(j) = c;                               %...and save the p-value.
    end         
end
cuedpsychdata(1,:) = cuedpsychdata(1,:)./uncuedpsychdata(1,:);
cuedpsychdata(2,:) = cuedpsychdata(2,:)./uncuedpsychdata(1,:);
uncuedpsychdata(2,:) = uncuedpsychdata(2,:)./uncuedpsychdata(1,:);
uncuedpsychdata(1,:) = uncuedpsychdata(1,:)./uncuedpsychdata(1,:);
subplot(numbackgrounds+1,1,1);
errorbar([cuedpsychdata(1,:)', uncuedpsychdata(1,:)'],[cuedpsychdata(2,:)', uncuedpsychdata(2,:)'],'linewidth',2);  %Plot the startle response means as error bars.
box off;        %Get rid of the plot box.
axis tight;     %Tighten the axes.
xlim([0.5,length(psychdata.stim)+0.5]);  %Set the x-axis limits.
temp = get(gca,'ylim');             %Grab the current y-axis limits.
ylim(temp + [-0.05,0.05]*range(temp));  %Slightly widen the y-axis limits.
temp = {};                          %Create an empty matrix to hold x labels.
for j = 1:length(psychdata.stim)         %Step through all stimuli.
    if stimuli(j,a) == 0            %If this was broadband noise.
        temp{j} = 'BBN';            %...mark it as such.
    else                            %Otherwise...
        temp{j} = [num2str(stimuli(j,a)) 'kHz'];    %...indicate the center frequency.
    end
end
set(gca,'xtick',1:length(psychdata.stim),'xticklabel',temp);
temp = get(gca,'ylim');             %Grab the current y-axis limits again.
a = find(p < alpha);                %Find all significant comparisons.
hold on;                            %Hold the plot.
plot(a,repmat(max(temp),length(a)),'markerfacecolor','r','marker','*','markersize',10,'linestyle','none');  %Plot significance markers.
hold off;                           %Release the plot.
temp = get(gca,'ytick');
set(gca,'yticklabel',round(100*(temp-1)));
ylabel('Relatve Startle Amplitude (%)'); %Label the y-axis.
legend('Cued','Uncued','location','best','orientation','horizontal');   %Make a legend.

for i = 1:length(spikedata)
   	sweeplength = spikedata(1).sweeplength;                  %All sweeps will have the same sweeplength.
    cued = zeros(1,sweeplength);                        %Pre-allocate a matrix to hold the PSTH as a sum of spikecounts.
    uncued = zeros(1,sweeplength);                    	%Pre-allocate a matrix to hold the PSTH as a sum of spikecounts.
    cued_n = 0;                                     	%To find average spikerates, we'll have to keep track of the total number of sweeps.
    uncued_n = 0;                                     	%To find average spikerates, we'll have to keep track of the total number of sweeps.
    numsweeps = length(spikedata(i).sweep);      %We'll need to know the number of sweeps for plotting.
    for k = 1:numsweeps                     %Step through each sweep...
        if ~isempty(spikedata(i).sweep(k).spikes);                       %If there are any spikes in this sweep...
            temp = histc(spikedata(i).sweep(k).spikes,0:sweeplength);    %Calculate a millisecond-scale histogram for this sweep.
%             spikedata(i).sweep(k).spikes = [];               %Pare down the spikedata structure as we work through it to save memory.
            if psychdata.stim(i).predicted(k)
                cued = cued + temp(1:sweeplength);                      %Add the histogram to the pooled PSTH.
            else
                uncued = uncued + temp(1:sweeplength);                      %Add the histogram to the pooled PSTH.
            end
        end
        if psychdata.stim(i).predicted(k)
            cued_n = cued_n + 1;                    %Add a count to the total number of sweeps regardless of if there spikes.
        else
            uncued_n = uncued_n + 1;                    %Add a count to the total number of sweeps regardless of if there spikes.
        end
    end
    cued = 1000*boxsmooth(cued/cued_n,10);
    uncued = 1000*boxsmooth(uncued/uncued_n,10);
    subplot(numbackgrounds+1,1,i+1);
    plot([uncued',cued'],'linewidth',2);
    axis tight;
    xlim([psychdata.predictor_delay - 50, psychdata.startler_delay + 50]);
    temp = max([cued(psychdata.predictor_delay-50:psychdata.startler_delay-10),...
        uncued(psychdata.predictor_delay-50:psychdata.startler_delay-10)]);
    ylim([min(get(gca,'ylim')),temp]);
    set(gca,'xtick',psychdata.startler_delay+(-100:50:100)-5,'xticklabel',-100:50:100);
    temp = get(gca,'ylim');
    ylim(temp + 0.05*range(temp)*[-1,1]);
    line(psychdata.predictor_delay*[1,1]-5,get(gca,'ylim'),'color','b','linestyle',':','linewidth',2);
    line(psychdata.predictor_delay*[1,1]-5+psychdata.param(1).value(i),get(gca,'ylim'),'color','b','linestyle',':','linewidth',2);
    line(psychdata.startler_delay*[1,1]-5,get(gca,'ylim'),'color','r','linestyle',':','linewidth',2);
    line(psychdata.startler_delay*[1,1]-5+psychdata.param(5).value(i),get(gca,'ylim'),'color','r','linestyle',':','linewidth',2);
    ylabel('spikerate (spks/s)');       %Label the y-axis.
    xlabel('sweep time (ms)');          %Label the x-axis.
    title([num2str(psychdata.param(2).value(i)) ' kHz']);
end
