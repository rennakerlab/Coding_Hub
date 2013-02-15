data1 = f32FileRead(uigetfile('*.f32'))
data2 = f32FileRead(uigetfile('*.f32'))
data=[data1;data2];
clear data1 data2

sweeps_concat=[]; %zeros(length(files),stim,20000);
    for ee=1:2%length(files)
        for tt=1%:stim  % step across each stimulus condition
            numsweeps = size(data(ee,tt).sweep,2); % get the number of sweeps
            sweepstart=1;
            for ss=1:numsweeps
                sweepcount=max(size(data(ee,tt).sweep(ee,ss).spikes,2))+sweepstart-1;
                sweeps_concat(ee,tt,sweepstart:sweepcount)=data(ee,tt).sweep(ee,ss).spikes;
                sweepstart=sweepstart+sweepcount;   
                data(ee,tt).sweep(ss).spikes = [];   
            end
         end
    end
sweeps_concat=sort(sweeps_concat,2);
