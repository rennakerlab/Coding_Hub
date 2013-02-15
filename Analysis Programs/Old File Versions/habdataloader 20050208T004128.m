function habdataloader

prefile = uigetfile('*.f32','Load Pre File');
habfile = uigetfile('*.f32','Load Hab File');
postfile = uigetfile('*.f32','Load Post File');

habfile
habrate = input('Habituation SPR:');

for m = 1:3;
    if m == 1
        data = spikedataf(prefile);
    elseif m ==2
        data = spikedataf(habfile);
    else
        data = spikedataf(postfile);
    end
    numreps = length(data(1).sweep);
    numfreq = length([data(:).stim]);
    temp = [data(:).stim];
    frequencies = temp(1,:)';
    temp = zeros(length(data(1).sweep),data(1).sweeplength);
    for i = 1:numfreq;
        for j = 1:numreps;
            try;
                temp(j,:) = histc(data(i).sweep(j).spikes,[1:data(i).sweeplength]);
            catch;
                temp(j,:) = zeros(1,data(i).sweeplength);
            end;
        end;
        data(i).spikerate = temp/(0.001);
    end;
    if m == 1
        predata = data
    elseif m ==2
        habdata = data
    else
        postdata = data
    end
end
