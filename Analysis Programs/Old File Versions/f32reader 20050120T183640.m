function F32Reader(filename)

f = fopen(filename,'r');
i=fread(f,inf,'float32');
fclose(f)
q=i
