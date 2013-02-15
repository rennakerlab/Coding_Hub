%% This subfunction finds peaks in the signal, accounting for equality of contiguous samples.
function [pks,i] = PeakFinder(signal,minpkdist)

%
%PEAKFINDER.m - Rennaker Neural Engineering Lab, 2013
%
%   PEAKFINDER identifies peaks in signals, accounting for equality of
%   contiguous samples by identifying on the first of N equal, contiguous
%   samples as the peak.
%
%   [pks,i] = PeakFinder(signal,minpkdist) finds the peaks in the vector
%   variable "signal", and kicks out any peaks that follow a preceding peak
%   by fewer samples than specified by "minpkdist".  The peak heights are
%   outputted into the "pks" variable, and the corresponding sample indices
%   are outputed into the "i" variable.
%
%   Last modified January 31, 2013, by Drew Sloan.

i = find(signal(2:end) - signal(1:end-1) > 0) + 1;                          %Find each point that's greater than the preceding point.
j = find(signal(1:end-1) - signal(2:end) >= 0);                             %Find each point that's greater than or equal to the following point.
i = intersect(i,j);                                                         %Find any points that meet both criteria.
checker = 1;                                                                %Make a variable to check for peaks too close together.
while checker == 1 && length(i) > 2                                         %Loop until no too-close together peaks are found.
    checker = 0;                                                            %Set the checker variable to a default of no too-close peaks found.
    j = i(2:end) - i(1:end-1);                                              %Find the time between peaks.
    if any(j < minpkdist)                                                   %If any too-close-together peaks were found...
        j = find(j < minpkdist,1,'first') + 1;                              %Find the first set of too-close-together peaks.
        i(j) = [];                                                          %Kick out the following peak of the too-close-together pair.
        checker = 1;                                                        %Set the checker variable back to one to loop around again.
    end
end
pks = signal(i);                                                            %Grab the value of the signal at each peak.