function varargout = Gap_Detection_Audiogram(varargin)

datapath = 'Z:\Gap Detection Startle\Behavior Data\';                       %Define the general folder for saving behavioral data text files.
datafile = [datapath 'noise_gap_detection_data.mat'];                       %All behavioral data is primarily saved in one large structure in a *.mat file.
load(datafile);                                                             %Load the primary behavioral data structure.


buttonChoice = questdlg('Check by rat(s) or by stage?',...                  %Query user for lookup mode: by rat or by stage.
                        'Rat Audiogram','Rat','Stage','Rat');

switch buttonChoice                    
    case 'Rat'                                                              %User wants to lookup by rat.
        rats = {detectdata.ratname};                                        %Make a cell array holding all the rat names.
        if nargin == 0                                                      %If the user didn't specify a rat in the function call...
            chosenRats = listdlg('liststring',rats,...
                'promptstring','Which rat(s) do you want to check?:',...
                'okstring','Select Rat(s)',...
                'cancelstring','Cancel',...
                'Name','Rat Audiogram',...
                'selectionmode','multiple',...
                'listsize',[400,300],...
                'uh',30);
            if isempty(chosenRats)                                          %If the user canceled selection...
                return                                                      %Skip execution of the rest of the function.
            end
        else                                                                %Otherwise, if the user did specify a rat in the function call.
            chosenRats = find(strcmpi(varargin{1},rats));                   %Find the index for the entered rat.
            if isempty(chosenRats)                                          %If no matching rat was found...
                error(['ERROR IN AUDIOGRAM: Couldn''t find the rat: '...
                    varargin{1} '!']);                                      %Return an error.
            end
        end
        if nargin > 1                                                       %If the user specified a display option.
            display = varargin{2};                                          %Set the display option to what the user specified.
        else                                                                %Otherwise, if no display option was specified.
            display = 'off';                                                %Display the audiogram by default.
        end

        warning off stats:glmfit:PerfectSeparation;                         %Turn off the "perfect fit" warning for gmlfit.


        allStages = [];                                                     %Create a vector to hold all stages available across chosen rats.
        for i = 1:length(chosenRats)                                        %Fill aforementioned vector.
            allStages = [allStages unique([detectdata(chosenRats(i)).session.stage])]; %Using unique here to only grab the unique stages for each rat.
        end
        uniqueAllStages = unique(allStages);                                %Using unique once again to trim to the unique stages across all chosen rats.
        stageCount = histc(allStages, uniqueAllStages);                     %Use a histogram count to tally the occurrence of each stage.
        sharedStages = [];                                                  %Create a vector to hold the unique stages shared across all chosen rats.
        for i = 1:length(stageCount)                                        %Fill aforementioned vector.
            if stageCount(i) == length(chosenRats)
                sharedStages = [sharedStages uniqueAllStages(i)];
            end
        end
        stagesCellArray = strread(num2str(sharedStages),'%s');              %Create a cell array from the shared stages vector for a list dialog box.
        if length(chosenRats) > 1                                           %If more than 1 rat was chosen...
            listIndex = listdlg('liststring',stagesCellArray,...            %Display the list dialog box and receive a list index as input.
                                'promptstring','Which shared stage do you want to check?',...
                                'okstring','Select Stage',...
                                'cancelstring','Cancel',...
                                'Name','Rat Audiogram',...
                                'selectionmode','single',...
                                'listsize',[400,300],...
                                'uh',30);
        else                                                                %Only 1 rat was chosen.
            listIndex = listdlg('liststring',stagesCellArray,...            %Display the list dialog box and receive a list index as input.
                                'promptstring','Which stage do you want to check?',...
                                'okstring','Select Stage',...
                                'cancelstring','Cancel',...
                                'Name','Rat Audiogram',...
                                'selectionmode','single',...
                                'listsize',[400,300],...
                                'uh',30);
        end
        chosenStage = stagesCellArray(listIndex);                           %Store the stage chosen as a string.
        for i = 1:length(chosenRats)
            a = ([detectdata(chosenRats(i)).session(:).stage] ~= str2double(chosenStage)); %Find all stages that aren't the chosen stage.
            detectdata(chosenRats(i)).session(a) = [];                      %Kick out all non-chosen stages.
        end
        if (str2double(chosenStage) == 13 || str2double(chosenStage) == 14) %If the chosen stage is 13 or 14...
            allStageIDs = {};                                               %Create a cell array to hold all stage IDs available across chosen rats.
            for i = 1:length(chosenRats)                                    %Fill aforementioned cell array.
                allStageIDs = {allStageIDs{:} detectdata(chosenRats(i)).session.stageid};
            end
            allStageIDs(cellfun('isempty',allStageIDs)) = [];               %Remove empty cells.
            [uniqueAllStageIDs, firstIndex, secondIndex] = unique(allStageIDs); %Using unique to trim to the unique stage IDs across all chosen rats.
            stageIDCount = histc(secondIndex, 1:length(firstIndex));        %Use a histogram count to tally the occurrence of each stage ID.
            sharedStageIDs = {};                                            %Create a cell array to hold the unique stage IDs shared across all chosen rats.
            for i = 1:length(stageIDCount)
                if stageIDCount(i) == length(chosenRats)
                    sharedStageIDs = {sharedStageIDs{:} uniqueAllStageIDs{i}};
                end
            end
            listIndex = listdlg('liststring',sharedStageIDs,...             %Display the list dialog box and receive a list index as input.
                    'promptstring','Which stage ID do you want to check?',...
                    'okstring','Select Stage ID',...
                    'cancelstring','Cancel',...
                    'Name','Rat Audiogram',...
                    'selectionmode','single',...
                    'listsize',[400,300],...
                    'uh',30);
            chosenStageID = sharedStageIDs{listIndex};                      %Store the stage chosen stage ID as a string.
            for i = 1:length({detectdata.ratname})                          %For each rat in the data structure...
               if(isfield(detectdata(i).session, 'stageid') == 1)           %If the rat has records with a stageid field...
                    a = strcmpi(vertcat({detectdata(i).session.stageid}),chosenStageID);
                    detectdata(i).session(~a) = [];                         %Remove the records that don't match the chosen stage ID.
               end
           end
        end
    case 'Stage'                                                            %User wants to lookup by stage.
        allStages = [];                                                     %Create a vector to hold all stages available across all rats.
        for i = 1:length({detectdata.ratname})                              %Fill aforementioned vector.
            allStages = [allStages unique([detectdata(i).session.stage])];  %Using unique here to only grab the unique stages for each rat.
        end
        uniqueAllStages = unique(allStages);                                %Using unique once again to trim to the unique stages across all rats.
        stagesCellArray = strread(num2str(uniqueAllStages),'%s');           %Create a cell array from the stage vector for a list dialog box.
        listIndex = listdlg('liststring',stagesCellArray,...                %Display the list dialog box and receive a list index as input.
                            'promptstring','Which stage do you want to check?',...
                            'okstring','Select Stage',...
                            'cancelstring','Cancel',...
                            'Name','Rat Audiogram',...
                            'selectionmode','single',...
                            'listsize',[400,300],...
                            'uh',30);
       chosenStage = stagesCellArray(listIndex);                            %Store the stage chosen as a string.
       for i = 1:length({detectdata.ratname})
           a = ([detectdata(i).session(:).stage] ~= str2double(chosenStage)); %Find all stages that aren't the chosen stage.
           detectdata(i).session(a) = [];                                   %Kick out all non-chosen stages.
       end
       if (str2double(chosenStage) == 13 || str2double(chosenStage) == 14)  %If the chosen stage is 13 or 14...
           allStageIDs = {};
           for i = 1:length({detectdata.ratname})
               if(isfield(detectdata(i).session, 'stageid') == 1)
                   allStageIDs = {allStageIDs{:} detectdata(i).session.stageid};
               end
           end
           allStageIDs(cellfun('isempty',allStageIDs)) = [];
           uniqueAllStageIDs = unique(allStageIDs);
           listIndex = listdlg('liststring',uniqueAllStageIDs,...           %Display the list dialog box and receive a list index as input.
                   'promptstring','Which stage ID do you want to check?',...
                   'okstring','Select Stage ID',...
                   'cancelstring','Cancel',...
                   'Name','Rat Audiogram',...
                   'selectionmode','single',...
                   'listsize',[400,300],...
                   'uh',30);
           chosenStageID = uniqueAllStageIDs{listIndex};                    %Store the chosen stage ID as a string.
       end
       if (str2double(chosenStage) == 13 || str2double(chosenStage) == 14)  %If the chosen stage is 13 or 14...
           ratsCellArray = {};
           for i = 1:length({detectdata.ratname})                           %For each rat in the data structure...
               if(isfield(detectdata(i).session, 'stageid') == 1)           %If the rat has records with a stageid field...
                    a = strcmpi(vertcat({detectdata(i).session.stageid}),chosenStageID);
                    detectdata(i).session(~a) = [];                         %Remove the records that don't match the chosen stage ID.
                    if (isempty(a) == 0)                                    %If the rat possesses the chosen stage ID...
                         ratsCellArray = {ratsCellArray{:} detectdata(i).ratname}; %Add that rat to the aforementioned cell array.
                    end
               end
           end
       else
           ratsCellArray = {};
           for i = 1:length({detectdata.ratname})                           %For each rat in the data structure...
               if (isempty(detectdata(i).session) == 0)                     %If the rat has completed the chosen stage...
                   ratsCellArray = {ratsCellArray{:} detectdata(i).ratname}; %Add that rat to the aforementioned cell array.
               end
           end
       end
       listIndex = listdlg('liststring',ratsCellArray,...                   %Display the list dialog box and receive a list index as input.
                   'promptstring','Which rat(s) do you want to check?',...
                   'okstring','Select Rat(s)',...
                   'cancelstring','Cancel',...
                   'Name','Rat Audiogram',...
                   'selectionmode','multiple',...
                   'listsize',[400,300],...
                   'uh',30);
        rats = {detectdata.ratname};       
        for i = 1:length(listIndex)
            chosenRats(i) = find(strcmpi((ratsCellArray{listIndex(i)}),rats));
        end
        if nargin > 1                                                       %If the user specified a display option.
            display = varargin{2};                                          %Set the display option to what the user specified.
        else                                                                %Otherwise, if no display option was specified.
            display = 'off';                                                 %Display the audiogram by default.
        end

        warning off stats:glmfit:PerfectSeparation;                         %Turn off the "perfect fit" warning for gmlfit.
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%At this point one should have:
%chosenRats - array of indices of chosen rats
%chosenStage - string for chosen stage
%if stage 13 or 14, chosenStageID - string for chosen stage ID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if str2double(chosenStage) == 13                                                    %If the chosen stage is stage 13...
    prevPerfMatrix = [];
    for ratIndex = 1:length(chosenRats)
        %% Load the historical performance of the rat on this stage. 
        if nargin > 2                                                               %If a third input argument was specified...
            num_days = varargin{3};                                                 %Set the number of previous days to look for.
            temp = zeros(length(detectdata(chosenRats(ratIndex)).session),1);       %Create a matrix to hold the session times for all sessions.
            for i = 1:length(temp)                                                  %Step through each session.
                temp(i) = detectdata(chosenRats(ratIndex)).session(i).clock_reading(1); %Grab the first trial's clock reading for each session.
            end
            d = unique(fix(temp));                                                  %Find the unique days that sessions were run.
            d = sort(d,'descend');                                                  %Sort the clock readings in descending order.
            if length(d) > num_days                                                 %If there's more than the requested number of days...
                d = d(num_days);                                                    %Set the day cut-off to the requested number of days.
            else                                                                    %Otherwise, if there's not that many days...
                d = d(end);                                                         %Set the day cut-off to include all the days.
            end
            detectdata(chosenRats(ratIndex)).session(temp < d) = [];                %Kick out all sessions older than the specified cut-off.
        end
        if ~isempty(detectdata(chosenRats(ratIndex)).session)                       %If there were any stage 4 sessions...
            durs = vertcat(detectdata(chosenRats(ratIndex)).session.duration);      %Grab all of the tone durations...
            d = mode(durs);                                                         %Find the mode of the noiseburst durations.
            freqs = floor(vertcat(detectdata(chosenRats(ratIndex)).session.freq));  %Grab all of the tested frequencies.
            freqs(durs ~= d) = [];                                                  %Kick out all trials not at the mode of the noiseburst durations.
            ints = vertcat(detectdata(chosenRats(ratIndex)).session.intensity);     %Grab all of the tested intensities.
            ints(durs ~= d) = [];                                                   %Kick out all trials not at the mode of the noiseburst durations.
            outcomes = vertcat(detectdata(chosenRats(ratIndex)).session.outcome);   %Grab all of the outcomes.
            outcomes(durs ~= d) = [];                                               %Kick out all trials not at the mode of the noiseburst durations.
            test_freqs = unique(freqs)';                                            %Find all of the unique tested frequencies.
            test_ints = unique(ints)';                                              %Find all of the unique tested intensities.
            prev_perf = zeros(length(test_ints),length(test_freqs),2);              %Create a matrix to hold historical threshold map data.
            for f = test_freqs                                                      %Step through each tested frequency.
                for i = test_ints                                                   %Step through each tested intensity.
                    a = (f == freqs & i == ints);                                   %Find all trials with this frequency/intensity combination.
                    if any(a == 1)                                                  %If there were any trials for this frequency/intensity combination.
                        prev_perf(i==test_ints,f==test_freqs,1) = ...
                            sum(outcomes(a) == 'H');                                %Save the total number of hits for this frequency/intensity combination.
                        prev_perf(i==test_ints,f==test_freqs,2) = ...
                            sum(outcomes(a) == 'H' | outcomes(a) == 'M');           %Save the total number of trials for this frequency/intensity combination.
                    end
                end
            end
        %     false_alarm = sum(outcomes=='F')/sum(outcomes =='F' | outcomes =='C'); %Calculate the false alarm rate.
            prev_perf = prev_perf(:,:,1)./prev_perf(:,:,2);                         %Convert the hit and trial counts to hit rate.
        %     prev_perf = (prev_perf-false_alarm)/(1-false_alarm);                  %Correct the hit rates for false alarm rate.
            audiogram = nan(1,length(test_freqs));                                  %Create a variable to hold the audiogram.            
            for i = 1:size(prev_perf,2)                                             %Step through each tested frequencies.
                disp(size(prev_perf,2))
                if all(prev_perf(:,i) == 1 | prev_perf(:,i) == 0)                   %If all of the datapoints are ones or zeros...
                    a = find(prev_perf(:,i) == 0,1,'last');                         %Find the last zero in the list of datapoints.
                    b = find(prev_perf(:,i) == 1,1,'first');                        %Find the first one in the list of datapoints.
                    if b > a                                                        %If the first one came after the last zero...
                        audiogram(i) = mean([a,b]);                                 %Set the 50% threshold to halfway between the last zero and first one.
                        disp(audiogram(i))
                        b = glmfit(1:length(test_ints),prev_perf(:,i),'binomial');  %Just to give yfit something to work with when calculating other hit rates
                        disp(b)
                    end
                end
                %audiogram(i)
                if isnan(audiogram(i))                                              %If the threshold for this frequency still isn't set...
                    b = glmfit(1:length(test_ints),prev_perf(:,i),'binomial');      %Fit a binomial regression to the hit-rates.
                    audiogram(i) = -b(1)/b(2);                                      %Find the 50% inflection point in the logistic regression.
                end
                xfit = test_ints(1):0.01:test_ints(end);
                yfit = glmval(b, xfit, 'logit');
                disp(yfit)
                    testhitrates = [0.2:0.1:0.8];
                    hitvsint = zeros(length(testhitrates), length(test_freqs));

                    for l = 1:length(testhitrates)
                        loind = find(yfit < testhitrates(l), 1, 'last');
                        hiind = find(yfit >= testhitrates(l), 1, 'first');
                        %disp([loind,hiind])
                        %pause
                        if loind == length(xfit)
                            hitvsints(l,i) = test_ints(end);
                        elseif hiind == 1
                            hitvsints(l,i) = test_ints(1);
                        else
                            hitvsints(l,i) = xfit(loind);
        %                     multiplier = (testhitrates(l) - yfit(loind))/(yfit(hiind) - yfit(loind));
        %                     hitvsints(l,i) = multiplier*(test_ints(hiind) - test_ints(loind)) + test_ints(loind);
                        end

                    end 
            end
            if strcmpi(display,'on');                                               %If the display option is turned on...
                figure('color','w');                                                %Create a new figure.
                axes('units','normalized','position',[0.1 0.2 0.89 0.74]);          %Create new axes.
                imagesc(prev_perf);                                                 %Show the corrected hit rates a scaled colormap.
                temp = flipud(gray);                                                %Grab the grayscale steps.
                temp = 0.5+temp/2;                                                  %Light up all the grayscale steps by half.
                colormap(temp);                                                     %Use a flipped grayscale as the colorscale in the colormap.
                set(gca,'ydir','normal');                                           %Flip the colormap around right-side up.
                hold on;                                                            %Hold the axes for overlaying plots.
                line([1.5,1.5],ylim,'color','k','linestyle',':');                   %Plot a line to mark off the BBN column.
                plot(audiogram,'color','r','linewidth',2,'marker','*');             %Overlay the thresholds on the audiogram.
                hold off;                                                           %Release the plot hold.
                set(gca,'ytick',1:length(test_ints),'yticklabel',test_ints);        %Label the y-axis.
                temp = cell(length(test_freqs),1);                                  %Create a cell array to hold the x-axis labels.
                for i = 1:length(test_freqs)                                        %Step through each of the tested frequencies.
                    temp{i} = num2str(test_freqs(i)/1000,'%1.1f');                  %Convert each frequency to kHz.
                end
                temp{test_freqs == 0} = 'BBN';                                      %Label the broadband noise column as BBN.
                set(gca,'xtick',1:length(test_freqs),'xticklabel',temp);            %Label the x-axis.
                xticklabel_rotate(90);                                              %Rotate the x-axis labels by 90 degrees.
                ylabel('Intensity (dB)');                                           %Label the y-axis.
                a = xlabel('Frequency (kHz)');                                      %Label the x-axis.
                set(a,'position',[mean(xlim),min(ylim)-0.15*range(ylim)]);          %Reposition the x-axis.
                title(['Audiogram: ' rats{chosenRats(ratIndex)}]);                  %Show the rat's name in the title
            else
                %step_size = test_ints(2) - test_ints(1);
                %audiogram = test_ints(1) + step_size*audiogram-10;
                %hitvsints = test_ints(1) + step_size*hitvsints;
            end
        else                                                                        %Otherwise, if there's no stage 4 sessions...
            audiogram = [];                                                         %Set the audiogram to an empty matrix.
            test_freqs = [];
            hitvsints = [];
            prev_perf = [];
        end
        prevPerfMatrix = [prevPerfMatrix; prev_perf];
    end
    disp('prevPerfMatrix:');
    disp(prevPerfMatrix);
    %varargout{1} = audiogram;                                                   %Output the audiogram if the user asked for it.
    varargout{2} = test_freqs;
    %varargout{3} = hitvsints;
    %varargout{4} = prev_perf;   
    varargout{1} = prevPerfMatrix;
