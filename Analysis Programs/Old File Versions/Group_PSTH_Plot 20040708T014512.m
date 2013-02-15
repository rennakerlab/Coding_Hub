function  [PSTH]=Group_PSTH_Plot(PSTH,SpDelay,NClicks,Bins,isi,Catch)
figure;
hold on;
Bins=round(Bins);
Step=6;
for i=1:25
    Height=ones(1,Bins)*((i-1)*Step)+.1;
    y=hist(PSTH(i).AllSpikes,Bins)-(PSTH(Catch).SponCI/35);
    PSTH(Catch).Sig(i).Spikes=sum(y);
    y(find(y<0))=0;
    y=y/130;
    x=1:1:Bins;
    plot(x,y+Height,'LineWidth',1);
    if (NClicks*isi(i)+SpDelay)>Bins
        ClickCount=(Bins-SpDelay)/(isi(i));
    else
        ClickCount=NClicks;
    end    
    ToneX=SpDelay:isi(i):isi(i)*ClickCount;
    ToneY=Height(1:length(ToneX))-.25;
    for j=1:length(ToneX),
        plot([ToneX(j),ToneX(j)+3],[ToneY(j),ToneY(j)], 'r','linewidth', 3);    
        
    end
end

rates=round(1000./isi);

set(gca, 'ylim', [0 Step*25], 'ytick', [.1:Step:Step*25]);
set(gca,'YTickLabel',rates);
xlabel('Time (ms)','fontsize',14);
title('PSTH','fontsize',14);
ylabel('Repetition Rate (Hz.)','fontsize',14);
axis([0,500,-1,155]);

saveas(gcf,['Group_PSTH ',num2str(Catch)],'tif');