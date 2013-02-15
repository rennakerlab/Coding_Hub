function Fwd_Mask_Player

cd('F:\Calibration Data');
cal = Load_Calibration;

soa = 0.005;
duration = 0.05;
hold_time = soa;
response = duration;
int = 70
atten = 0;
sample_rate = 97656.25;
ramp = 5;

%At higher freq (6000/8000/15000) tone separates into two around 55/60/65ms
%Below that sounds as one tone.

ref_freq = 8000;
tar_freq = 10000;


signal = [];
isi = soa - duration;                           %The interstimulus interval is the Stimulus-Onset-Asynchrony (SOA) minus the duration.
response = ceil(response/(duration+isi));       %Response defines the amount of time a rat has to respond to the target, adjusted to have a whole number of tones.
hold_time = ceil(hold_time/(duration+isi));     %Hold time is how long the reference is, adjusted to have a whole number of tones.
f = cal(:,1);                                   %f is a list of the frequencies used during calibration.
int = int + atten;                              %We'll calibrate for a signal 10 dB louder than it will actually be due to the PA% attenuation.
%We'll interpolate a voltage value for the reference frequency between the
%two nearest calibration frequencies.
l_freq = max(find(ref_freq > f));
h_freq = min(find(ref_freq < f));
l_volt = exp((int - cal(l_freq,2))/cal(l_freq,3));
h_volt = exp((int - cal(h_freq,2))/cal(h_freq,3));
ref_volt = (ref_freq - f(l_freq))/(f(h_freq) - f(l_freq))*(h_volt - l_volt) + l_volt;
%The calibration is repeated for the target.
l_freq = max(find(tar_freq > f));
h_freq = min(find(tar_freq < f));
l_volt = exp((int - cal(l_freq,2))/cal(l_freq,3));
h_volt = exp((int - cal(h_freq,2))/cal(h_freq,3));
tar_volt = (tar_freq - f(l_freq))/(f(h_freq) - f(l_freq))*(h_volt - l_volt) + l_volt;
num_samples = round(duration*sample_rate);         %We'll find the sample size by multiplying the duration by the sampling rate.
ramp = round(ramp*sample_rate/1000);               %The length of the cosine ramps, in samples, is found the same way.
ref = ref_volt*sin([1:num_samples]*2*pi/(sample_rate/ref_freq));    %Pure tones are just sine waves at selected frequencies, adjusted for sampling rate.
ref(1:ramp) = ref(1:ramp).*(1-cos(pi*[1:ramp]/ramp))/2;             %We'll ramp the beginning and end of the sine wave.
ref((length(ref)-ramp+1):length(ref)) = ref((length(ref)-ramp+1):length(ref)).*(1+cos(pi*[1:ramp]/ramp))/2;
tar = tar_volt*sin([1:num_samples]*2*pi/(sample_rate/tar_freq));    %The target tone is made exactly like the reference, but at a different frequency.
tar(1:ramp) = tar(1:ramp).*(1-cos(pi*[1:ramp]/ramp))/2;
tar((length(tar)-ramp+1):length(tar)) = tar((length(tar)-ramp+1):length(tar)).*(1+cos(pi*[1:ramp]/ramp))/2;
space = zeros(1,round(isi*sample_rate)); %Interstimulus intervals (ISIs) are filled with zeros.
if isempty(space)
    signal = [ref(1:round(soa*sample_rate)), (ref(round(soa*sample_rate+1):round(duration*sample_rate))' + tar(1:round(duration*sample_rate)-round(soa*sample_rate))')', tar(round(duration*sample_rate)-round(soa*sample_rate)+1:length(tar))]
else
    ref = repmat([ref,space],1,hold_time); %The reference/ISI combo is repeated to fill the hold time.
    tar = repmat([tar,space],1,response); %The target/ISI combo is repeated to fill the hold time.
    signal = [ref,tar]; %The overal signal is the reference and target put together.
    hold_time = hold_time*(duration+isi);   %The hold time is sent back adjusted to whole number multiples of the SOA.
end

wavplay(signal,sample_rate);