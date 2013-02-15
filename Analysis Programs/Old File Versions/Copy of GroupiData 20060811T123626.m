
cd(uigetdir);
files = dir('*.f32');

%We'll use the "spikedataf.m" function that came with Brainware to read the
%*.f32 file.
[NFiles,k] = size(files);
i = 0;
for j = 1:NFiles    
    file = files(j);
    data = spikedataf(file.name);
    try        
        [FwdData] = Forward_Masking_Analysis(data,file);
        if isempty(FwdData)
        else
            i = i+1;
            Group(i).Name = file.name;
            Group(i).Probe1 = FwdData.Probefreq(1);
            Group(i).Probe2 = FwdData.Probefreq(2);            
            Group(i).BF=FwdData.BF;
            Group(i).BFNumber = FwdData.BFNumber;
            Group(i).MaskerLow = FwdData.MaskerBW(1);
            Group(i).MaskerHigh = FwdData.MaskerBW(2);                        
            Group(i).Probe1Low = FwdData.Probe(1).BWL;            
            Group(i).Probe1High = FwdData.Probe(1).BWH;                       
            Group(i).Probe2Low = FwdData.Probe(2).BWL;            
            Group(i).Probe2High = FwdData.Probe(2).BWH;
            Group(i).Probe1Number = FwdData.ProbeNumber(1);
            Group(i).Probe2Number = FwdData.ProbeNumber(2);
            Group(i).MaskerLowNumber = FwdData.MaskerBWNumber(1);
            Group(i).MaskerHighNumber = FwdData.MaskerBWNumber(2);
            Group(i).Probe1LowNumber = FwdData.Probe(1).BWLNumber;
            Group(i).Probe1HighNumber = FwdData.Probe(1).BWHNumber;
            Group(i).Probe2LowNumber = FwdData.Probe(2).BWLNumber;
            Group(i).Probe2HighNumber = FwdData.Probe(2).BWHNumber;
            Group(i).Probe1LongestSOA = FwdData.Probe(1).LongestSOA;
            Group(i).Probe2LongestSOA = FwdData.Probe(2).LongestSOA;  
        end
    catch
        
    end
end
save(GroupData);
exit;