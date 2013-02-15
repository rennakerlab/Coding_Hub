function S = boxsmooth(X,wsize)
%Box smoothing function for 2-D matrices.

%S = BOXSMOOTH(X,WSIZE) performs a box-type smoothing function on 2-D
%matrices with window width and height equal to WSIZE.  If WSIZE isn't
%given, the function uses a default value of 5.

if (nargin < 2), wsize = 5; end
if (nargin < 1)
   error('BoxSmooth requires 2-D matrix input.');
end

wsize = round(wsize);
if fix(wsize/2) == wsize/2
    wsize = wsize + 1;
end
w = fix(wsize/2);

[r,c] = size(X);
S = zeros(r,c);

for i = 1:r
    for j = 1:c
        a = [(i-w):(i+w)];
        b = [(j-w):(j+w)];
        a(find(a < 1)) = [];
        b(find(b < 1)) = [];
        a(find(a > r)) = [];
        b(find(b > c)) = [];
        S(i,j) = nanmean(nanmean(X(a,b)));
    end
end
        
            


