%-------------------
%---Set Variables---
%-------------------
ratname = 'Backhoe';
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
all_hits = [];
perc = [];
t=1;
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
                            if b > 7 | b < -7
                            all_hits(t,:) =[ t, (behav(rat).session(i).nosepoke_response(j) < 0.6)];
                            t=t+1;
                            end
                        end                            
                    end
                end
            end
        end
        if ~isempty(previous_performance)
            previous_performance = sortrows(previous_performance,1);
        end
        
%------------------------
        
s=1;
    for s=1:(t-26)
        perc(s,:) = [all_hits(s+25,1),sum(all_hits(s:s+25,2))/25];
    end
    
plot(perc(:,2))
        