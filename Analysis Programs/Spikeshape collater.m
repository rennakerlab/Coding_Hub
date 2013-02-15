temp = [data.stim];
numstim = length(temp(1,:));
temp = [data.sweep];
numsweeps = length(temp)/numstim;

spikeshapes = [];

for i = 1:numstim;
    for j = 1:numsweeps;
        spikeshapes = [spikeshapes data(i).sweep(j).shapes];
    end;
end;

%Right here the spikeshapes matrix has one waveform per column, so to
%switch to one waveform per row do the following, but beware, if you want
%to plot the waveforms you need to switch it back to columns.

spikeshapes = spikeshapes;