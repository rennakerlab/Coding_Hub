function Stage_9_behavior_analysis(ratname)

%-------------------
%---Set Variables---
%-------------------
ratname = 'Cannonball';
stage = 9;

%-------------------
%---Finding specific rat data
%---------------------
datapath = 'Z:\Pitch Discrimination\Behavior Data';
cd(datapath);
load('pitch_discrimination_data');
rat = 0;
for i = 1:length(behav);
    if strcmpi(ratname,behav(i).ratname);
        rat = i; 
    end
end

%---------------------------------
%---Creates delta F data matrix---
%---------------------------------
previous_performance = [];
        a = find([behav(rat).session(:).stage] == stage & [behav(rat).session(:).mk801_dose] == 0);
        for i = a
            for j = 1:behav(rat).session(i).trials
                if ~any(behav(rat).session(i).outcome(j) == 'AT') & behav(rat).session(i).intensity(j) == 60;
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
        end
        
%---------------------------------
%---Creates Duration Data Matrix---
%---------------------------------
duration_matrix = [];
        a = find([behav(rat).session(:).stage] == stage & [behav(rat).session(:).mk801_dose] == 0);
        for i = a
            for j = 1:behav(rat).session(i).trials
                if ~any(behav(rat).session(i).outcome(j) == 'AT') & behav(rat).session(i).intensity(j) == 60;
                    if isempty(duration_matrix)
                        duration_matrix = [behav(rat).session(i).duration(j), ...
                            (behav(rat).session(i).nosepoke_response(j) < 0.6), 1];                 
                    else
                        b = find(behav(rat).session(i).duration(j) == duration_matrix(:,1));
                        if isempty(b)
                            duration_matrix = [duration_matrix; behav(rat).session(i).duration(j), ...
                                (behav(rat).session(i).nosepoke_response(j) < 0.6), 1];
                        else
                            duration_matrix(b,:) = [behav(rat).session(i).duration(j), ...
                                duration_matrix(b,2) + (behav(rat).session(i).nosepoke_response(j) < 0.6), ...
                                duration_matrix(b,3) + 1];
                        end                            
                    end
                end
            end
        end
        if ~isempty(duration_matrix)
            duration_matrix = sortrows(duration_matrix,1);
        end
        
%---------------------------------
%---Creates 3 Duration Data Matrix---
%---------------------------------
duration_matrix_new = [];
duration_matrix_new_2 = [];
duration_matrix_new_3 = [];
        a = find([behav(rat).session(:).stage] == stage & [behav(rat).session(:).mk801_dose] == 0);
        for i = a
            for j = 1:behav(rat).session(i).trials
                if ~any(behav(rat).session(i).outcome(j) == 'AT') & behav(rat).session(i).intensity(j) == 60 & abs(behav(rat).session(i).delta_f(j)) > 10;
                    if isempty(duration_matrix_new)
                        duration_matrix_new = [behav(rat).session(i).duration(j), ...
                            (behav(rat).session(i).nosepoke_response(j) < 0.6), 1];                 
                    else
                        b = find(behav(rat).session(i).duration(j) == duration_matrix_new(:,1));
                        if isempty(b)
                            duration_matrix_new = [duration_matrix_new; behav(rat).session(i).duration(j), ...
                                (behav(rat).session(i).nosepoke_response(j) < 0.6), 1];
                        else
                            duration_matrix_new(b,:) = [behav(rat).session(i).duration(j), ...
                                duration_matrix_new(b,2) + (behav(rat).session(i).nosepoke_response(j) < 0.6), ...
                                duration_matrix_new(b,3) + 1];
                        end                            
                    end
                end
                if ~any(behav(rat).session(i).outcome(j) == 'AT') & behav(rat).session(i).intensity(j) == 60 & (abs(behav(rat).session(i).delta_f(j)) <= 10 & abs(behav(rat).session(i).delta_f(j)) > 5);
                    if isempty(duration_matrix_new_2)
                        duration_matrix_new_2 = [behav(rat).session(i).duration(j), ...
                            (behav(rat).session(i).nosepoke_response(j) < 0.6), 1];                 
                    else
                        b = find(behav(rat).session(i).duration(j) == duration_matrix_new_2(:,1));
                        if isempty(b)
                            duration_matrix_new_2 = [duration_matrix_new_2; behav(rat).session(i).duration(j), ...
                                (behav(rat).session(i).nosepoke_response(j) < 0.6), 1];
                        else
                            duration_matrix_new_2(b,:) = [behav(rat).session(i).duration(j), ...
                                duration_matrix_new_2(b,2) + (behav(rat).session(i).nosepoke_response(j) < 0.6), ...
                                duration_matrix_new_2(b,3) + 1];
                        end                            
                    end
                end
                if ~any(behav(rat).session(i).outcome(j) == 'AT') & behav(rat).session(i).intensity(j) == 60 & abs(behav(rat).session(i).delta_f(j)) <= 5;
                    if isempty(duration_matrix_new_3)
                        duration_matrix_new_3 = [behav(rat).session(i).duration(j), ...
                            (behav(rat).session(i).nosepoke_response(j) < 0.6), 1];                 
                    else
                        b = find(behav(rat).session(i).duration(j) == duration_matrix_new_3(:,1));
                        if isempty(b)
                            duration_matrix_new_3 = [duration_matrix_new_3; behav(rat).session(i).duration(j), ...
                                (behav(rat).session(i).nosepoke_response(j) < 0.6), 1];
                        else
                            duration_matrix_new_3(b,:) = [behav(rat).session(i).duration(j), ...
                                duration_matrix_new_3(b,2) + (behav(rat).session(i).nosepoke_response(j) < 0.6), ...
                                duration_matrix_new_3(b,3) + 1];
                        end                            
                    end
                end
            end
        end
        if ~isempty(duration_matrix_new)
            duration_matrix_new = sortrows(duration_matrix_new,1);
        end  
        if ~isempty(duration_matrix_new_2)
            duration_matrix_new_2 = sortrows(duration_matrix_new_2,1);
        end 
        if ~isempty(duration_matrix_new_3)
            duration_matrix_new_3 = sortrows(duration_matrix_new_3,1);
        end 
        
