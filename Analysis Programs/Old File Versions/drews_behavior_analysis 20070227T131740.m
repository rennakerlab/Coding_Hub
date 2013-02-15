function drews_behavior_analysis(ratname)

datapath = 'F:\Pitch Discrimination\Behavior Data';
cd(datapath);
load('pitch_discrimination_data');

numfreq = 20;                   %The number of reference frequencies we'll use.
lower_freq_bound = 2000;        %Lower frequency bound, in Hertz.
upper_freq_bound = 32000;       %Upper frequency bound, in Hertz.
standard_frequency_set = pow2(log2(lower_freq_bound):((log2(upper_freq_bound)-log2(lower_freq_bound))/(numfreq-1)):log2(upper_freq_bound));
delta_f_step = ((log2(upper_freq_bound)-log2(lower_freq_bound))/(numfreq-1))/15;

for stage = [4,8];
    upper_thresholds = [];
    lower_thresholds = [];
    for rat = 1:length(behav)
        a = find([behav(rat).session(:).stage] == stage & [behav(rat).session(:).mk801_dose] == 0);
        if ~isempty(a)
            temp = [];
            for i = a       
                temp = [temp; fix(behav(rat).session(i).ref_freq), fix(behav(rat).session(i).tar_freq),...
                    sum([behav(rat).session(i).outcome == 'H', behav(rat).session(i).outcome == 'M',...
                    behav(rat).session(i).outcome == 'F', behav(rat).session(i).outcome == 'C'],2)];
            end
            temp = temp(find(temp(:,3) ~= 0),:);    %We'll remove all abort trials.
            temp = sortrows(temp);                  %We'll sort the trials according to reference frequency.
            [temp, m, n] = unique(temp,'rows');
            for i = 1:length(temp);
                m(i) = length(find(i == n));
            end
            %if min(m) >= 10
                upper = [];
                lower = [];
                for freq = 1:length(standard_frequency_set)
                    previous_performance = [];
                    a = find([behav(rat).session(:).stage] == stage & [behav(rat).session(:).mk801_dose] == 0);
                    for i = a
                        for j = 1:length(behav(rat).session(i).ref_freq)
                            if round(behav(rat).session(i).ref_freq(j)) == round(standard_frequency_set(freq)) & ~any(behav(rat).session(i).outcome(j) == 'AT')
                                if isempty(previous_performance)
                                    previous_performance = [behav(rat).session(i).delta_f(j), ...
                                        (behav(rat).session(i).nosepoke_response(j) < 0.6), 1];                        
                                else
                                    b = find(behav(rat).session(i).delta_f(j) == previous_performance(:,1));
                                    if isempty(b)
                                        previous_performance = [previous_performance; behav(rat).session(i).delta_f(j), ...
                                            (behav(rat).session(i).nosepoke_response(j) < 0.6), 1]; 
                                    else
                                        previous_performance(b,:) = [behav(rat).session(i).delta_f(j), ...
                                            previous_performance(b,2) + (behav(rat).session(i).nosepoke_response(j) < 0.6), ...
                                            previous_performance(b,3) + 1];
                                    end                            
                                end
                            end
                        end
                    end
                    if ~isempty(previous_performance)
                        previous_performance = sortrows(previous_performance,1);
                        curve = previous_performance(:,2)./previous_performance(:,3);
                        max_hit = max(curve);
                        false_alarm = curve(11);
                        cutoff = (max_hit + false_alarm)/2;
                        figure(1); cla;
                        set(1,'position',[220   188   844   480]);
                        plot([-10:10],curve,'linewidth',2,'color','b');
                        xlim([-11,11]);
                        line(get(gca,'xlim'),[cutoff, cutoff],'color','g','linestyle',':','linewidth',2);
                        temp = curve(11:-1:1);
                        a = min(intersect(find(temp >= cutoff) - 1, find(temp < cutoff)));
                        if ~isempty(a) & a < 11
                            b = (a)+(cutoff-temp(a))/(temp(a+1)-temp(a))-1;
                            lower = [lower, -b];
                            line([-b, -b], get(gca,'ylim'),'color','r','linestyle','--','linewidth',2);
                        else
                            lower = [lower, NaN];                   
                        end
                        temp = curve(11:21);
                        a = min(intersect(find(temp >= cutoff) - 1, find(temp < cutoff)));
                        if ~isempty(a) & a < 11
                            b = (a)+(cutoff-temp(a))/(temp(a+1)-temp(a))-1;
                            upper = [upper, b];
                            line([b, b], get(gca,'ylim'),'color','r','linestyle','--','linewidth',2);
                        else
                            upper = [upper, NaN];                   
                        end
                        set(gca,'xtick',[-10:2:10],'ytick',[0:0.2:1],'yticklabel',[0:20:100],'fontweight','bold','fontsize',12);
                        xlabel('\Delta\itf \rm(%)', 'fontweight','bold','fontsize',14);
                        ylabel('Hits (%)', 'fontweight','bold','fontsize',14);
                        title([behav(rat).ratname ' - ' num2str(round(standard_frequency_set(freq))) ' Hz'],'fontweight','bold','fontsize',16);
                        pause(0.1);
                    end
                end
                upper_thresholds = [upper_thresholds; upper];
                lower_thresholds = [lower_thresholds; lower];
            %end
        end
    end
    figure(2);
    subplot(2,1,1);
    hold on;
    clear p a;
    for i = 1:size(upper_thresholds,2)
        temp = upper_thresholds(~isnan(upper_thresholds(:,i)),i);
        p(i) = mean(temp);
        [h,b,temp] = ttest(temp,0,0.05);
        a(i) = temp(2) - p(i);
    end
    if stage == 4
        errorbar(p',a','color','k','linewidth',2);
    else
        errorbar(p',a','color',[0 0.5 0],'linewidth',2);
    end
    clear p a;
    for i = 1:size(lower_thresholds,2)
        temp = lower_thresholds(~isnan(lower_thresholds(:,i)),i);
        p(i) = mean(temp);
        [h,b,temp] = ttest(temp,0,0.05);
        a(i) = temp(2) - p(i);
    end
    if stage == 4
        errorbar(p',a','color','k','linewidth',2);
    else
        errorbar(p',a','color',[0 0.5 0],'linewidth',2);
    end
    set(gca,'xtick',[2:4:19],'xticklabel',round(standard_frequency_set(3:4:19)),'fontweight','bold','fontsize',12);
    ylabel('Threshold \Delta\itf \rm(%)', 'fontweight','bold','fontsize',14);
    xlabel('Reference Frequency (Hz)', 'fontweight','bold','fontsize',14);
    line(get(gca,'xlim'),[0,0],'color','k','linestyle',':','linewidth',2);
    xlim([0.5,18.5]);
    ylim([-5.2,9.1]);
