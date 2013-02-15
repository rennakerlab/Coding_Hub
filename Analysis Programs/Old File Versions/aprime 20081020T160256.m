function [Ai, Bii] = aprime(H,M,F,C)

%
%aprime.m - OU Neural Engineering Lab, 2008
%
%   aprime.m takes the number of hits, misses, false alarms, and correct
%   rejections and calculates the signal detection index A' ("A prime")
%   defined by Pollack and Norman, 1964.
%
%   aprime(H,M,F,C) returns the A' index calculated from the number of
%   hits (H), number of misses (M), number of false alarms (F), and number
%   of correct rejections (C).
%
%   [Ai, Bii] = aprime(H,M,F,C) returns the calculated d' as well as
%   the associated bias index B'' ("B double-prime"), taken from Grier,
%   1971.
%
%   Last updated September 21, 2008 by Drew Sloan.

%If the number of hits and the number of misses are both greater than zero...
if M > 0 && H > 0
    h = H/(H + M);      %Hit rate is hits divided by hits plus misses.
    
%If just the number of misses is zero...
elseif H > 0 && M == 0
    h = (H-0.5)/(H);    %Hit rate is hits minus an arbitrary one-half divided by hits.
    
%If both are zero, then hit rate is arbitrarily set to 0.5 so that it
%returns a z score of zero for the d' calculation.
else
    h = 0.5;
end

%If the number of false alarms and the number of correct rejections are 
%both greater than zero...
if F > 0 && C > 0
    f = F/(F + C);      %False alarm rate is false alarms divided by false alarms plus correct rejections.
    
%If just the number of false alarms is zero...
elseif F == 0 && C > 0
    f = 0.5/C;          %False alarm rate is false alarms minus an arbitrary one-half divided by false alarms.
    
%If both are zero, then false alarm rate is arbitrarily set to 0.5 so that it
%returns a z score of zero for the d' calculation.
else
    f = 0.5;
end

%The A' index is calculated as follows from the hit rate (a) and false
%alarm rate (b).
Ai = 0.5 + (h-f)*(1+h-f)/(4*h*(1-f));

%If the user asks for the B'' bias index...
if nargout > 1
    %The B'' bias index is calculated from the hit rate (a) and false alarm
    %rate (b) as follows.
    Bii = (h*(1-h)-f*(1-f))/(h*(1-h)+f*(1-f));
end