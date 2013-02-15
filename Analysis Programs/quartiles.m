function q = quartiles(data)

q = nan(2,size(data,2));
for c = 1:size(data,2)
    temp = sort(data(:,c));
    temp(~isnan(temp));
    N = length(temp);
    if N >= 4
        a = ceil(0.25*N);
        q(1) = temp(a);
        a = fix(0.75*N);
        q(2) = temp(a);
    end
end