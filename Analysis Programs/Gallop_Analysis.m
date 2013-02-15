function Gallop_Analysis

[file path] = uigetfile('*.f32');                                           %Have the user grab a file to analyze.
cd(path);                                                                   %Change the directory to the file's directory.

data = f32FileRead(file);                                                   %Use the f32FileRead function to read in the file's data.

sweeplength = data(1).sweeplength;                                          %Grab the sweeplength from the first stimulus.

psths = zeros(length(data),sweeplength+1);                                  %Pre-allocate a matrix to hold PSTHs.

for i = 1:length(data)                                                      %Step through each stimulus in the file.
    for j = 1:length(data(i).sweep)                                         %Step through each sweep for this stimulus.
        if ~isempty(data(i).sweep(j).spikes)                                %If there's spikes in this sweep...
            psths(i,:) = psths(i,:) + histc(data(i).sweep(j).spikes,0:sweeplength); %Add this sweep's PSTH to the summed PSTH.
        end
    end
    psths(i,:) = psths(i,:)/length(data(i).sweep);                          %Convert the summed PSTH to the average PSTH.
    psths(i,:) = boxsmooth(psths(i,:),5);                                   %Smooth the average PSTH with a 5 millisecond box smooth.
end

%Basic analysis.
spont_delay = data(1).params(8);                                            %Grab the spontaneous recording delay.
dur = data(1).params(5);                                                    %Grab the tone duration.
iti = data(1).params(6);                                                    %Grab the inter-tone interval.
peak = zeros(length(data),80);                                              %Pre-allocate a matrix to hold peak spikerates.
steps = spont_delay:(dur + iti):sweeplength-500;                            %Make time-steps for the for loop.     
for i = steps                                                               %Step through by tone.
    for j = 1:length(data)                                                  %Step through by stimulus.
        peak(j,i==steps) = max(psths(j,i:(i+dur)));                         %Save the peak spikerate for this tone.
    end
end

plot(1:2:80,peak(8,1:2:80),'b',2:4:80,peak(8,2:4:80),'r');

plot((2:4:80)',peak(8:9,2:4:80)')
hold on;
plot((1:2:80)',peak(8:9,1:2:80)','linestyle','--')
        

