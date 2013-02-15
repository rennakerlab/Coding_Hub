% sp: create gray-scale spectrogram 
% Usage: h=sp(wave,rate,nfft,nsampf,nhop,pre,drng,title,ngray,clr);
% wave: input waveform
% rate: sample rate in Hz (default 8000 Hz)
% nfft: FFT window length (default: 256 samples)
% nsampf: number of samples per frame (default: 60)
% nhop: number of samples to hop to next frame
%           (default: 5 samples)
% pre: preemphasis factor (0-1) (default: 1)
% drng: dynamic range in dB (default: 80)
% title: title for graph (default: none)
% ngray: number of gray levels for colormap (default 48) 
% clr: clearscreen flag; if set to 1, clear figure window (default 1) 
% h: axes handles

% Peter Assmann - Oct 20, 1992/ Modified for Matlab 5.0 [PA, 6-15-97]
function h=spk(wave,rate,nfft,nsampf,nhop,pre,drng,string,ngray,clr);
if ~exist('rate','var'), rate=8000; end;
if ~exist('nfft','var'), nfft=256; end;
if ~exist('nsampf','var'), nsampf=60; end;
if ~exist('nhop','var'), nhop=5; end;
if ~exist('pre','var'), pre=1; end;
if ~exist('drng','var'), drng=80; end;
if ~exist('string','var'), string=''; end;
if ~exist('ngray','var'), ngray=64; end;
if ~exist('clr','var'), clr=1; end;
[n,m]=size(wave);
if n==1 && m>1
    wave=wave'; 
    n=m; 
end; % want row vector
w=(wave(1:n))/3276.8;
ms=n/rate*1000;
t=1:n;
t=t'/(rate/1000);
plotflag=0;
b=20.*log10(fftpsd(w,rate,nfft,nsampf,nhop,pre,plotflag)+eps)';
if clr, clf reset; end;
h(2)=axes('Position',[0.13 0.11 0.775 0.65]);
maxb=max(max(b));
b=(b-maxb)+drng;
i=find(b<0); b(i)=zeros(size(i))+eps;
imagesc([0 max(t)],[0 rate/2],b,'EraseMode','normal');
colormap(1-summer(ngray).*copper(ngray));
axis manual on xy;
xlabel('Time (ms)');
ylabel('Frequency (kHz)');
%set(h(2),'XLim',[0 max(t)],'YLim',[0 rate/2],'FontSize',16,...
% 'TickLength',[0.01 0.25],'TickDir','Out','Box','On','XGrid','Off',...
% 'YTick',0:100:rate/2,'XMinorTick','Off','XMinorGrid','Off',...
% 'TickDir','Out','YTickLabel',sprintf('%1.0f||||||||||',0:rate/2000));

%for i=0:rate/2000,
% line([0 max(t)],[i*1000 i*1000],'Color','k','LineStyle',':');
%end;

h(1)=axes('pos',[0.13 0.8 0.775 0.15],...
  'Vis','Off');
%wp(wave,length(wave),rate,string);
%set(h(1),'XLim',[0 ms],'FontSize',14);
hold on, plot(wave)
xlim([0,length(wave)]);
axis off;
font(15); 
set(get(h(1),'title'),'VerticalAlignment','middle');
colormap (hot.*copper)
brighten(.5)