end


stage = 8
for rat = 3:4
    previous_performance = [];
    a = find([behav(rat).session(:).stage] == stage & [behav(rat).session(:).mk801_dose] == 0);
    for i = a
        for j = 1:length(behav(rat).session(i).ref_freq)
            if ~any(behav(rat).session(i).outcome(j) == 'AT')
                if isempty(previous_performance)
                    previous_performance = [behav(rat).session(i).delta_f(j), ...
                        (behav(rat).session(i).nosepoke_response(j) < 0.6), 1];                        
                else
                    b = find(behav(rat).session(i).delta_f(j) == previous_performance(:,1));
                    if isempty(b)
                        previous_performance = [previous_performance; behav(rat).session(i).delta_f(j), ...
                            (behav(rat).session(i).nosepoke_response(j) < 0.6), 1]; 
                    else
                        previous_performance(b,:) = [behav(rat).session(i).delta_f(j), ...
                            previous_performance(b,2) + (behav(rat).session(i).nosepoke_response(j) < 0.6), ...
                            previous_performance(b,3) + 1];
                    end                            
                end
            end
        end
    end
    if ~isempty(previous_performance)
        previous_performance = sortrows(previous_performance,1);
        curve = previous_performance(:,2)./previous_performance(:,3);
        max_hit = max(curve);
        false_alarm = curve(11);
        cutoff = (max_hit + false_alarm)/2;
        figure(1); cla;
        set(1,'position',[220   188   844   480]);
        plot([-10:10],curve,'linewidth',2,'color','b');
        xlim([-11,11]);
        line(get(gca,'xlim'),[cutoff, cutoff],'color','g','linestyle',':','linewidth',2);
        temp = curve(11:-1:1);
        a = min(intersect(find(temp >= cutoff) - 1, find(temp < cutoff)));
        if ~isempty(a) & a < 11
            b = (a)+(cutoff-temp(a))/(temp(a+1)-temp(a))-1;
            lower = [lower, -b];
            line([-b, -b], get(gca,'ylim'),'color','r','linestyle','--','linewidth',2);
        else
            lower = [lower, NaN];                   
        end
        temp = curve(11:21);
        a = min(intersect(find(temp >= cutoff) - 1, find(temp < cutoff)));
        if ~isempty(a) & a < 11
            b = (a)+(cutoff-temp(a))/(temp(a+1)-temp(a))-1;
            upper = [upper, b];
            line([b, b], get(gca,'ylim'),'color','r','linestyle','--','linewidth',2);
        else
            upper = [upper, NaN];                   
        end
        set(gca,'xtick',[-10:2:10],'ytick',[0:0.2:1],'yticklabel',[0:20:100],'fontweight','bold','fontsize',12);
        xlabel('\Delta\itf \rm(%)', 'fontweight','bold','fontsize',14);
        ylabel('Hits (%)', 'fontweight','bold','fontsize',14);
        title([behav(rat).ratname ' - ' num2str(round(standard_frequency_set(freq))) ' Hz'],'fontweight','bold','fontsize',16);
        pause(0.1);
    end
