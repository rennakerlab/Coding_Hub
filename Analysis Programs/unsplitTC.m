function unsplitTC

[file path] = uigetfile('*.f32');
cd(path);
files = dir('*.f32');

tempfile = file(1:(length(file)-6));

temp = [];
counter = 0;

for i = 1:length(files);
    if files(i).name(1:length(tempfile)) == tempfile;
        if counter == 0;
            data = spikedataf(files(i).name);
            temp = data;
            counter = 1;
            delete(files(i).name);
        else
            data = spikedataf(files(i).name);
            counter = counter + 1;
            for j = 1:length(temp);
                if ~isempty(data(j).sweep);
                    temp(j).sweep(counter).spikes = data(j).sweep(1).spikes;
                end
            end
            delete(files(i).name);
        end
    end
end

f32data = [];
for j = 1:length(temp);
    f32data=[f32data; -2; temp(j).sweeplength; length(temp(j).stim); temp(j).stim];
    for k = 1:length(temp(j).sweep);
        f32data = [f32data; -1];
        f32data = [f32data; temp(j).sweep(k).spikes'];
    end
end

temp = [tempfile '_unsplit.f32'];
fpnt = fopen(temp, 'wb');  
fwrite(fpnt,f32data,'float32');
fclose(fpnt);