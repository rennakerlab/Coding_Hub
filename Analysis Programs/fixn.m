function [x,msg] = fixn(x,n)
%FIXN  Round numbers to specified power of 10
%
%  y = FIXN(x) rounds the input data x to the nearest hundredth.
%
%  y = FIXN(x,n) rounds the input data x at the specified power
%  of tens position.  For example, n = -2 rounds the input data to
%  the 10E-2 (hundredths) position.
%
%  [y,msg] = FIXN(...) returns the text of any error condition
%  encountered in the output variable msg.
%
%  See also FIX

% Copyright 1996-2006 The MathWorks, Inc.
% Written by:  E. Byrns, E. Brown
% $Revision: 1.9.4.2 $    $Date: 2006/05/24 03:36:29 $

msg = [];   %  Initialize output

if nargin == 0
    error('Incorrect number of arguments')
elseif nargin == 1
    n = -2;
end

%  Test for scalar n

if max(size(n)) ~= 1
   msg = 'Scalar accuracy required';
   if nargout < 2;  error(msg);  end
   return
elseif ~isreal(n)
   warning('Imaginary part of complex N argument ignored')
   n = real(n);
end

%  Compute the exponential factors for rounding at specified
%  power of 10.  Ensure that n is an integer.

factors  = 10 ^ (fix(-n));

%  Set the significant digits for the input data

x = round(x * factors) / factors;
