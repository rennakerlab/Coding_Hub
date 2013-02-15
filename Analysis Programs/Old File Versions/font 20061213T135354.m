% font: set font size 
% Usage: font(size);
function font(size);

h=findobj('type','axes');
for i=1:length(h),
 set(h(i),'FontSize',size);
 set(h(i),'FontSize',size);
 set(get(h(i),'Title'),'FontSize',size);
 set(get(h(i),'Xlabel'),'FontSize',size,'VerticalAlignment','bot');
 set(get(h(i),'Ylabel'),'FontSize',size,'VerticalAlignment','bot');
 set(get(h(i),'XLabel'),'VerticalAlignment','top')
end;

