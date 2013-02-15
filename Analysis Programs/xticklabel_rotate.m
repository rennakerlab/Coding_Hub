function h = xticklabel_rotate(rot)

if isempty(get(gca,'xticklabel'))                   
    warning('xticklabel_rotate : can not process, either xticklabel_rotate has already been run or XTickLabel field has been erased');
    return
end

xtick = get(gca,'xtick');                                                   %Grab the x-ticks.
xticklabels = get(gca,'xticklabel');                                        %Grab the x-tick labels.
set(gca,'xticklabel',[]);                                                   %Get rid of the existing x-tick labels.
drawnow;                                                                    %Update the plot before grabbing the y-axis limits.
y = ylim;                                                                   %Grab the y-axis limits.
y = y(1) - 0.01*range(y);                                                   %Set the y coordinate of the text labels.
h = text(xtick,repmat(y,size(xtick)),xticklabels);                          %Create the text objects for the x-tick labels.
set(h,'rotation',rot,...
    'horizontalalignment','right',...
    'verticalalignment','middle');                                          %Set the rotation and alignment of the x-tick labels.
for prop = {'fontsize','fontweight','fontangle','fontname'}                 %Step through the set text properties on the x-axis.
    set(h,prop{1},get(gca,prop{1}));                                        %Set the property on the x-tick labels.
end