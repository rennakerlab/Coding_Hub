function yhat = expdecay(beta,x)

%EXPDECAY Exponential decay model for biological or chemical data.
%   YHAT = EXPDECAY(BETA,X) gives the predicted values of the
%   decay, YHAT, as a function of the vector of 
%   parameters, BETA, and the matrix of data, X.
%   BETA must have 3 elements and X must have 1
%   columns.
%
%   The model form is:
%   y = b1 + b2*exp(-x1/b3)

%   b3 represents the time constant of decay.

b1 = beta(1);
b2 = beta(2);
b3 = beta(3);

x1 = x(:,1);

yhat = b1 + (b2 - b1).*exp(-x1/b3);