function h = pplot(data);

[a,b] = size(data);
for i = 1:a
    for j = 1:b
        if data(i,j) == 0;
            data(i,j) = 0;
        elseif data(i,j) > 0
            data(i,j) = -log10(data(i,j));
        else
            data(i,j) = log10(-data(i,j));
        end
        if data(i,j) > -1.3010 & data(i,j) < 1.3010
            data(i,j) = 0;
        end
    end
end
data = [data; zeros(1,b)];
surf(data,'EdgeColor','none');
view(0,90);
axis tight;
caxis([-5,5]);
temp = colormap;
if length(temp) == 64
	for i = 27:38
        temp(i,:) = [0.5,0.5,0.5];
	end
	temp = [temp(1:32,:); repmat([0.5,0.5,0.5],6,1); temp(33:64,:)];
	colormap(temp);
end
a = colorbar;
temp = [-5,-4,-3,-2,-1.3010,0,1.3010,2,3,4,5];
set(a,'YTick',temp);
temp = {' p < 0.00001',' p < 0.0001',' p < 0.001',' p < 0.01',' p < 0.05',' Not Significant',' p < 0.05',' p < 0.01',' p < 0.001',' p < 0.0001', ' p < 0.00001'};
set(a,'YTickLabel',temp);
    