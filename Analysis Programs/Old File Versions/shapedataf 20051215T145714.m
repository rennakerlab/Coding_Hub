function [data, spikeshapes, spiketimes] = shapedataf(fname);
% reads binary spike data file "fname" generated with
% BrainWare 6.1 "File | Save As | Spike Times as Binary"
% (c) Jan Schnupp, Feb 1999
%

tempstring = fname;
f=fopen(fname, 'r');

numsets=0;
numsweeps=0;
totalsweeps=0;
totalspikes=0;
i=fread(f,1,'float32');
while ~isempty(i);

   switch i
   case (-2) % new dataset
	  numsets=numsets+1;         %
     numsweeps=0;
     % read sweeplength
	  data(numsets).sweeplength=fread(f,1,'float32');
     % read stimulus parameters
     numparams=fread(f,1,'float32');

     data(numsets).stim=fread(f,numparams,'float32');
       
   case (-1) % new sweep
      numsweeps=numsweeps+1;     %

      totalsweeps=totalsweeps+1;
      data(numsets).sweep(numsweeps).spikes=[];
      data(numsets).sweep(numsweeps).shapes=[];

   otherwise % read spike time for next spike in current sweep
       i = fread(f,1,'float32');
      data(numsets).sweep(numsweeps).spikes=...
			[data(numsets).sweep(numsweeps).spikes i];
      i = fread(f,27,'float32');
      data(numsets).sweep(numsweeps).shapes = [data(numsets).sweep(numsweeps).shapes i];
      totalspikes=totalspikes+1;
   end;
   
   i=fread(f,1,'float32');

end;
fclose(f);

temp = [data.stim];
numstim = length(temp(1,:));
temp = [data.sweep];
numsweeps = length(temp)/numstim;

spiketimes = [];            %Puts all spiketimes into a 1 X (Number of Spikes) matrix
spikeshapes = [];

for i = 1:numstim;
   for j = 1:numsweeps;
       spiketimes = [spiketimes data(i).sweep(j).spikes];
       spikeshapes = [spikeshapes data(i).sweep(j).shapes];
   end;
end;

disp(sprintf('read %d sets, %d sweeps, %d spikes',...
   numsets,totalsweeps, totalspikes))

%tempstring = tempstring(1:(length(tempstring)-4));
%tempstring = [tempstring '_Data'];
save 'NEL_Data' data;
%tempstring = tempstring(1:(length(tempstring)-5));
%tempstring = [tempstring '_Param'];
NELparam=numparams+2;
save 'NEL_Param' NELparam;


