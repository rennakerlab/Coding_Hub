function behav_anal(rat)

for i = 1:length(run);
    temp = run(i).data(:,8);
    run(i).numfeed = sum(temp(~isnan(temp)));
    for j = 1:length(run(i).data);
        if ~isnan(run(i).data(j,10)) | ~isnan(run(i).data(j,11));
            temp = run(i).data(j,10:11);
            run(i).data(j,10)=temp(~isnan(temp));
        end
    end
    run(i).data = run(i).data(:,1:10);
    temp = run(i).data(:,10);
    run(i).current = temp(~isnan(temp));
    temp = run(i).data(:,9);
    run(i).outcome = temp(~isnan(temp));
    temp = [0:10:90]';
    temp = [temp, zeros(10,2)];
    for j = 1:length(run(i).current);
        temp(run(i).current(j)/10+1,2)=temp(run(i).current(j)/10+1,2)+run(i).outcome(j);
        temp(run(i).current(j)/10+1,3)=temp(run(i).current(j)/10+1,3)+1;
    end
    run(i).bin = temp;
    b = glmfit(temp(:,1), temp(:,2:3), 'binomial');
    run(i).glm = b;
    x = [0:0.1:90]';
    y = glmval(b,x,'logit');
    run(i).xy = [x, y];
    plot(temp(:,1),temp(:,2)./temp(:,3),'m*',x,y,'m-');
    for j = 1:length(y);
        if y(j)<=0.5;
            temp = x(j);
        end
    end
    run(i).fifty = temp;
end


%Effect of Pulse Duration
figure;
temp = run(2).bin+run(3).bin;
temp(:,1)=temp(:,1)/2;
b = glmfit(temp(:,1), temp(:,2:3), 'binomial');
x = [0:0.1:90]';
y = glmval(b,x,'logit');
plot(temp(:,1),temp(:,2)./temp(:,3),'r*',x,y,'r-');
hold;
for j = 1:length(y);
    if y(j)<=0.5;
        temp = x(j);
    end
end
line([temp temp],[0,0.5],'Color','r','LineStyle',':');

temp = run(10).bin;
b = glmfit(temp(:,1), temp(:,2:3), 'binomial');
x = [0:0.1:90]';
y = glmval(b,x,'logit');
plot(temp(:,1),temp(:,2)./temp(:,3),'b*',x,y,'b-');
for j = 1:length(y);
    if y(j)<=0.5;
        temp = x(j);
    end
end
line([temp temp],[0,0.5],'Color','b','LineStyle',':');

temp = run(4).bin;
b = glmfit(temp(:,1), temp(:,2:3), 'binomial');
x = [0:0.1:90]';
y = glmval(b,x,'logit');
plot(temp(:,1),temp(:,2)./temp(:,3),'g*',x,y,'g-');
for j = 1:length(y);
    if y(j)<=0.5;
        temp = x(j);
    end
end
line([temp temp],[0,0.5],'Color','g','LineStyle',':');

temp = run(6).bin;
b = glmfit(temp(:,1), temp(:,2:3), 'binomial');
x = [0:0.1:90]';
y = glmval(b,x,'logit');
plot(temp(:,1),temp(:,2)./temp(:,3),'m*',x,y,'m-')
for j = 1:length(y);
    if y(j)<=0.5;
        temp = x(j);
    end
end
line([temp temp],[0,0.5],'Color','m','LineStyle',':');

ylim([0,1.1]);
set(gca,'YTickLabel',[0:20:100]);
ylabel('Percent Correct');
xlabel('Current Amplitude (uA)');
title('Effect of Pulse Duration');
legend('','100 us','','','200 us','','','300 us','','','500 us','','Location','SouthEast');

