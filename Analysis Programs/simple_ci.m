function ci = simple_ci(X,alpha)
%Simple confidence interval calculator.

%CI = SIMPLE_CI(X,ALPHA) finds the confidence range for the single column
%dataset X using the significance level ALPHA.  If ALPHA isn't specified,
%the function uses a default value of 0.05.

if (nargin < 2)     %If the use didn't specify an alpha.
    alpha = 0.05; 
end     
if (nargin < 1)
   error('simple_ci requires single column data input.');
end
[h,p,ci] = ttest(X,0,alpha);
ci = nanmean(X,1)-ci(1,:);