function doyles_behavior_analysis(ratname)

%-------------------
%---Set Variables---
%-------------------
ratname = 'Cannonball';
stage = 9;

%-------------------
%---Finding specific rat data
%---------------------
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
title(ratname 'Duration Curve','FontWeight','Bold','FontSize',14)
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
%---Creates delta F data matrix---
%---------------------------------

previous_performance = [];
        a = find([behav(rat).session(:).stage] == 10 & [behav(rat).session(:).mk801_dose] == 0 & [behav(rat).session(:).daycode] > 53);
        for i = a
            for j = 1:behav(rat).session(i).trials
                if ~any(behav(rat).session(i).outcome(j) == 'AT') & behav(rat).session(i).duration(j) == .2;
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
%---Creates Intensity Data Matrix---
%---------------------------------
intensity_matrix = [];
        a = find([behav(rat).session(:).stage] == 10 & [behav(rat).session(:).mk801_dose] == 0 & [behav(rat).session(:).daycode] > 53);
        for i = a
            for j = 1:behav(rat).session(i).trials
                if ~any(behav(rat).session(i).outcome(j) == 'AT') & behav(rat).session(i).duration(j) == .2;
                    if isempty(intensity_matrix)
                        intensity_matrix = [behav(rat).session(i).intensity(j), ...
                            (behav(rat).session(i).nosepoke_response(j) < 0.6), 1];                 
                    else
                        b = find(behav(rat).session(i).intensity(j) == intensity_matrix(:,1));
                        if isempty(b)
                            intensity_matrix = [intensity_matrix; behav(rat).session(i).intensity(j), ...
                                (behav(rat).session(i).nosepoke_response(j) < 0.6), 1];
                        else
                            intensity_matrix(b,:) = [behav(rat).session(i).intensity(j), ...
                                intensity_matrix(b,2) + (behav(rat).session(i).nosepoke_response(j) < 0.6), ...
                                intensity_matrix(b,3) + 1];
                        end                            
                    end
                end
            end
        end
        if ~isempty(intensity_matrix)
            intensity_matrix = sortrows(intensity_matrix,1);
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
title('Intensity Curve','FontWeight','Bold','FontSize',14)
xlim([-16, 16]);
ylim([0,1]);
xlabel('\Delta\it{f} \rm\bf(~%)','FontWeight','Bold','FontSize',14);
ylabel('Nosepoke Responses','FontWeight','Bold','FontSize',14);
hold off;
%-----------------------------------------
%----creates 'Intensity vs. Nosepoke' plot
%-----------------------------------------
clear p a
subplot(2,2,3)
for i = 1:size(intensity_matrix,1)
    p(i) = intensity_matrix(i,2)./intensity_matrix(i,3);       %Calcs hit percent
    a(i) = 1.96*sqrt(p(i)*(1-p(i))/intensity_matrix(i,3));          %Calcs confidence intervals
end
errorbar(intensity_matrix(:,1),p',a','color','g','linewidth',2);
set(gca,'XTick',[-15 -10 -5 0 5 10 15],'XTickLabel',[-15 -10 -5 0 5 10 15],'YTick',[0:0.2:1],...
    'YTickLabel',[0:20:100],'FontWeight','Bold','FontSize',12);
title('All \Delta\it{f} \rm\bf Values','FontWeight','Bold','FontSize',14)
xlim([-16, 16]);
ylim([0,1]);
line(-16:.1:16, 0.50)
xlabel('Intensity (Db)','FontWeight','Bold','FontSize',14);
%-----------------------------------------------------
%----creates 3 'Intensity Bin vs. Nosepoke' lines plot
%-----------------------------------------------------
intensity_matrix_new = [];
intensity_matrix_new_2 = [];
intensity_matrix_new_3 = [];
        a = find([behav(rat).session(:).stage] == 10 & [behav(rat).session(:).mk801_dose] == 0 & [behav(rat).session(:).daycode] > 53);
        for i = a
            for j = 1:behav(rat).session(i).trials
                if ~any(behav(rat).session(i).outcome(j) == 'AT') & behav(rat).session(i).duration(j) == .2 & abs(behav(rat).session(i).delta_f(j)) > 10;
                    if isempty(intensity_matrix_new)
                        intensity_matrix_new = [behav(rat).session(i).intensity(j), ...
                            (behav(rat).session(i).nosepoke_response(j) < 0.6), 1];                 
                    else
                        b = find(behav(rat).session(i).intensity(j) == intensity_matrix_new(:,1));
                        if isempty(b)
                            intensity_matrix_new = [intensity_matrix_new; behav(rat).session(i).intensity(j), ...
                                (behav(rat).session(i).nosepoke_response(j) < 0.6), 1];
                        else
                            intensity_matrix_new(b,:) = [behav(rat).session(i).intensity(j), ...
                                intensity_matrix_new(b,2) + (behav(rat).session(i).nosepoke_response(j) < 0.6), ...
                                intensity_matrix_new(b,3) + 1];
                        end                            
                    end
                end
                if ~any(behav(rat).session(i).outcome(j) == 'AT') & behav(rat).session(i).duration(j) == .2 & (abs(behav(rat).session(i).delta_f(j)) <= 10 & abs(behav(rat).session(i).delta_f(j)) > 5);
                    if isempty(intensity_matrix_new_2)
                        intensity_matrix_new_2 = [behav(rat).session(i).intensity(j), ...
                            (behav(rat).session(i).nosepoke_response(j) < 0.6), 1];                 
                    else
                        b = find(behav(rat).session(i).intensity(j) == intensity_matrix_new_2(:,1));
                        if isempty(b)
                            intensity_matrix_new_2 = [intensity_matrix_new_2; behav(rat).session(i).intensity(j), ...
                                (behav(rat).session(i).nosepoke_response(j) < 0.6), 1];
                        else
                            intensity_matrix_new_2(b,:) = [behav(rat).session(i).intensity(j), ...
                                intensity_matrix_new_2(b,2) + (behav(rat).session(i).nosepoke_response(j) < 0.6), ...
                                intensity_matrix_new_2(b,3) + 1];
                        end                            
                    end
                end
                if ~any(behav(rat).session(i).outcome(j) == 'AT') & behav(rat).session(i).duration(j) == .2  & abs(behav(rat).session(i).delta_f(j)) <= 5;
                    if isempty(intensity_matrix_new_3)
                        intensity_matrix_new_3 = [behav(rat).session(i).intensity(j), ...
                            (behav(rat).session(i).nosepoke_response(j) < 0.6), 1];                 
                    else
                        b = find(behav(rat).session(i).intensity(j) == intensity_matrix_new_3(:,1));
                        if isempty(b)
                            intensity_matrix_new_3 = [intensity_matrix_new_3; behav(rat).session(i).intensity(j), ...
                                (behav(rat).session(i).nosepoke_response(j) < 0.6), 1];
                        else
                            intensity_matrix_new_3(b,:) = [behav(rat).session(i).intensity(j), ...
                                intensity_matrix_new_3(b,2) + (behav(rat).session(i).nosepoke_response(j) < 0.6), ...
                                intensity_matrix_new_3(b,3) + 1];
                        end                            
                    end
                end
            end
        end
        if ~isempty(intensity_matrix_new)
            intensity_matrix_new = sortrows(intensity_matrix_new,1);
        end  
        if ~isempty(intensity_matrix_new_2)
            intensity_matrix_new_2 = sortrows(intensity_matrix_new_2,1);
        end 
        if ~isempty(intensity_matrix_new_3)
            intensity_matrix_new_3 = sortrows(intensity_matrix_new_3,1);
        end 