%Effect of Anodic vs. Cathodic
figure;
temp = run(7).bin;
b = glmfit(temp(:,1), temp(:,2:3), 'binomial');
x = [0:0.1:90]';
y = glmval(b,x,'logit');
plot(temp(:,1),temp(:,2)./temp(:,3),'r*',x,y,'r-');
hold;
for j = 1:length(y);
    if y(j)<=0.5;
        temp = x(j);
    end
end
line([temp temp],[0,0.5],'Color','r','LineStyle',':');

temp = run(10).bin;
b = glmfit(temp(:,1), temp(:,2:3), 'binomial');
x = [0:0.1:90]';
y = glmval(b,x,'logit');
plot(temp(:,1),temp(:,2)./temp(:,3),'b*',x,y,'b-');
for j = 1:length(y);
    if y(j)<=0.5;
        temp = x(j);
    end
end
line([temp temp],[0,0.5],'Color','b','LineStyle',':');

ylim([0,1.1]);
set(gca,'YTickLabel',[0:20:100]);
ylabel('Percent Correct');
xlabel('Current Amplitude (uA)');
title('Effect of First Phase Direction');
legend('','Anodic','','','Cathodic','','Location','SouthEast');


%Effect of Train Burst Width
figure;
temp = run(8).bin;
b = glmfit(temp(:,1), temp(:,2:3), 'binomial');
x = [0:0.1:90]';
y = glmval(b,x,'logit');
plot(temp(:,1),temp(:,2)./temp(:,3),'r*',x,y,'r-');
hold;
for j = 1:length(y);
    if y(j)<=0.5;
        temp = x(j);
    end
end
line([temp temp],[0,0.5],'Color','r','LineStyle',':');

temp = run(5).bin;
b = glmfit(temp(:,1), temp(:,2:3), 'binomial');
x = [0:0.1:90]';
y = glmval(b,x,'logit');
plot(temp(:,1),temp(:,2)./temp(:,3),'b*',x,y,'b-');
for j = 1:length(y);
    if y(j)<=0.5;
        temp = x(j);
    end
end
line([temp temp],[0,0.5],'Color','b','LineStyle',':');

temp = run(10).bin;
b = glmfit(temp(:,1), temp(:,2:3), 'binomial');
x = [0:0.1:90]';
y = glmval(b,x,'logit');
plot(temp(:,1),temp(:,2)./temp(:,3),'m*',x,y,'m-');
for j = 1:length(y);
    if y(j)<=0.5;
        temp = x(j);
    end
end
line([temp temp],[0,0.5],'Color','m','LineStyle',':');

ylim([0,1.1]);
set(gca,'YTickLabel',[0:20:100]);
ylabel('Percent Correct');
xlabel('Current Amplitude (uA)');
title('Effect of Burst Width');
legend('','50 ms','','','150 ms','','','200 ms','','Location','SouthEast');

%Effect of IPP
figure;
temp = run(10).bin;
b = glmfit(temp(:,1), temp(:,2:3), 'binomial');
x = [0:0.1:90]';
y = glmval(b,x,'logit');
plot(temp(:,1),temp(:,2)./temp(:,3),'r*',x,y,'r-');
hold;
for j = 1:length(y);
    if y(j)<=0.5;
        temp = x(j);
    end
end
line([temp temp],[0,0.5],'Color','r','LineStyle',':');

temp = run(9).bin;
b = glmfit(temp(:,1), temp(:,2:3), 'binomial');
x = [0:0.1:90]';
y = glmval(b,x,'logit');
plot(temp(:,1),temp(:,2)./temp(:,3),'b*',x,y,'b-');
for j = 1:length(y);
    if y(j)<=0.5;
        temp = x(j);
    end
end
line([temp temp],[0,0.5],'Color','b','LineStyle',':');

ylim([0,1.1]);
set(gca,'YTickLabel',[0:20:100]);
ylabel('Percent Correct');
xlabel('Current Amplitude (uA)');
title('Effect of Interphase Period');
legend('','5 ms','','','10 ms','','Location','SouthEast');

