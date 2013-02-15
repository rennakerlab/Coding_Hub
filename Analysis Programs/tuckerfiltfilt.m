function fy=tuckerfilter(x, y, plotter)
% Tim Tucker Filter
%cd C:\TDT\SigGenRP\SigCalRP
%load cal401221with15dBPA4.nrm
%fy=tuckerfilter(cal401221with15dBPA4, randn(10000, 1)/5);

ntaps=255*4;  %bigger is better
if exist('plotter'), subplot(4, 1, 1), loglog(x(:, 1), x(:, 2)), xlabel('frequency'), ylabel('Intensity in dB'), end
m = x(:,2)/2;
%m=10.^(m/20);
%m=sqrt(m);
%m=log10(m)*20;


%m=sqrt(m);
m(length(m)+1) = m(length(m));
%m(128)= m(127)
f = x(:,1);
f(length(m)) = 50000; %f(length(m)+1) = 50000;
%f(128) = 50000
ff=f/max(f);
l = 10.0.^(m./20);
%l(128)=l(127)
%loglog(f, l)

im = fir2(ntaps, ff, l);
im = im';
if exist('plotter'), subplot(4, 1, 2), plot(im), end
%save im.txt im -ascii -double  
%We were not able to figure out how to save a file that RPVDS could open
%y=randn(10000, 1)/5;
%fy = filter(im, 1, y);
fy = filtfilt(im, 1, y);
if exist('plotter'), subplot(4, 1, 3), powerspectrumplot(fy, y); xlabel('frequency'), ylabel('Intensity in dB'), end

if exist('plotter'), subplot(4, 1, 4), [m, f]=powerspectrumplot(fy), end

%plot(20*log10(abs(fft(fx)))) 


%%%%%%
% plot(20*log10(abs(fft(im))))
% m2 = 20*log10(abs(fft(im)))
% whos
% m1 = m2(1:32)
% plot(m1)

















