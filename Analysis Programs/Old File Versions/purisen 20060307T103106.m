function [p,Table,stats] = purisen(X, reps, displayopt)
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

[r,c] = size(X);
if r <=1 | c <= 1
    error('Must have at least two rows and columns.');
end
if nargin < 2 
    reps = 1; 
end
if nargin < 3
    displayopt = 'on'; 
end
if any(isnan(X(:)))
    error('NaN values in input not allowed.');
end
if reps > 1
   r = r/reps;
   if floor(r) ~= r
       error('The number of rows must be a multiple of REPS.');
   end
end   
if ~(isequal(displayopt,'on') | isequal(displayopt,'off'))
   error('Third argument must be ''on'' or ''off''.');
end

% Get a matrix of ranks.  For the unusual case of replicated
% measurements, rank together all replicates in the same row.  This
% is the advice given by Zar (1996), "Biostatistical Analysis."
[r,c] = size(X);
ranks = zeros(r*c,1);
for i = 1:c
    ranks(((i-1)*r+1):(i*r)) = X(:,i);
end
[ranks sumties] = tiedrank(ranks);
ranks = ranks';
Xprime = zeros(r,c);
for i = 1:c
    Xprime(:,i) = ranks(((i-1)*r+1):(i*r));
end

if isequal(displayopt,'on')
    if nargout < 2
        p = anova2(Xprime,reps,'on');
    elseif nargout == 2
        [p,Table] = anova2(Xprime,reps,'on');
    else
        [p,Table,stats] = anova2(Xprime,reps,'on');
    end
else
    if nargout < 2
        p = anova2(Xprime,reps,'off');
    elseif nargout == 2
        [p,Table] = anova2(Xprime,reps,'off');
    else
        [p,Table,stats] = anova2(Xprime,reps,'off');
    end
end