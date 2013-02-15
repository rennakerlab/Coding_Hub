
cla, hold on,
errorbar([mean(uncuedresponses) mean(cuedresponses)], [std(uncuedresponses) std(cuedresponses)]);
[h,p,ci] = ttest(uncuedresponses',0,0.05);
temp(1) = mean(uncuedresponses) - ci(1);
[h,p,ci] = ttest(cuedresponses',0,0.05);
temp(2) = mean(uncuedresponses) - ci(1);
eb=errorbar([mean(uncuedresponses) mean(cuedresponses)], temp);
set(eb, 'color', 'r', 'linewidth', 2), %yl=get(gca, 'ylim'); set(gca, 'ylim', [0 yl(2)])
if exist('exp_name'), title([ratname ' ' exp_name ]), else title(ratname), end
if length(cuedresponses)>1 & length(uncuedresponses)>1
    [h_unpaired, p_unpaired]=ttest2(cuedresponses, uncuedresponses);
    min_len=min([length(cuedresponses) length(uncuedresponses)]);
    [h_paired, p_paired]=ttest(cuedresponses(1:min_len)-uncuedresponses(1:min_len));
    if h_paired |  h_unpaired
        plot(2, mean(cuedresponses)+(std(cuedresponses)*1), 'r*', 'markersize', 12)
    end
    if exist('exp_name')
        title([ratname ' ' exp_name ' unpaired-pvalue=' num2str(p_unpaired, 2) ' paired-pvalue=' num2str(p_paired, 2)])
    else 
        title([ratname  ' unpaired-pvalue=' num2str(p_unpaired, 2) ' paired-pvalue=' num2str(p_paired, 2)])
    end
end
ylabel('response'), set(gca, 'xtick', [1 2], 'xticklabel', {'Uncued', 'Cued'})
if length(cuefilelist)-length(backgroundfilelist)>1
    shortlist={'Uncued', 'Cued'};
    for c=1:length(cuefilelist)
        %strmatch(char(cuefilelist(c)), noisesounds)
        dd=datastore(strmatch(char(cuefilelist(c)), noisesounds), 3);
        summary(c, :)=[mean(dd) se(dd) std(dd)];
        %errorbar(mean)
        cc=char(cuefilelist(c));  dd=max([findstr(cc, '\') 0])+1; cc=cc(dd:length(cc)-4);
        shortlist=[shortlist {cc}];
    end
    a=1:length(backgroundfilelist); ebb=errorbar(a+2, summary(a, 1), summary(a, 2));
    a=length(backgroundfilelist)+1:length(cuefilelist); ebc=errorbar(a+2, summary(a, 1), summary(a, 2));
    set(gca, 'xtick', 1:length(shortlist), 'xticklabel', shortlist, 'xlim', [.5 length(shortlist)+.5])
set(ebb, 'color', 'k', 'linewidth', 2), set(ebc, 'color', 'g', 'linewidth', 2)
end
disp([num2str(totalsounds) ' Total Sounds, ' num2str(n) ' Total Startles, '  num2str(length(cuedresponses)) ' Good Cues, ' num2str(length(uncuedresponses)) ' Good Uncued' ])
if length(cuefilelist)>5, set(gca, 'fontsize', 8), end
set(gca, 'ygrid', 'on')