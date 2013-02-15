function [signal, hold_time] = bandpass_noise(ref_freq, tar_freq, int, atten, duration, isi, response, ramp, cal, hold_time)

sampling_rate = 97656.25;
ramp = 5;
duration = 0.5;
ref_freq = 3000;
filter_high = 3990;          %High-pass filter cut-off.
filter_low = 4000;          %Low-pass filter cut-off.
[b,a] = butter(10,filter_low/(sampling_rate/2),'low');            %Low-Pass filter setting.
coef_low = [b,a];
[b,a] = butter(10,filter_high/(sampling_rate/2),'high');            %High-Pass filter setting.
coef_high = [b,a];
wavelength = round(duration*sampling_rate);

signal = [];
phase_offset = 0;
for i = 1:wavelength
    freq = filter_high + rand*(filter_low - filter_high);
    signal = [signal, sin(2*pi/(97656.25/freq) + phase_offset)];
    phase_offset = 2*pi/(97656.25/freq) + phase_offset;
end

signal = filter(coef_high(1),coef_high(2),signal);
signal = filter(coef_low(1),coef_low(2),signal);


wavplay(signal, sampling_rate);

spk(signal, sampling_rate);

colormap(jet);

i = sqrt(-1);
Y = [];
for j = 1:wavelength
    if j > filter_high/2 & j < filter_low/2
        a = 40*(1-2*rand);
        b = -sqrt(1600 - a^2)*i;
        temp = a + b;
        Y(j) = temp;
    else
        a = (1-2*rand);
        b = -sqrt(0.001 - a^2)*i;
        temp = a + b;
        Y(j) = temp;
    end
end
signal = ifft(Y);
signal = signal.*conj(signal);


Pyy = Y.* conj(Y);
f = 97656*(0:(sampling_rate/2))/sampling_rate;
plot(f,Pyy(1:(sampling_rate/2)));
    title('Frequency content of REF');
    xlabel('frequency (kHz)');
    set(gca,'xtick',[0:5000:50000],'xticklabel',[0:5:50]);
    
    
numfreq = 20;                   %The number of reference frequencies we'll use.
lower_freq_bound = 2000;        %Lower frequency bound, in Hertz.
upper_freq_bound = 32000;       %Upper frequency bound, in Hertz.
frequencies = pow2(log2(lower_freq_bound):((log2(upper_freq_bound)-log2(lower_freq_bound))/(numfreq-1)):log2(upper_freq_bound));
delta_f_step = ((log2(upper_freq_bound)-log2(lower_freq_bound))/(numfreq-1))/15;
    
    pow2(log2(frequencies(i)) + j*delta_f_step)
    
    bandwidth = delta_f_step
function [signal, hold_time] = bandpass_noise(ref_freq, tar_freq, int, atten, duration, isi, response, ramp, cal, hold_time)

    response = ceil(response/(duration+isi));
    hold_time = ceil(hold_time/(duration+isi));
    f = cal(:,1);
    int = int + atten;
    
    bandwidth = 200*delta_f_step;
    bandwidth = bandwidth/2;
    
    wavelength = round(duration*97656.25);
    
    ramp = 5;
    
    high_freq = pow2(log2(ref_freq) + bandwidth);
    low_freq = pow2(log2(ref_freq) - bandwidth);
    
    l_freq = max(find(ref_freq > f));
    h_freq = min(find(ref_freq < f));
    
    
    l_volt = exp((int - cal(l_freq,2))/cal(l_freq,3));
    h_volt = exp((int - cal(h_freq,2))/cal(h_freq,3));
    ref_volt = (ref_freq - f(l_freq))/(f(h_freq) - f(l_freq))*(h_volt - l_volt) + l_volt;
    
    
        
    freqs = low_freq + rand(1,wavelength)*(high_freq - low_freq);
    temp = 2*pi*[1:wavelength]./(97656.25./freqs)
    ref = ref_volt*sin(2*pi*[1:wavelength]./(97656.25./ref_freq));
        
    filter_low = 3200;
    filter_high = 2800;
    [b,a] = butter(7,filter_low/(97656.25/2),'low');
    ref = filter(b,a,ref);
    [b,a] = butter(7,filter_high/(97656.25/2),'high'); 
    ref = filter(b,a,ref);
    
    ramp = 5;
