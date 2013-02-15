function spectrogram

[file path] = uigetfile('*.wav');
cd(path);

[signal,rate] = wavread([path file]);
wavplay(signal,rate);

spk(signal, rate);

colormap(jet);

colormap(flipud(gray));