function noiseplayer(file)

fid = fopen(file);

i = fread(fid,1,'int16');
signal = []

while ~isempty(i);
    signal = [signal; i];
    i = fread(fid, 1, 'int16');
end;

signal = signal'*(10/(2^15));

RP2 = actxcontrol('RPco.x',[5 5 26 26]);
invoke(RP2,'ConnectRP2','GB',1);
invoke(RP2, 'ClearCOF');
invoke(RP2,'LoadCOF','C:\Sound Files\RCOs\Novel_Bed.rco');
invoke(RP2, 'Run');

error1 = invoke(RP2,'WriteTagV','signal', 0, signal);

invoke(RP2, 'SoftTrg', 1);

pause(2);

invoke(RP2, 'halt');

