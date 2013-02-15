function [p,Table,stats] = purisen(data,reps,displayopt)

%Puri and Sen Nonparametric two-way analysis of variance (ANOVA).

%PURISEN(X,REPS,DISPLAYOPT) performs a Puri and Sen (PS) nonparametric
%verison of the two-way ANOVA for linear models.  "The rank tests given by
%Puri and Sen (PS) (1985) for linear models can be adopted for tests on
%main effects and interaction in a two-way layout and can be presented as a
%funtion of the porportion of variability due to the desired effect (see
%Harwell, 1991; Harwell and Serlin, 1990)." - Quote taken from Toothaker
%and Newman, 1994.

%[P,TABLE,STATS] = PURISEN(...) returns three items.  P is either a two- or
%three-element matrix.  If there is only one sample per cell, P is a matrix
%consisting of the p-value for the column effect and the p-value for the
%row effect, in that order.  If there is more than one sample per cell, P
%is matrix consisting of the p value for the column effect, the row effect,
%and the interaction effect.  TABLE is a cell array containing the contents 
%of the anova table.  STATS is a structure of statistics, useful for performing 
%multiple comparisons with the multcompare function.

%   See also ANOVA2, MULTCOMPARE, FRIEDMAN.

%   Reference: Puri, M.L., and Sen, P.K. (1985) Nonparametric methods in
%   general linear models.  New York, Wiley.

%   Prepared by Andrew Sloan, University of Oklahoma Neural Engineering Lab
%   $Date: 2006/03/01 23:11:00 $

[r,c] = size(data);                                                         %Find the size of the input data matrix.
if r <= 1 || c <= 1                                                         %If the matrix is too small for an ANOVA... 
    error('Must have at least two rows and columns.');                      %Show an error.
end
if nargin < 2                                                               %If the user didn't specify the number of replications...
    reps = 1;                                                               %Assume there's only one replication per sample.
end
if nargin < 3                                                               %If the user hasn't specified a display option...
    displayopt = 'on';                                                      %Assume they want the ANOVA table shown.
end
if any(isnan(data(:)))                                                      %If there's any NaNs in the data...
    error('ERROR IN PURISEN: NaN values in input are not allowed!');        %Show an error.
end
if mod(r,reps) ~= 0                                                         %If the number of rows isn't a multiple of the number of replications...
   error('ERROR IN PURISEN: The number of rows must be a multiple of "reps"!');     %Show an error.
end   
if ~(isequal(displayopt,'on') || isequal(displayopt,'off'))                 %If the user specified something other than 'on' or 'off' for the display option...
   error('ERROR IN PURISEN: The third argument must be ''on'' or ''off''.');        %Show an error.
end

X = zeros(r*c,1);                                                           %Pre-allocate a vector to hold the data for the anovan function.
group = zeros(r*c,2);                                                       %Pre-allocate a matrix to hold group information for each sample.
for i = 1:reps:r                                                            %Step through the rows of the input data by replication number.
    for j = 1:c                                                             %Step through the columns of the input data.
        X(r*(j-1)+(i:(i+reps-1))) = data(i:(i+reps-1),j);                   %Move each input sample over to the vector.
        group(r*(j-1)+(i:(i+reps-1)),1) = (i+reps-1)/reps;                  %Save the row group number for each sample..
        group(r*(j-1)+(i:(i+reps-1)),2) = j;                                %Save the column group number for each sample..
    end
end

%Convert the vector of values to a vector of ranks.Get a matrix of ranks.  
%For the unusual case of replicated measurements, rank together all 
% replicates in the same row.  This is the advice given by Zar (1996), 
%"Biostatistical Analysis."
Xprime = tiedrank(X);                                                       %Rank the vector, adjusting for ties.   

%Run the ANOVA on the ranks using the anovan function.
[p,Table,stats] = anovan(Xprime,group,'display',displayopt,'model','interaction');