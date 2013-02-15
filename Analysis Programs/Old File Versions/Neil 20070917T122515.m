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
        r = [1:6,16,26:31]
        previous_performance = previous_performance(r,:)