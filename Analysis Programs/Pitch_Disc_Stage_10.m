%-----------------------------------------------
%---Sets Path  ---
%-----------------------------------------------
ratname = 'Cannonball';
datapath = 'F:\Pitch Discrimination\Behavior Data';
cd(datapath);
load('pitch_discrimination_data');
rat = 0;
for i = 1:length(behav);
    if strcmpi(ratname,behav(i).ratname);
        rat = i; 
    end
end

        
        
%---------------------------------
%---  ---
%---------------------------------
low_thr = [];
up_thr = [];
for ref_freq = [4000 9000 18000]
    for intensity = [-15 -10 -5 0 5 10 15]
    previous_performance = [];
    dprimes = [];
        a = find([behav(rat).session(:).stage] == 10 & [behav(rat).session(:).mk801_dose] == 0 & [behav(rat).session(:).daycode] > 53);
        for i = a
            for j = 1:behav(rat).session(i).trials
                if ~any(behav(rat).session(i).outcome(j) == 'AT') & behav(rat).session(i).duration(j) == .2...
                        & roundn(behav(rat).session(i).ref_freq(j),3) == ref_freq & behav(rat).session(i).intensity(j) == intensity;
                    if isempty(previous_performance)
                        previous_performance = [behav(rat).session(i).delta_f(j), ...
                            (behav(rat).session(i).nosepoke_response(j) < 0.6), 1];   
                        dprimes = [dprimes; ref_freq intensity behav(rat).session(i).delta_f(j)];
                    else
                        b = find(behav(rat).session(i).delta_f(j) == previous_performance(:,1));
                        if isempty(b)
                            previous_performance = [previous_performance; behav(rat).session(i).delta_f(j), ...
                                (behav(rat).session(i).nosepoke_response(j) < 0.6), 1];
                            dprimes = [dprimes; ref_freq intensity behav(rat).session(i).delta_f(j)];
                        else
                            previous_performance(b,:) = [behav(rat).session(i).delta_f(j), ...
                                previous_performance(b,2) + (behav(rat).session(i).nosepoke_response(j) < 0.6), ...
                                previous_performance(b,3) + 1];
                        end  
                    end
                end
            end            
        end
        dprimes = sortrows(dprimes);
        if ~isempty(previous_performance)
            previous_performance = sortrows(previous_performance,1);
        end
        
        
        %------------------------------------------------------
        %---Creates 4th column in PP Matrix to act as a 
        %------'smoothed' number of hits----------------
        %------------------------------------------------------
        for i = 1
            previous_performance(i,4) = mean(previous_performance(i:i + 1,2));
            previous_performance(i,5) = mean(previous_performance(i:i + 1,3));
        end
        for i = 2:14
            previous_performance(i,4) = mean(previous_performance(i - 1:i + 1,2));
            previous_performance(i,5) = mean(previous_performance(i - 1:i + 1,3));
        end
        for i = 15
            previous_performance(i,4) = mean(previous_performance(i - 1:i,2));
            previous_performance(i,5) = mean(previous_performance(i - 1:i,3));
        end
        for i = 16
            previous_performance(i,4) = (previous_performance(i,2));
            previous_performance(i,5) = (previous_performance(i,3));
        end
        for i = 17
            previous_performance(i,4) = mean(previous_performance(i:i + 1,2));
            previous_performance(i,5) = mean(previous_performance(i:i + 1,3));
        end
        for i = 18:30
            previous_performance(i,4) = mean(previous_performance(i - 1:i + 1,2));
            previous_performance(i,5) = mean(previous_performance(i - 1:i + 1,3));
        end
        for i = 31
            previous_performance(i,4) = mean(previous_performance(i - 1:i,2));
            previous_performance(i,5) = mean(previous_performance(i - 1:i,3));
        end
        
        %------------------------------------------------------
        %---Creates Delta f vs. Percent Correct Graphs per each
        %---intensity/reference frequency combo----------------
        %------------------------------------------------------
        figure;
        hold on;
        for i = 1:size(previous_performance,1)
            p(i) = sum(previous_performance(i,2))/sum(previous_performance(i,3));       %Calcs hit percent, %change back to (i,2),(i,3) to use non-smoothed data, (i,5),(i,4) for smoothed
            a(i) = 1.96*sqrt(p(i)*(1-p(i))/previous_performance(i,3));          %Calcs confidence intervals, change to (i,3) for non-smoothes, (1,5) for smoothed
        end
        errorbar(previous_performance(:,1),p',a','color','g','linewidth',2);
        set(gca,'XTick',[-20:5:20],'XTickLabel',[-20:5:20],'YTick',[0:0.2:1],...
            'YTickLabel',[0:20:100],'FontWeight','Bold','FontSize',12);
        if ref_freq == 4000
            rf = '4.1 kHz';
        elseif ref_freq == 9000
            rf = '8.6 kHz';
        else ref_freq == 4000
            rf = '17.8 kHz';
        end
        int = [' at ' num2str(intensity) ' dB'];
        title([rf int],'FontWeight','Bold','FontSize',14)
        xlim([-16, 16]);
        ylim([0,1]);
        xlabel('\Delta\it{f} \rm\bf(~%)','FontWeight','Bold','FontSize',14);
        ylabel('Nosepoke Responses','FontWeight','Bold','FontSize',14);

        %-------------------------------------------
        %---Calculates D-Prime Values---------------
        %-------------------------------------------
        if any(previous_performance(:,1) == 0) & size(previous_performance,1) > 3
            temp = previous_performance(find(previous_performance(:,1) == 0),:);
            F = temp(2);
            C = temp(3) - temp(2);
            for i = 1:size(previous_performance,1)
                if previous_performance(i,1) ~= 0
                    H = previous_performance(i,2);    %change back to (i,2) to use non-smoothed data, (i,4) for smoothed data
                    M = previous_performance(i,3) - previous_performance(i,2);    %change back to (i,3),(i,2) to use non-smoothed data, (i,5),(i,4) for smoothed
                    if M > 0 & H > 0
                        a = H/(H + M);
                    elseif H > 0 & M == 0
                        a = (H-0.5)/(H);
                    else
                        a = 0.0001;
                    end
                    if F > 0 & C > 0
                        b = F/(F + C);
                    elseif F == 0 & C > 0
                        b = 0.5/C;
                    else
                        b = 0.0001;
                    end
                    dc(1) = norminv(a) - norminv(b);
                    dc(2) = -0.5*(norminv(a) + norminv(b))/abs(dc(1));
