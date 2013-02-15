function S = boxsmooth3(X,wsize)
%Box smoothing function for 2-D matrices.

%S = BOXSMOOTH(X,WSIZE) performs a box-type smoothing function on 2-D
%matrices with window width and height equal to WSIZE.  If WSIZE isn't
%given, the function uses a default value of 5.  If WSIZE is set to an even
%number or a non-whole number, the edge values of the box are weighted
%according to the remainder.

if (nargin < 2), wsize = 5; end
if (nargin < 1)
   error('BoxSmooth requires 2-D matrix input.');
end

w = (wsize-1)/2;

[r,c] = size(X);
S = zeros(r,c);

for i = 1:r
    for j = 1:c
        a = unique([i-w,(i-fix(w)):(i+fix(w)),i+w]);
        b = unique([j-w,(j-fix(w)):(j+fix(w)),j+w]);
        a(find(a < 1)) = [];
        b(find(b < 1)) = [];
        a(find(a > r)) = [];
        b(find(b > c)) = [];
        d = a - fix(a);
        e = b - fix(b);
        d(find(d == 0)) = 1;
        e(find(e == 0)) = 1;
        weights = d'*e;
        a = ceil(a);
        b = ceil(b);
        S(i,j) = nansum(nansum(weights.*X(a,b)))/nansum(nansum(weights(find(~isnan(X(a,b))))));
    end
end