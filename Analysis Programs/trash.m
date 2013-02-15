[file path] = uigetfile('*.NEL');
cd(path);
file = file(4:end);
files = dir('*.NEL');   %['*' file]);
for i = 1:length(files)
    NELtoLFP(files(i).name,'Display','Off');
    NELtoSPK(files(i).name,'Interpolate','On','SavePlots','On');
end
files = dir('*.SPK');
for i = 1:length(files)
    NEL_Spike_Sorter(files(i).name,'Display','On');
    SPKtoF32(files(i).name);
end

