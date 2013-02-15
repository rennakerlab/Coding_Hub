%This script will grab data for the specified rats from each testing stage
%and obtain the mean and 95% ci for their hit rats in each.
clear all
rats = [{'LANT52'}, {'LANT50'}, {'LANT51'}, {'START99'}];


for i = 1:length(rats)
    [agram, freqs, ahvsi] = Noise_Detection_Audiogram(rats{i}, 'off');
    if isempty(agram)
        disp([rats{i}, ' has no audiogram']);
    else
    audiogram(i,:) = agram;
    freqs(i,:) = freqs;
    ahitvsints(:,:,i) = ahvsi;
    end
    
   [dgram, junk, dhvsi] = Gap_Detection_Audiogram(rats{i}, 'off');
   if isempty(dgram)
       disp([rats{i}, ' has no detectogram']);
   else
       detectogram(i,:) = dgram;
       dhitvsints(:,:,i) = dhvsi;
   end
end

ahitvsints = permute(ahitvsints, [3 2 1]);
dhitvsints = permute(dhitvsints, [3 2 1]);

audiogram_mean = col_mean(audiogram);
audiogram_ci = simple_ci(audiogram);
detectogram_mean = col_mean(detectogram);
detectogram_ci = simple_ci(detectogram);
shiftogram = detectogram - audiogram;
shiftogram_mean = col_mean(shiftogram);
shiftogram_ci = simple_ci(shiftogram);

errorbar(audiogram_mean, audiogram_ci);
hold on
errorbar(detectogram_mean, detectogram_ci);
temp = cell(length(freqs(1,:)),1);                                  %Create a cell array to hold the x-axis labels.
        for i = 1:length(freqs(1,:))                                        %Step through each of the tested frequencies.
            temp{i} = num2str(freqs(1,i)/1000,'%1.1f');                  %Convert each frequency to kHz.
        end
set(gca, 'XTickLabel', temp)

figure
errorbar(shiftogram_mean, shiftogram_ci)
set(gca, 'XTickLabel', temp)

%Now let's find the 20, 40, 60, 80% hit intensities in audio and gap
%detectograms

for i = 1:length(ahitvsints(:,1,:))
    ahit_mean(i,:) = col_mean(ahitvsints(:,:,i));
    ahit_ci(i,:) = simple_ci(ahitvsints(:,:,i));
    dhit_mean(i,:) = col_mean(dhitvsints(:,:,i));
    dhit_ci(i,:) = simple_ci(dhitvsints(:,:,i));
end