clear p a
subplot(2,2,4)
for i = 1:size(intensity_matrix_new,1)
    p(i) = intensity_matrix_new(i,2)./intensity_matrix_new(i,3);       %Calcs hit percent
    a(i) = 1.96*sqrt(p(i)*(1-p(i))/intensity_matrix_new(i,3));          %Calcs confidence intervals
end
errorbar(intensity_matrix_new(:,1),p',a','color','g','linewidth',2);
hold on;
for i = 1:size(intensity_matrix_new_2,1)
    p(i) = intensity_matrix_new_2(i,2)./intensity_matrix_new_2(i,3);       %Calcs hit percent
    a(i) = 1.96*sqrt(p(i)*(1-p(i))/intensity_matrix_new_2(i,3));          %Calcs confidence intervals
end
errorbar(intensity_matrix_new_2(:,1),p',a','color','r','linewidth',2);
hold on;
for i = 1:size(intensity_matrix_new_3,1)
    p(i) = intensity_matrix_new_3(i,2)./intensity_matrix_new_3(i,3);       %Calcs hit percent
    a(i) = 1.96*sqrt(p(i)*(1-p(i))/intensity_matrix_new_3(i,3));          %Calcs confidence intervals
end
errorbar(intensity_matrix_new_3(:,1),p',a','color','p','linewidth',2);
set(gca,'XTick',[-15 -10 -5 0 5 10 15],'XTickLabel',[-15 -10 -5 0 5 10 15],'YTick',[0:0.2:1],...
    'YTickLabel',[0:20:100],'FontWeight','Bold','FontSize',12);
title('\pm5% \Delta\it{f} \rm\bf Bins','FontWeight','Bold','FontSize',14)
xlim([-16, 16]);
ylim([0,1]);
line(-16:.1:16, 0.50)
xlabel('Intensity (Db)','FontWeight','Bold','FontSize',14);
ylabel('Correct Response (%)','FontWeight','Bold','FontSize',14);





%---------------------------------
%---Creates delta F/10ms intensity data matrix---
%---------------------------------
figure;
previous_performance = [];
        a = find([behav(rat).session(:).stage] == 10 & [behav(rat).session(:).mk801_dose] == 0 & [behav(rat).session(:).daycode] > 53);
        for i = a
            for j = 1:behav(rat).session(i).trials
                if ~any(behav(rat).session(i).outcome(j) == 'AT') & behav(rat).session(i).intensity(j) == -15;
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
subplot(2,2,1)
for i = 1:size(previous_performance,1)
    p(i) = previous_performance(i,2)./previous_performance(i,3);       %Calcs hit percent
    a(i) = 1.96*sqrt(p(i)*(1-p(i))/previous_performance(i,3));          %Calcs confidence intervals
end
errorbar(previous_performance(:,1),p',a','color','g','linewidth',2);
set(gca,'XTick',[-20:5:20],'XTickLabel',[-20:5:20],'YTick',[0:0.2:1],...
    'YTickLabel',[0:20:100],'FontWeight','Bold','FontSize',12);
xlim([-16, 16]);
ylim([0,1]);
title('-15 Db')
xlabel('\Delta\it{f} \rm\bf(~%)','FontWeight','Bold','FontSize',14);
ylabel('Nosepoke Responses','FontWeight','Bold','FontSize',14);
line(-16:.1:16, 0.5)
hold off;
previous_performance = [];
        a = find([behav(rat).session(:).stage] == 10 & [behav(rat).session(:).mk801_dose] == 0 & [behav(rat).session(:).daycode] > 53);
        for i = a
            for j = 1:behav(rat).session(i).trials
                if ~any(behav(rat).session(i).outcome(j) == 'AT') & behav(rat).session(i).intensity(j) == -10;
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
subplot(2,2,2)
for i = 1:size(previous_performance,1)
    p(i) = previous_performance(i,2)./previous_performance(i,3);       %Calcs hit percent
    a(i) = 1.96*sqrt(p(i)*(1-p(i))/previous_performance(i,3));          %Calcs confidence intervals
end
errorbar(previous_performance(:,1),p',a','color','g','linewidth',2);
set(gca,'XTick',[-20:5:20],'XTickLabel',[-20:5:20],'YTick',[0:0.2:1],...
    'YTickLabel',[0:20:100],'FontWeight','Bold','FontSize',12);
xlim([-16, 16]);
ylim([0,1]);
title('-10 Db')
xlabel('\Delta\it{f} \rm\bf(~%)','FontWeight','Bold','FontSize',14);
ylabel('Nosepoke Responses','FontWeight','Bold','FontSize',14);
line(-16:.1:16, 0.5)
hold off;
previous_performance = [];
        a = find([behav(rat).session(:).stage] == 10 & [behav(rat).session(:).mk801_dose] == 0 & [behav(rat).session(:).daycode] > 53);
        for i = a
            for j = 1:behav(rat).session(i).trials
                if ~any(behav(rat).session(i).outcome(j) == 'AT') & behav(rat).session(i).intensity(j) == -5;
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
subplot(2,2,3)
for i = 1:size(previous_performance,1)
    p(i) = previous_performance(i,2)./previous_performance(i,3);       %Calcs hit percent
    a(i) = 1.96*sqrt(p(i)*(1-p(i))/previous_performance(i,3));          %Calcs confidence intervals
