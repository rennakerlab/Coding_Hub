function lightwriter

%Have an integer array of lights

for i = 1:2:9766;
    light(i)=1;
end

light
fid = fopen('Solid12.L64', 'wb');
fwrite(fid, light, 'double');
fclose(fid);