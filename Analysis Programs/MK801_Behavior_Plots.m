function MK801_Behavior_Plots
    global DATAMIN; global TEMP2; global DOSES;
    plotall = 0; TEMP2 = []; dated = [];
    marker = 0; dosage = [];
    
    datapath = 'F:\Pitch Discrimination\Behavior Data';   %Main path for saving data.
    cd(datapath);
    load('pitch_discrimination_data');
    
    entry = cell2mat(inputdlg('Which rat or dosage do you want to analyze? (For all data, enter "ALL")', 'Entry:'));
    timeplot = 'No';
    rats = [];
    
    % Sets up to plot averages for all MK-801 sessions and all rats

    % Sets up to plot averages for one rat over all or one specific MK-801
    % session
    for i = 1:length(behav);
        if strcmpi(entry,behav(i).ratname); rats = i; end
    end

    if isempty(rats)
        plotall = strcmpi(entry,'ALL');
        c=0;
        sessions = zeros(1,4); dates = zeros(1,4); % Fills 1x4 matrix because max. MK-801 sessions per rat is 3
        for i=1:length(behav)
            temp = [];
            [b,ses] = unique([behav(i).session(:).daycode]);
            if ~plotall; temp = ses(find([behav(i).session(ses).mk801_dose] == str2num(entry))); end
            if ~isempty(temp)
                DATAMIN = 80;
                c = c+1;
                dates(c,1:(length(temp)+1)) = [i, behav(i).session(temp).daycode];
                sessions(c,1:(length(temp)+1)) = [i,temp];
                rats = [rats,i];
            end
            temp = ses(find([behav(i).session(ses).mk801_dose] ~= 0));
            if plotall & ~isempty(temp)
                DATAMIN = 80;
                c = c+1;
                sessions(c,1:(length(temp)+1)) = [i,temp];
                dates(c,1:(length(temp)+1)) = [i, behav(i).session(temp).daycode];
                rats = [rats, i];
            end
        end
        plotall = 1;
    else
        dated = cell2mat(inputdlg('When did you run this rat on MK801 (Day Code)?', 'Day Code:'));
        [b,ses] = unique([behav(rats).session(:).daycode]);
        if strcmpi(dated,'ALL')
            DATAMIN = 50;
            plotall = 1;
            temp = ses(find([behav(rats).session(ses).mk801_dose] ~= 0));
            dates = [rats, behav(rats).session(temp).daycode];
            sessions = [rats, temp];
            if length(sessions) == 1
                errordlg('No MK-801 data found for this rat')
                return
            end
        else
            DATAMIN = 40;
            date = round(str2num(dated));
            sessions = [rats, ses(find([behav(rats).session(ses).daycode] == date))];
            if length(sessions) == 1
                errordlg('No data found for given daycode')
                return
            end
            timeplot = questdlg('Do you want a plot of DL over time?','Time Plot','Yes', 'No', 'No');
        end
    end
    
    predata = []; predata2 = []; predata3 = [];
    mkdata = []; mkdata2 = []; mkdata3 = [];
    postdata = []; postdata2 = []; postdata3 = [];
    
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
            if plotall == 1
                date = dates(index,index2);
            end

            %PRE performance - Up to 3 days before injection
            ses = find([behav(currentrat).session(:).stage] == 4 & [behav(currentrat).session(:).mk801_dose] == 0 ...
                & [behav(currentrat).session(:).daycode] < date & [behav(currentrat).session(:).daycode] > (date-4));

            if ~isempty(ses)
                temp = 0; data4 = [];
                for i = ses
                    if behav(currentrat).session(i).daycode == temp
                        k = predata(end,1);
                        tempdata = filldata(currentrat,ref_freq,i,k);
                        data3 = [data3; tempdata];
                        predata = [predata; tempdata];
                    else
                        k = 0;
                        if ~isempty(data4)
                            predata2 = [predata2; DL,DL2,dosage];
                            predata3 = [predata3; data4];
                        end
                        data3 = filldata(currentrat,ref_freq,i,k);
                        predata = [predata; data3];
                    end
                    
                    if ~isempty(data3) & size(data3,1) > DATAMIN
                        dosage = behav(currentrat).session(current_session).mk801_dose;
                        [DL,DL2] = findDL(data3);
                        data4 = findDLtime(data3);
                    else
                        DL = []; DL2 = []; dosage = []; data4 = [];
                    end
                    temp = behav(currentrat).session(i).daycode;
                end
                predata2 = [predata2; DL,DL2,dosage];
                predata3 = [predata3; data4];
            end


            %MK801 performance
            ses = find([behav(currentrat).session(:).stage] == 4 & [behav(currentrat).session(:).mk801_dose] ~= 0 ...
                & [behav(currentrat).session(:).daycode] == date);

            if ~isempty(ses)
                temp = 0; data4 = [];
                for i = ses
                    if behav(currentrat).session(i).daycode == temp
                        k = mkdata(end,1);
                        tempdata = filldata(currentrat,ref_freq,i,k);
                        data3 = [data3; tempdata];
                        mkdata = [mkdata; tempdata];
                    else
                        k = 0;
                        if ~isempty(data4)
                            mkdata2 = [mkdata2; DL,DL2,dosage];
                            mkdata3 = [mkdata3; data4];
                        end
                        data3 = filldata(currentrat,ref_freq,i,k);
                        mkdata = [mkdata; data3];
                    end
                    
                    if ~isempty(data3) & size(data3,1) > DATAMIN
                        dosage = behav(currentrat).session(current_session).mk801_dose;
                        [DL,DL2] = findDL(data3);
                        data4 = findDLtime(data3);
                    else
                        DL = []; DL2 = []; dosage = []; data4 = [];
                    end
                    temp = behav(currentrat).session(i).daycode;
                end
                mkdata2 = [mkdata2; DL,DL2,dosage];
                mkdata3 = [mkdata3; data4];
            end

            %POST performance - Up to 3 days after injection
            ses = find([behav(currentrat).session(:).stage] == 4 & [behav(currentrat).session(:).mk801_dose] == 0 ...
                & [behav(currentrat).session(:).daycode] > date & [behav(currentrat).session(:).daycode] < (date+4));

            if ~isempty(ses)
                temp = 0; data4 = [];
                for i = ses
                    if behav(currentrat).session(i).daycode == temp
                        k = postdata(end,1);
                        tempdata = filldata(currentrat,ref_freq,i,k);
                        data3 = [data3; tempdata];
                        postdata = [postdata; tempdata];
                    else
                        k = 0;
                        if ~isempty(data4)
                            postdata2 = [postdata2; DL,DL2,dosage];
                            postdata3 = [postdata3; data4];
                        end
                        data3 = filldata(currentrat,ref_freq,i,k);
                        postdata = [postdata; data3];
                    end
                    
                    if ~isempty(data3) & size(data3,1) > DATAMIN
                        dosage = behav(currentrat).session(current_session).mk801_dose;
                        [DL,DL2] = findDL(data3);
                        data4 = findDLtime(data3);
                    else
                        DL = []; DL2 = []; dosage = []; data4 = [];
                    end
                    temp = behav(currentrat).session(i).daycode;
                end
                postdata2 = [postdata2; DL,DL2,dosage];
                postdata3 = [postdata3; data4];
            end
            end
        end
    end
    
    if ~isempty(predata2) & ~isempty(mkdata2) & ~isempty(postdata2)
        if strcmpi(timeplot,'No')
            [premean,preinterv] = stat_eval(predata2);
            [mkmean,mkinterv] = stat_eval(mkdata2);
            [postmean,postinterv] = stat_eval(postdata2);
            datastat(:,:,1) = [premean; mkmean; postmean];
            datastat(:,:,2) = [preinterv; mkinterv; postinterv];
            sort_plot(datastat,2,'');
        end
        
        fullsort = [sortie(predata,1,size(predata,1)),sortie(mkdata,1,size(mkdata,1)),sortie(postdata,1,size(postdata,1))];
        for i=1:size(fullsort,1)
            for j=1:3
                p(i,j) = fullsort(i,j*3-1)./fullsort(i,j*3);
                q(i,j) = 1.96*sqrt(p(i,j)*(1-p(i,j))/fullsort(i,3*j));
            end
            if ((p(i,2)+q(i,2)) < (p(i,1)-q(i,1)) & (p(i,2)+q(i,2)) < (p(i,3)-q(i,3)))
                TEMP2(i) = p(i,2);
            else
                TEMP2(i) = NaN;
            end
        end
    end
    if ~isempty(predata); sort_plot(predata,1,'b'); end
    if ~isempty(mkdata); sort_plot(mkdata,1,'g'); end
    if ~isempty(postdata); sort_plot(postdata,1,'r'); end
    
    if strcmpi(timeplot,'Yes')
        if ~isempty(predata3); sort_plot(predata3,3,'b'); end
        if ~isempty(mkdata3); sort_plot(mkdata3,3,'g'); end
        if ~isempty(postdata3); sort_plot(postdata3,3,'r'); end
    end
    %subplot(1,3,[1:2]);
    subplot(2,1,2);
    %legend('PRE','Sig. PRE','MK801','Sig. MK801','Sig. Change','POST','Sig. POST',4);
    if plotall
        title([entry, ' - MK801 Comparison'],'fontweight','bold');
    else
        title([entry, ' - MK801 Comparison - ' num2str(date)],'fontweight','bold');
    end
    hold off;
    temp = questdlg('Autosave?','Save Figure','Yes', 'No', 'No');
    if strcmpi(temp,'Yes')
        datapath = 'F:\Mikes Files\Grant';
        cd(datapath);
        if plotall
            hgsave([entry, '_MK801 Plot_ALL']);
        else
            hgsave([entry, '_MK801 Plot_', num2str(dated)]);
        end
    end
