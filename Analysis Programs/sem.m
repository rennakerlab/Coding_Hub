function ci = sem(X)
%Simple confidence interval calculator.

%CI = SEM(X) finds the standard error of the mean, ignoring any NaNs for
%all columns of the input matrix X.

if (nargin > 1)
   error('SEM requires only one input matrix.');
end
ci = zeros(1,size(X,2));                                                    %Pre-allocate a matrix to hold the SEM for each column.
N = zeros(1,size(X,2));                                                     %Pre-allocate a matrix to hold the sample counts of each column.
for i = 1:size(X,2)                                                         %Step through each colum of the input matrix.
    N(i) = sum(~isnan(X(:,i)));                                             %Find the number of non-NaN samples in each colum.
    ci(i) = nanstd(X(:,i));                                                 %Find the standard deviation across each column.
    ci(i) = ci(i)/sqrt(N(i));                                               %Find the standard error of the mean by dividing by the square root of the sample size.
end