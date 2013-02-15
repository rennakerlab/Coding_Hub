graph_all = [];
delta_f = [];
ref_freq = [];

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



for ref_freq = [4000 9000 18000]        
    graph = [];
    %figure;
    for delta_f = [0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15]
        previous_performance = [];
        dprimes = [];
        a = find([behav(rat).session(:).stage] == 10 & [behav(rat).session(:).mk801_dose] == 0);
        for i = a
            for j = 1:behav(rat).session(i).trials
                if ~any(behav(rat).session(i).outcome(j) == 'AT') & behav(rat).session(i).duration(j) == .2...
                        & roundn(behav(rat).session(i).ref_freq(j),3) == ref_freq & behav(rat).session(i).delta_f(j) == delta_f;
                    if isempty(previous_performance)
                        previous_performance = [behav(rat).session(i).intensity(j) (behav(rat).session(i).nosepoke_response(j) < 0.6) 1];   
                        dprimes = [dprimes; ref_freq delta_f behav(rat).session(i).intensity(j)];
                    else
                        b = find(behav(rat).session(i).intensity(j) == previous_performance(:,1));
                        if isempty(b)
                            previous_performance = [previous_performance; behav(rat).session(i).intensity(j), ...
                                (behav(rat).session(i).nosepoke_response(j) < 0.6), 1];
                            dprimes = [dprimes; ref_freq behav(rat).session(i).delta_f(j) behav(rat).session(i).intensity(j)];
                        else
                            previous_performance(b,:) = [behav(rat).session(i).intensity(j), ...
                                previous_performance(b,2) + (behav(rat).session(i).nosepoke_response(j) < 0.6), ...
                                previous_performance(b,3) + 1];
                        end  
                    end
                end
            end            
        end
        previous_performance = sortrows(previous_performance);
        intensities = [-15, -10, -5, 0, 5, 10, 15];
        a = [];
        for k = 1:size(previous_performance,1)
            if previous_performance(k,1) ~= intensities
                a = [a;k];
            end
        end
        previous_performance(a,:) = [];
        dprimes = sortrows(dprimes);
        a = [];
        for k = 1:size(dprimes,1)
            if dprimes(k,3) ~= intensities
                a = [a;k];
            end
        end
        dprimes(a,:) = [];
        
        %--The following is for creating combined
        %--data matrices for multiple rats.
        for i = 1:size(previous_performance,1)
            if isempty(graph_all)
                graph_all = [graph_all; ref_freq, delta_f, previous_performance(i,1:3)];
            else
                b = find(graph_all(:,1) == ref_freq & graph_all(:,2) == delta_f & graph_all(:,3) == previous_performance(i,1));
                if isempty(b)
                    graph_all = [graph_all; ref_freq, delta_f, previous_performance(i,1:3)];
                else
                    graph_all(b,:) = [ref_freq, delta_f, previous_performance(i,1)...
                        graph_all(b,4) + previous_performance(i,2)...
                        graph_all(b,5) + previous_performance(i,3)];
                end
            end
        end
        if any(delta_f) >= 2
            graph_all = sortrows(graph_all);
        end
        
        if delta_f == 0
            false_alarms = previous_performance;    %Sets False Alarm rate from PP Matrix
        end


        %-------------------------------------------
        %---Calculates D-Prime Values---------------
        %-------------------------------------------