%----------------------------------------
%----creates 'Delta F-V Curve' plot
%------------------------------------------ 
figure;
hold on;
subplot(2,2,1:2)
for i = 1:size(previous_performance,1)
    p(i) = previous_performance(i,2)./previous_performance(i,3);       %Calcs hit percent
    a(i) = 1.96*sqrt(p(i)*(1-p(i))/previous_performance(i,3));          %Calcs confidence intervals
end
errorbar(previous_performance(:,1),p',a','color','g','linewidth',2);
set(gca,'XTick',[-20:5:20],'XTickLabel',[-20:5:20],'YTick',[0:0.2:1],...
    'YTickLabel',[0:20:100],'FontWeight','Bold','FontSize',12);
title([ratname 'Duration Curve'],'FontWeight','Bold','FontSize',14)
xlim([-16, 16]);
ylim([0,1]);
xlabel('\Delta\it{f} \rm\bf(~%)','FontWeight','Bold','FontSize',14);
ylabel('Correct Response (%)','FontWeight','Bold','FontSize',14);
hold off;

%----------------------------------------
%----creates 'Duration vs. Nosepoke' plot
%------------------------------------------
duration_matrix(:,1) = duration_matrix(:,1) * 1000;
%duration_matrix(find(duration_matrix(:,1)==20),1) = 40;
%duration_matrix(find(duration_matrix(:,1)==50),1) = 80;
%duration_matrix(find(duration_matrix(:,1)==100),1) = 130;
clear p a
subplot(2,2,3)
for i = 1:size(duration_matrix,1)
    p(i) = duration_matrix(i,2)./duration_matrix(i,3);       %Calcs hit percent
    a(i) = 1.96*sqrt(p(i)*(1-p(i))/duration_matrix(i,3));          %Calcs confidence intervals
end
errorbar(duration_matrix(:,1),p',a','color','g','linewidth',2);
set(gca,'XTick',[10 40 80 130 200],'XTickLabel',[10 20 50 100 200],'YTick',[0:0.2:1],...
    'YTickLabel',[0:20:100],'FontWeight','Bold','FontSize',12);
title('All \Delta\it{f} \rm\bf Values','FontWeight','Bold','FontSize',14)
xlim([0 ,210]);
ylim([0,1]);
xlabel('Duration (ms)','FontWeight','Bold','FontSize',14);
ylabel('Correct Response (%)','FontWeight','Bold','FontSize',14);

