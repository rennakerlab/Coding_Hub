function BandPassNoise

duration = 0.5;

sampling_rate = 97656;

t = 0:(1/sampling_rate):duration;

x = zeros(1, length(t));
for j=1:length(t)
    x(j) = -1 + rand*2;
end

hf = 5000/(sampling_rate/2);
lf = 6000/(sampling_rate/2);

%design the highpass filter
[bh,ah] = butter(10,hf,'high');
%design the lowpass filter
[bl,al] = butter(10,lf,'low');
%filter the data
signal = filter(bh,ah,x);
signal = filter(bl,al,signal);
wavplay(signal, sampling_rate);

spk(signal, sampling_rate);

colormap(jet);


Y = fft(signal, sampling_rate);
for j = 2:length(Y)
    if j < 2000 & j > 3000
        Y(j) = 0.1 - 0.1i;
    else
        Y(j) = -40 + 4i;
    end
end
Pyy = Y.* conj(Y);
f = 97656*(0:(sampling_rate/2))/sampling_rate;
plot(f,Pyy(1:(1+sampling_rate/2)));
    title('Frequency content of REF');
    xlabel('frequency (kHz)');
    set(gca,'xtick',[0:5000:50000],'xticklabel',[0:5:50]);
    
    

[signal,rate] = wavread([path file]);
wavplay(signal,rate);

Y = fft(signal, 340);
Pyy = Y.*conj(Y)/340;
f = 25000*(0:340/2)/340;
plot(f, Pyy(1:(340/2)+1));

[file path] = uigetfile('*.wav');
cd(path);

colormap(flipud(gray));

Y = fft(r, 340);
Pyy = Y.*conj(Y)/340;
f = 25000*(0:340/2)/340;
plot(f, Pyy(1:(340/2)+1));

[file path] = uigetfile('*.wav');
cd(path);
