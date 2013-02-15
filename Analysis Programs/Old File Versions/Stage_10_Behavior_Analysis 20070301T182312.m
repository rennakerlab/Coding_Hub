function Stage_10_behavior_analysis(ratname)

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
%---Creates delta F Intensity data matrix---
%---------------------------------    
previous_performance = [];
for intensities = [-15 -10 -5 0 5 10 15];
    a = find([behav(rat).session(:).stage] == 10 & [behav(rat).session(:).mk801_dose] == 0);
    for i = a
        for j = 1:behav(rat).session(i).trials
            if ~any(behav(rat).session(i).outcome(j) == 'AT') & behav(rat).session(i).intensity(j) == intensities;
                if isempty(previous_performance)
                    previous_performance = [behav(rat).session(i).intensity(j), behav(rat).session(i).delta_f(j), ...
                        (behav(rat).session(i).nosepoke_response(j) < 0.6), 1];                 
                else
                    b = intersect(find(behav(rat).session(i).intensity(j) == previous_performance(:,1)),...
                        find(behav(rat).session(i).delta_f(j) == previous_performance(:,2)));
                    if isempty(b)
                        previous_performance = [previous_performance; behav(rat).session(i).intensity(j), behav(rat).session(i).delta_f(j), ...
                            (behav(rat).session(i).nosepoke_response(j) < 0.6), 1];
                    else
                        previous_performance(b,:) = [behav(rat).session(i).intensity(j), behav(rat).session(i).delta_f(j), ...
                            previous_performance(b,3) + (behav(rat).session(i).nosepoke_response(j) < 0.6), ...
                            previous_performance(b,4) + 1];
                    end                            
                end
            end
        end
    end
    if ~isempty(previous_performance)
        previous_performance = sortrows(previous_performance,1:2);
    end
end
figure;
hold on;
clear p a
for i = 1:size(previous_performance,1)
    p(i) = previous_performance(i,3)./previous_performance(i,4);       %Calcs hit percent
    a(i) = 1.96*sqrt(p(i)*(1-p(i))/previous_performance(i,4));          %Calcs confidence intervals
end
errorbar(previous_performance(1:31,2),p(1:31),a(1:31),'color','r','linewidth',2);
errorbar(previous_performance(32:62,2),p(32:62),a(32:62),'color','b','linewidth',2);
%errorbar(previous_performance(63:93,2),p(63:93),a(63:93),'color','g','linewidth',2);
%errorbar(previous_performance(94:124,2),p(94:124),a(94:124),'color','c','linewidth',2);
%errorbar(previous_performance(125:155,2),p(125:155),a(125:155),'color','m','linewidth',2);
%errorbar(previous_performance(156:186,2),p(156:186),a(156:186),'color','y','linewidth',2);
errorbar(previous_performance(187:217,2),p(187:217),a(187:217),'color','black','linewidth',2);
set(gca,'XTick',[-20:5:20],'XTickLabel',[-20:5:20],'YTick',[0:0.2:1],...
    'YTickLabel',[0:20:100],'FontWeight','Bold','FontSize',12);
title('Intensity Curve','FontWeight','Bold','FontSize',14)
xlim([-16, 16]);
ylim([0,1]);
xlabel('\Delta\it{f} \rm\bf(~%)','FontWeight','Bold','FontSize',14);
ylabel('Nosepoke Responses','FontWeight','Bold','FontSize',14);
hold off;


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
figure
%subplot(2,2,4)
for i = 1:size(intensity_matrix_new,1)
    p(i) = intensity_matrix_new(i,2)./intensity_matrix_new(i,3);       %Calcs hit percent
    a(i) = 1.96*sqrt(p(i)*(1-p(i))/intensity_matrix_new(i,3));          %Calcs confidence intervals
end
errorbar(intensity_matrix_new(:,1),p',a','color','g','linewidth',2);
hold on;
% for i = 1:size(intensity_matrix_new_2,1)
%     p(i) = intensity_matrix_new_2(i,2)./intensity_matrix_new_2(i,3);       %Calcs hit percent
%     a(i) = 1.96*sqrt(p(i)*(1-p(i))/intensity_matrix_new_2(i,3));          %Calcs confidence intervals
% end
% errorbar(intensity_matrix_new_2(:,1),p',a','color','r','linewidth',2);
% hold on;
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
%---Creates delta F/10 Db intensity data matrix---
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




