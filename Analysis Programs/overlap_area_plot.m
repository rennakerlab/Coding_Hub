function overlap_area_plot(x,y,baseline)

if nargin == 1
    x = repmat(1:length(y),1,size(y,2));
    baseline = min(y);
elseif nargin == 2
    if size(y,1) == 1
        baseline = y;
        y = x;
    end
end

for i = 1:size(x,2)
    if length(unique(x(:,i))) ~= size(x,1)
        error('Error in overlap_area_plot: all x-values must be distinct and non-repeated.');
    end
end
if size(x,2) == 1
    x = repmat(x,1,size(y,1));
end


all_x = unique(x(:));                   %Find all unique x values in all data.
r = length(all_x);
c = size(y,2);
new_y = nan(r,c);  	%Pre-allocate a matrix to hold interpolated data.
for i = 1:r
    for j = 1:c
        k = find(all_x(i) == x(:,j));
        if ~isempty(k)
            new_y(i,j) = y(k,j);
        end
    end
end
for j = 1:c
    a = find(isnan(new_y(:,j)))';
    for i = a
        x1 = find(~isnan(new_y(1:i,j)),1,'last');
        x2 = find(~isnan(new_y(i:r,j)),1,'first')+i-1;
        if ~isempty(x1) && ~isempty(x2)
            y1 = new_y(x1,j);
            y2 = new_y(x2,j);
            x1 = all_x(x1);
            x2 = all_x(x2);
            new_y(i,j) = (y2-y1)*(all_x(i)-x1)/(x2-x1)+y1;
        end
    end
end
for i = 1:c
    for j = (i+1):c
        for k = 1:r-1
            x1 = all_x([k,k+1]);
            y1 = new_y(k:k+1,[i,j]);
            if ~any(isnan(y1(:))) && sign(y1(1)-y1(3)) ~= sign(y1(2)-y1(4))
                all_x(end+1) = ((y1(1)-y1(3))*x1(2)+(y1(4)-y1(2))*x1(1))/(y1(1)-y1(2)-y1(3)+y1(4));
            end
        end
    end
end
if length(all_x) > r
   new_y(r+1:length(all_x),1:c) = NaN;
   [all_x,i] = sort(all_x);
   new_y = new_y(i,:);
   r = length(all_x);
end
for j = 1:c
    a = find(isnan(new_y(:,j)))';
    for i = a
        x1 = find(~isnan(new_y(1:i,j)),1,'last');
        x2 = find(~isnan(new_y(i:r,j)),1,'first')+i-1;
        if ~isempty(x1) && ~isempty(x2)
            y1 = new_y(x1,j);
            y2 = new_y(x2,j);
            x1 = all_x(x1);
            x2 = all_x(x2);
            new_y(i,j) = (y2-y1)*(all_x(i)-x1)/(x2-x1)+y1;
        end
    end
end
colors = lines(c);
hold on;
for i = 1:r-1
    temp = sum(new_y(i:i+1,:),1);
    [temp, a] = sort(temp,'descend');
    a(isnan(temp)) = [];
    for j = 1:length(a)
        c = sum(colors(a(1:j),:),1)/j;
        x1 = all_x(i + [0 0 1 1]);
        y1 = [baseline, new_y(i,a(j)), new_y(i+1,a(j)), baseline];
        fill(x1,y1,c,'edgecolor',c);
    end
end
plot(all_x,new_y,'linewidth',2);
hold off;