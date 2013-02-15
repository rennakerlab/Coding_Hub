ratname = 'Backhoe';
datapath = 'F:\Pitch Discrimination\Behavior Data';
cd(datapath);
load('pitch_discrimination_data');
rat = 0;
for i = 1:length(behav);
    if strcmpi(ratname,behav(i).ratname);
        rat = i; 
    end
end

figure;
n = 0;
for ref_freq = [4000 9000 18000]
    for durations = [10 20 50 100 200]/1000
    previous_performance = [];
    dprimes = [];
    n = n + 1;
        a = find([behav(rat).session(:).stage] == 9 & [behav(rat).session(:).mk801_dose] == 0);
        for i = a
            for j = 1:behav(rat).session(i).trials
                if ~any(behav(rat).session(i).outcome(j) == 'AT') & behav(rat).session(i).intensity(j) == 60 & roundn(behav(rat).session(i).ref_freq(j),3) == ref_freq & behav(rat).session(i).duration(j) == durations;
                    if isempty(previous_performance)
                        previous_performance = [behav(rat).session(i).delta_f(j), ...
                            (behav(rat).session(i).nosepoke_response(j) < 0.6), 1]; 
                        dprimes = [dprimes; ref_freq durations behav(rat).session(i).delta_f(j)];
                    else
                        b = find(behav(rat).session(i).delta_f(j) == previous_performance(:,1));
                        if isempty(b)
                            previous_performance = [previous_performance; behav(rat).session(i).delta_f(j), ...
                                (behav(rat).session(i).nosepoke_response(j) < 0.6), 1];
                            dprimes = [dprimes; ref_freq durations behav(rat).session(i).delta_f(j)];
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
        %---duration/reference frequency combo----------------
        %------------------------------------------------------
        subplot(3,5,n)
        hold on;
        plot(dprimes(:,3),dprimes(:,4),'color','black','linewidth',2);
        set(gca,'XTick',[-15:10:15],'XTickLabel',[-15:10:15],'YTick',[-3:1:4],...
            'YTickLabel',[-3:1:4],'FontWeight','Bold','FontSize',12);
        int = [num2str(durations) ' dB'];
        xlim([-15, 15]);
        ylim([-3,4]);
        line(-16:.1:16, 1.96)
        if any(n == [11:15])
            xlabel('\Delta\it{f} \rm\bf(~%)','FontWeight','Bold','FontSize',14);
        end
        if n == 1 | n == 6 | n== 11
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