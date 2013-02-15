function model_diffTC

cd(uigetdir);
files = dir('*.f32');

counter = 0;
for index = 1:length(files)
    if files(index).name(1) ~= ' '
        temp = [files(index).name(1:7) '*' files(index).name(9:(length(files(index).name)-4)) '*.f32'];
        tempfiles = dir(temp);
        files(index).name(1) = ' ';
        if length(tempfiles) == 2
            counter = counter + 1
            data1 = spikedataf(tempfiles(1).name);
            numreps = length(data1(1).sweep);
			freqs = [];
			ints = [];
			for i = 1:length(data1);
                if isempty(find(freqs==data1(i).stim(1)));
                    freqs = [freqs; data1(i).stim(1)];
                end
                if isempty(find(ints==data1(i).stim(2)));
                    ints = [ints; data1(i).stim(2)];
                end
			end
			numfreq = length(freqs);
			numint = length(ints);

			for i = 1:length(data1);
                x = find(data1(i).stim(1)==freqs);
                z = find(data1(i).stim(2)==ints);
                temp1 = [];
                for r = 1:numreps;
                    try;
                        temp2 = histc(data1(i).sweep(r).spikes,[0:1:data1(i).sweeplength]);
                    catch;
                        temp2 = zeros(1,data1(i).sweeplength+1);
                    end;
                    temp1 = [temp1; temp2];
                    for y = 1:length(temp2);
                        tc(x,y,z,r,1) = temp2(y)/0.001;
                    end
                end
                data1(i).spikerate = temp1/0.001;
			end

            data2 = spikedataf(tempfiles(2).name);

			for i = 1:length(data2);
                x = find(data2(i).stim(1)==freqs);
                z = find(data2(i).stim(2)==ints);
                temp1 = [];
                for r = 1:numreps;
                    try;
                        temp2 = histc(data2(i).sweep(r).spikes,[0:1:data2(i).sweeplength]);
                    catch;
                        temp2 = zeros(1,data2(i).sweeplength+1);
                    end;
                    temp1 = [temp1; temp2];
                    for y = 1:length(temp2);
                        tc(x,y,z,r,2) = temp2(y)/0.001;
                    end
                end
                data2(i).spikerate = temp1/0.001;
			end
            
            [a,b,c,d,e] = size(tc);
            for i = 1:a
                for j = 1:b
                    for k = 1:c
                        if mean(tc(i,j,k,:,1)) ~= 0
                            temp = (mean(tc(i,j,k,:,2))-mean(tc(i,j,k,:,1)))/mean(tc(i,j,k,:,1));
                        elseif mean(tc(i,j,k,:,2)) ~= 0
                            temp = (mean(tc(i,j,k,:,2))-mean(tc(i,j,k,:,1)))/mean(tc(i,j,k,:,2));
                        else
                            temp = 0;
                        end
                        model(i,j,k,counter) = 100*temp;
                    end
                end
            end
        end
    end
end

[a,b,c,d] = size(model);
for i = 1:a
    for j = 1:b
        for k = 1:c
            Ds(i,j,k)=mean(model(i,j,k,:));
            if std([model(i,j,k,:)])
                temp = ttest([model(i,j,k,:)],0);
            else
                temp = 0;
            end
            if temp == 1 & mean([model(i,j,k,:)]) > 0
                Sig(i,j,k) = 1;
            elseif  temp == 1 & mean([model(i,j,k,:)]) < 0
                Sig(i,j,k) = -1;
            else
                Sig(i,j,k) = 0;
            end
        end
    end
end

for k = 1:c
    Ds(:,:,k)=smoothts(smoothts(Ds(:,:,k)')');
end

scrnsize = get(0,'ScreenSize');
pos = [scrnsize(3)/20 scrnsize(4)/16 (scrnsize(3)-2*(scrnsize(3)/20)) (scrnsize(4)-2*(scrnsize(4)/16))];

close all;
counter = 2;
for i = 1:numint
    if counter == 2;
        figure('Position',pos);
        counter = 1;
        
    else
        counter = counter + 1;
    end
    
    subplot(2,2,2*counter-1)
    surf(Ds(:,:,i,1),'EdgeColor', 'none');
    view(0,90);
    set(gca,'XLim',[1 data1(1).sweeplength],'YLim', [1 numfreq]);
    if numfreq<20
        set(gca,'YTick', [1:numfreq],'YTickLabel', round(freqs(2:5:numfreq)/100)/10);
    else
        set(gca,'YTick', [2.5:5:numfreq],'YTickLabel', round(freqs(2:5:numfreq)/100)/10);
    end
    ylabel('frequency (kHz)','FontWeight','Bold');
    xlabel('time (ms)','FontWeight','Bold');
    set(gca,'XTick', [35:50:data2(1).sweeplength],'XTickLabel',[0:50:(data2(1).sweeplength-35)]);
    line([35 35],[1 numfreq],[10000 10000],'Color','w','LineStyle', '--');
    [a,b,c,d] = size(model);
	test_data = [];
	for x = 1:a
        rows = [];
        for y = 5:5:b
            obs = [];
            for r = 1:d
                obs = [obs; mean(model(x,(y-4):y,i,r))];
            end
            rows = [rows, obs];
        end
        test_data = [test_data; rows];
	end
	p = anova2(test_data,d,'off');
    title(['Model Difference, ' num2str(ints(i)) ' dB, p = ' num2str(round(1000*p(3))/1000)],'FontWeight','Bold','FontSize',10);
    colorbar;
    
    subplot(2,2,2*counter)
    surf(Sig(:,:,i,1),'EdgeColor', 'none');
    view(0,90);
    set(gca,'XLim',[1 data1(1).sweeplength],'YLim', [1 numfreq]);
    if numfreq<20
        set(gca,'YTick', [1:numfreq],'YTickLabel', round(freqs(2:5:numfreq)/100)/10);
    else
        set(gca,'YTick', [2.5:5:numfreq],'YTickLabel', round(freqs(2:5:numfreq)/100)/10);
    end
    ylabel('frequency (kHz)','FontWeight','Bold');
    xlabel('time (ms)','FontWeight','Bold');
    set(gca,'CLim',[-1 1]);
    set(gca,'XTick', [35:50:data2(1).sweeplength],'XTickLabel',[0:50:(data2(1).sweeplength-35)]);
    line([35 35],[1 numfreq],[10000 10000],'Color','w','LineStyle', '--');
    title(['Model Significant Difference, ' num2str(ints(i)) ' dB'],'FontWeight','Bold','FontSize',10);
    colorbar;
end