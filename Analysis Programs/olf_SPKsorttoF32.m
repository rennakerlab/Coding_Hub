files = dir('*.SPK');
for i = 1:length(files);
    SPKtoF32(files(i).name);
end