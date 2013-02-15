data1 = f32FileRead(uigetfile('*.f32'))
data2 = f32FileRead(uigetfile('*.f32'))
data=[data1;data2];
clear data1 data2
sweep_hist=[];
stim=size(data(1,:),2);
% sweeps_concat=[]; %zeros(length(files),stim,20000);
    for ee=1:2%length(files)
        for tt=1:stim  % step across each stimulus condition
            numsweeps = size(data(ee,tt).sweep,2); % get the number of sweeps
%             sweepstart=1;
            for ss=1:numsweeps
                %sweepcount=max(size(data(ee,tt).sweep(ee,ss).spikes,2))+sweepstart-1;
                sweep_hist(ee,tt,:)=histc(data(ee,tt).sweep(1,ss).spikes(),1:1000);
                sweep_hist=sweep_hist+sweep_hist;   
            end
        end
        sweep_hist(ee,tt,:) = sweep_hist(ee,tt,:)/numsweeps;
    end
% sweeps_concat=sort(sweeps_concat,2);
