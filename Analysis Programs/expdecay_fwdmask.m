function yhat = expdecay_fwdmask(beta,x)

%EXPDECAY Exponential decay model for biological or chemical data.
%   YHAT = EXPDECAY(BETA,X) gives the predicted values of the
%   decay, YHAT, as a function of the vector of 
%   parameters, BETA, and the matrix of data, X.
%   BETA must have 3 elements and X must have 1
%   columns.
%
%   The model form is:
%   y = b1 + (b2-b1)*exp(b4-x1/b3)

%   b3 represents the time constant of decay.

b1 = 1;
b2 = beta(1);       %Starting point above baseline.
b3 = beta(2);       %Time constant.
b4 = beta(3);       %Time-shift from zero.
% b4 = 0;

x1 = x(:,1);

yhat = b1 + (b2 - b1).*exp((b4-x1)/b3); % for normalized data, make sure it reaches 1