%                     if dc(1) > 1.96
%                         temp(i) = p(i);
%                     else
%                         temp(i) = NaN;
%                     end
                else
                    temp(i) = NaN;
                end
                dprimes(i,4) = dc(1);
            end
%             plot(previous_performance(:,1),temp,'color',[0.7,0.7,1],'marker','o', ...   %Marks significant percent corrects on graphs
%                 'markerfacecolor',[0.7,1,0.7],'markersize',5);
        end
        %------------------------------------------------------
        %---Smooths Graph by averaging values before and after
        %------------------------------------------------------
        
        %------------------------------------------------------
        %---Creates Delta f vs. D-Primes Graphs per each
        %---intensity/reference frequency combo----------------
        %------------------------------------------------------
        figure;
        hold on;
        plot(dprimes(:,3),dprimes(:,4),'color','g','linewidth',2);
        set(gca,'XTick',[-20:5:20],'XTickLabel',[-20:5:20],'YTick',[-3:0.5:4],...
            'YTickLabel',[-3:0.5:4],'FontWeight','Bold','FontSize',12);
        if ref_freq == 4000
            rf = '4.1 kHz';
        elseif ref_freq == 9000
            rf = '8.6 kHz';
        else ref_freq == 4000
            rf = '17.8 kHz';
        end
        int = [' at ' num2str(intensity) ' dB'];
        title([rf int],'FontWeight','Bold','FontSize',14)
        xlim([-16, 16]);
        ylim([-3,4]);
        line(-16:.1:16, 1.96)
        xlabel('\Delta\it{f} \rm\bf(~%)','FontWeight','Bold','FontSize',14);
        ylabel('Nosepoke Responses(D-Primes)','FontWeight','Bold','FontSize',14);
        hold off; 
        %------------------------------------------------------------------
        %---Finds upper and lower threshold values from the d-primes matrix
        %------------------------------------------------------------------
        a = find(dprimes(:,4) > 1.96 & dprimes(:,3) < 0);
        lower_thresh = max(a);
        if ~isempty(lower_thresh)
            low_thr = [low_thr; dprimes(lower_thresh,:)];
        else
            low_thr = [low_thr; dprimes(1,1:2) nan nan];
        end        
        b = find(dprimes(:,4) > 1.96 & dprimes(:,3) > 0);
        upper_thresh = min(b);
        if ~isempty(upper_thresh)
            up_thr = [up_thr; dprimes(upper_thresh,:)];
        else
            up_thr = [up_thr; dprimes(1,1:2) nan nan];
        end
    end
