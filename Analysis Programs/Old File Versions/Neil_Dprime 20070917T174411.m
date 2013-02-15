%-------------------
%---Set Variables---
%-------------------
ratname = 'Cannonball';
stage = 8;

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
d_prime_vect = [];
moving_matrix = [];
        a = find([behav(rat).session(:).stage] == stage & [behav(rat).session(:).mk801_dose] == 0);
        for i = a
            d_prime_vect = [];
            moving_matrix = [];
            for j = 1:behav(rat).session(i).trials
                if ~any(behav(rat).session(i).outcome(j) == 'AT') & behav(rat).session(i).intensity(j) == 60;  
                  if behav(rat).session(i).outcome(j) == 'H'
                        d_prime_vect = [d_prime_vect; 1 0 0 0];
                    elseif behav(rat).session(i).outcome(j) == 'M'
                        d_prime_vect = [d_prime_vect; 0 1 0 0];
                    elseif behav(rat).session(i).outcome(j) == 'C'
                        d_prime_vect = [d_prime_vect; 0 0 1 0];
                    elseif behav(rat).session(i).outcome(j) == 'F'
                        d_prime_vect = [d_prime_vect; 0 0 0 1];
                    end

                    if(length(d_prime_vect) > 50)
                        d_prime_vect = d_prime_vect(2:51,:);
                        moving_hits = (sum(d_prime_vect(:,1)));
                        moving_misses = (sum(d_prime_vect(:,2)));
                        moving_FA = (sum(d_prime_vect(:,3)));
                        moving_CR = (sum(d_prime_vect(:,4)));
                    else
                        moving_hits = (sum(d_prime_vect(:,1)));
                        moving_misses = (sum(d_prime_vect(:,2)));
                        moving_FA = (sum(d_prime_vect(:,3)));
                        moving_CR = (sum(d_prime_vect(:,4)));
                    if moving_misses > 0;
                    moving_hit_rate = (moving_hits)/(moving_hits + moving_misses);
                    else
                        moving_hit_rate = (moving_hits - .5)/(moving_hits + moving_misses);
                    end
                    if moving_FA > 0;
                        moving_FA_rate = (moving_FA)/(moving_FA + moving_CR);
                    else
                        moving_FA_rate = (.5)/(moving_FA + moving_CR);
                    end
                    moving_z_of_H = norminv(moving_hit_rate);
                    moving_z_of_F = norminv(moving_FA_rate);
                    moving_d_prime = moving_z_of_F - moving_z_of_H; 
                    moving_a_prime = 0.5 + ((moving_hit_rate-moving_FA_rate)*(1 + (moving_hit_rate-moving_FA_rate)))/(4*moving_hit_rate *(1-moving_FA_rate));
                    moving_matrix = [moving_matrix; i moving_d_prime moving_a_prime];
                    end
                end
            end
            
            figure
            plot(moving_matrix(:,2),'r')
            hold on;
            plot(moving_matrix(:,3),'g')
            moving_matrix = [];
        end
%         if ~isempty(previous_performance)
%             previous_performance = sortrows(previous_performance,1);
%         end

                    