elseif str2double(chosenStage) == 14                                                %If the chosen stage is stage 14...
    prevPerfMatrix = [];
    for ratIndex = 1:length(chosenRats)
        %% Load the historical performance of the rat on this stage. 
        if nargin > 2                                                               %If a third input argument was specified...
            num_days = varargin{3};                                                 %Set the number of previous days to look for.
            temp = zeros(length(detectdata(chosenRats(ratIndex)).session),1);       %Create a matrix to hold the session times for all sessions.
            for i = 1:length(temp)                                                  %Step through each session.
                temp(i) = detectdata(chosenRats(ratIndex)).session(i).clock_reading(1); %Grab the first trial's clock reading for each session.
            end
            d = unique(fix(temp));                                                  %Find the unique days that sessions were run.
            d = sort(d,'descend');                                                  %Sort the clock readings in descending order.
            if length(d) > num_days                                                 %If there's more than the requested number of days...
                d = d(num_days);                                                    %Set the day cut-off to the requested number of days.
            else                                                                    %Otherwise, if there's not that many days...
                d = d(end);                                                         %Set the day cut-off to include all the days.
            end
            detectdata(chosenRats(ratIndex)).session(temp < d) = [];                %Kick out all sessions older than the specified cut-off.
        end
        if ~isempty(detectdata(chosenRats(ratIndex)).session)                       %If there were any stage 4 sessions...
            durs = vertcat(detectdata(chosenRats(ratIndex)).session.duration);      %Grab all of the tone durations...
            d = mode(durs);                                                         %Find the mode of the noiseburst durations.
            freqs = floor(vertcat(detectdata(chosenRats(ratIndex)).session.freq));  %Grab all of the tested frequencies.
            freqs(durs ~= d) = [];                                                  %Kick out all trials not at the mode of the noiseburst durations.
            ints = vertcat(detectdata(chosenRats(ratIndex)).session.intensity);     %Grab all of the tested intensities.
            ints(durs ~= d) = [];                                                   %Kick out all trials not at the mode of the noiseburst durations.
            outcomes = vertcat(detectdata(chosenRats(ratIndex)).session.outcome);   %Grab all of the outcomes.
            outcomes(durs ~= d) = [];                                               %Kick out all trials not at the mode of the noiseburst durations.
            test_freqs = unique(freqs)';                                            %Find all of the unique tested frequencies.
            test_ints = unique(ints)';                                              %Find all of the unique tested intensities.
            prev_perf = zeros(length(test_ints),length(test_freqs),2);              %Create a matrix to hold historical threshold map data.
            for f = test_freqs                                                      %Step through each tested frequency.
                for i = test_ints                                                   %Step through each tested intensity.
                    a = (f == freqs & i == ints);                                   %Find all trials with this frequency/intensity combination.
                    if any(a == 1)                                                  %If there were any trials for this frequency/intensity combination.
                        prev_perf(i==test_ints,f==test_freqs,1) = ...
                            sum(outcomes(a) == 'H');                                %Save the total number of hits for this frequency/intensity combination.
                        prev_perf(i==test_ints,f==test_freqs,2) = ...
                            sum(outcomes(a) == 'H' | outcomes(a) == 'M');           %Save the total number of trials for this frequency/intensity combination.
                    end
                end
            end
        %     false_alarm = sum(outcomes=='F')/sum(outcomes =='F' | outcomes =='C'); %Calculate the false alarm rate.
            prev_perf = prev_perf(:,:,1)./prev_perf(:,:,2);                         %Convert the hit and trial counts to hit rate.
        %     prev_perf = (prev_perf-false_alarm)/(1-false_alarm);                  %Correct the hit rates for false alarm rate.
            audiogram = nan(1,length(test_freqs));                                  %Create a variable to hold the audiogram.            
            for i = 1:size(prev_perf,2)                                             %Step through each tested frequencies.
                disp(size(prev_perf,2))
                if all(prev_perf(:,i) == 1 | prev_perf(:,i) == 0)                   %If all of the datapoints are ones or zeros...
                    a = find(prev_perf(:,i) == 0,1,'last');                         %Find the last zero in the list of datapoints.
                    b = find(prev_perf(:,i) == 1,1,'first');                        %Find the first one in the list of datapoints.
                    if b > a                                                        %If the first one came after the last zero...
                        audiogram(i) = mean([a,b]);                                 %Set the 50% threshold to halfway between the last zero and first one.
                        disp(audiogram(i))
                        %b = glmfit(1:length(test_ints),prev_perf(:,i),'binomial');  %Just to give yfit something to work with when calculating other hit rates
                        disp(b);
                    end
                end
                %audiogram(i)
                if isnan(audiogram(i))                                              %If the threshold for this frequency still isn't set...
                    b = glmfit(1:length(test_ints),prev_perf(:,i),'binomial');      %Fit a binomial regression to the hit-rates.
                    audiogram(i) = -b(1)/b(2);                                      %Find the 50% inflection point in the logistic regression.
                end
                xfit = test_ints(1):0.01:test_ints(end);
                yfit = glmval(b, xfit, 'logit');
                %disp(yfit);
                    testhitrates = [0.2:0.1:0.8];
                    hitvsint = zeros(length(testhitrates), length(test_freqs));

                    for l = 1:length(testhitrates)
                        loind = find(yfit < testhitrates(l), 1, 'last');
                        hiind = find(yfit >= testhitrates(l), 1, 'first');
                        %disp([loind,hiind])
                        %pause
                        if loind == length(xfit)
                            hitvsints(l,i) = test_ints(end);
                        elseif hiind == 1
                            hitvsints(l,i) = test_ints(1);
                        else
                            hitvsints(l,i) = xfit(loind);
        %                     multiplier = (testhitrates(l) - yfit(loind))/(yfit(hiind) - yfit(loind));
        %                     hitvsints(l,i) = multiplier*(test_ints(hiind) - test_ints(loind)) + test_ints(loind);
                        end

                    end 
            end
            if strcmpi(display,'on');                                               %If the display option is turned on...
                figure('color','w');                                                %Create a new figure.
                axes('units','normalized','position',[0.1 0.2 0.89 0.74]);          %Create new axes.
                imagesc(prev_perf);                                                 %Show the corrected hit rates a scaled colormap.
                temp = flipud(gray);                                                %Grab the grayscale steps.
                temp = 0.5+temp/2;                                                  %Light up all the grayscale steps by half.
                colormap(temp);                                                     %Use a flipped grayscale as the colorscale in the colormap.
                set(gca,'ydir','normal');                                           %Flip the colormap around right-side up.
                hold on;                                                            %Hold the axes for overlaying plots.
                line([1.5,1.5],ylim,'color','k','linestyle',':');                   %Plot a line to mark off the BBN column.
                plot(audiogram,'color','r','linewidth',2,'marker','*');             %Overlay the thresholds on the audiogram.
                hold off;                                                           %Release the plot hold.
                set(gca,'ytick',1:length(test_ints),'yticklabel',test_ints);        %Label the y-axis.
                temp = cell(length(test_freqs),1);                                  %Create a cell array to hold the x-axis labels.
                for i = 1:length(test_freqs)                                        %Step through each of the tested frequencies.
                    temp{i} = num2str(test_freqs(i)/1000,'%1.1f');                  %Convert each frequency to kHz.
                end
                temp{test_freqs == 0} = 'BBN';                                      %Label the broadband noise column as BBN.
                set(gca,'xtick',1:length(test_freqs),'xticklabel',temp);            %Label the x-axis.
                xticklabel_rotate(90);                                              %Rotate the x-axis labels by 90 degrees.
                ylabel('Intensity (dB)');                                           %Label the y-axis.
                a = xlabel('Frequency (kHz)');                                      %Label the x-axis.
                set(a,'position',[mean(xlim),min(ylim)-0.15*range(ylim)]);          %Reposition the x-axis.
                title(['Audiogram: ' rats{chosenRats(ratIndex)}]);                            %Show the rat's name in the title
            else
                step_size = test_ints(2) - test_ints(1);
                audiogram = test_ints(1) + step_size*audiogram-10;
                %hitvsints = test_ints(1) + step_size*hitvsints;
            end
        else                                                                        %Otherwise, if there's no stage 4 sessions...
            audiogram = [];                                                         %Set the audiogram to an empty matrix.
            test_freqs = [];
            hitvsints = [];
            prev_perf = [];
        end
        prev_perf
        disp(chosenRats(ratIndex));
        prevPerfMatrix = [prevPerfMatrix; col_mean(prev_perf)];
        disp(prevPerfMatrix)
    end
    disp('prevPerfMatrix:');
    disp(prevPerfMatrix);
    varargout{1} = prevPerfMatrix;
    %varargout{1} = audiogram;                                                   %Output the audiogram if the user asked for it.
    varargout{2} = test_freqs;
    %varargout{3} = hitvsints;
    %varargout{4} = nanmean(prev_perf); 
