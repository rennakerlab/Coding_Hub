function [SmoothVector]=Data_Smooth(Vector,Window)

%---Calculates the number of sample above and below to be averaged in.
low=floor(Window/2);
high=ceil(Window/2);
if low+high==Window
else
    low=low+1;
end

[NRow,NCol]=size(Vector);
if (NRow>1)&(NCol>1)
    display('Data_Smooth works on a singl row or column.');
else
    j=0;k=0;
    for i=1:length(Vector)
        if i<=low
            WinLow=i-j;
            SmoothVector(i)=mean(Vector(WinLow:Window-(j-i)));
            j=j+1;
        elseif (i+high)>=length(Vector)
             SmoothVector(i)=mean(Vector(i-low:i+high-k));
             k=k+1;
         else
             SmoothVector(i)=mean(Vector(i-low:i+high));
        end
    end
end

        
    