function HiLow

cd(uigetdir);
files = dir('*.f32'); 
NFiles=length(files);
BinSize=5;%PSTH Binsize in ms
AllPSTH=[];
for A=1:NFiles%Runs through all f32 files.
    A,
    fname=files(A).name;
    data=spikedata(fname);%Opens f32 files
        % parameters:1) Masker Freq (Hz), 2)Masker Intensity, 3)Probe Freq(Hz),
        % 4)Probe Int, 5)Inter-Tone-Interval (ms), 6) Tone Duration (ms),7)Spontaneous;
    Stimulus=horzcat(data(:).stim)';%Puts stimulus parameters into columns
    NStimuli=length(Stimulus);
    
    for B=1:NStimuli
        NSweeps=length(data(B).sweep);
        for C=1:NSweeps
            try
                PSTH=histc(data(B).sweep(C).spikes,[1:BinSize:data(B).sweeplength]);%Puts spike times in 5ms Bins
            catch
                PSTH=zeros(1,floor(data(B).sweeplength/BinSize));
            end
            if isempty(AllPSTH)
                AllPSTH=PSTH;
            else
                AllPSTH=vertcat(AllPSTH,PSTH);
            end
            
        end
        File(A).Stimulus(B).PSTH=AllPSTH;
        AllPSTH=[];
    end
end



for A=1:NFiles%Plots mean PSTH for Each File.
    [Reps,Bins]=size(File(A).Stimulus(B).PSTH);
    [Stimuli,Var]=size(Stimulus);
    FigureData=zeros(Stimuli,Bins);   
    for B=1:Stimuli
        
        FigureData(B,:)=mean(File(A).Stimulus(B).PSTH);

    end
    figure;
    surf(FigureData,'edgecolor','none');
    axis([0,80,0,16]);
end

















        