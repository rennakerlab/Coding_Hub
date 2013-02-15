function s = int162char(i)

i = dec2bin(uint16(i),16);
byteA = i(1:8);
byteB = i(9:16);
byteA = bin2dec(byteA);
byteB = bin2dec(byteB);
s = char([byteA byteB]);