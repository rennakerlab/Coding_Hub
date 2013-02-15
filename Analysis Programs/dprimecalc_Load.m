%function dprimecalc_Load

[file path] = uigetfile('*.txt');
cd(path);

%warning('off','MATLAB:dispatcher:InexactMatch');

	data = textread(file,'%s');
	run.ratname = cell2mat(data(1));
	run.weight = str2num(cell2mat(data(2)));
	run.daycode = str2num(cell2mat(data(3)));
    run.novelsound = cell2mat(data(6));
  
    i = 23;                     %skips text at top of file
	trial = 0;
        
%%%%% defining arrays %%%%%%
    

    
	run.outcome = [];
	run.hits = [];
	run.miss = [];
	run.falsealarm = [];
    run.correctrej = [];
    run.novelhit = [];
    run.novelmiss = [];
    run.nonresp = [];            %omissions are non-responses
    
% Start of Tom's concatenating script %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for m = 23:1:(length(data)-12) %starts at 23, increments by 1, ends at length(data)-12
    current = data{m};
    next = data{m + 1};
        try 
            if(length(str2num(current)) == 0 && length(str2num(next)) == 0)
            newstring = [current next];
            data{m} = newstring;
            data{m+1} = -1;
            end
        catch
    end
end
    
new_data = {};

for i = 1:length(data)
    if(data{i} ~= -1)
        data{1} ~= -1;
        new_data(length(new_data)+1) = data(i);
    end
end

data = new_data;
data = reshape(data, length(data), 1); %linearizes the data into one column

%data %outputs data

% End of concatenating script %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  2 is light, 1 is sound                        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  if its a 2 and 2 then its a correct rejection %
%  if its a 1 and 1 then its a hit               %
%  if its a 1 and 2 then its a miss              %
%  if its a 2 and 1 then its a false alarm       %
%  if its a 1 and 0 then omit                    %
%  if its a 2 and 0 then omit                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

i = 23;

while i < (length(data)-12)  % "-12" gets rid of the junk at the bottom
    trial = trial + 1;
    temp = cell2mat(data(i+4)); % goes from trial # to outcome
    run.outcome = [run.outcome; temp(1)];

    if(temp(1) == 'f' || temp(1) == 'F')
        i = i + 6;
        
    elseif(temp(1) == 'h' || temp(1) == 'w' || temp(1) == 'm')
        temp = str2num(cell2mat(data(i+7)));
        
        if temp(1) == 2
            temp = str2num(cell2mat(data(i+8)));
            if temp(1) == 2
               run.correctrej = [run.correctrej; trial];
            elseif temp(1) == 1
               run.falsealarm = [run.falsealarm; trial];
            elseif temp(1) == 0
               run.nonresp = [run.nonresp; trial];
            end
            i = i + 11;
        
        elseif temp(1) == 1
            temp = str2num(cell2mat(data(i+8)));
            if temp(1) == 1
                run.hits = [run.hits; trial];
            %    i = i + 11;
            elseif temp(1) == 2
                run.miss = [run.miss; trial];
            %    i = i + 11;
            elseif temp(1) == 0
                run.nonresp = [run.nonresp; trial];
            %    i = i + 11;
            end
            i = i + 11;
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Displays the number in each array        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%     disp('outcomes');
%     disp(length(run.outcome));
%     disp('hits');
%     disp(length(run.hits));
%     disp('miss');
%     disp(length(run.miss));
%     disp('false alarms');
%     disp(length(run.falsealarm));
%     disp('correct rejections');
%     disp(length(run.correctrej));
%     disp('novel hit');
%     disp(length(run.novelhit));
%     disp('novel miss');
%     disp(length(run.novelmiss));
%     disp('non-responses');
%     disp(length(run.nonresp));
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Detection Theory stuff:               %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%     d' = z(H)-z(F)                    %
%     c = (1/2)*[z(H)+z(F)]             % 
%     c' = c/d'                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

H = length(run.hits)/(length(run.hits) + length(run.miss));
F = length(run.falsealarm)/(length(run.falsealarm) + length(run.correctrej));

if F == 0
    F = 0.001;
end

c = 0.5*(norminv(H,0,1) + norminv(F,0,1));

dprime = norminv(H,0,1) - norminv(F,0,1);

cprime = c/dprime;

dprime

cprime

% total = length(run.hits) + length(run.miss) + length(run.falsealarm) 
%         + length(run.correctrej) + length(run.novelhit) + length(run.novelmiss)
%         + length(run.nonresp);
% 
% total
% 
% length(run.outcome)