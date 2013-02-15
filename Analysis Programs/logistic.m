function yhat = logistic(beta,x)

%LOGISTIC Logistic equation model for biological or psychophysical data.
%   YHAT = EXPDECAY(BETA,X) gives the predicted values of the logistic 
%   regression, YHAT, as a function of the vector of parameters, BETA, and
%   the matrix of data, X. BETA must have 4 elements and X must have 1
%   columns.
%
%   The model form is:
%   y = b1 + b2/[1 + exp(-(x - b3)/b4)]

b1 = beta(1);   %Initial value
b2 = beta(2);   %Final value
b3 = beta(3);   %Horizontal shift.
b4 = beta(4);   %Time constant/slope.

x1 = x(:,1);

yhat = b1 + b2/(1 + exp(-(x1 - b3)/b4));