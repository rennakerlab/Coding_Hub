function setKeyPressFcns(h,fcn)

set(h,'KeyPressFcn',fcn);                                                   %Set the KeyPress function for the main figure.
c = get(h,'children');                                                      %Grab all of the children of the main figure.
i = 0;                                                                      %Create a counter to step through the uicontrols.
while i < length(c)                                                         %Loop until we've set the KeyPress function for all children.
    i = i + 1;                                                              %Increment the counter.
    if strcmpi(get(c(i),'type'),'uicontrol')                                %If the child is a uicontrol...
        set(c(i),'KeyPressFcn',fcn);                                        %Set the KeyPress function for all uicontrols.
    else                                                                    %Otherwise, if the child isn't a uicontrol...
        c = [c; get(c(i),'children')];                                      %Add the children of this object to the list to check.
    end
end