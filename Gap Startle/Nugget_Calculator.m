str = ['Please enter the animal''', 's weight in grams: '];
currweight = input(str);
str = ['Please enter the animal''', 's current percent body mass (in integers): '];
percentweight = input(str);
pellets = input('Please enter the number of pellets the rat consumed today: ');

pelmass = 0.045;
nuggmass = 4.5;

baseweight = currweight/(.01*percentweight);
targetweight = baseweight*0.89;

gainamount = targetweight - currweight;

nugtogive = round(((gainamount) - (pellets*pelmass))/nuggmass);
nugtogivewgt = ((gainamount) - (pellets*pelmass));


str = ['Give the rat ', num2str(nugtogivewgt, '%.1f'), ' grams of nuggets.'];
disp(str);
str = ['Approximately ', num2str(nugtogive), ' nuggets.'];
disp(str);