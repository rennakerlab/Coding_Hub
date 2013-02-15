function ltimes=gettimes(r, slow)
if slow==1, pause(.05), end
ntimes=invoke(r, 'GetTagVal','lpress');

if ntimes > 0
   if slow==1, pause(.05), end
   %ltimes=invoke(r, 'ReadTagVEX','ltimes', 0, ntimes,'I32','I32',1);    
   ltimes=invoke(r, 'ReadTagV','ltimes', 1, ntimes);    

   if ltimes == -1, disp('Error reading: Buffer'), sound(sin(1:1000)), end
elseif ntimes == -1
   disp('Error reading: Buffer index'), sound(sin(1:1000))
   ltimes=[];
else 
   ltimes=[];
end
ltimes=double(ltimes);
