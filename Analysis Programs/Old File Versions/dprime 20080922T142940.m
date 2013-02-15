function [d, c, p] = dprime(H,M,F,C)

%
%dprime.m - OU Neural Engineering Lab, 2008
%
%   dprime.m takes the number of hits, misses, false alarms, and correct
%   rejections and calculates the signal detection index d' ("d prime")
%   according to Green and Swet's signal detection theory.
%
%   dprime(H,M,F,C) returns the d' index calculated from the number of
%   hits (H), number of misses (M), number of false alarms (F), and number
%   of correct rejections (C).
%
%   [d, c] = dprime(H,M,F,C) returns the calculated d' index as well as
%   the associated bias measure c' ("c prime").
%
%   [d, c, p] = dprime(H,M,F,C) returns the calculated d' and c' as well
%   as 1 minues the the value of the normal cumulative distribution
%   function for the calculated d', approximately equivalent to a
%   statistical p value.
%
%   Last updated September 21, 2008 by Drew Sloan.

%If the number of hits and the number of misses are both greater than zero...
if M > 0 && H > 0
    a = H/(H + M);      %Hit rate is hits divided by hits plus misses.
    
%If just the number of misses is zero...
elseif H > 0 && M == 0
    a = (H-0.5)/(H);    %Hit rate is hits minus an arbitrary one-half divided by hits.
    
%If both are zero, then hit rate is arbitrarily set to 0.5 so that it
%returns a z score of zero for the d' calculation.
else
    a = 0.5;
end

%If the number of false alarms and the number of correct rejections are 
%both greater than zero...
if F > 0 && C > 0
    b = F/(F + C);      %False alarm rate is false alarms divided by false alarms plus correct rejections.
    
%If just the number of false alarms is zero...
elseif F == 0 && C > 0
    b = 0.5/C;          %False alarm rate is false alarms minus an arbitrary one-half divided by false alarms.
    
%If both are zero, then false alarm rate is arbitrarily set to 0.5 so that it
%returns a z score of zero for the d' calculation.
else
    b = 0.5;
end

%d' is calculated as the z value of the hit rate minus the z value of the
%false alarm rate.
d = norminv(a) - norminv(b);

%If the user asks for the c'...
if nargout > 1
    %c' is calculated as negative one-half of the z value of the hit rate
    %plus the z value of the false alarm rate divided by the absolute value
    %of d'.
    c = -0.5*(norminv(a) + norminv(b))/abs(d);
end

%If the user asks for the value of the normal cumulative distribution
%function for d', just
if nargout > 2
    p = 1 - normcdf(d);
end