end
errorbar(previous_performance(:,1),p',a','color','g','linewidth',2);
set(gca,'XTick',[-20:5:20],'XTickLabel',[-20:5:20],'YTick',[0:0.2:1],...
    'YTickLabel',[0:20:100],'FontWeight','Bold','FontSize',12);
xlim([-16, 16]);
ylim([0,1]);
title('-5 Db')
xlabel('\Delta\it{f} \rm\bf(~%)','FontWeight','Bold','FontSize',14);
ylabel('Nosepoke Responses','FontWeight','Bold','FontSize',14);
line(-16:.1:16, 0.5)
hold off;
previous_performance = [];
        a = find([behav(rat).session(:).stage] == 10 & [behav(rat).session(:).mk801_dose] == 0 & [behav(rat).session(:).daycode] > 53);
        for i = a
            for j = 1:behav(rat).session(i).trials
                if ~any(behav(rat).session(i).outcome(j) == 'AT') & behav(rat).session(i).intensity(j) == 0;
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
subplot(2,2,4)
for i = 1:size(previous_performance,1)
    p(i) = previous_performance(i,2)./previous_performance(i,3);       %Calcs hit percent
    a(i) = 1.96*sqrt(p(i)*(1-p(i))/previous_performance(i,3));          %Calcs confidence intervals
end
errorbar(previous_performance(:,1),p',a','color','g','linewidth',2);
set(gca,'XTick',[-20:5:20],'XTickLabel',[-20:5:20],'YTick',[0:0.2:1],...
    'YTickLabel',[0:20:100],'FontWeight','Bold','FontSize',12);
xlim([-16, 16]);
ylim([0,1]);
title('0 Db')
xlabel('\Delta\it{f} \rm\bf(~%)','FontWeight','Bold','FontSize',14);
ylabel('Nosepoke Responses','FontWeight','Bold','FontSize',14);
line(-16:.1:16, 0.5)
hold off;
figure;
previous_performance = [];
        a = find([behav(rat).session(:).stage] == 10 & [behav(rat).session(:).mk801_dose] == 0 & [behav(rat).session(:).daycode] > 53);
        for i = a
            for j = 1:behav(rat).session(i).trials
                if ~any(behav(rat).session(i).outcome(j) == 'AT') & behav(rat).session(i).intensity(j) == 5;
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
subplot(2,2,1)
for i = 1:size(previous_performance,1)
    p(i) = previous_performance(i,2)./previous_performance(i,3);       %Calcs hit percent
    a(i) = 1.96*sqrt(p(i)*(1-p(i))/previous_performance(i,3));          %Calcs confidence intervals
end
errorbar(previous_performance(:,1),p',a','color','g','linewidth',2);
set(gca,'XTick',[-20:5:20],'XTickLabel',[-20:5:20],'YTick',[0:0.2:1],...
    'YTickLabel',[0:20:100],'FontWeight','Bold','FontSize',12);
xlim([-16, 16]);
ylim([0,1]);
title('5 Db')
xlabel('\Delta\it{f} \rm\bf(~%)','FontWeight','Bold','FontSize',14);
ylabel('Nosepoke Responses','FontWeight','Bold','FontSize',14);
line(-16:.1:16, 0.5)
hold off;
previous_performance = [];
        a = find([behav(rat).session(:).stage] == 10 & [behav(rat).session(:).mk801_dose] == 0 & [behav(rat).session(:).daycode] > 53);
        for i = a
            for j = 1:behav(rat).session(i).trials
                if ~any(behav(rat).session(i).outcome(j) == 'AT') & behav(rat).session(i).intensity(j) == 10;
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
subplot(2,2,2)
for i = 1:size(previous_performance,1)
    p(i) = previous_performance(i,2)./previous_performance(i,3);       %Calcs hit percent
    a(i) = 1.96*sqrt(p(i)*(1-p(i))/previous_performance(i,3));          %Calcs confidence intervals
end
errorbar(previous_performance(:,1),p',a','color','g','linewidth',2);
set(gca,'XTick',[-20:5:20],'XTickLabel',[-20:5:20],'YTick',[0:0.2:1],...
    'YTickLabel',[0:20:100],'FontWeight','Bold','FontSize',12);
xlim([-16, 16]);
ylim([0,1]);
title('10 Db')
xlabel('\Delta\it{f} \rm\bf(~%)','FontWeight','Bold','FontSize',14);
ylabel('Nosepoke Responses','FontWeight','Bold','FontSize',14);
line(-16:.1:16, 0.5)
hold off;
previous_performance = [];
        a = find([behav(rat).session(:).stage] == 10 & [behav(rat).session(:).mk801_dose] == 0 & [behav(rat).session(:).daycode] > 53);
        for i = a
            for j = 1:behav(rat).session(i).trials
                if ~any(behav(rat).session(i).outcome(j) == 'AT') & behav(rat).session(i).intensity(j) == 15;
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
subplot(2,2,3)
for i = 1:size(previous_performance,1)
    p(i) = previous_performance(i,2)./previous_performance(i,3);       %Calcs hit percent
    a(i) = 1.96*sqrt(p(i)*(1-p(i))/previous_performance(i,3));          %Calcs confidence intervals
end
errorbar(previous_performance(:,1),p',a','color','g','linewidth',2);
set(gca,'XTick',[-20:5:20],'XTickLabel',[-20:5:20],'YTick',[0:0.2:1],...
    'YTickLabel',[0:20:100],'FontWeight','Bold','FontSize',12);
xlim([-16, 16]);
ylim([0,1]);
title('15 Db')
xlabel('\Delta\it{f} \rm\bf(~%)','FontWeight','Bold','FontSize',14);
ylabel('Nosepoke Responses','FontWeight','Bold','FontSize',14);
line(-16:.1:16, 0.5)
hold off;