else                                                                                %If the chosen stage is not 13 or 14...
    audiogramMatrix = [];
    for ratIndex = 1:length(chosenRats)
        %% Load the historical performance of the rat on this stage.
        if nargin > 2                                                               %If a third input argument was specified...
            num_days = varargin{3};                                                 %Set the number of previous days to look for.
            temp = zeros(length(detectdata(chosenRats(ratIndex)).session),1);       %Create a matrix to hold the session times for all sessions.
            for i = 1:length(temp)                                                  %Step through each session.
                temp(i) = detectdata(chosenRats(ratIndex)).session(i).clock_reading(1); %Grab the first trial's clock reading for each session.
            end
            d = unique(fix(temp));                                                  %Find the unique days that sessions were run.
            d = sort(d,'descend');                                                  %Sort the clock readings in descending order.
            if length(d) > num_days                                                 %If there's more than the requested number of days...
                d = d(num_days);                                                    %Set the day cut-off to the requested number of days.
            else                                                                    %Otherwise, if there's not that many days...
                d = d(end);                                                         %Set the day cut-off to include all the days.
            end
            detectdata(chosenRats(ratIndex)).session(temp < d) = [];                %Kick out all sessions older than the specified cut-off.
        end
        if ~isempty(detectdata(chosenRats(ratIndex)).session)                       %If there were any stage 4 sessions...
            durs = vertcat(detectdata(chosenRats(ratIndex)).session.duration);      %Grab all of the tone durations...
            d = mode(durs);                                                         %Find the mode of the noiseburst durations.
            freqs = floor(vertcat(detectdata(chosenRats(ratIndex)).session.freq));  %Grab all of the tested frequencies.
            freqs(durs ~= d) = [];                                                  %Kick out all trials not at the mode of the noiseburst durations.
            ints = vertcat(detectdata(chosenRats(ratIndex)).session.intensity);     %Grab all of the tested intensities.
            ints(durs ~= d) = [];                                                   %Kick out all trials not at the mode of the noiseburst durations.
            outcomes = vertcat(detectdata(chosenRats(ratIndex)).session.outcome);   %Grab all of the outcomes.
            outcomes(durs ~= d) = [];                                               %Kick out all trials not at the mode of the noiseburst durations.
            test_freqs = unique(freqs)';                                            %Find all of the unique tested frequencies.
            test_ints = unique(ints)';                                              %Find all of the unique tested intensities.
            prev_perf = zeros(length(test_ints),length(test_freqs),2);              %Create a matrix to hold historical threshold map data.
            for f = test_freqs                                                      %Step through each tested frequency.
                for i = test_ints                                                   %Step through each tested intensity.
                    a = (f == freqs & i == ints);                                   %Find all trials with this frequency/intensity combination.
                    if any(a == 1)                                                  %If there were any trials for this frequency/intensity combination.
                        prev_perf(i==test_ints,f==test_freqs,1) = ...
                            sum(outcomes(a) == 'H');                                %Save the total number of hits for this frequency/intensity combination.
                        prev_perf(i==test_ints,f==test_freqs,2) = ...
                            sum(outcomes(a) == 'H' | outcomes(a) == 'M');           %Save the total number of trials for this frequency/intensity combination.
                    end
                end
            end
        %     false_alarm = sum(outcomes=='F')/sum(outcomes =='F' | outcomes =='C');%Calculate the false alarm rate.
            prev_perf = prev_perf(:,:,1)./prev_perf(:,:,2);                         %Convert the hit and trial counts to hit rate.
        %     prev_perf = (prev_perf-false_alarm)/(1-false_alarm);                  %Correct the hit rates for false alarm rate.
            audiogram = nan(1,length(test_freqs));                                  %Create a variable to hold the audiogram.            
            for i = 1:size(prev_perf,2)                                             %Step through each tested frequencies.
                if all(prev_perf(:,i) == 1 | prev_perf(:,i) == 0)                   %If all of the datapoints are ones or zeros...
                    a = find(prev_perf(:,i) == 0,1,'last');                         %Find the last zero in the list of datapoints.
                    b = find(prev_perf(:,i) == 1,1,'first');                        %Find the first one in the list of datapoints.
                    if b > a                                                        %If the first one came after the last zero...
                        audiogram(i) = mean([a,b]);                                 %Set the 50% threshold to halfway between the last zero and first one.
                    end
                end
                if isnan(audiogram(i))                                              %If the threshold for this frequency still isn't set...
                    b = glmfit(1:length(test_ints),prev_perf(:,i),'binomial');      %Fit a binomial regression to the hit-rates.
                    audiogram(i) = -b(1)/b(2);                                      %Find the 50% inflection point in the logistic regression.
                    yfit = glmval(b, 1:length(test_ints), 'logit');
                    testhitrates = [0.2:0.1:0.8];
                    hitvsint = zeros(length(testhitrates), length(test_freqs));
                    for l = 1:length(testhitrates)
                        loind = find(yfit < testhitrates(l), 1, 'last');
                        hiind = find(yfit >= testhitrates(l), 1, 'first');
                        %disp([loind,hiind])
                        %pause
                        if loind == length(yfit)
                            hitvsints(l,i) = test_ints(end);
                        elseif hiind == 1
                                hitvsints(l,i) = test_ints(1);
                        else
                            multiplier = (testhitrates(l) - yfit(loind))/(yfit(hiind) - yfit(loind));
                            hitvsints(l,i) = multiplier*(test_ints(hiind) - test_ints(loind)) + test_ints(loind);
                        end
                    end
                end
            end
            if strcmpi(display,'on');                                               %If the display option is turned on...
                figure('color','w');                                                %Create a new figure.
                axes('units','normalized','position',[0.1 0.2 0.89 0.74]);          %Create new axes.
                imagesc(prev_perf);                                                 %Show the corrected hit rates a scaled colormap.
                temp = flipud(gray);                                                %Grab the grayscale steps.
                temp = 0.5+temp/2;                                                  %Light up all the grayscale steps by half.
                colormap(temp);                                                     %Use a flipped grayscale as the colorscale in the colormap.
                set(gca,'ydir','normal');                                           %Flip the colormap around right-side up.
                hold on;                                                            %Hold the axes for overlaying plots.
                line([1.5,1.5],ylim,'color','k','linestyle',':');                   %Plot a line to mark off the BBN column.
                plot(audiogram,'color','r','linewidth',2,'marker','*');             %Overlay the thresholds on the audiogram.
                hold off;                                                           %Release the plot hold.

                set(gca,'ytick',1:length(test_ints),'yticklabel',test_ints);        %Label the y-axis.
                temp = cell(length(test_freqs),1);                                  %Create a cell array to hold the x-axis labels.
                for i = 1:length(test_freqs)                                        %Step through each of the tested frequencies.
                    temp{i} = num2str(test_freqs(i)/1000,'%1.1f');                  %Convert each frequency to kHz.
                end
                temp{test_freqs == 0} = 'BBN';                                      %Label the broadband noise column as BBN.
                set(gca,'xtick',1:length(test_freqs),'xticklabel',temp);            %Label the x-axis.
                xticklabel_rotate(90);                                              %Rotate the x-axis labels by 90 degrees.
                ylabel('Intensity (dB)');                                           %Label the y-axis.
                a = xlabel('Frequency (kHz)');                                      %Label the x-axis.
                set(a,'position',[mean(xlim),min(ylim)-0.15*range(ylim)]);          %Reposition the x-axis.
                title(['Audiogram: ' rats{chosenRats(ratIndex)}]);                            %Show the rat's name in the title
            else
                step_size = test_ints(2) - test_ints(1);
                audiogram = test_ints(1) + step_size*audiogram-10;
            end
        else                                                                        %Otherwise, if there's no stage 4 sessions...
            audiogram = [];                                                         %Set the audiogram to an empty matrix.
            test_freqs = [];
            hitvsints = [];
        end
        audiogramMatrix = [audiogramMatrix; audiogram];
    end
    disp('audiogramMatrix:');
    disp(audiogramMatrix);
    disp('I be outputtin the audiogram matrix, yo!')
    varargout{1} = audiogram;                                                   %Output the audiogram if the user asked for it.
    varargout{2} = test_freqs;
    varargout{3} = hitvsints; 
end