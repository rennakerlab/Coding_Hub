function STRFComparator

PreData = spikedataf(PreFile);
%HabData = spikedataf(HabFile);
PostData = spikedataf(PostFile);

TrimPercent = 0.2

NumPreReps = length(PreData(1).sweep);
NumFreq = length([PreData(:).stim]);
temp = [PreData(:).stim]
Frequencies = temp(1,:)'
temp = zeros(length(PreData(1).sweep),PreData(1).sweeplength);
for i = 1:NumFreq;
    for j = 1:NumPreReps;
        try;
            temp(j,:) = histc(PreData(i).sweep(j).spikes,[1:PreData(i).sweeplength]);
        catch;
            temp(j,:) = zeros(1,PreData(i).sweeplength);
        end;
    end;
   PreData(i).spikerate = temp/(0.001);
end;
%NumHabReps = length(HabData(1).sweep);
%temp = zeros(length(HabData(1).sweep),HabData(1).sweeplength);
%for j = 1:NumHabReps;
    %try;
        %temp(j,:)=histc(HabData(1).sweep(j).spikes,[1:HabData(1).sweeplength]);
        %catch;
        %temp(j,:)=zeros(1,HabData(1).sweeplength);
        %end;
    %end;
%HabData(1).spikerate = temp/(0.001)
NumPostReps = length(PostData(1).sweep)
temp = zeros(length(PostData(1).sweep),PostData(1).sweeplength)
for i = 1:NumFreq;
    for j = 1:NumPostReps;
        try;
            temp(j,:)=histc(PostData(i).sweep(j).spikes,[1:PostData(i).sweeplength]);
        catch;
            temp(j,:)=zeros(1,PostData(i).sweeplength);
        end;
    end;
    PostData(i).spikerate = temp/(0.001);
end;
temp = zeros(NumFreq,PreData(1).sweeplength);
for i = 1:NumFreq;
    temp(i,:)=mean(PreData(i).spikerate);
end;
STRF.Pre.Mean = temp;
for i = 1:NumFreq;
    temp(i,:)=trimmean(PreData(i).spikerate,TrimPercent);
end;
STRF.Pre.Trim = temp;
STRF.Pre.Smooth = smoothts(smoothts(STRF.Pre.Mean)')';
for i = 1:NumFreq;
    temp(i,:)=std(PreData(i).spikerate);
end;
STRF.Pre.StDev = temp;
for i = 1:NumFreq;
    temp(i,:)=mean(PostData(i).spikerate);
end;
STRF.Post.Mean = temp;
for i = 1:NumFreq;
    temp(i,:)=trimmean(PostData(i).spikerate,TrimPercent);
end;
STRF.Post.Trim = temp;
STRF.Post.Smooth = smoothts(smoothts(STRF.Post.Mean)')'
for i = 1:NumFreq;
    temp(i,:)=std(PostData(i).spikerate);
end;
STRF.Post.StDev = temp;
STRF.Diff.Mean = STRF.Post.Mean-STRF.Pre.Mean;
STRF.Diff.Trim = STRF.Post.Trim-STRF.Pre.Trim;
STRF.Diff.Smooth = STRF.Post.Smooth-STRF.Pre.Smooth;
for i = 1:NumFreq;
    for j = 1:PreData(i).sweeplength;
        try;
            temp(i,j)=ttest2(PreData(i).spikerate(:,j),PostData(i).spikerate(:,j));
        catch;
            temp(i,j)=0;
        end;
    end;
end;
STRF.Diff.Sig = temp;
end