%         if any(previous_performance(:,1) == 0) & size(previous_performance,1) > 3
%             for i = 1:size(previous_performance,1)
%                 if previous_performance(i,1) ~= 0
%                     H = previous_performance(i,2);    %change back to (i,2) to use non-smoothed data, (i,4) for smoothed data
%                     M = previous_performance(i,3) - previous_performance(i,2);    %change back to (i,3),(i,2) to use non-smoothed data, (i,5),(i,4) for smoothed
%                     if M > 0 & H > 0
%                         a = H/(H + M);
%                     elseif H > 0 & M == 0
%                         a = (H-0.5)/(H);
%                     else
%                         a = 0.0001;
%                     end
%                     F = false_alarms(i,2);
%                     C = false_alarms(i,3) - false_alarms(i,2);
%                     if F > 0 & C > 0
%                         b = F/(F + C);
%                     elseif F == 0 & C > 0
%                         b = 0.5/C;
%                     else
%                         b = 0.0001;
%                     end
%                     dc(1) = norminv(a) - norminv(b);
%                     dc(2) = -0.5*(norminv(a) + norminv(b))/abs(dc(1));
%                 else
%                     temp(i) = NaN;
%                 end
%                 dprimes(i,4) = dc(1);   
%             end
%             graph = [graph, dprimes(:,4)];
%         end  
%         if ref_freq == 4000
%             calibration = [-11 -6 -2 2 7 11 16];
%         elseif ref_freq == 9000
%             calibration = [-12 -7 -3 2 6 10 15];
%         elseif ref_freq == 18000
%             calibration = [-12 -8 -3 1 6 10 14];
%         end
%         plot(calibration,graph,'linewidth',2);
%         set(gca,'XTick',calibration,'XTickLabel',calibration,'YTick',[-3:1:4],...
%                 'YTickLabel',[-3:1:4],'FontWeight','Bold','FontSize',12);
%         xlim([min(calibration),max(calibration)]);
%         ylim([-3,4]);
%         line(-16:.1:16, 1.96)
%         xlabel('Intensity (dB)','FontWeight','Bold','FontSize',14);
%         ylabel('D-Prime Value','FontWeight','Bold','FontSize',14);
%         legend('0%','1%','2%','3%','4%','5%','6%','7%','8%','9%','10%','11%','12%','13%','14%','15%','Location','EastOutside')
%         if ref_freq == 4000
%             rf = '  - 4.1 kHz Ref. Freq.';
%         elseif ref_freq == 9000
%             rf = '  - 8.6 kHz Ref. Freq.';
%         else ref_freq == 18000
%             rf = '  - 17.8 kHz Ref. Freq.';
%         end
%         title([ratname rf])
    end
end
    
    



%-------------------------------------------------
%---Calculates D-Prime Values for combined data---
%-------------------------------------------------
num_ref_freq = 3;
num_delta_f = 16;  %Remember to count 0% delta f
num_intensities = 7;
false_alarms = [];
a=[];
graph_all = graph_all(:,1:5);

        start = 0;
        for h = 1:num_ref_freq
            figure;
            graph = [];
            graph_all_new = graph_all(1 + start * (h - 1):(size(graph_all,1)/num_ref_freq) + start * (h - 1),:);
            false_alarms = [graph_all_new(1:num_intensities,:)];
            for i = 1:num_delta_f
                graph_all_next = graph_all_new(1 + num_intensities*(i-1):num_intensities + num_intensities*(i-1),:);
                 for j = 1:num_intensities
                    H = graph_all_next(j,4);
                    M = graph_all_next(j,5) - graph_all_next(j,4);
                    if M > 0 & H > 0
                        a = H/(H + M);
                    elseif H > 0 & M == 0
                        a = (H-0.5)/(H);
                    else
                        a = 0.0001;
                    end
                    F = false_alarms(j,4);
                    C = false_alarms(j,5) - false_alarms(j,4);
                    if F > 0 & C > 0
                        b = F/(F + C);
                    elseif F == 0 & C > 0
                        b = 0.5/C;
                    else
                        b = 0.0001;
                    end
                    dc(1) = norminv(a) - norminv(b);
                    dc(2) = -0.5*(norminv(a) + norminv(b))/abs(dc(1));
                    graph_all_next(j,6) = dc(1);
                 end
                 graph = [graph, graph_all_next(:,6)];
            end
            if graph_all_next(1,1) == 4000
                calibration = [-11 -6 -2 2 7 11 16];
            elseif graph_all_next(1,1) == 9000
                calibration = [-12 -7 -3 2 6 10 15];
            elseif graph_all_next(1,1) == 18000
                calibration = [-12 -8 -3 1 6 10 14];
            end
            set(0,'DefaultAxesColorOrder',[0 0 0;1 1 0;1 0 1;0 1 1;1 0 0;0 1 0;0 0 1;.5 .75 0],'DefaultAxesLineStyleOrder','--|-')
            plot(calibration,graph,'linewidth',2);
            set(gca,'XTick',calibration,'XTickLabel',calibration,'YTick',[-3:1:4],...
                    'YTickLabel',[-3:1:4],'FontWeight','Bold','FontSize',12);
            xlim([calibration(1,2),max(calibration)]);
            ylim([-1,4]);
            line(-16:.1:16,1.96)
            xlabel('Intensity (dB)','FontWeight','Bold','FontSize',14);
            ylabel('D-Prime Value','FontWeight','Bold','FontSize',14);
            if graph_all_next(1,2) >= 2
                legend('0%','1%','2%','3%','4%','5%','6%','7%','8%','9%','10%','11%','12%','13%','14%','15%','Location','EastOutside')
            else
                legend('0%','- 1%','- 2%','- 3%','- 4%','- 5%','- 6%','- 7%','- 8%','- 9%','- 10%','- 11%','- 12%','- 13%','- 14%','- 15%','Location','EastOutside')
            end
            if graph_all_next(1,1) == 4000
                rf = '  - 4.1 kHz Ref. Freq.';
            elseif graph_all_next(1,1) == 9000
                rf = '  - 8.6 kHz Ref. Freq.';
            else graph_all_next(1,1) == 18000
                rf = '  - 17.8 kHz Ref. Freq.';
            end
            ratname = 'Combined Data';
            title([ratname rf])
            start = i*j;
        end
            
            
            














































