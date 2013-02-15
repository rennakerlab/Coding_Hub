function S = boxsmooth2(X,xwsize,ywsize)
%Box smoothing function for 2-D matrices.

%S = BOXSMOOTH(X,WSIZE) performs a box-type smoothing function on 2-D
%matrices with window width equal to XWSIZE and window height equal to
%YWSIZE.  If *WSIZE isn't given, the function uses a default value of 5.

if (nargin == 2), xwsize = ywsize; end
if (nargin < 2), xwsize = 5; ywsize = 5; end
if (nargin < 1)
   error('BoxSmooth requires 2-D matrix input.');
end

xwsize = round(xwsize);
if fix(xwsize/2) == xwsize/2
    xwsize = xwsize + 1;
end
xw = fix(xwsize/2);

ywsize = round(ywsize);
if fix(ywsize/2) == ywsize/2
    ywsize = ywsize + 1;
end
yw = fix(ywsize/2);

[r,c] = size(X);
S = zeros(r,c);

for i = 1:r
    for j = 1:c
        a = (i-yw):(i+yw);
        b = (j-xw):(j+xw);
        a(find(a < 1)) = [];
        b(find(b < 1)) = [];
        a(find(a > r)) = [];
        b(find(b > c)) = [];
        S(i,j) = mean(mean(X(a,b)));
    end
end
        
            


