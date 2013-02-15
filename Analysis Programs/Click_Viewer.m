function Click_Viewer

[file path] = uigetfile('*.16');
cd(path)
fid = fopen(file);
i = fread(fid,1,'int16');
csound = [];
while ~isempty(i);
    csound = [csound; i];
    i = fread(fid, 1, 'int16');
end;
csound = csound'*(10/(2^15));
fclose(fid);

plot(csound,'k','LineWidth',2);
xlim([0 length(csound)]);
ylim([-0.25 3]);
ylabel('Amplitude (V)','FontWeight','Bold');
xlabel('Time (ms)','FontWeight','Bold');
set(gca,'XTick',[0:(length(csound)/10):length(csound)],'XTickLabel',[0:100:1000],'FontWeight','Bold');