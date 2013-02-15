function Volume_Change

[file path] = uigetfile('*.16');
cd(path);
file = [path file];
fid = fopen(file);

i = fread(fid,1,'int16');
signal = []

while ~isempty(i);
    signal = [signal; i];
    i = fread(fid, 1, 'int16');
end;

fclose(fid);

signal = signal'*(10/(2^15));

RP2 = actxcontrol('RPco.x',[5 5 26 26])
invoke(RP2,'ConnectRP2','GB',1);
invoke(RP2, 'ClearCOF');
invoke(RP2,'LoadCOF','C:\Sound Files\RCOs\novelbed.rco');
invoke(RP2, 'Run');

checker = 0;

while checker == 0;
    error1 = invoke(RP2,'WriteTagV','signal', 0, signal);
    invoke(RP2, 'SoftTrg', 1);
    result =  questdlg('How does it sound?', 'Set Volume:', 'Quieter', 'Good', 'Louder', 'Good');
    if result(1) == 'Q';
        signal = 0.9*signal;
    elseif result(1) == 'G';
        checker = 1;
    elseif result(1) == 'L';
        signal = 1.1*signal;
    end
end

signal = signal'/(10/(2^15));

fid = fopen(file, 'w');
fwrite(fid, signal, 'int16');
fclose(fid);

invoke(RP2, 'halt');


close all;