function [dless, varargout] = perfthresh(counts, index, alpha)

%
%perfthresh.m - OU Neural Engineering Lab, 2008
%
%   perfthresh.m takes pitch discrimination data, in the form of hit, miss,
%   false alarm, and correct rejection counts for each tested frequency
%   difference, and returns the upward and downward change thresholds as
%   well as the directionless threshold.
%
%   [up, down, dless, curve] = perfthresh(counts, index, alpha) returns the
%   upward-change threshold ("up"), downward change threshold ("down"), 
%   directionless threshold ("down"), and performance curve ("curve") using
%   the inputs: "counts", a matrix with 3 columns of delta f, number of 
%   hits/false alarms, and number of trials at that delta f; "index", the 
%   detection index used for calculation, which can be set to d' 
%   ('dprime'), A' ('aprime'), or false-alarm-correct hit rate ('hitrate');
%   and "alpha", the significance level used to find thresholds for 
%   detection indices that use significance levels.
%
%   Last updated March 6th, 2012 by Drew Sloan.

i = isnan(counts(:,2)) | isnan(counts(:,3));                                %Find any NaN values in the input matrix.
counts(i,:) = [];                                                           %Kick out all rows with NaN values.
if isempty(counts) || ~any(counts(:,1) == 0) || ...
        counts(counts(:,1) == 0,3) == 0                                     %If there's no non-NaN values or no catch trials...
    dless = NaN;                                                            %Return a NaN as the threshold.
    varargout{1} = NaN;                                                     %Return a NaN also as the first optional output.
    varargout{2} = NaN;                                                     %Return a NaN also as the second optional output.
    return
end
counts = sortrows(counts);                                                  %Make sure the input matrix is sorted.

if strcmpi(index,'hitrate')                                                 %If we're calculating thresholds using false-alarm-corrected hit rates...
    curve = [counts(:,1), counts(:,2)./counts(:,3)];                        %Convert the hit/false alarm counts to percent hit/false alarms.
    F = curve(curve(:,1) == 0,2);                                           %Grab the false alarm rate.
    curve(curve(:,1) ~= 0,2) = curve(curve(:,1) ~= 0,2)*(1-F);              %Correct hit rate with false alarm rate by the equation Hc = H*(1-F).
    temp = [];                                                              %Create a temporary matrix to hold direction-less thresholds.
    for i = unique(abs(counts(:,1)))'                                       %Step through all absolute delta fs.
        temp = [temp; i, sum(counts(abs(counts(:,1)) == i,2:3),1)];         %Add the positive and negative counts together.
    end
    dless_curve = [temp(:,1), temp(:,2)./temp(:,3)];                        %Convert the absolute delta-f counts to hit rate and false alarm rate.
    dless_curve(dless_curve(:,1) ~= 0,2) = ...
        dless_curve(dless_curve(:,1) ~= 0,2)*(1-F);                         %Correct the absolute delta-f  hit rate with false alarm rate by the equation Hc = H*(1-F).
    threshold = 0.5;                                                        %For corrected hit rate we'll use a threshold of 0.5.
elseif strcmpi(index,'dprime') || strcmpi(index,'aprime')                   %If we're calculatign thresholds using d-prime or A-prime...
    F = counts(counts(:,1) == 0,2);                                         %Grab the number of false alarms.
    C = counts(counts(:,1) == 0,3) - F;                                     %Grab the number of correct rejections.
    curve = [];                                                             %Make a matrix to hold the performance curve.
    for i = unique(counts(:,1))'                                            %Step through by delta f.
        H = counts(counts(:,1) == i,2);                                     %Grab the number of hits.
        M = counts(counts(:,1) == i,3) - H;                                 %Grab the number of misses.
        if strcmpi(index,'dprime')                                          %If we're using d-prime...
            curve = [curve; i, dprime(H,M,F,C)];                            %Compute the d-prime for this delta f and add it to the curve.
        else                                                                %If we're using a-prime...
            curve = [curve; i, aprime(H,M,F,C)];                            %Compute the a-prime for this delta f and add it to the curve.
        end
    end
    dless_curve = [];                                                       %Make a matrix to hold direction-less performance curves.
    for i = unique(abs(counts(:,1)))'                                       %Step through by absolute delta f.
        H = sum(counts(abs(counts(:,1)) == i,2));                           %Grab the number of hits.
        M = sum(counts(abs(counts(:,1)) == i,3)) - H;                       %Grab the number of misses.
        if strcmpi(index,'dprime')                                          %If we're using d-prime...
            dless_curve = [dless_curve; i, dprime(H,M,F,C)];                %Compute the d-prime for this absolute delta f and add it to the curve.
        else                                                                %If we're using A-prime...
            dless_curve = [dless_curve; i, aprime(H,M,F,C)];                %Compute the A-prime for this delta f and add it to the curve.
        end
    end
    if strcmpi(index,'dprime')                                              %If we're using d-prime...
        threshold = norminv(1-alpha/2);                                     %We'll use the z-value of the alpha for the threshold.
    else                                                                    %If we're using A-prime...
        threshold = 0.85;                                                   %We'll use a value 0f 0.85 as the threshold.
    end
else                                                                        %If the index is none of the above options, show an error.
    error('Detection index not recognized.  Choose ''dprime'', ''aprime'', or ''hitrate''.');
end

%Now we'll take the index curves and use them to find thresholds.

%First, the upward-going threshold.
temp = curve(curve(:,1) >= 0,:);                                            %Find all positive delta fs.
a = find(temp(:,2) >= threshold,1,'first');                                 %Find the first curve point above threshold.
if ~isempty(a) && a ~= 1                                                    %If some point crossed threshold and it's not at the 0 delta f...
    up = temp(a-1,1) + (threshold - ...
        temp(a-1,2))*(temp(a,1)-temp(a-1,1))/(temp(a,2)-temp(a-1,2));       %Interpolate the threshold crossing.
else                                                                        %If the first curve point above threshold is at the 0 delta f or no points are above threshold...
    up = NaN;                                                               %Leave the threshold undefined.
end

%Second, the downward-going threshold.
temp = curve(curve(:,1) <= 0,:);                                            %Find all negative delta fs.
temp = flipud(temp);                                                        %Flip the order of the delta fs so zero comes first.
a = find(temp(:,2) >= threshold,1,'first');                                 %Find the first curve point above threshold.
if ~isempty(a) && a ~= 1                                                    %If some point crossed threshold and it's not at the 0 delta f...
    
    down = temp(a-1,1) + (threshold - ...
        temp(a-1,2))*(temp(a,1)-temp(a-1,1))/(temp(a,2)-temp(a-1,2));       %Interpolate the threshold crossing.
else                                                                        %If the first curve point above threshold is at the 0 delta f or no points are above threshold...
    down = NaN;                                                             %Leave the threshold undefined.
end

%Finally, compute the directionless threshold from the directionless curve.
a = find(dless_curve(:,2) >= threshold,1,'first');                          %Find the first curve point above threshold.
if ~isempty(a) && a ~= 1                                                    %If some point crossed threshold and it's not at the 0 delta f...
    dless = dless_curve(a-1,1) + (threshold - dless_curve(a-1,2))*...
        (dless_curve(a,1)-dless_curve(a-1,1))/...
        (dless_curve(a,2)-dless_curve(a-1,2));                              %Interpolate the threshold crossing.
else                                                                        %If the first curve point above threshold is at the 0 delta f or no points are above threshold...
    dless = NaN;                                                            %Leave the threshold undefined.
end

varargout{1} = up;                                                          %The first optional output is the upward-going threshold.
varargout{2} = down;                                                        %The second optional output is the downward-going threshold.