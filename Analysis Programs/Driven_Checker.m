function Driven_Checker

alpha = 0.05

NumFiles = length(dir('*.f32'));
Files = dir('*.f32');

for currentFile = 1:NumFiles;
    data = spikedataf(Files(currentFile).name);
    NumReps = length(data(1).sweep);
    NumFreq = length([data(:).stim]);
    temp = zeros(NumFreq*NumReps,data(1).sweeplength);
    for i = 1:NumFreq;
        for j = 1:NumReps;
            try;
                temp(NumFreq*(i-1)+j,:) = histc(data(i).sweep(j).spikes,[1:data(i).sweeplength]);
            catch;
                temp(NumFreq*(i-1)+j,:) = zeros(1,data(i).sweeplength);
            end;
        end;
    end;
    Spont = 1000*mean(temp(:,1:30),2);
    Driven = 1000*mean(temp(:,45:75),2);
    Files(currentFile).Driven = ttest2(Spont, Driven, alpha);
    figure(1);
    plot(mean(temp/0.001));
    figure(1).name = Files(currentFile).name
    if Files(currentFile).Driven == 1
        title('Driven');
    else
        title('Undriven')
    end
    xlabel('time (ms)');
    ylabel('response rate (spikes/s)')
    line([0 0],[0,max(mean(temp/0.001))],'Color',[0 0 1],'LineStyle','--');
    line([30 30],[0,max(mean(temp/0.001))],'Color',[0 0 1],'LineStyle','--');
    line([45 45],[0,max(mean(temp/0.001))],'Color',[1 0 0],'LineStyle','--');
    line([75 75],[0,max(mean(temp/0.001))],'Color',[1 0 0],'LineStyle','--');
    pause(1);
    close(1);
end;

csvwrite('Driven_Checker.txt',[Files(:).name Files(:).Driven])

end