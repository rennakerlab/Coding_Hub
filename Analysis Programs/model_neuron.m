function sample = model_neuron

[file path] = uigetfile('*f32');
cd(path);
files = dir('*.f32');
numfiles = length([files.bytes]);

warning off MATLAB:divideByZero;

TrimPercent = 0.2;

for i = -19:19;
    for j = 1:200
        neuron(20+i).bin(j).values = [];
    end;
end;

for currentfile = 1:numfiles;
    if files(currentfile).name(1,5:9)=='IsoTC' | files(i).name(1,6:10)=='IsoTC';
        data = spikedataf(files(currentfile).name);
        NumReps = length(data(1).sweep);
        NumFreq = length([data(:).stim]);
        temp = [data(:).stim];
        Frequencies = temp(1,:)';
        temp = [];
        for i = 1:NumFreq;
            for j = 1:NumReps;
                try;
                    temp(j,:) = histc(data(i).sweep(j).spikes,[0:data(i).sweeplength]);
                catch;
                    temp(j,:) = zeros(1,data(i).sweeplength+1);
                end;
            end;
            data(i).spikerate = temp(:,1:data(i).sweeplength)/(0.001);
        end;
        spont = [];
        for i = 1:NumFreq;
            spont = [spont, mean(data(i).spikerate(:,1:30)')];
        end;
        spont = spont';
        driven = [];
        for i = 1:NumFreq;
            driven = [driven, mean(data(i).spikerate(:,45:75)')];
        end;
        driven = driven';
        if ttest2(spont,driven)==1;
            strf = zeros(NumFreq,data(1).sweeplength);
            for i = 1:NumFreq;
                strf(i,:)=mean(data(i).spikerate);
            end;
            strf = strf - mean(mean(strf(:,1:30))');
            strf_ci = zeros(NumFreq,data(1).sweeplength);
            for i = 1:NumFreq;
                for j = 1:data(i).sweeplength
                    [h, sig, ci]=ttest(data(i).spikerate(:,j),0,0.05);
                    strf_ci(i,j)=ci(1,1);
                end;
            end;
            figure(1);
            surf(smoothts(smoothts(strf_ci)')');
            view(0,90);
            pause(1);
            C = max(strf_ci');
            [C bf] = max(C');
            C = max(max(strf)');
            strf = strf/C;
            for i = 1:NumFreq;
                for j = 1:data(i).sweeplength;
                    neuron(20-bf+i).bin(j).values = [neuron(20-bf+i).bin(j).values; strf(i,j)];
                end;
            end;
        end
        clear data;
    end
end

sample = neuron
save neuron;

model_strf = zeros(39,200);
model_sig = zeros(39,200);
for i = 1:39
    for j = 1:200
        model_strf(i,j)=mean(neuron(i).bin(j).values);
        if mean(neuron(i).bin(j).values) >0;
            model_sig(i,j)=ttest(neuron(i).bin(j).values,0,0.001);
        else
            model_sig(i,j)=-ttest(neuron(i).bin(j).values,0,0.001);
        end
    end
end

figure(1);
surf(model_strf);
view(0,90);
figure(2);
contour(model_strf);
figure(3);
contour(model_sig);
view(0,90);