%-----------------------------------------------------
%----creates 3 'Intensity Bin vs. Nosepoke' lines w/ legend plot
%-----------------------------------------------------
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
intensity_matrix_new = [];
intensity_matrix_new_2 = [];
intensity_matrix_new_3 = [];
        a = find([behav(rat).session(:).stage] == 10 & [behav(rat).session(:).mk801_dose] == 0 & [behav(rat).session(:).daycode] > 53);
        for i = a
            for j = 1:behav(rat).session(i).trials
                if ~any(behav(rat).session(i).outcome(j) == 'AT') & behav(rat).session(i).duration(j) == .2 & abs(behav(rat).session(i).delta_f(j)) > 10;
                    if isempty(intensity_matrix_new)
                        intensity_matrix_new = [behav(rat).session(i).intensity(j), ...
                            (behav(rat).session(i).nosepoke_response(j) < 0.6), 1];                 
                    else
                        b = find(behav(rat).session(i).intensity(j) == intensity_matrix_new(:,1));
                        if isempty(b)
                            intensity_matrix_new = [intensity_matrix_new; behav(rat).session(i).intensity(j), ...
                                (behav(rat).session(i).nosepoke_response(j) < 0.6), 1];
                        else
                            intensity_matrix_new(b,:) = [behav(rat).session(i).intensity(j), ...
                                intensity_matrix_new(b,2) + (behav(rat).session(i).nosepoke_response(j) < 0.6), ...
                                intensity_matrix_new(b,3) + 1];
                        end                            
                    end
                end
                if ~any(behav(rat).session(i).outcome(j) == 'AT') & behav(rat).session(i).duration(j) == .2 & (abs(behav(rat).session(i).delta_f(j)) <= 10 & abs(behav(rat).session(i).delta_f(j)) > 5);
                    if isempty(intensity_matrix_new_2)
                        intensity_matrix_new_2 = [behav(rat).session(i).intensity(j), ...
                            (behav(rat).session(i).nosepoke_response(j) < 0.6), 1];                 
                    else
                        b = find(behav(rat).session(i).intensity(j) == intensity_matrix_new_2(:,1));
                        if isempty(b)
                            intensity_matrix_new_2 = [intensity_matrix_new_2; behav(rat).session(i).intensity(j), ...
                                (behav(rat).session(i).nosepoke_response(j) < 0.6), 1];
                        else
                            intensity_matrix_new_2(b,:) = [behav(rat).session(i).intensity(j), ...
                                intensity_matrix_new_2(b,2) + (behav(rat).session(i).nosepoke_response(j) < 0.6), ...
                                intensity_matrix_new_2(b,3) + 1];
                        end                            
                    end
                end
                if ~any(behav(rat).session(i).outcome(j) == 'AT') & behav(rat).session(i).duration(j) == .2  & abs(behav(rat).session(i).delta_f(j)) <= 5;
                    if isempty(intensity_matrix_new_3)
                        intensity_matrix_new_3 = [behav(rat).session(i).intensity(j), ...
                            (behav(rat).session(i).nosepoke_response(j) < 0.6), 1];                 
                    else
                        b = find(behav(rat).session(i).intensity(j) == intensity_matrix_new_3(:,1));
                        if isempty(b)
                            intensity_matrix_new_3 = [intensity_matrix_new_3; behav(rat).session(i).intensity(j), ...
                                (behav(rat).session(i).nosepoke_response(j) < 0.6), 1];
                        else
                            intensity_matrix_new_3(b,:) = [behav(rat).session(i).intensity(j), ...
                                intensity_matrix_new_3(b,2) + (behav(rat).session(i).nosepoke_response(j) < 0.6), ...
                                intensity_matrix_new_3(b,3) + 1];
                        end                            
                    end
                end
            end
        end
        if ~isempty(intensity_matrix_new)
            intensity_matrix_new = sortrows(intensity_matrix_new,1);
        end  
        if ~isempty(intensity_matrix_new_2)
            intensity_matrix_new_2 = sortrows(intensity_matrix_new_2,1);
        end 
        if ~isempty(intensity_matrix_new_3)
            intensity_matrix_new_3 = sortrows(intensity_matrix_new_3,1);
        end 
clear p a
figure;
for i = 1:size(intensity_matrix_new,1)
    p(i) = intensity_matrix_new(i,2)./intensity_matrix_new(i,3);       %Calcs hit percent
    a(i) = 1.96*sqrt(p(i)*(1-p(i))/intensity_matrix_new(i,3));          %Calcs confidence intervals
end
errorbar(intensity_matrix_new(:,1),p',a','color','g','linewidth',2);
hold on;
clear p a
for i = 1:size(intensity_matrix_new_2,1)
    p(i) = intensity_matrix_new_2(i,2)./intensity_matrix_new_2(i,3);       %Calcs hit percent
    a(i) = 1.96*sqrt(p(i)*(1-p(i))/intensity_matrix_new_2(i,3));          %Calcs confidence intervals
end
errorbar(intensity_matrix_new_2(:,1),p',a','color','r','linewidth',2);
hold on;
clear p a
for i = 1:size(intensity_matrix_new_3,1)
    p(i) = intensity_matrix_new_3(i,2)./intensity_matrix_new_3(i,3);       %Calcs hit percent
    a(i) = 1.96*sqrt(p(i)*(1-p(i))/intensity_matrix_new_3(i,3));          %Calcs confidence intervals
end
errorbar(intensity_matrix_new_3(:,1),p',a','color','b','linewidth',2);
set(gca,'XTick',[-15 -10 -5 0 5 10 15],'XTickLabel',[-15 -10 -5 0 5 10 15],'YTick',[0:0.2:1],...
    'YTickLabel',[0:20:100],'FontWeight','Bold','FontSize',12);
title('\pm5% \Delta\it{f} \rm\bf Bins','FontWeight','Bold','FontSize',14)
xlim([-16, 16]);
ylim([0,1.05]);
line(-16:.1:16, 0.50)
xlabel('Intensity (Db)','FontWeight','Bold','FontSize',14);
ylabel('Correct Response (%)','FontWeight','Bold','FontSize',14);
legend('\pm10-15% \Delta\it{f}','\pm5-10% \Delta\it{f}','\pm0-5% \Delta\it{f}','Location','NorthWest');


















