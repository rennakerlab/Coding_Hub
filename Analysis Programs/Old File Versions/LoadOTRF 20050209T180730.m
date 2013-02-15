function loadSTRF

[file,path] = uigetfile('*.f32')
file = [path file];

data=spikedataf(file);

trimpercent = 0.2

numreps = length(data(1).sweep);
numodors = length([data(:).stim]);
temp = [data(:).stim];
odors = temp(1,:)';
temp = zeros(numreps,data(1).sweeplength/100+1);

for i = 1:numodors;
    for j = 1:numreps;
        try;
            temp(j,:) = histc(data(i).sweep(j).spikes,[0:100:data(i).sweeplength]);
        catch;
            temp(j,:) = zeros(1,(data(i).sweeplength/100+1));
        end;
    end;
   data(i).spikerate = temp/(0.1);
end;

temp = zeros(numodors,data(1).sweeplength/100+1);
for i = 1:numodors;
    temp(i,:)=mean(data(i).spikerate);
end;
otrf.mean = temp(1:numodors, 1:50);
otrf.smooth = smoothts(otrf.mean);
otrf.psth = mean(otrf.mean);

figure(1);
surf(otrf.mean);
view(0,90);
set(gca, 'XTickLabel', [0:1000:5000], 'YTickLabel', [0:8]);
xlabel('Time [ms]');
ylabel('Odor');
title('OTRF');
colorbar;

figure(2);
surf(otrf.smooth);
view(0,90);
set(gca, 'XTickLabel', [0:1000:5000], 'YTickLabel', [0:8]);
xlabel('Time [ms]');
ylabel('Odor');
title('Smoothed OTRF');
colorbar;

figure(3);
plot(otrf.psth);
set(gca, 'XTickLabel', [0:500:5000]);
xlabel('Time [ms]');
ylabel('Spike Rate [Hz]');
title('PSTH');

end