%----------------------------------------
%----creates 'Duration vs. Nosepoke' plot
%------------------------------------------
duration_matrix_new(:,1) = duration_matrix_new(:,1) * 1000;
duration_matrix_new_2(:,1) = duration_matrix_new_2(:,1) * 1000;
duration_matrix_new_3(:,1) = duration_matrix_new_3(:,1) * 1000;
%duration_matrix_new(find(duration_matrix_new(:,1)==20),1) = 40;
%duration_matrix_new(find(duration_matrix_new(:,1)==50),1) = 80;
%duration_matrix_new(find(duration_matrix_new(:,1)==100),1) = 130;
clear p a
subplot(2,2,4)
for i = 1:size(duration_matrix_new,1)
    p(i) = duration_matrix_new(i,2)./duration_matrix_new(i,3);       %Calcs hit percent
    a(i) = 1.96*sqrt(p(i)*(1-p(i))/duration_matrix_new(i,3));          %Calcs confidence intervals
end
errorbar(duration_matrix_new(:,1),p',a','color','g','linewidth',2);
hold on;
for i = 1:size(duration_matrix_new_2,1)
    p(i) = duration_matrix_new_2(i,2)./duration_matrix_new_2(i,3);       %Calcs hit percent
    a(i) = 1.96*sqrt(p(i)*(1-p(i))/duration_matrix_new_2(i,3));          %Calcs confidence intervals
end
errorbar(duration_matrix_new_2(:,1),p',a','color','g','linewidth',2);
hold on;
for i = 1:size(duration_matrix_new_3,1)
    p(i) = duration_matrix_new_3(i,2)./duration_matrix_new_3(i,3);       %Calcs hit percent
    a(i) = 1.96*sqrt(p(i)*(1-p(i))/duration_matrix_new_3(i,3));          %Calcs confidence intervals
end
errorbar(duration_matrix_new_3(:,1),p',a','color','g','linewidth',2);
set(gca,'XTick',[10 20 50 100 200],'XTickLabel',[10 20 50 100 200],'YTick',[0:0.2:1],...
    'YTickLabel',[0:20:100],'FontWeight','Bold','FontSize',12);
title('\pm5% \Delta\it{f} \rm\bf Bins','FontWeight','Bold','FontSize',14)
xlim([0 ,210]);
ylim([0,1]);
xlabel('Duration (ms)','FontWeight','Bold','FontSize',14);
ylabel('Correct Response (%)','FontWeight','Bold','FontSize',14);




%---------------------------------
%---Creates delta F/10ms Duration data matrix---
%---------------------------------
figure;
previous_performance = [];
        a = find([behav(rat).session(:).stage] == stage & [behav(rat).session(:).mk801_dose] == 0);
        for i = a
            for j = 1:behav(rat).session(i).trials
                if ~any(behav(rat).session(i).outcome(j) == 'AT') & behav(rat).session(i).duration(j) == .01;
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
        end
hold on;
subplot(2,3,1)
for i = 1:size(previous_performance,1)
    p(i) = previous_performance(i,2)./previous_performance(i,3);       %Calcs hit percent
    a(i) = 1.96*sqrt(p(i)*(1-p(i))/previous_performance(i,3));          %Calcs confidence intervals
end
errorbar(previous_performance(:,1),p',a','color','g','linewidth',2);
set(gca,'XTick',[-20:5:20],'XTickLabel',[-20:5:20],'YTick',[0:0.2:1],...
    'YTickLabel',[0:20:100],'FontWeight','Bold','FontSize',12);
xlim([-16, 16]);
ylim([0,1]);
title('10 ms')
xlabel('\Delta\it{f} \rm\bf(~%)','FontWeight','Bold','FontSize',14);
ylabel('Nosepoke Responses','FontWeight','Bold','FontSize',14);
line(-16:.1:16, 0.5)
hold off;
%---------------------------------
%---Creates delta F/20ms Duration data matrix---
%---------------------------------
previous_performance = [];
        a = find([behav(rat).session(:).stage] == stage & [behav(rat).session(:).mk801_dose] == 0);
        for i = a
            for j = 1:behav(rat).session(i).trials
                if ~any(behav(rat).session(i).outcome(j) == 'AT') & behav(rat).session(i).duration(j) == .02;
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
        end
hold on;
subplot(2,3,2)
for i = 1:size(previous_performance,1)
    p(i) = previous_performance(i,2)./previous_performance(i,3);       %Calcs hit percent
    a(i) = 1.96*sqrt(p(i)*(1-p(i))/previous_performance(i,3));          %Calcs confidence intervals
end
errorbar(previous_performance(:,1),p',a','color','g','linewidth',2);
set(gca,'XTick',[-20:5:20],'XTickLabel',[-20:5:20],'YTick',[0:0.2:1],...
    'YTickLabel',[0:20:100],'FontWeight','Bold','FontSize',12);