%     ref = rand(1,wavelength)-0.5;
    ramp = round(ramp*97656.25/1000);
    ref(1:ramp) = ref(1:ramp).*(1-cos(pi*[1:ramp]/ramp))/2;
    ref((length(ref)-ramp+1):length(ref)) = ref((length(ref)-ramp+1):length(ref)).*(1+cos(pi*[1:ramp]/ramp))/2;
    wavplay(ref,97656.2)
    plot(ref);
    
    ref = sin(2*pi*[1:wavelength]./(97656.25./ref_freq));
   
    Y = fft(ref, 97656);
    Pyy = Y.* conj(Y)/97656;
    f = 97656*(0:48828)/97656;
    plot(f,Pyy(1:48829));
    title('Frequency content of REF');
    xlabel('frequency (kHz)');
    set(gca,'xtick',[0:5000:50000],'xticklabel',[0:5:50]);
    
    ref = 0;
    for ref_freq = 2000:1:4000
        ref = ref + 0.01*sin(2*pi*[1:wavelength]./(97656.25./ref_freq) + rand*pi);
    end
    ref = sum(ref);
        
    l_freq = max(find(ref_freq > f));
    h_freq = min(find(ref_freq < f));
    
    
    l_volt = exp((int - cal(l_freq,2))/cal(l_freq,3));
    h_volt = exp((int - cal(h_freq,2))/cal(h_freq,3));
    ref_volt = (ref_freq - f(l_freq))/(f(h_freq) - f(l_freq))*(h_volt - l_volt) + l_volt;
    l_freq = max(find(tar_freq > f));
    h_freq = min(find(tar_freq < f));
    l_volt = exp((int - cal(l_freq,2))/cal(l_freq,3));
    h_volt = exp((int - cal(h_freq,2))/cal(h_freq,3));
    tar_volt = (tar_freq - f(l_freq))/(f(h_freq) - f(l_freq))*(h_volt - l_volt) + l_volt;
    
    
    
    ref = 0.2*((rand(1,wavelength))-0.5)
    ref(1:ramp) = ref(1:ramp).*(1-cos(pi*[1:ramp]/ramp))/2;
    ref((length(ref)-ramp+1):length(ref)) = ref((length(ref)-ramp+1):length(ref)).*(1+cos(pi*[1:ramp]/ramp))/2;
    wavplay(ref,97656.2)
    plot(ref);
    
    
    ref = ref_volt*sin([1:wavelength]*2*pi/(97656.25/ref_freq));
    ref(1:ramp) = ref(1:ramp).*(1-cos(pi*[1:ramp]/ramp))/2;
    ref((length(ref)-ramp+1):length(ref)) = ref((length(ref)-ramp+1):length(ref)).*(1+cos(pi*[1:ramp]/ramp))/2;
    space = zeros(1,round(isi*97656.25));
    ref = repmat([ref,space],1,hold_time);
    tar = tar_volt*sin([1:wavelength]*2*pi/(97656.25/tar_freq));
    tar(1:ramp) = tar(1:ramp).*(1-cos(pi*[1:ramp]/ramp))/2;
    tar((length(tar)-ramp+1):length(tar)) = tar((length(tar)-ramp+1):length(tar)).*(1+cos(pi*[1:ramp]/ramp))/2;
    space = zeros(1,round(isi*97656.25));
    tar = repmat([tar,space],1,response);
    signal = [ref, tar];
    hold_time = hold_time*(duration+isi);    
    
    
    ref = 0;
    for i = 1:3
        ref = ref+sin(2*pi*[1:wavelength]./(97656.25./(i*ref_freq)));
    end
    ref = ref/(2*max(ref));
    wavplay(ref,97656.2)
    pause(1);
    
    ref = 0;
    for i = 2:4
        ref = ref+sin(2*pi*[1:wavelength]./(97656.25./(i*ref_freq)));
    end
    ref = ref/(2*max(ref));
    wavplay(ref,97656.2)
    pause(1);
    
    ref = 0;
    for i = 3:5
        ref = ref+sin(2*pi*[1:wavelength]./(97656.25./(i*ref_freq)));
    end
    ref = ref/(2*max(ref));
    wavplay(ref,97656.2)
    pause(1);
    
    ref = 0;
    for i = 4:6
        ref = ref+sin(2*pi*[1:wavelength]./(97656.25./(i*ref_freq)));
    end
    ref = ref/(2*max(ref));
    wavplay(ref,97656.2)
    pause(1);
    
    ref = 0;
    for i = 5:7
        ref = ref+sin(2*pi*[1:wavelength]./(97656.25./(i*ref_freq)));
    end
    ref = ref/(2*max(ref));
    wavplay(ref,97656.2)
    pause(1);
    
    ref = 0;
    for i = 6:8
        ref = ref+sin(2*pi*[1:wavelength]./(97656.25./(i*ref_freq)));
    end
    ref = ref/(2*max(ref));
    wavplay(ref,97656.2)
    pause(1);
    
    ref = 0;
    for i = 7:9
        ref = ref+sin(2*pi*[1:wavelength]./(97656.25./(i*ref_freq)));
    end
    ref = ref/(2*max(ref));
    wavplay(ref,97656.2)
    pause(1);
    
    ref = 0;
    for i = 8:10
        ref = ref+sin(2*pi*[1:wavelength]./(97656.25./(i*ref_freq)));
    end
    ref = ref/(2*max(ref));
    wavplay(ref,97656.2)
    pause(1);
    
    
    
    
    
end