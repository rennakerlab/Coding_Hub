function F32Writer(data)

for i=1:length(data)
    filename = ['celldata_' int2str(i) '.f32'];
    fpnt = fopen(filename, 'wb');
    current_data_stream = data{i};
    fwrite(fpnt,current_data_stream,'float32');
    fclose(fpnt);
end