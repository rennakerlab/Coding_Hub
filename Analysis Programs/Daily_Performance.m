%-----------------------------------------------------------------------
%This program will generate a 'daily_performance' matrix for each day
%that a rat was run on a specific stage.  The purpose of this is to be able
%to analyze the data and find trends in the the rats performance throughout
%a daily session.  This also generates an 'overall_performance' graph to
%analyze the summed data from all of the sessions.

% Ali
% Backhoe
% Cannonball
% Commie
% Fridge
% Latrina
% Sherlock
% Tiberius


%-------------------
%---Set Variables---
%-------------------
ratname = 'Ali';
stage = 8;
window_length = 25;

%----------------------------
%---Finding specific rat data
%----------------------------
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
day = sort([behav(rat).session(:).daycode]);        %Creates a list of each day the rat was run on
temp = [];
for p = 1:length(day)                               %Eliminates multiple entries from the list of days
    day = [day 0];
    if day(1,p) ~= day(1,p+1)
        temp = [temp day(:,p)];
    end
end
day = temp;

overall_performance = [];
for q = 1:length(day)
    a = find([behav(rat).session(:).daycode] == day(1,q) &...
        [behav(rat).session(:).stage] == stage &...
        [behav(rat).session(:).mk801_dose] == 0);
    date = day(1,q);
    if ~isempty(a)
        daily_performance = [];
        moving_window = [];
        daily_moving_matrix = [];
        n = window_length - 1;
        moving_d_prime = [];
        moving_c_prime = [];
        for i = a
            for j = 1:behav(rat).session(i).trials
                if ~any(behav(rat).session(i).outcome(j) == 'AT') & behav(rat).session(i).intensity(j) == 60;
                    %-----------------------------------------------------
                    %This loop generates the 'overall_performace' data
                    %-----------------------------------------------------
                    if isempty(overall_performance)
                        overall_performance = [behav(rat).session(i).delta_f(j), ...
                            (behav(rat).session(i).nosepoke_response(j) < 0.6), 1];                 
                    else
                        b = find(behav(rat).session(i).delta_f(j) == overall_performance(:,1));
                        if isempty(b)
                            overall_performance = [overall_performance; behav(rat).session(i).delta_f(j), ...
                                (behav(rat).session(i).nosepoke_response(j) < 0.6), 1];
                        else
                            overall_performance(b,:) = [behav(rat).session(i).delta_f(j), ...
                                overall_performance(b,2) + (behav(rat).session(i).nosepoke_response(j) < 0.6), ...
                                overall_performance(b,3) + 1];
                        end                            
                    end
                    %-----------------------------------------------------
                    %This loop generates the 'daily_performace' matrix
                    %-----------------------------------------------------
                    if isempty(daily_performance)
                        daily_performance = [behav(rat).session(i).delta_f(j), ...
                            (behav(rat).session(i).nosepoke_response(j) < 0.6), 1];                 
                    else
                        b = find(behav(rat).session(i).delta_f(j) == daily_performance(:,1));
                        if isempty(b)
                            daily_performance = [daily_performance; behav(rat).session(i).delta_f(j), ...
                                (behav(rat).session(i).nosepoke_response(j) < 0.6), 1];
                        else
                            daily_performance(b,:) = [behav(rat).session(i).delta_f(j), ...
                                daily_performance(b,2) + (behav(rat).session(i).nosepoke_response(j) < 0.6), ...
                                daily_performance(b,3) + 1];
                        end                            
                    end
                    %-----------------------------------------------------
                    %---This loop generates the 'moving window' matrix
                    %-----------------------------------------------------
                    if behav(rat).session(i).duration(j) == .1 | behav(rat).session(i).duration(j) == .2
                        if behav(rat).session(i).delta_f(j) > 4 | behav(rat).session(i).delta_f(j) < -4
                            moving_window = [moving_window; (behav(rat).session(i).nosepoke_response(j) < 0.6), 1];
                            if(length(moving_window) > window_length)
                                moving_window = moving_window(2:(window_length+1),:);
                                n = n + 1;
                                daily_moving_matrix = [daily_moving_matrix; n, sum(moving_window(:,1)), sum(moving_window(:,2))];
                            end
                        end
                    end
                end
            end
        end
        if ~isempty(daily_performance)
            daily_performance = sortrows(daily_performance,1);              %Arranges the 'daily_performance' matrix in order
        end
        
        %------------------------------------------------------------------
        %---Begins D-Prime Calculation
        %------------------------------------------------------------------
        for h = 1:length(daily_performance)
            if daily_performance(h,1) == 0
                FA = daily_performance(h,2);
                CR = daily_performance(h,3) - daily_performance(h,2);
            end
        end
        
        for h = 1:length(daily_moving_matrix)
            hits =  daily_moving_matrix(h,2);
            misses = daily_moving_matrix(h,3) - daily_moving_matrix(h,2);
            if misses > 0;
                hit_rate = (hits)/(hits + misses);
            else
                hit_rate = (hits - .5)/(hits + misses);
            end
            if FA > 0;
                FA_rate = (FA)/(FA + CR);
            else
                FA_rate = (.5)/(FA + CR);
            end
            z_of_H = norminv(hit_rate);
            z_of_F = norminv(FA_rate);
            d_prime = z_of_H - z_of_F;
            c_prime = (z_of_H + z_of_F)/-2;
            moving_d_prime = [moving_d_prime; daily_moving_matrix(h,1) d_prime daily_moving_matrix(h,3)];
            moving_c_prime = [moving_c_prime; daily_moving_matrix(h,1) c_prime daily_moving_matrix(h,3)];
        end
        
        %------------------------------------------------------------------
        %-Plot:Subplot 1: Trials vs. Detectability (% Correct, using the
        %-moving window)
        %------------------------------------------------------------------
        if length(daily_moving_matrix) > window_length
            clear p v
            figure;
            hold on;
            subplot(1,3,1)
            for i = 1:size(daily_moving_matrix,1)
                p(i) = daily_moving_matrix(i,2)/daily_moving_matrix(i,3);         %Calcs hit percent
                v(i) = 1.96*sqrt(p(i)*(1-p(i))/daily_moving_matrix(i,3));          %Calcs confidence intervals
            end
            plot(daily_moving_matrix(:,1),p','color','g','linewidth',2);
            set(gca,'XTick',[0:2*window_length:length(daily_moving_matrix)],...
                'XTickLabel',[0:2*window_length:(length(daily_moving_matrix)+window_length)],...
                'YTick',[0:0.2:1],'YTickLabel',[0:20:100],'FontWeight','Bold','FontSize',12);
            title([ratname ' Moving Window - ' num2str(date)],'FontWeight','Bold','FontSize',14)
            xlim([(window_length-10), (length(daily_moving_matrix)+window_length+10)]);
            ylim([0,1]);
            xlabel('Trial','FontWeight','Bold','FontSize',14);
            ylabel('Correct Response (%)','FontWeight','Bold','FontSize',14);
            line(0:10:1000, .5)
            %--------------------------------------------------------------
            %---Subplot 2: Trials vs. D-Prime
            %--------------------------------------------------------------
            hold on;
            subplot(1,3,2)
            plot(moving_d_prime(:,1),moving_d_prime(:,2),moving_c_prime(:,1),moving_c_prime(:,2),'linewidth',2);
            set(gca,'XTick',[0:2*window_length:length(moving_d_prime)],...
                'XTickLabel',[0:2*window_length:(length(moving_d_prime)+window_length)],...
                'YTick',[-0.5:0.5:3],'YTickLabel',[-0.5:0.5:3],'FontWeight','Bold','FontSize',12);
            title([ratname ' Moving D-Prime - ' num2str(date)],'FontWeight','Bold','FontSize',14)
            xlim([(window_length-10), (length(daily_moving_matrix)+window_length+10)]);
            ylim([-0.5,3]);
            xlabel('Trial','FontWeight','Bold','FontSize',14);
            ylabel('D-Prime','FontWeight','Bold','FontSize',14);
            line(0:10:1000, 1.96)
            line(0:10:1000, 0)
            hold off;
        else
            %--------------------------------------------------------------
            %-Displays "Insufficient Data" if the days data is not enough 
            %-tocreate Trials vs... graphs
            %--------------------------------------------------------------
            figure;
            hold on;
            subplot(1,3,1)
            set(gca,'XTick',[0:1:1],...
                'XTickLabel',[0:1:1],...
                'YTick',[0:0.2:1],'YTickLabel',[0:20:100],'FontWeight','Bold','FontSize',12);
            title([ratname ' Moving Window - ' num2str(date)],'FontWeight','Bold','FontSize',14)
            xlim([0,1]);
            ylim([0,1]);
            xlabel('Trial','FontWeight','Bold','FontSize',14);
            ylabel('Correct Response (%)','FontWeight','Bold','FontSize',14);
            line(0:10:1000, .5)
            text(.1,.5, texlabel('Insufficient Data'),'FontWeight','Bold','FontSize',15,...
                'Color','red','BackgroundColor','black');
            
            subplot(1,3,2)
            set(gca,'XTick',[0:2*window_length:length(moving_d_prime)],...
                'XTickLabel',[0:2*window_length:(length(moving_d_prime)+window_length)],...
                'YTick',[0:0.5:3],'YTickLabel',[0:0.5:3],'FontWeight','Bold','FontSize',12);
            title([ratname ' Moving D-Prime - ' num2str(date)],'FontWeight','Bold','FontSize',14)
            xlim([(window_length-10), (length(daily_moving_matrix)+window_length+10)]);
            ylim([0,3]);
            xlabel('Trial','FontWeight','Bold','FontSize',14);
            ylabel('D-Prime','FontWeight','Bold','FontSize',14);
            text(.1,1.5, texlabel('Insufficient Data'),'FontWeight','Bold','FontSize',15,...
                'Color','red','BackgroundColor','black');
        end
        %------------------------------------------------------------------
        %-Creates 'V-Curve' for this day's data
        %------------------------------------------------------------------
        subplot(1,3,3)
        clear p v
        for i = 1:size(daily_performance,1)
            p(i) = daily_performance(i,2)/daily_performance(i,3);       %Calcs hit percent
            v(i) = 1.96*sqrt(p(i)*(1-p(i))/daily_performance(i,3));          %Calcs confidence intervals
        end
        errorbar(daily_performance(:,1),p',v','color','g','linewidth',2);
        set(gca,'XTick',[-20:5:20],'XTickLabel',[-20:5:20],'YTick',[0:0.2:1],...
            'YTickLabel',[0:20:100],'FontWeight','Bold','FontSize',12);
        title([ratname ' Daily Performance - ' num2str(date)],'FontWeight','Bold','FontSize',14)
        xlim([-16, 16]);
        ylim([0,1]);
        xlabel('\Delta\it{f} \rm\bf(~%)','FontWeight','Bold','FontSize',14);
        ylabel('Correct Response (%)','FontWeight','Bold','FontSize',14);
        line(0:10:1000, .5)
        hold off;
    end
end




if ~isempty(overall_performance)
    overall_performance = sortrows(overall_performance,1);                  %Arranges the 'overall_performance' matrix in order
end
%------------------------------------------------------------------
%-Creates 'V-Curve' for all of the data for this rat on this stage
%------------------------------------------------------------------
figure;
clear p v
for i = 1:size(overall_performance,1)
    p(i) = overall_performance(i,2)/overall_performance(i,3);       %Calcs hit percent
    v(i) = 1.96*sqrt(p(i)*(1-p(i))/overall_performance(i,3));          %Calcs confidence intervals
end
errorbar(overall_performance(:,1),p',v','color','g','linewidth',2);
set(gca,'XTick',[-20:5:20],'XTickLabel',[-20:5:20],'YTick',[0:0.2:1],...
    'YTickLabel',[0:20:100],'FontWeight','Bold','FontSize',12);
title([ratname ' - Overall Performance - Stage ' num2str(stage)],'FontWeight','Bold','FontSize',14)
xlim([-16, 16]);
ylim([0,1]);
xlabel('\Delta\it{f} \rm\bf(~%)','FontWeight','Bold','FontSize',14);
ylabel('Correct Response (%)','FontWeight','Bold','FontSize',14);
line(0:10:1000, .5)