xlim([-16, 16]);
ylim([0,1]);
title('20 ms')
xlabel('\Delta\it{f} \rm\bf(~%)','FontWeight','Bold','FontSize',14);
ylabel('Nosepoke Responses','FontWeight','Bold','FontSize',14);
line(-16:.1:16, 0.5)
hold off;
%---------------------------------
%---Creates delta F/50ms Duration data matrix---
%---------------------------------
previous_performance = [];
        a = find([behav(rat).session(:).stage] == stage & [behav(rat).session(:).mk801_dose] == 0);
        for i = a
            for j = 1:behav(rat).session(i).trials
                if ~any(behav(rat).session(i).outcome(j) == 'AT') & behav(rat).session(i).duration(j) == .05;
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
        end
hold on;
subplot(2,3,3)
for i = 1:size(previous_performance,1)
    p(i) = previous_performance(i,2)./previous_performance(i,3);       %Calcs hit percent
    a(i) = 1.96*sqrt(p(i)*(1-p(i))/previous_performance(i,3));          %Calcs confidence intervals
end
errorbar(previous_performance(:,1),p',a','color','g','linewidth',2);
set(gca,'XTick',[-20:5:20],'XTickLabel',[-20:5:20],'YTick',[0:0.2:1],...
    'YTickLabel',[0:20:100],'FontWeight','Bold','FontSize',12);
xlim([-16, 16]);
ylim([0,1]);
title('50 ms')
xlabel('\Delta\it{f} \rm\bf(~%)','FontWeight','Bold','FontSize',14);
ylabel('Nosepoke Responses','FontWeight','Bold','FontSize',14);
line(-16:.1:16, 0.5)
hold off;
%---------------------------------
%---Creates delta F/100ms Duration data matrix---
%---------------------------------
previous_performance = [];
        a = find([behav(rat).session(:).stage] == stage & [behav(rat).session(:).mk801_dose] == 0);
        for i = a
            for j = 1:behav(rat).session(i).trials
                if ~any(behav(rat).session(i).outcome(j) == 'AT') & (behav(rat).session(i).duration(j) == .1);
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
        end
hold on;
subplot(2,3,4)
for i = 1:size(previous_performance,1)
    p(i) = previous_performance(i,2)./previous_performance(i,3);       %Calcs hit percent
    a(i) = 1.96*sqrt(p(i)*(1-p(i))/previous_performance(i,3));          %Calcs confidence intervals
end
errorbar(previous_performance(:,1),p',a','color','g','linewidth',2);
set(gca,'XTick',[-20:5:20],'XTickLabel',[-20:5:20],'YTick',[0:0.2:1],...
    'YTickLabel',[0:20:100],'FontWeight','Bold','FontSize',12);
xlim([-16, 16]);
ylim([0,1]);
title('100ms');
xlabel('\Delta\it{f} \rm\bf(~%)','FontWeight','Bold','FontSize',14);
ylabel('Nosepoke Responses','FontWeight','Bold','FontSize',14);
line(-16:.1:16, 0.5)
hold off;
%---------------------------------
%---Creates delta F/100-200ms Duration data matrix---
%---------------------------------
previous_performance = [];
        a = find([behav(rat).session(:).stage] == stage & [behav(rat).session(:).mk801_dose] == 0);
        for i = a
            for j = 1:behav(rat).session(i).trials
                if ~any(behav(rat).session(i).outcome(j) == 'AT') & (behav(rat).session(i).duration(j) == .2);
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
        end
hold on;
subplot(2,3,5)
for i = 1:size(previous_performance,1)
    p(i) = previous_performance(i,2)./previous_performance(i,3);       %Calcs hit percent
    a(i) = 1.96*sqrt(p(i)*(1-p(i))/previous_performance(i,3));          %Calcs confidence intervals
end
errorbar(previous_performance(:,1),p',a','color','g','linewidth',2);
set(gca,'XTick',[-20:5:20],'XTickLabel',[-20:5:20],'YTick',[0:0.2:1],...
    'YTickLabel',[0:20:100],'FontWeight','Bold','FontSize',12);
xlim([-16, 16]);
ylim([0,1]);
title('200ms');
xlabel('\Delta\it{f} \rm\bf(~%)','FontWeight','Bold','FontSize',14);
ylabel('Nosepoke Responses','FontWeight','Bold','FontSize',14);
line(-16:.1:16, 0.5)
hold off;