end

%     
%     
% rat = 0;
% for i = 1:length(behav);
%     if strcmpi(ratname,behav(i).ratname);
%         rat = i; 
%     end
% end
% stages = unique([behav(rat).session(:).stage]);
% stages = sort(stages);
% for s = stages
%     a = find([behav(rat).session(:).stage] == s);
%     session_order = [];
%     for i = a
%         session_order = [session_order, behav(rat).session(i).clock_reading(1)];
%     end
%     [temp, session_order] = sort(session_order);
%     session_order = a(session_order);
%     outcomes = [];
%     clocks = [];
%     for i = session_order
%         outcomes = [outcomes; behav(rat).session(i).outcome];
%         clocks = [clocks; behav(rat).session(i).clock_reading];
%     end
%     clocks = clocks(find(outcomes ~= 'A'));
%     outcomes = outcomes(find(outcomes ~= 'A'));
%     dprimes = [];
%     if length(outcomes) >= 200
%         for i = 1:(length(outcomes)-199)
%             temp = outcomes(i:(i+199));
%             if length(find(temp == 'M')) > 0 & length(find(temp == 'H')) > 0
%                 a = length(find(temp == 'H'))/(length(find(temp == 'H')) + length(find(temp == 'M')));
%             elseif length(find(temp == 'H')) > 0 & length(find(temp == 'M')) == 0
%                 a = (length(find(temp == 'H'))-0.5)/(length(find(temp == 'H')));
%             else
%                 a = 0.0001;
%             end
%             if length(find(temp == 'F')) > 0 & length(find(temp == 'C')) > 0
%                 b = length(find(temp == 'F'))/(length(find(temp == 'F')) + length(find(temp == 'C')));
%             elseif length(find(temp == 'F')) == 0 & length(find(temp == 'C')) > 0
%                 b = 0.5/length(find(temp == 'C'));
%             else
%                 b = 0.0001;
%             end
%             dprimes = [dprimes; norminv(a) - norminv(b)];
%         end
%         figure;
%         clocks = clocks(1:(length(dprimes)));
%         plot(clocks,dprimes,'b');
%         title(['Stage ' num2str(s)]);
%     end
% end
% 
% previous_performance = [];
% if exist('behav')
%     if rat <= length(behav)
%         a = find([behav(rat).session(:).stage] == stage & [behav(rat).session(:).mk801_dose] == 0);
%         for i = a
%             for j = 1:length(behav(rat).session(i).ref_freq)
%                 if ~any(behav(rat).session(i).outcome(j) == 'AT')
%                     if isempty(previous_performance)
%                         previous_performance = [behav(rat).session(i).delta_f(j), ...
%                             (behav(rat).session(i).nosepoke_response(j) < 0.6), 1, ...
%                             (behav(rat).session(i).visited_feeder(j) == 'R'), (behav(rat).session(i).feeder_response(j) < 2)];                        
%                     else
%                         b = find(behav(rat).session(i).delta_f(j) == previous_performance(:,1));
%                         if isempty(b)
%                             previous_performance = [previous_performance; behav(rat).session(i).delta_f(j), ...
%                                 (behav(rat).session(i).nosepoke_response(j) < 0.6), 1, ...
%                                 (behav(rat).session(i).visited_feeder(j) == 'R'), (behav(rat).session(i).feeder_response(j) < 2)]; 
%                         else
%                             previous_performance(b,:) = [behav(rat).session(i).delta_f(j), ...
%                                 previous_performance(b,2) + (behav(rat).session(i).nosepoke_response(j) < 0.6), ...
%                                 previous_performance(b,3) + 1, ...
%                                 previous_performance(b,4) + (behav(rat).session(i).visited_feeder(j) == 'R'), ...
%                                 previous_performance(b,5) + (behav(rat).session(i).feeder_response(j) < 2)];
%                         end                            
%                     end
%                 end
%             end
%         end
%         if ~isempty(previous_performance)
%             previous_performance = sortrows(previous_performance,1);
%         end
%     end
% end
% hold on;
% if size(previous_performance,1) >= 3 & any(previous_performance(:,4) ~= 0)
%     [b,dev,stats] = glmfit(previous_performance(:,1), previous_performance(:,4:5), 'binomial');
%     x = (-allowable_delta_f(2) - 1):0.1:(allowable_delta_f(2) + 1);
%     [y,dlo,dhi] = glmval(b,x,'logit',stats);
%     plot(x,y,'Color','m','LineStyle','--','LineWidth',2);
%     plot(x,y-dlo,'Color','m','LineStyle',':','LineWidth',2);
%     plot(x,y+dhi,'Color','m','LineStyle',':','LineWidth',2);
%     a = y-dlo;
%     p = find(abs(a - 0.5) == min(abs(a -0.5)));
%     p = round(median(p));
%     line([x(p),x(p)],[0,a(p)],'Color','m','LineStyle',':','LineWidth',1);
%     a = y+dhi;
%     p = find(abs(a - 0.5) == min(abs(a -0.5)));
%     p = round(median(p));
%     line([x(p),x(p)],[0,a(p)],'Color','m','LineStyle',':','LineWidth',1);
% end
% clear p a;
% for i = 1:size(previous_performance,1)
%     p(i) = previous_performance(i,2)./previous_performance(i,3);
%     a(i) = 1.96*sqrt(p(i)*(1-p(i))/previous_performance(i,3));
% end
% errorbar(previous_performance(:,1),p',a','color','g','linewidth',2);
% set(gca,'XTick',[-20:5:20],'XTickLabel',[-20:5:20],'YTick',[0:0.2:1],...
%     'YTickLabel',[0:20:100],'FontWeight','Bold','FontSize',12);
% xlim([-allowable_delta_f(2) - 1, allowable_delta_f(2) + 1]);
% ylim([0,1]);
% xlabel('\Delta\it{f} \rm\bf(~%)','FontWeight','Bold','FontSize',14);
% ylabel('Nosepoke/Righthand Responses','FontWeight','Bold','FontSize',14);
% hold off;
%         
%     
%     
%     
% session_order = [];
% for i = 1:length(behav(rat).session)
%     session_order = [session_order; behav(rat).session(i).clock_reading(1)];
% end
% [temp, session_order] = sort(session_order);
% dprimes = [];
% for i = session_order'
%     temp = behav(rat).session(i).outcome;
%     if length(find(temp == 'M')) > 0 & length(find(temp == 'H')) > 0
%         a = length(find(temp == 'H'))/(length(find(temp == 'H')) + length(find(temp == 'M')));
%     elseif length(find(temp == 'H')) > 0 & length(find(temp == 'M')) == 0
%         a = (length(find(temp == 'H'))-0.5)/(length(find(temp == 'H')));
%     else
%         a = 0.0001;
%     end
%     if length(find(temp == 'F')) > 0 & length(find(temp == 'C')) > 0
%         b = length(find(temp == 'F'))/(length(find(temp == 'F')) + length(find(temp == 'C')));
%     elseif length(find(temp == 'F')) == 0 & length(find(temp == 'C')) > 0
%         b = 0.5/length(find(temp == 'C'));
%     else
%         b = 0.0001;
%     end
%     dc(1) = norminv(a) - norminv(b);
%     dc(2) = -0.5*(norminv(a) + norminv(b))/abs(dc(1));
%     dprimes = [dprimes, dc(1)];
% end
%     