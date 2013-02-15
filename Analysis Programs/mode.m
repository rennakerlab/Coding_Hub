function [result,percents] = mode(x)
%MODE
% Finds the mode of a 2d matrix.
% [result perecents]=mode(matrix)
% where result is the mode of the matrix
% and percents is the amount of difference within the mode
% ORIGNALLY TABULATE.m by B.A. Jones
% Changes by David Li, UCSB updated: 4-8-2004

[Mo,No]=size(x);
x=reshape(x,Mo*No,1);

y = x(find(~isnan(x)))+1;

maxlevels = max(y(:));
minlevels = min(y(:));
[counts values] = hist(y,(minlevels:maxlevels)); 
total = sum(counts);

result=-1;
index=1; 
while(counts(index) ~= max(counts))
    index=index+1;    
end
result=values(index)-1; %disp(result);

percents =counts(index)/total;