figure;
n = 0;
for ref_freq = [4000 9000 18000]
    for delta_f = [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15]
    previous_performance = [];
    dprimes = [];
    n = n + 1;
    a = find([behav(rat).session(:).stage] == 10 & [behav(rat).session(:).mk801_dose] == 0) %& [behav(rat).session(:).daycode] < 100);  %Cannonball's first weep was completed before daycode 100. 
        for i = a
            for j = 1:behav(rat).session(i).trials
                if ~any(behav(rat).session(i).outcome(j) == 'AT') & behav(rat).session(i).duration(j) == .2...
                        & roundn(behav(rat).session(i).ref_freq(j),3) == ref_freq & behav(rat).session(i).delta_f(j) == delta_f;
                    if isempty(previous_performance)
                        previous_performance = [behav(rat).session(i).delta_f(j), ...
                            (behav(rat).session(i).nosepoke_response(j) < 0.6), 1];   
                        dprimes = [dprimes; ref_freq behav(rat).session(i).delta_f(j) behav(rat).session(i).intensity(j)];
                    else
                        b = find(behav(rat).session(i).intensity(j) == previous_performance(:,1));
                        if isempty(b)
                            previous_performance = [previous_performance; behav(rat).session(i).delta_f(j), ...
                                (behav(rat).session(i).nosepoke_response(j) < 0.6), 1];
                            dprimes = [dprimes; ref_freq behav(rat).session(i).delta_f(j) behav(rat).session(i).intensity(j)];
                        else
                            previous_performance(b,:) = [behav(rat).session(i).delta_f(j), ...
                                previous_performance(b,2) + (behav(rat).session(i).nosepoke_response(j) < 0.6), ...
                                previous_performance(b,3) + 1];
                        end  
                    end
                end
            end            
        end
        dprimes = sortrows(dprimes,1);
        if ~isempty(previous_performance)
            previous_performance = sortrows(previous_performance,1);
        end
        
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
                else
                    temp(i) = NaN;
                end
                dprimes(i,4) = dc(1);
            end
        end
        
        %------------------------------------------------------
        %---Creates Delta f vs. D-Primes Graphs per each
        %---intensity/reference frequency combo----------------
        %------------------------------------------------------
        subplot(3,7,n)
        hold on;
        plot(dprimes(:,3),dprimes(:,4),'color','black','linewidth',2);
        set(gca,'XTick',[-15:10:15],'XTickLabel',[-15:10:15],'YTick',[-3:1:4],...
            'YTickLabel',[-3:1:4],'FontWeight','Bold','FontSize',12);
        int = [num2str(intensity) ' dB'];
        xlim([-15, 15]);
        ylim([-3,4]);
        line(-16:.1:16, 1.96)
        if any(n == [15:21])
            xlabel('\Delta\it{f} \rm\bf(~%)','FontWeight','Bold','FontSize',14);
        end
        if n == 1 | n == 8 | n== 15
            ylabel('D-Prime Value','FontWeight','Bold','FontSize',14);
        end
        hold off; 
    end
end



        


if ref_freq == 4000
            rf = '4.1 kHz';
        elseif ref_freq == 9000
            rf = '8.6 kHz';
        else ref_freq == 18000
            rf = '17.8 kHz';
        end