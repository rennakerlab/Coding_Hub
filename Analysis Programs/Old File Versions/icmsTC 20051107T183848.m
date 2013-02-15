function icmsTC

%Load the first *.f32 file
[file1,path] = uigetfile('*.f32', 'Load the First Tuning Curve.');
cd(path);
temp = [file1(1:3) '*.f32'];
file2 = uigetfile(temp, 'Load the Second Tuning Curve');

data1 = spikedataf(file1);
data2 = spikedataf(file2);

numreps = length(data1(1).sweep);

freqs = [];
ints = [];
for i = 1:length(data1);
    if isempty(find(freqs==data1(i).stim(1)));
        freqs = [freqs; data1(i).stim(1)];
    end
    if isempty(find(ints==data1(i).stim(2)));
        ints = [ints; data1(i).stim(2)];
    end
end
numfreq = length(freqs);
numint = length(ints);


for i = 1:length(data1);
    x = find(data1(i).stim(1)==freqs);
    y = find(data1(i).stim(2)==ints);
    temp1 = [];
    for r = 1:numreps;
        try;
            temp2 = histc(data1(i).sweep(r).spikes,[0:1:data1(i).sweeplength]);
        catch;
            temp2 = zeros(1,data1(i).sweeplength + 1);
        end;
        temp1 = [temp1; temp2];
    end
    data1(i).spikerate = temp1/0.001;
end
