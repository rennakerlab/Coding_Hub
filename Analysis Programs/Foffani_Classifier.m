function varargout = Foffani_Classifier(varargin)

%
%Foffani_Classifier.m - Rennaker Neural Engineering Lab, 2010
%
%   Foffani_Classifier takes the raw, unfiltered sweeep traces from neural recordings
%   saved in the *.NEL format, filters the signal, and then thresholds the
%   filtered signal to identify spikes.  Spike shapes and spike times are then
%   saved in the *.SPK file format.  All spikes are preliminarily assigned to
%   cluster #1 prior to spike sorting.
%
%   thresh = NELtoSPK(file) thresholds the input *.NEL file using all 
%   function defaults and returns the set threshold value in volts.
%
%
%   Last updated January 20, 2010, by Drew Sloan.

if nargin < 2                                                               %If there's less than two input arguments...
    error('Foffani_Classifier: Not enought input arguments!');              %...Show an error.
else
    psths = varargin{1};                                                    %The PSTH matrix should be the first input argument.
    actual = varargin{2};                                                   %The stimulus identity matrix should be the second input argument.
    if size(actual,2) > 1                                                   %If there's more than one column in the stimulus identity matrix...
        error('Foffani_Classifier: Stimulus identity matrix should be a single-column vector!');            %...Show an error.
    elseif size(actual,1) ~= size(psths,1)                                  %Or if the stimulus identity matrix doesn't match the size of the PSTH matrix.
        error('Foffani_Classifier: Stimulus identity matrix size doesn''t match the PSTH matrix size!');    %...Show an error.
    end
end
if nargin == 3                                                              %If there's a third input argument...
    sameweight = varargin{3};                                               %...that argument should indicate whether the weights of the constituent units are equal.
    if ~any(sameweight == [0 1])                                            %If the entered value isn't a one or a zero...
        error('Foffani_Classifier: The equal-weighting property must be set to 0 or 1!');                   %...Show an error.
    end
else                                                                        %Otherwise...
    sameweight = 1;                                                         %...by default, weight all the units the same.
end
stim = unique(actual)';                                                     %Find all unique stimuli.
numstim = length(stim);                                                     %Find the number of stimuli to classify to.
numtrials = size(psths,1);                                                  %Find the total number of trials.
numcolumns = size(psths,2);                                                 %Find the total number of columns in the PSTHs.
numunits = size(psths,3);                                                   %Find the number of input units. 
templates = nan(numstim,numcolumns,numunits);                               %Create a matrix to hold PSTH templates for matching.
distance = nan(numstim,numunits);                                           %Pre-allocate a matrix to hold Euclidean distances to each template.
accuracy = 0;                                                               %To find the accuracy, we'll just count correct classifier guesses.
if nargout > 1                                                              %If the user's specified an output for classifier guesses...
    guess = zeros(numtrials,1);                                             %Pre-allocate a matrix to hold those guesses.
end
if nargout > 2                                                              %If the user's specified an output for by-column accuracy...
    bycolumn = zeros(1,numcolumns);                                         %...pre-allocate a matrix to hold by-column accuracy...
    columndist = zeros(numstim,numcolumns,numunits);                        %...and pre-allocate a matrix to hold by-column distances.
end
for i = 1:numtrials                                                         %Step through by trial.
    for j = 1:numstim                                                       %Step through each unique stimulus.
        for k = 1:numunits                                                  %Step through each included unit.
            a = setdiff(find(actual == stim(j)),i);                         %Find all of this stimuli, not including the current trial.
            templates(j,:,k) = mean(psths(a,:,k));                          %Create a template out of the mean PSTH for this stimulus.
            distance(j,k) = sqrt(sum((templates(j,:,k) - ...
                psths(i,:,k)).^2));                                         %Find the Euclidean distance to each template.
            if nargout > 2                                                  %If the user specified by-column classification...
                columndist(j,:,k) = abs(templates(j,:,k) - psths(i,:,k));   %...find the Euclidean distance at each column.
            end
        end
    end
    if sameweight && numunits > 1                                           %If all the units are supposed to be weighted the same...
        for k = 1:numunits                                                  %Step through each unit.
            distance(:,k) = distance(:,k)/sum(distance(:,k));               %Normalize the distance values for this unit by the sum of the distances.
            if nargout > 2                                                  %If the user specified by-column classification...
                for j = 1:numcolumns                                        %...step through each column...
                    columndist(:,j,k) = ...
                        columndist(:,j,k)/sum(columndist(:,j,k));           %and normalize the by-column distance values.
                end
            end
        end
    end
    j = sum(distance,2);                                                    %Sum the distance values across units.
    if sum(j == min(j)) == 1                                                %If there's only one match...
        accuracy = accuracy + (stim(j == min(j)) == actual(i));             %...classify accuracy according to the shortest total distance.
        if nargout > 1                                                      %If the user's specified an output for classifier guesses...
            guess(i) = stim(j == min(j));                                   %...save the classifier guess for this trial.
        end
    elseif nargout > 1                                                      %If there's more than one match and the user's specified an output for classifier guesses...
        guess(i) = NaN;                                                     %...save a NaN to indicate no classifier guess for this trial.
    end
    if nargout > 2                                                          %If the user specified by-column classification...
        j = sum(columndist,3);                                              %...sum the by-column distances across units...
        for k = 1:numcolumns                                                 %...and step through each column.
            if sum(j(:,k) == min(j(:,k))) == 1                              %If there's only one match...
                bycolumn(k) = bycolumn(k) + ...
                    (stim(j(:,k) == min(j(:,k))) == actual(i));             %...count by-column correct classifier guesses.
            end
        end
    end
end
accuracy = accuracy/numtrials;                                              %Divide by total number of trials to find the accuracy.
if nargout > 2
    bycolumn = bycolumn/numtrials;
end
varargout{1} = accuracy;                                                    %The primary output is the accuracy.
if nargout > 1
    varargout{2} = guess;                                                   %The second (optional) output is the classifier guesses for each trial.
end
if nargout > 2
    varargout{3} = bycolumn;                                                %The third (optional) output is the by-column accuracy.
end