%-------------------------------------------------
%----Drew's Magical 4-in-1 Graph For The Grant----
%-------------------------------------------------
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
%-------------------------------------------------
%----Calculates Delta F Matrices------------------
%-------------------------------------------------
delta_f_matrix_4 = [];
delta_f_matrix_8 = [];
        a = find([behav(rat).session(:).stage] == 4 & [behav(rat).session(:).mk801_dose] == 0);
        for i = a
            for j = 1:behav(rat).session(i).trials
                if ~any(behav(rat).session(i).outcome(j) == 'AT');
                    if isempty(delta_f_matrix_4)
                        delta_f_matrix_4 = [behav(rat).session(i).delta_f(j), ...
                            (behav(rat).session(i).nosepoke_response(j) < 0.6), 1];                 
                    else
                        b = find(behav(rat).session(i).delta_f(j) == delta_f_matrix_4(:,1));
                        if isempty(b)
                            delta_f_matrix_4 = [delta_f_matrix_4; behav(rat).session(i).delta_f(j), ...
                                (behav(rat).session(i).nosepoke_response(j) < 0.6), 1];
                        else
                            delta_f_matrix_4(b,:) = [behav(rat).session(i).delta_f(j), ...
                                delta_f_matrix_4(b,2) + (behav(rat).session(i).nosepoke_response(j) < 0.6), ...
                                delta_f_matrix_4(b,3) + 1];
                        end                            
                    end
                end
            end
        end
        if ~isempty(delta_f_matrix_4)
            delta_f_matrix_4 = sortrows(delta_f_matrix_4,1);
        end
        a = find([behav(rat).session(:).stage] == 8 & [behav(rat).session(:).mk801_dose] == 0);
        for i = a
            for j = 1:behav(rat).session(i).trials
                if ~any(behav(rat).session(i).outcome(j) == 'AT');
                    if isempty(delta_f_matrix_8)
                        delta_f_matrix_8 = [behav(rat).session(i).delta_f(j), ...
                            (behav(rat).session(i).nosepoke_response(j) < 0.6), 1];                 
                    else
                        b = find(behav(rat).session(i).delta_f(j) == delta_f_matrix_8(:,1));
                        if isempty(b)
                            delta_f_matrix_8 = [delta_f_matrix_8; behav(rat).session(i).delta_f(j), ...
                                (behav(rat).session(i).nosepoke_response(j) < 0.6), 1];
                        else
                            delta_f_matrix_8(b,:) = [behav(rat).session(i).delta_f(j), ...
                                delta_f_matrix_8(b,2) + (behav(rat).session(i).nosepoke_response(j) < 0.6), ...
                                delta_f_matrix_8(b,3) + 1];
                        end                            
                    end
                end
            end
        end
        if ~isempty(delta_f_matrix_8)
            delta_f_matrix_8 = sortrows(delta_f_matrix_8,1);
        end
%----------------------------------------------------------------
%----Creates plot of Delta F for discrete and indescrete tones---
%----------------------------------------------------------------
clear p a
figure;
hold on;
subplot(2,2,1)
for i = 1:size(delta_f_matrix_4,1)
    p(i) = delta_f_matrix_4(i,2)./delta_f_matrix_4(i,3);       %Calcs hit percent
    a(i) = 1.96*sqrt(p(i)*(1-p(i))/delta_f_matrix_4(i,3));          %Calcs confidence intervals
end
errorbar(delta_f_matrix_4(:,1),p',a','color','r','linewidth',2);
clear p a
hold off;
hold on;
for i = 1:size(delta_f_matrix_8,1)
    p(i) = delta_f_matrix_8(i,2)./delta_f_matrix_8(i,3);       %Calcs hit percent
    a(i) = 1.96*sqrt(p(i)*(1-p(i))/delta_f_matrix_8(i,3));          %Calcs confidence intervals
end
errorbar(delta_f_matrix_8(:,1),p',a','color','g','linewidth',2);
set(gca,'XTick',[-10:5:10],'XTickLabel',[-10:5:10],'YTick',[0:0.2:1],...
    'YTickLabel',[0:20:100],'FontWeight','Bold','FontSize',12);
title('Discrete vs. Indiscrete Tones','FontWeight','Bold','FontSize',14)
xlim([-11, 11]);
ylim([0,1]);
xlabel('\Delta\it{f} \rm\bf(~%)','FontWeight','Bold','FontSize',14);
ylabel('Correct Response (%)','FontWeight','Bold','FontSize',14);
hold off;



%--------------------------------------------------
%----Calculates Upper and Lower Threshold Matrices
%--------------------------------------------------
numfreq = 20;               %The number of reference frequencies we'll use.
lower_freq_bound = 2000;    %Lower frequency bound, in Hertz.
upper_freq_bound = 32000;   %Upper frequency bound, in Hertz.
standard_frequency_set = pow2(log2(lower_freq_bound):((log2(upper_freq_bound)-log2(lower_freq_bound))/(numfreq-1)):log2(upper_freq_bound));
upper = [];
lower = [];
for freq = 2:19
    previous_performance = [];
  	a = find(([behav(rat).session(:).stage] == 8 | [behav(rat).session(:).stage] == 9) & [behav(rat).session(:).mk801_dose] == 0);
    for i = a
        for j = 1:behav(rat).session(i).trials
            if round(behav(rat).session(i).ref_freq(j)) == round(standard_frequency_set(freq))...
                    & ~any(behav(rat).session(i).outcome(j) == 'AT')...
                    & behav(rat).session(i).duration(j) == .2
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
    curve = previous_performance(:,2)./previous_performance(:,3);
    max_hit = max(curve);
    false_alarm = curve(11);
    cutoff = (max_hit + false_alarm)/2;
%     figure; 
%     cla;
%     set(1,'position',[220 188 844 480]);
%     plot([-10:10],curve,'linewidth',2,'color','b');
%     xlim([-11,11]);
%     line(get(gca,'xlim'),[cutoff, cutoff],'color','g','linestyle',':','linewidth',2);
    temp = curve(11:-1:1);
    a = min(intersect(find(temp >= cutoff) - 1, find(temp < cutoff)));
    if ~isempty(a) & a < 11
        b = (a)+(cutoff-temp(a))/(temp(a+1)-temp(a))-1;
        lower = [lower, -b];
%         line([-b, -b], get(gca,'ylim'),'color','r','linestyle','--','linewidth',2);
    else
        lower = [lower, NaN]; 
    end
    temp = curve(11:21);
    a = min(intersect(find(temp >= cutoff) - 1, find(temp < cutoff)));
    if ~isempty(a) & a < 11
        b = (a)+(cutoff-temp(a))/(temp(a+1)-temp(a))-1;
        upper = [upper, b];
%         line([b, b], get(gca,'ylim'),'color','r','linestyle','--','linewidth',2);
    else
        upper = [upper, NaN]; 
    end
