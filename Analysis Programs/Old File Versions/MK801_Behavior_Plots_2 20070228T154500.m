function MK801_Behavior_Plots_2
    global DATAMIN;
    datapath = 'F:\Pitch Discrimination\Behavior Data';   %Main path for saving data.
    cd(datapath);
    load('pitch_discrimination_data');
    
    rats = []; c=0; DATAMIN = 50;
    sessions = zeros(1,4); dates = zeros(1,4); % Fills 1x4 matrix because max. MK-801 sessions per rat is 3
    for i = 1:length(behav)
        [b,ses] = unique([behav(i).session(:).daycode]);
        temp = ses(find([behav(i).session(ses).mk801_dose] ~= 0));
        if ~isempty(temp)
            c = c+1;
            sessions(c,1:(length(temp)+1)) = [i,temp];
            dates(c,1:(length(temp)+1)) = [i, behav(i).session(temp).daycode];
            rats = [rats, i];
        end
    end
    
    predata = []; predata2 = [];
    mkdata = []; mkdata2 = [];
    postdata = []; postdata2 = [];
    
    % Loop through each MK-801 session and find the last significant pre-session (i.e. more than 50
    % correct trials) and get the DL for both the pre- and during- sessions
    
    for currentrat = rats
        index = find([sessions(:,1)] == currentrat);
        for current_session = sessions(index,2:end)
            if current_session == 0
                continue
            else
            marker = 0;
            index2 = find([sessions(index,:)] == current_session);
            ref_freq = unique(behav(currentrat).session(current_session).ref_freq);
            if length(ref_freq) > 1
                errordlg('Session used all frequencies - cannot plot data')
                return
            end
            date = dates(index,index2);

            %PRE performance - Up to 3 days before injection
            ses = find([behav(currentrat).session(:).stage] == 4 & [behav(currentrat).session(:).mk801_dose] == 0 ...
                & [behav(currentrat).session(:).daycode] < date & [behav(currentrat).session(:).daycode] > (date-4));

            if ~isempty(ses)
                temp = 0; DL = []; DL2 = []; dosage = [];
                for i = ses
                    if behav(currentrat).session(i).daycode == temp     % If this is a continuation of the previous session on the same day,
                        k = data3(end,1);                               % we want the data to be added on for the DL calculations.
                        tempdata = filldata(currentrat,ref_freq,i,k);
                        data3 = [data3; tempdata];
                    else
                        k = 0;
                        data3 = filldata(currentrat,ref_freq,i,k);
                    end
                    
                    if ~isempty(data3) & size(data3,1) > DATAMIN
                        dosage = behav(currentrat).session(current_session).mk801_dose;
                        [DL,DL2] = findDL(data3);
                    end
                    temp = behav(currentrat).session(i).daycode;
                end
                if currentrat ~= 2
                    predata = [predata; data3];
                    predata2 = [predata2; DL,DL2,dosage];
                end
            end


            %MK801 performance
            ses = find([behav(currentrat).session(:).stage] == 4 & [behav(currentrat).session(:).mk801_dose] ~= 0 ...
                & [behav(currentrat).session(:).daycode] == date);

            if ~isempty(ses)
                temp = 0; DL = []; DL2 = []; dosage = [];
                for i = ses
                    if behav(currentrat).session(i).daycode == temp
                        k = predata(end,1);
                        tempdata = filldata(currentrat,ref_freq,i,k);
                        data3 = [data3; tempdata];
                    else
                        k = 0;
                        data3 = filldata(currentrat,ref_freq,i,k);
                    end
                    
                    if ~isempty(data3) & size(data3,1) > DATAMIN
                        dosage = behav(currentrat).session(current_session).mk801_dose;
                        [DL,DL2] = findDL(data3);
                    end
                    temp = behav(currentrat).session(i).daycode;
                end
                mkdata = [mkdata; data3];
                mkdata2 = [mkdata2; DL,DL2,dosage];
            end

            %POST performance - Up to 3 days after injection
            ses = find([behav(currentrat).session(:).stage] == 4 & [behav(currentrat).session(:).mk801_dose] == 0 ...
                & [behav(currentrat).session(:).daycode] > date & [behav(currentrat).session(:).daycode] < (date+4));

            if ~isempty(ses)
                temp = 0; DL = []; DL2 = []; dosage = [];
                for i = ses
                    if behav(currentrat).session(i).daycode == temp
                        k = predata(end,1);
                        tempdata = filldata(currentrat,ref_freq,i,k);
                        data3 = [data3; tempdata];
                    else
                        k = 0;
                        data3 = filldata(currentrat,ref_freq,i,k);
                    end
                    
                    if ~isempty(data3) & size(data3,1) > DATAMIN
                        dosage = behav(currentrat).session(current_session).mk801_dose;
                        [DL,DL2] = findDL(data3);
                    end
                    temp = behav(currentrat).session(i).daycode;
                end
                postdata = [postdata; data3];
                postdata2 = [postdata2; DL,DL2,dosage];
            end
            
            end
        end
    end
    subplot(1,3,3);
    set(gca,'XTick',[0:2:8],'YTick',[0:2:8],'XTickLabel',[0:2:8],'YTickLabel',[0:2:8],'FontWeight','Bold','FontSize',12);
    xlim([0,8]); ylim([0,8]);
    xlabel('Pre-Injection DL \rm\bf(~%)','FontWeight','Bold','FontSize',14);
    ylabel('MK-801 DL \rm\bf(~%)','FontWeight','Bold','FontSize',14);
    hold on;
    line([0,10],[0,10],'color','k','LineWidth',0.5,'LineStyle','--');
    hold on;
    for i = 1:size(mkdata2,1)
        if mkdata2(i,3) == 0.04
            plot(predata2(i,1),mkdata2(i,1),'c^','MarkerFaceColor','c');
            plot(abs(predata2(i,2)),abs(mkdata2(i,2)),'cv','MarkerFaceColor','c');
        elseif mkdata2(i,3) == 0.05
            plot(predata2(i,1),mkdata2(i,1),'b^','MarkerFaceColor','b');
            plot(abs(predata2(i,2)),abs(mkdata2(i,2)),'bv','MarkerFaceColor','b');
        elseif mkdata2(i,3) == 0.06
            plot(predata2(i,1),mkdata2(i,1),'g^','MarkerFaceColor','g');
            plot(abs(predata2(i,2)),abs(mkdata2(i,2)),'gv','MarkerFaceColor','g');
        elseif mkdata2(i,3) == 0.08
            plot(predata2(i,1),mkdata2(i,1),'r^','MarkerFaceColor','r');
            plot(abs(predata2(i,2)),abs(mkdata2(i,2)),'rv','MarkerFaceColor','r');
        else
            plot(predata2(i,1),mkdata2(i,1),'k^','MarkerFaceColor','k');
            plot(abs(predata2(i,2)),abs(mkdata2(i,2)),'kv','MarkerFaceColor','k');
        end
        hold on;
    end
    title('MK801 Effect on Frequency DL','fontweight','bold');