end



%SUB FUNCTIONS*************************************************************
%**************************************************************************
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

% Returns normalized difference limens (DL's) as a function of trial # within a session
function data2 = findDLtime(data)
    global DATAMIN;
    DL2 = [];
    k = 0;
    data2 = [];
    if size(data,1) < DATAMIN
        min1 = size(data,1) - 1;
    else
        min1 = DATAMIN;
    end
    for d = min1:size(data,1)
        k=k+1;
        datastart = d+1-min1;
        datasort = sortie(data,datastart,d);
        %avg_clock = datevec(mean(data(datastart:d,1)));
        %avg_clock = avg_clock(4)*60 + avg_clock(5) + fix(100*avg_clock(6)/60)/100;      % Returns average time (min) from start
        avg_trial = round(mean(data(datastart:d,1)));
        HR = datasort(:,2) ./ datasort(:,3);
        base = find(datasort(:,1) == 0);
        if ~isempty(base)
            if HR(base) == 1
                DL = NaN;
                DL2 = NaN;
                k=k-1;
                continue
            else
                HR(:) = (HR(:) - HR(base))/(1 - HR(base));
            end
        end
        xi = -10:0.1:10;
        yi = interp1(datasort(:,1),HR(:),xi);
        upbound = 0.50;
        lowbound = 0.50;
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
        data2(k,1:3) = [avg_trial, DL, DL2];
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

% Plot collected data: 1. Frequency change vs. correct response rate; compare PRE, MK-801, POST
%                      2. Mean difference limen (DL) over several sessions; compare PRE, MK-801, POST
%                      3. Difference limen (DL) over time within session; compare PRE, MK-801, POST
function sort_plot(data,ptype,color)
    global DATAMIN; global TEMP2; global DOSES;
    if ptype == 1
        data = sortie(data,1,size(data,1));
        for i = 1:size(data,1)
            p(i) = data(i,2)./data(i,3);
            q(i) = 1.96*sqrt(p(i)*(1-p(i))/data(i,3));
        end
        %subplot(1,3,[1:2]);
        subplot(2,1,1);
        errorbar(data(:,1),p',q','color',color,'linewidth',2);
        set(gca,'XTick',[-20:5:20],'XTickLabel',[-20:5:20],'YTick',[0:0.2:1],...
            'YTickLabel',[0:20:100],'FontWeight','Bold','FontSize',12);
        xlim([-11, 11]);
        ylim([0,1]);
        xlabel('\Delta\it{f} \rm\bf(~%)','FontWeight','Bold','FontSize',14);
        ylabel('NosepokeResponses','FontWeight','Bold','FontSize',14);
        hold on;
        if any(data(:,1) == 0) & size(data,1) > 3
            temp = data(find(data(:,1) == 0),:);
            F = temp(2);
            C = temp(3) - temp(2);
            for i = 1:size(data,1)
                if data(i,1) ~= 0
                    dc = dprime_cprime_calculator(data(i,2),data(i,3) - ...
                        data(i,2),F,C);
                    if dc(1) > 1.96
                        temp(i) = p(i);
                    else
                        temp(i) = NaN;
                    end
                else
                    temp(i) = NaN;
                end
            end
            plot(data(:,1),temp,'color',color,'marker','o','markerfacecolor',color,'markersize',5);
            if color == 'g' & ~isempty(TEMP2)
                plot(data(:,1),TEMP2','color',color,'marker','x','markerfacecolor',color,'markersize',18);
            end
        end
    elseif ptype == 3
        sdata = sortrows(data,1);
        %data = sdata(1:(DATAMIN/5):end,:);
        data = sdata(1:127,:);
        for i = 1:size(data,1)
            p(i) = data(i,2);
            p2(i) = data(i,3);
            q(i) = 1.96*sqrt(p(i)*(1-p(i))/DATAMIN);
            q2(i) = 1.96*sqrt(p2(i)*(1-p2(i))/DATAMIN);
        end
        subplot(2,1,2);
        %errorbar(data(:,1),data(:,2),p',q','color',color,'linewidth',2);
        set(gca,'XTick',[0:25:200],'YTick',[-10:2:10],...
            'YTickLabel',[-10:2:10],'FontWeight','Bold','FontSize',12);
        xlim([0, 200]);
        ylim([-11,11]);
        xlabel('Session Time (min)','FontWeight','Bold','FontSize',14);
        ylabel('Frequency DL \rm\bf(~%)','FontWeight','Bold','FontSize',14);
        hold on;
        
        plot(data(:,1),data(:,2),'color',color,'linewidth',2);
        
        subplot(2,1,2);
        %errorbar(data(:,1),data(:,3),p2',q2','color',color,'linewidth',2);
        uplim = ceil(max(data(:,1))/100)*100;
        set(gca,'XTick',[0:100:uplim],'YTick',[-10:2:10],...
            'YTickLabel',[-10:2:10],'FontWeight','Bold','FontSize',12);
        xlim([0, max(data(:,1))]);
        ylim([-11,11]);
        xlabel('Trial #','FontWeight','Bold','FontSize',14);
        ylabel('Frequency DL \rm\bf(~%)','FontWeight','Bold','FontSize',14);
        hold on;
        plot(data(:,1),data(:,3),'color',color,'linewidth',2);
    elseif ptype == 2
        subplot(2,1,2);
        ticklabel = {}; x = [];
        for i = 2:2:2*size(DOSES,1)
            ticklabel{i-1} = [num2str(DOSES(i/2)),' (+)'];
            ticklabel{i} = [num2str(DOSES(i/2)),' (-)'];
            x = [x;i-1.225,i-1,i-0.775;i-0.225,i,i+0.225];
        end
        set(gca,'XTick',[1:size(data,2)],'XTickLabel',ticklabel,'FontWeight','Bold','FontSize',12);
        ylim([min(data(2,:,1))-max(data(2,:,2)),max(data(2,:,1))+max(data(2,:,2))]);
        xlabel('Dosage (mg/kg)','FontWeight','Bold','FontSize',14);
        ylabel('Frequency DL \rm\bf(~%)','FontWeight','Bold','FontSize',14);
        hold on;
        bar(data(:,:,1)');
        hold on;
        errorbar(x,data(:,:,1)',data(:,:,2)','.','linewidth',2);
    end
end

function [means,intervs] = stat_eval(data)
    global DOSES;
    means = []; intervs = []; DOSES = []; d = 0;
    for i = (unique(data(:,3)))'
        d=d+1;
        rows = find(data(:,3) == i);
        if size(rows,1) > 1
            means = [means, mean(data(rows,1)), mean(data(rows,2))];
            [h,sig,ci] = ttest(data(rows,1));
            [h2,sig2,ci2] = ttest(data(rows,2));
            intervs = [intervs, ci(2) - means(2*d-1), means(2*d)-ci2(1)];
        else
            means = [means, data(rows,1), data(rows,2)];
            intervs = [intervs, 0,0];
        end
        DOSES = [DOSES;i];
    end
end
        