%     set(gca,'xtick',[-10:2:10],'ytick',[0:0.2:1],'yticklabel',[0:20:100],'fontweight','bold','fontsize',12);
%     xlabel('\Delta\itf \rm(%)', 'fontweight','bold','fontsize',14);
%     ylabel('Hits (%)', 'fontweight','bold','fontsize',14);
end
%---------------------------------------------
%-----Created Upper & Lower Threshold plot----
%---------------------------------------------
subplot(2,2,2);
hold on;
x = [2:19];
plot(x, upper,'color','g','linewidth',2);
lower = abs(lower);
plot(x, lower,'color','r','linewidth',2);
set(gca,'XTick',[0:5:20],'XTickLabel',[0:5:20],'YTick',[0:2:10],...
    'YTickLabel',[0:2:10],'FontWeight','Bold','FontSize',12);
title('Upper & Lower Thresh','FontWeight','Bold','FontSize',14)
xlim([0, 20]);
ylim([0,10]);
xlabel('Ref \it{f}','FontWeight','Bold','FontSize',14);
ylabel('|\Delta\it{f}| Thresh','FontWeight','Bold','FontSize',14);
hold off;





%----------------------------------------------------------
%----Calculates Duration Upper and Lower Threshold Matrices
%----------------------------------------------------------
numfreq = 20;                %The number of reference frequencies we'll use.
lower_freq_bound = 2000;    %Lower frequency bound, in Hertz.
upper_freq_bound = 32000;   %Upper frequency bound, in Hertz.
standard_frequency_set = pow2(log2(lower_freq_bound):((log2(upper_freq_bound)-log2(lower_freq_bound))/(numfreq-1)):log2(upper_freq_bound));
duration_matrix = [];
for ref_freq = [6,11,16];
    for durations = [10 20 50 100 200]/1000;
        previous_performance = [];
        upper = [];
        lower = [];
        a = find([behav(rat).session(:).stage] == 9 & [behav(rat).session(:).mk801_dose] == 0);
        for i = a
            for j = 1:behav(rat).session(i).trials
                if round(behav(rat).session(i).ref_freq(j)) == round(standard_frequency_set(ref_freq))...
                        & ~any(behav(rat).session(i).outcome(j) == 'AT')...
                        & behav(rat).session(i).duration(j) == durations;
                    if isempty(previous_performance)
                        previous_performance = [abs(behav(rat).session(i).delta_f(j)), ...
                            (behav(rat).session(i).nosepoke_response(j) < 0.6), 1];                 
                    else
                        b = find(abs(behav(rat).session(i).delta_f(j)) == previous_performance(:,1));
                        if isempty(b)
                            previous_performance = [previous_performance; abs(behav(rat).session(i).delta_f(j)), ...
                                (behav(rat).session(i).nosepoke_response(j) < 0.6), 1];
                        else
                            previous_performance(b,:) = [abs(behav(rat).session(i).delta_f(j)), ...
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
        curve = previous_performance(:,2)./previous_performance(:,3);
        max_hit = max(curve);
        false_alarm = curve(1);
        cutoff = (max_hit + false_alarm)/2;
%         figure; 
%         cla;
%         set(1,'position',[220 188 844 480]);
%         plot([0:15],curve,'linewidth',2,'color','b');
%         xlim([-1,16]);
%         ylim([0 1]);
%         line(get(gca,'xlim'),[cutoff, cutoff],'color','g','linestyle',':','linewidth',2);
        temp = curve(1:16);
        a = min(intersect(find(temp >= cutoff) - 1, find(temp < cutoff)));
        if ~isempty(a) & a < 16
            b = (a)+(cutoff-temp(a))/(temp(a+1)-temp(a))-1;
            upper = [upper, b];
%             line([b, b], get(gca,'ylim'),'color','r','linestyle','--','linewidth',2);
        else
            upper = [upper, NaN]; 
        end
%         set(gca,'xtick',[-0:2:14],'ytick',[0:0.2:1],'yticklabel',[0:20:100],'fontweight','bold','fontsize',12);
%         xlabel('\Delta\itf \rm(%)', 'fontweight','bold','fontsize',14);
%         ylabel('Hits (%)', 'fontweight','bold','fontsize',14);
    duration_matrix = [duration_matrix; ref_freq, durations, upper];
    end     
end
duration_matrix(:,2) = duration_matrix(:,2) * 1000;
%------------------------------------------------------
%-----Created Duration Upper & Lower Threshold plot----
%------------------------------------------------------
subplot(2,2,3);
hold on;
x = duration_matrix(1:5,2);
y = duration_matrix(1:5,3);
plot(x, y,'color','g','linewidth',2);
x = duration_matrix(6:10,2);
y = duration_matrix(6:10,3);
plot(x, y,'color','r','linewidth',2);
x = duration_matrix(11:15,2);
y = duration_matrix(11:15,3);
plot(x, y,'color','b','linewidth',2);
set(gca,'XTick',[10 40 80 130 200],'XTickLabel',[10 20 50 100 200],'YTick',[0:2:14],...
    'YTickLabel',[0:2:14],'FontWeight','Bold','FontSize',12);
title('\Delta\it{f} \rm\bf Duration','FontWeight','Bold','FontSize',14)
xlim([0 ,210]);
ylim([0,14]);
xlabel('Duration (ms)','FontWeight','Bold','FontSize',14);
ylabel('Correct Response (%)','FontWeight','Bold','FontSize',14);
hold off;






%----------------------------------------------------------
%----Calculates Duration Upper and Lower Threshold Matrices
%----------------------------------------------------------
numfreq = 20;                %The number of reference frequencies we'll use.
lower_freq_bound = 2000;    %Lower frequency bound, in Hertz.
upper_freq_bound = 32000;   %Upper frequency bound, in Hertz.
standard_frequency_set = pow2(log2(lower_freq_bound):((log2(upper_freq_bound)-log2(lower_freq_bound))/(numfreq-1)):log2(upper_freq_bound));
intensity_matrix = [];
for ref_freq = [6,11,16];
    for intensities = [-15 -10 -5 0 5 10 15];
        previous_performance = [];
        upper = [];
        lower = [];
        a = find([behav(rat).session(:).stage] == 10 & [behav(rat).session(:).mk801_dose] == 0);
        for i = a
            for j = 1:behav(rat).session(i).trials
                if round(behav(rat).session(i).ref_freq(j)) == round(standard_frequency_set(ref_freq))...
                        & ~any(behav(rat).session(i).outcome(j) == 'AT')...
                        & behav(rat).session(i).intensity(j) == intensities;
                    if isempty(previous_performance)
                        previous_performance = [abs(behav(rat).session(i).delta_f(j)), ...
                            (behav(rat).session(i).nosepoke_response(j) < 0.6), 1];                 
                    else
                        b = find(abs(behav(rat).session(i).delta_f(j)) == previous_performance(:,1));
                        if isempty(b)
                            previous_performance = [previous_performance; abs(behav(rat).session(i).delta_f(j)), ...
                                (behav(rat).session(i).nosepoke_response(j) < 0.6), 1];
                        else
                            previous_performance(b,:) = [abs(behav(rat).session(i).delta_f(j)), ...
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
        curve = previous_performance(:,2)./previous_performance(:,3);
        max_hit = max(curve);
        false_alarm = curve(1);
        cutoff = (max_hit + false_alarm)/2;
%         figure; 
%         cla;
%         set(1,'position',[220 188 844 480]);
%         plot([0:15],curve,'linewidth',2,'color','b');
%         xlim([-1,16]);
%         ylim([0 1]);
%         line(get(gca,'xlim'),[cutoff, cutoff],'color','g','linestyle',':','linewidth',2);
        temp = curve(1:16);
        a = min(intersect(find(temp >= cutoff) - 1, find(temp < cutoff)));
        if ~isempty(a) & a < 16
            b = (a)+(cutoff-temp(a))/(temp(a+1)-temp(a))-1;
            upper = [upper, b];
%             line([b, b], get(gca,'ylim'),'color','r','linestyle','--','linewidth',2);
        else
            upper = [upper, NaN]; 
        end
%         set(gca,'xtick',[-0:2:14],'ytick',[0:0.2:1],'yticklabel',[0:20:100],'fontweight','bold','fontsize',12);
%         xlabel('\Delta\itf \rm(%)', 'fontweight','bold','fontsize',14);
%         ylabel('Hits (%)', 'fontweight','bold','fontsize',14);
    intensity_matrix = [intensity_matrix; ref_freq, intensities, upper];
    end 
end
%------------------------------------------------------
%-----Created intensity Upper & Lower Threshold plot----
%------------------------------------------------------
subplot(2,2,4);
hold on;
x = intensity_matrix(1:7,2);
y = intensity_matrix(1:7,3);
plot(x, y,'color','g','linewidth',2);
x = intensity_matrix(8:14,2);
y = intensity_matrix(8:14,3);
plot(x, y,'color','r','linewidth',2);
x = intensity_matrix(15:21,2);
y = intensity_matrix(15:21,3);
plot(x, y,'color','b','linewidth',2);
set(gca,'XTick',[-15 -10 -5 0 5 10 15],'XTickLabel',[-15 -10 -5 0 5 10 15],'YTick',[0:2:14],...
    'YTickLabel',[0:2:14],'FontWeight','Bold','FontSize',12);
title('\Delta\it{f} \rm\bf intensity','FontWeight','Bold','FontSize',14)
xlim([-16 ,16]);
ylim([0,14]);
xlabel('intensity (ms)','FontWeight','Bold','FontSize',14);
ylabel('Correct Response (%)','FontWeight','Bold','FontSize',14);
hold off;




















%-----------------------------------------------
%---Analysis for 3 different Reference Freq's---
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
%---Creates Intensity Data Matrix---
%---------------------------------
intensity_matrix_ref_6 = [];
intensity_matrix_ref_11 = [];
intensity_matrix_ref_16 = [];
        a = find([behav(rat).session(:).stage] == 10 & [behav(rat).session(:).mk801_dose] == 0 & [behav(rat).session(:).daycode] > 53);
        for i = a
            for j = 1:behav(rat).session(i).trials
                if ~any(behav(rat).session(i).outcome(j) == 'AT') & behav(rat).session(i).duration(j) == .2 & roundn(behav(rat).session(i).ref_freq(j),3) == 4000;
                    if isempty(intensity_matrix_ref_6)
                        intensity_matrix_ref_6 = [behav(rat).session(i).intensity(j), ...
                            (behav(rat).session(i).nosepoke_response(j) < 0.6), 1];                 
                    else
                        b = find(behav(rat).session(i).intensity(j) == intensity_matrix_ref_6(:,1));
                        if isempty(b)
                            intensity_matrix_ref_6 = [intensity_matrix_ref_6; behav(rat).session(i).intensity(j), ...
                                (behav(rat).session(i).nosepoke_response(j) < 0.6), 1];
                        else
                            intensity_matrix_ref_6(b,:) = [behav(rat).session(i).intensity(j), ...
                                intensity_matrix_ref_6(b,2) + (behav(rat).session(i).nosepoke_response(j) < 0.6), ...
                                intensity_matrix_ref_6(b,3) + 1];
                        end                            
                    end
                end
                if ~any(behav(rat).session(i).outcome(j) == 'AT') & behav(rat).session(i).duration(j) == .2 & roundn(behav(rat).session(i).ref_freq(j),3) == 9000;
                    if isempty(intensity_matrix_ref_11)
                        intensity_matrix_ref_11 = [behav(rat).session(i).intensity(j), ...
                            (behav(rat).session(i).nosepoke_response(j) < 0.6), 1];                 
                    else
                        b = find(behav(rat).session(i).intensity(j) == intensity_matrix_ref_11(:,1));
                        if isempty(b)
                            intensity_matrix_ref_11 = [intensity_matrix_ref_11; behav(rat).session(i).intensity(j), ...
                                (behav(rat).session(i).nosepoke_response(j) < 0.6), 1];
                        else
                            intensity_matrix_ref_11(b,:) = [behav(rat).session(i).intensity(j), ...
                                intensity_matrix_ref_11(b,2) + (behav(rat).session(i).nosepoke_response(j) < 0.6), ...
                                intensity_matrix_ref_11(b,3) + 1];
                        end                            
                    end
                end
                if ~any(behav(rat).session(i).outcome(j) == 'AT') & behav(rat).session(i).duration(j) == .2 & roundn(behav(rat).session(i).ref_freq(j),3) == 18000;
                    if isempty(intensity_matrix_ref_16)
                        intensity_matrix_ref_16 = [behav(rat).session(i).intensity(j), ...
                            (behav(rat).session(i).nosepoke_response(j) < 0.6), 1];                 
                    else
                        b = find(behav(rat).session(i).intensity(j) == intensity_matrix_ref_16(:,1));
                        if isempty(b)
                            intensity_matrix_ref_16 = [intensity_matrix_ref_16; behav(rat).session(i).intensity(j), ...
                                (behav(rat).session(i).nosepoke_response(j) < 0.6), 1];
                        else
                            intensity_matrix_ref_16(b,:) = [behav(rat).session(i).intensity(j), ...
                                intensity_matrix_ref_16(b,2) + (behav(rat).session(i).nosepoke_response(j) < 0.6), ...
                                intensity_matrix_ref_16(b,3) + 1];
                        end                            
                    end
                end
            end
        end
        if ~isempty(intensity_matrix_ref_6)
            intensity_matrix_ref_6 = sortrows(intensity_matrix_ref_6,1);
        end
        if ~isempty(intensity_matrix_ref_11)
            intensity_matrix_ref_11 = sortrows(intensity_matrix_ref_11,1);
        end
        if ~isempty(intensity_matrix_ref_16)
            intensity_matrix_ref_16 = sortrows(intensity_matrix_ref_16,1);
        end
%------------------------------------------------------------
%-------Booth 1 Calibration fix------------------------------
%         intensity_matrix_ref_6(:,1) = [-5 -1 4 8 12 17 21];
%         intensity_matrix_ref_11(:,1) = [-9 -5 0 4 8 13 17];
%         intensity_matrix_ref_16(:,1) = [-11 -7 -3 2 6 11 15];

%------------------------------------------------------------
%-------Booth 2 Calibration fix------------------------------
        intensity_matrix_ref_6(:,1) = [-11 -6 -2 2 7 11 16];
        intensity_matrix_ref_11(:,1) = [-12 -7 -3 2 6 10 15];
        intensity_matrix_ref_16(:,1) = [-12 -8 -3 1 6 10 14];
        
%-----------------------------------------
%----creates 'Intensity vs. Nosepoke' plot
%-----------------------------------------
figure;
hold on;
clear p a
%subplot(1,3,1)
for i = 1:size(intensity_matrix_ref_6,1)
    p(i) = intensity_matrix_ref_6(i,2)./intensity_matrix_ref_6(i,3);       %Calcs hit percent
    a(i) = 1.96*sqrt(p(i)*(1-p(i))/intensity_matrix_ref_6(i,3));          %Calcs confidence intervals
end
errorbar(intensity_matrix_ref_6(:,1),p',a','color','r','linewidth',2);
clear p a
for i = 1:size(intensity_matrix_ref_11,1)
    p(i) = intensity_matrix_ref_11(i,2)./intensity_matrix_ref_11(i,3);       %Calcs hit percent
    a(i) = 1.96*sqrt(p(i)*(1-p(i))/intensity_matrix_ref_11(i,3));          %Calcs confidence intervals
end
errorbar(intensity_matrix_ref_11(:,1),p',a','color','b','linewidth',2);
clear p a
for i = 1:size(intensity_matrix_ref_16,1)
    p(i) = intensity_matrix_ref_16(i,2)./intensity_matrix_ref_16(i,3);       %Calcs hit percent
    a(i) = 1.96*sqrt(p(i)*(1-p(i))/intensity_matrix_ref_16(i,3));          %Calcs confidence intervals
end
errorbar(intensity_matrix_ref_16(:,1),p',a','color','g','linewidth',2);
set(gca,'XTick',[-10 -5 0 5 10 15 20],'XTickLabel',[-10 -5 0 5 10 15 20],'YTick',[0:0.2:1],...
    'YTickLabel',[0:20:100],'FontWeight','Bold','FontSize',12);
title('3 Reference Frequencies','FontWeight','Bold','FontSize',14)
xlim([-13, 17]);
ylim([0,1]);
line(-13:.1:17, 0.50)
xlabel('Intensity (Db)','FontWeight','Bold','FontSize',14);
ylabel('Correct Detection (%)','FontWeight','Bold','FontSize',14);
legend('  4.1 kHz','  8.6 kHz','17.8 kHz','Location','SouthEast');
 
% subplot(1,3,2)
% for i = 1:size(intensity_matrix_ref_11,1)
%     p(i) = intensity_matrix_ref_11(i,2)./intensity_matrix_ref_11(i,3);       %Calcs hit percent
%     a(i) = 1.96*sqrt(p(i)*(1-p(i))/intensity_matrix_ref_11(i,3));          %Calcs confidence intervals
% end
% errorbar(intensity_matrix_ref_11(:,1),p',a','color','g','linewidth',2);
% set(gca,'XTick',[-15 -10 -5 0 5 10 15],'XTickLabel',[-15 -10 -5 0 5 10 15],'YTick',[0:0.2:1],...
%     'YTickLabel',[0:20:100],'FontWeight','Bold','FontSize',12);
% title('8.6 kHz','FontWeight','Bold','FontSize',14)
% xlim([-16, 16]);
% ylim([0,1]);
% line(-16:.1:16, 0.50)
% xlabel('Intensity (Db)','FontWeight','Bold','FontSize',14);
% 
% subplot(1,3,3)
% for i = 1:size(intensity_matrix_ref_16,1)
%     p(i) = intensity_matrix_ref_16(i,2)./intensity_matrix_ref_16(i,3);       %Calcs hit percent
%     a(i) = 1.96*sqrt(p(i)*(1-p(i))/intensity_matrix_ref_16(i,3));          %Calcs confidence intervals
% end
% errorbar(intensity_matrix_ref_16(:,1),p',a','color','g','linewidth',2);
% set(gca,'XTick',[-15 -10 -5 0 5 10 15],'XTickLabel',[-15 -10 -5 0 5 10 15],'YTick',[0:0.2:1],...
%     'YTickLabel',[0:20:100],'FontWeight','Bold','FontSize',12);
% title('17.8 kHz','FontWeight','Bold','FontSize',14)
% xlim([-16, 16]);
% ylim([0,1]);
% line(-16:.1:16, 0.50)
% xlabel('Intensity (Db)','FontWeight','Bold','FontSize',14);

%duration_matrix(find(duration_matrix(:,1)==20),1) = 40;
%duration_matrix(find(duration_matrix(:,1)==50),1) = 80;
%duration_matrix(find(duration_matrix(:,1)==100),1) = 130;



