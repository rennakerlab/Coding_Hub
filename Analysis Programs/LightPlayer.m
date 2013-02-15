function lightplayer(file)

[file path] = uigetfile('*.L64');
cd(path);
file = [path file];
fid = fopen(file);

i = fread(fid,1,'double');
signal = []

while ~isempty(i);
    signal = [signal; i];
    i = fread(fid, 1, 'double');
end;

signal = signal';

fclose(fid);

RP2 = actxcontrol('RPco.x',[5 5 26 26]);
invoke(RP2,'ConnectRP2','GB',1);
invoke(RP2, 'ClearCOF');
invoke(RP2,'LoadCOF','C:\Documents and Settings\nel_students\Desktop\RPvds Circuits\LightSound_Tester.rco');
invoke(RP2, 'Run');

error1 = invoke(RP2,'WriteTagV','lights', 0, signal);

for i = 1:20;
    invoke(RP2, 'SoftTrg', 2);
    pause(0.5);
end

invoke(RP2, 'halt');

