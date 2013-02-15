function NEL_SNR

%------------
% Signal to noise ratio calculator for .dam files
%------------

path = uigetdir;
cd(path);
files = dir('*.dam');

file_name = 'SNR_DATA.txt';
file = java.lang.String(file_name);
writer = java.io.BufferedWriter(java.io.FileWriter(file));
t = sprintf('\t');
space = java.lang.String(t);
space = char(space);
writer.write('FileName:');
writer.write(space);
writer.write('SNR:');
writer.write(space);
writer.write('Noise:');
writer.newLine;
writer.flush;

for currentfile = 1:length(files);
    disp(files(currentfile).name);
    %data reading from damFileRead.m
    data=[];
    f=fopen(files(currentfile).name,'r');
    i=0;
    stamp=fread(f,1,'float64'); % read time stamp for 1st data sweep
    while ~isempty(stamp);
        i=i+1;
        data(i).timestamp=stamp;
        % stimulus object follows
        data(i).stimIndex=fread(f,1,'int16'); % stimulus index
        numPar=fread(f,1,'int16'); % how many stimulus parameters are there?
        stim.params=[];
        % read stimulus parameter names
        for p=1:numPar
            % read name of stimulus parameter p
            slen=fread(f,1,'uint8');
            sbuf=fread(f,slen,'uchar');
            c=find(sbuf < 32);
            sbuf(c)=[];
            sbuf=char(sbuf');
            stim.params(p).stimname = sbuf;
        end;
        stim.values=fread(f,numPar,'float32'); % read stimulus parameter values
        data(i).stim=stim;
        sigLen=fread(f,1,'int32'); %read length of data sweep
        data(i).signal=fread(f,sigLen,'int16');     % read data sweep itself
        stamp=fread(f,1,'float64');     % read time stamp for next data sweep
    end;
    fclose(f);

    scrnsize = get(0,'ScreenSize');
    pos = [scrnsize(3)/20 scrnsize(4)/16 (scrnsize(3)-2*(scrnsize(3)/20)) (scrnsize(4)-2*(scrnsize(4)/16))];

    close all;
    figure('Position',pos);

    %-----------
    %signal to noise ratio code
    %-----------
    snrs = [];
    noise = [];
    for i=1:length(data)
        waveform = 5*data(i).signal/32767;
        threshold = -3*sqrt(sum(waveform.^2)/length(waveform));
        noise = [noise; sqrt(sum(waveform.^2)/length(waveform))];
        figure(1);
        hold off;
        plot(waveform(1:(length(waveform)-1)),'g');
        xlim([1,length(waveform)-1]);
        ylim([-5,5]);
        hold on;
        line([1,length(waveform)-1],[threshold,threshold],'color','b','LineStyle',':');
        for j = 1:(length(waveform)-25)
             if waveform(j) > threshold & waveform(j+1) < threshold
                 if (j+25) < length(waveform)                 
                     [a,b] = max(waveform(j:(j+24)));
                     x1 = j + b - 1;
                     [a,b] = min(waveform(j:(j+24)));
                     x2 = j + b - 1;
                     if waveform(x1) < 25000
                        plot([j:(j+24)]',waveform(j:(j+24)),'Color','r');
                        snrs = [snrs; -3*(waveform(x1)-waveform(x2))/threshold];
                        plot([x1,x2],[waveform(x1),waveform(x2)],'*r');
                     end
                 end
            end
        end
        hold off;
        pause(0.05);
    end
    writer.write(files(currentfile).name);
    writer.write(space);
    writer.write(num2str(mean(snrs)));
    writer.write(space);
    writer.write(num2str(mean(noise)));
    writer.newLine;
    writer.flush;
    
end

writer.flush;
writer.close;