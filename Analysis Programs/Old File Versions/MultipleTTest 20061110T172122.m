[PValues]=MultipleTTest(Data,Spon,alpha)

[DNRow,DNCol]=size(Data);
[SNRow,SNCol]=size(Spon);

alphaprime=1-(1-alpha)^(1/DNCol);
alphaprime,

for i=1:DNCol
    [h,p,ci]=ttest(Data(:,i),Spon,alpha);
    p,
    if p<alphaprime
        if ci(1)<0&ci(2)<0
            p=-1*p;
        end
    end
    PValues(i)=p;
end

    













