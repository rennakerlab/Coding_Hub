function SpikeSorter

files=dir('*.NEL');
numfiles = length(files);

bdwidth = 5;
topbdwidth = 30;
set(0,'Units','pixels') 
scnsize = get(0,'ScreenSize');
pos1  = [bdwidth, 1/2*scnsize(4) + bdwidth,scnsize(3)/2 - 2*bdwidth, scnsize(4)/2 - (topbdwidth + bdwidth)];
pos2 = [pos1(1) + scnsize(3)/2, pos1(2),pos1(3),pos1(4)];
tempstring1 = 'E99'

for currentfile = 1:numfiles;
    data = [];
    files(currentfile).name
    [data, spikeshapes, spiketimes] = shapedataf(files(currentfile).name);
    numreps = length(data(1).sweep);
    [m numstim] = size([data.stim]);
    [m n] = size(spikeshapes);
    n = fix(n/50);
    plotspikes = [];
    for i = 1:n;
        plotspikes = [plotspikes spikeshapes(:,i)];
    end;
    figure('Position', pos1);
    plot(plotspikes);
    spikeshapes = spikeshapes';
    [m n] = size(spikeshapes);
    meanspikeshapes=spikeshapes - repmat(mean(spikeshapes),m,1);
    [PC, PCscore, PCvar] = princomp(spikeshapes);
    figure('Position', pos2);
    plot3(PCscore(:,1),PCscore(:,2),PCscore(:,3),'.b');
    xlabel('1st Principal Component');
    ylabel('2nd Principal Component');
    zlabel('3rd Principal Component');
    view(0,90);
    first3PC = PCscore(:,1:3);
    tempstring2 = files(currentfile).name;
    tempstring2 = tempstring2(1,1:3);
    
    if tempstring1 == tempstring2;
        numclusters
    else;
        numclusters = input('Number of Clusters:');
    end;
    
    if numclusters > 1;
        clustermarkers = kmeans(first3PC,numclusters,'distance','sqEuclidean','replicates',10);
    else
        clustermarkers = ones(length(spikeshapes),1);
    end
    close all
    figure('Position', pos1)
    placeholder = 0;
    counter = 0;
    
    if numclusters > 1 ;
        plotdata = [clustermarkers, meanspikeshapes];
        for i = 1:numclusters;
            meanwaveshape = mean(plotdata(find(plotdata(:,1)==i),2:28));
            clusterranking(i,1)=i;
            clusterranking(i,2)=sum(abs(meanwaveshape));
        end
        m = 0;
        while m  < 1;
            m = 1;
            for i =1:(numclusters-1)
                if clusterranking(i,2) < clusterranking(i+1,2);
                    temp = clusterranking(i,1:2);
                    clusterranking(i,1:2)=clusterranking(i+1,1:2);
                    clusterranking(i+1,1:2) = temp;
                    m = 0;
                end
            end
        end
    else
        clusterranking = [1,1];
    end
    clusterranking
    
    for i = 1:numstim;
        for j = 1:numreps;
            data(i).sweep(j).cluster = [];
            for k = 1:length(data(i).sweep(j).spikes);
                data(i).sweep(j).cluster = [data(i).sweep(j).cluster; clustermarkers(placeholder+k,1)];
                if counter == 50;
                    if clustermarkers(placeholder +k,1)==clusterranking(1,1);
                        line(1:27,spikeshapes(placeholder +k,1:27),'Color','b')
                    elseif clustermarkers(placeholder +k,1)==clusterranking(2,1);
                        line(1:27,spikeshapes(placeholder +k,1:27),'Color','r')
                    elseif clustermarkers(placeholder +k,1)==clusterranking(3,1);
                        line(1:27,spikeshapes(placeholder +k,1:27),'Color','c')
                    elseif clustermarkers(placeholder +k,1)==clusterranking(4,1);
                        line(1:27,spikeshapes(placeholder +k,1:27),'Color','g')
                    else
                        line(1:27,spikeshapes(placeholder +k,1:27),'Color','k')
                    end
                    counter = 0;
                else
                    counter = counter+1;
                end
            end
            placeholder = placeholder+length(data(i).sweep(j).spikes);
        end
    end

    figure('Position', pos2);
    plotdata = [clustermarkers, PCscore(:,1:3)];
    try
        plot3(plotdata(find(plotdata(:,1)==clusterranking(1,1)), 2),plotdata(find(plotdata(:,1)==clusterranking(1,1)), 3),plotdata(find(plotdata(:,1)==clusterranking(1,1)), 4), '.b');
        hold on;
        plot3(plotdata(find(plotdata(:,1)==clusterranking(2,1)), 2),plotdata(find(plotdata(:,1)==clusterranking(2,1)), 3),plotdata(find(plotdata(:,1)==clusterranking(2,1)), 4), '.r');
        plot3(plotdata(find(plotdata(:,1)==clusterranking(3,1)), 2),plotdata(find(plotdata(:,1)==clusterranking(3,1)), 3),plotdata(find(plotdata(:,1)==clusterranking(3,1)), 4), '.c');
        plot3(plotdata(find(plotdata(:,1)==clusterranking(4,1)), 2),plotdata(find(plotdata(:,1)==clusterranking(4,1)), 3),plotdata(find(plotdata(:,1)==clusterranking(4,1)), 4), '.g');
        plot3(plotdata(find(plotdata(:,1)==clusterranking(5,1)), 2),plotdata(find(plotdata(:,1)==clusterranking(5,1)), 3),plotdata(find(plotdata(:,1)==clusterranking(5,1)), 4), '.k');
        xlabel('1st Principal Component');
        ylabel('2nd Principal Component');
        zlabel('3rd Principal Component');
    catch
    end
    view(0,90);
    
    for i = 1:numclusters;
        f32data = [];
        for j = 1:numstim;
            f32data=[f32data; -2; data(j).sweeplength; length(data(j).stim); data(j).stim];
            for k = 1:numreps;
                f32data = [f32data; -1];
                for l = 1:length(data(j).sweep(k).cluster);
                    if data(j).sweep(k).cluster(l,1)==clusterranking(i,1);
                        f32data = [f32data; data(j).sweep(k).spikes(1,l)];
                    end
                end
            end
        end
        temp = files(currentfile).name;
        if i == 1 & numclusters == 1;
            temp = [temp(1,1:(length(temp)-4)) '.f32'];
        elseif i == 1 & numclusters > 1;
            temp = [temp(1,1:(length(temp)-4)) '_A.f32'];
        elseif i == 2;
            temp = [temp(1,1:(length(temp)-4)) '_B.f32'];
        elseif i == 3;
            temp = [temp(1,1:(length(temp)-4)) '_C.f32'];
        elseif i == 4;
            temp = [temp(1,1:(length(temp)-4)) '_D.f32'];
        else;
            temp = [temp(1,1:(length(temp)-4)) '_E.f32'];
        end
        fpnt = fopen(temp, 'wb');  
        fwrite(fpnt,f32data,'float32');
        fclose(fpnt);
        tempstring1 = files(currentfile).name;
        tempstring1=tempstring1(1,1:3);
        pause(1);
    end
end

close all

end