end

%%% SUB FUNCTIONS %%%
function dc = dprime_cprime_calculator(H,M,F,C)
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
    dc(1) = norminv(a) - norminv(b);                    %d prime
    dc(2) = -0.5*(norminv(a) + norminv(b))/abs(dc(1));  %c prime
end

function data = filldata(currentrat,ref_freq,ses,k)
    data = [];
    d=0;
    load('pitch_discrimination_data');
    for j = 1:length(behav(currentrat).session(ses).ref_freq)
        if behav(currentrat).session(ses).ref_freq(j) == ref_freq
            if any(behav(currentrat).session(ses).outcome(j) == 'HMFC')
                d = d+1; k = k+1;
                %data(d,1) = behav(currentrat).session(ses).clock_reading(j) - behav(currentrat).session(ses).clock_reading(1);
                data(d,1) = k;
                data(d,2) = behav(currentrat).session(ses).delta_f(j);
                data(d,3) = any(behav(currentrat).session(ses).outcome(j) == 'HF');
            end
        end
    end
end

% Returns average difference limens (DL's) for the session
function [DL,DL2] = findDL(data)
    DL = [];
    datasort = sortie(data,1,size(data,1));
    HR = datasort(:,2)./datasort(:,3);
    base = find(datasort(:,1) == 0);
    if HR(base) ~= 1
        HR(:) = (HR(:)-HR(base))/(1-HR(base));
        xi = -10:0.1:10;
        yi = interp1(datasort(:,1),HR(:),xi);
        upbound = 0.52;
        lowbound = 0.48;
        DL = [];
        DL2 = [];
        while (isempty(DL) | isempty(DL2)) & upbound ~= 0.8
            upbound = upbound + 0.01;
            lowbound = lowbound - 0.01;
            DL = find(yi < upbound & yi > lowbound & xi > 0);
            DL2 = find(yi < upbound & yi > lowbound & xi < 0);
        end
        DL = xi(min(DL));       % Positive DL
        DL2 = xi(max(DL2));     % Negative DL
    else
        DL = []; DL2 = [];
    end
end

% Converts array [trial #, freq change, hit/miss] into sorted totals by
% frequency change: [freq change, # hits, # trials]
function datasort = sortie(data,min,max)
    datasort = [];
    for i = min:max
        if isempty(datasort)
            datasort = [datasort; data(i,2:3), 1];
        else
            c = find(data(i,2) == datasort(:,1));
            if isempty(c);
                c = size(datasort,1) + 1;
                datasort(c,1:3) = [data(i,2:3), 1];
            else
                datasort(c,1:3) = [data(i,2), datasort(c,2) + data(i,3), datasort(c,3) + 1];
            end
        end
    end
    datasort = sortrows(datasort,1);
end