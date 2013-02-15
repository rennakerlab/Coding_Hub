function SimpleStimTest

r = actxcontrol('RPco.X', [5 5 26 26]);
if invoke(r, 'connectRX7','GB',1);
    disp('Connected to the RX7');
else
    disp('Could not connect to the RX7');
end

invoke(r,'ClearCOF')

rcofile='C:\Documents and Settings\Owner\Desktop\RPvds Circuits\SingleChannelStim.rco'
l = invoke(r,'LoadCOF', rcofile)

rn=invoke(r,'Run');
if(double(l)+double(rn)<2) 
    disp('Error in initialization'), disp('Check to be sure RP2 is on and GB interface is working properly.'), disp('You may need to reinstall the GB drivers (see help).'),  return 
else
    disp('RCO file loaded');
end

pw = 0.3;
ipp = 5;
tbw = 100;
curamp = 100;
stimchan = 4;
anodcath = -1;
refchan = 0;

invoke(r,'SetTagVal','PulseWidth',pw)
invoke(r,'SetTagVal','IPP',ipp)
invoke(r,'SetTagVal','BurstWidth',tbw)
invoke(r,'SetTagVal','CurAmp',curamp)
invoke(r,'SetTagVal','StimChan',stimchan)
invoke(r,'SetTagVal','AnodCath',anodcath)
invoke(r,'SetTagVal','RefChan',refchan)

for i = 1:500
    disp(i)
    invoke(r, 'SoftTrg', 1);
    pause(1);
end

invoke(r,'Halt')