function wav_converter

[file path] = uigetfile('*.wav');
cd(path);
[data,Fs,bits] = wavread(file);
stretch = round(50000/Fs);
newdata = [];

if max(data) > 0.5;
    data = data*(0.5/(max(data)));
end

for i = 1:(length(data)-1);
    ychange = (data(i+1) - data(i))/stretch;
    for j = 0:(stretch-1);
        newdata = [newdata; (data(i) + j*ychange)];
    end
end

wavwrite(newdata, 50000, file);

wavplay(data,50000);
pause(0.5);
wavplay(newdata,50000);

clear all;