end

% %------------------------------------------------
% %-----Creates Upper and Lower % Threshold Graphs---
% %------------------------------------------------
% figure
% hold on;
% x = low_thr(1:7,2);
% y = abs(low_thr(1:7,3));
% plot(x, y,'color','g','linewidth',2);
% y = abs(low_thr(8:14,3));
% plot(x, y,'color','r','linewidth',2);
% y = abs(low_thr(15:21,3));
% plot(x, y,'color','b','linewidth',2);
% set(gca,'XTick',[-15 -10 -5 0 5 10 15],'XTickLabel',[-15 -10 -5 0 5 10 15],'YTick',[0:2:14],...
%     'YTickLabel',[0:2:14],'FontWeight','Bold','FontSize',12);
% title('Lower Intesity Thresholds','FontWeight','Bold','FontSize',14)
% xlim([-16, 16]);
% ylim([0,16]);
% xlabel('Intensity (Db)','FontWeight','Bold','FontSize',14);
% ylabel('\Delta\it{f} \rm\bf Threshold (%)','FontWeight','Bold','FontSize',14);
% legend('  4.1 kHz','  8.6 kHz','17.8 kHz','Location','NorthEast');
% 
% 
% figure
% hold on;
% x = up_thr(1:7,2);
% y = abs(up_thr(1:7,3));
% plot(x, y,'color','g','linewidth',2);
% y = abs(up_thr(8:14,3));
% plot(x, y,'color','r','linewidth',2);
% y = abs(up_thr(15:21,3));
% plot(x, y,'color','b','linewidth',2);
% set(gca,'XTick',[-15 -10 -5 0 5 10 15],'XTickLabel',[-15 -10 -5 0 5 10 15],'YTick',[0:2:14],...
%     'YTickLabel',[0:2:14],'FontWeight','Bold','FontSize',12);
% title('Upper Intesity Thresholds','FontWeight','Bold','FontSize',14)
% xlim([-16, 16]);
% ylim([0,16]);
% xlabel('Intensity (Db)','FontWeight','Bold','FontSize',14);
% ylabel('\Delta\it{f} \rm\bf Threshold (%)','FontWeight','Bold','FontSize',14);
% legend('  4.1 kHz','  8.6 kHz','17.8 kHz','Location','NorthEast');
% 
% 
% 
% 
% %----------------------------------------------------------
% %-----Combines Upper and Lower Threshold Graphs into one---
% %----------------------------------------------------------
figure
hold on;
x = low_thr(1:7,2);
y = low_thr(1:7,3);
plot(x, y,'color','g','linewidth',2);
y = low_thr(8:14,3);
plot(x, y,'color','r','linewidth',2);
y = low_thr(15:21,3);
plot(x, y,'color','b','linewidth',2);
y = up_thr(1:7,3);
plot(x, y,'color','g','linewidth',2);
y = up_thr(8:14,3);
plot(x, y,'color','r','linewidth',2);
y = up_thr(15:21,3);
plot(x, y,'color','b','linewidth',2);
set(gca,'XTick',[-15 -10 -5 0 5 10 15],'XTickLabel',[-15 -10 -5 0 5 10 15],'YTick',[-14:2:14],...
    'YTickLabel',[-14:2:14],'FontWeight','Bold','FontSize',12);
title('Upper & Lower Thresholds','FontWeight','Bold','FontSize',14)
xlim([-16, 16]);
ylim([-16,16]);
line(-16:.1:16, 0)
xlabel('Intensity (Db)','FontWeight','Bold','FontSize',14);
ylabel('\Delta\it{f} \rm\bf Threshold (% Difference)','FontWeight','Bold','FontSize',14);
legend('  4.1 kHz','  8.6 kHz','17.8 kHz','Location','SouthEast');






