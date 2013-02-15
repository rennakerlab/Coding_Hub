function textFileReader(file_name)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%This program reads the 'TEXT' file (Spike times saved as ASCII) and split
%it into three text files. 
% 'int.txt' has the Spike Values.
% 'float.txt' has the Spike Times.
% 'int.bin' is the binary format of the spike values. 
% Program written by Shazafar Khaja (Shahzafar@gmail.com) and
% Tom Slavens.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

int_file = 'int.txt';
float_file = 'float.txt';
bit_file = 'bit.txt';
int_binary_file = 'int.bin';

empty = [];

% Reading the file
in_file = file_name;
file = java.lang.String(in_file);
reader = java.io.BufferedReader(java.io.FileReader(in_file));
int_writer = java.io.BufferedWriter(java.io.FileWriter(int_file));
float_writer = java.io.BufferedWriter(java.io.FileWriter(float_file));
bit_writer = java.io.BufferedWriter(java.io.FileWriter(bit_file));
t = sprintf('\t');
space = java.lang.String(t);

%open the binary file for writing
fbin = fopen(int_binary_file, 'w', 'n');
int_holder = []; %the holder array of int values to write to the binary file
row = 0; %current matrix row
column = 1; %current matrix column

current_set = 1;
try
    reader = java.io.BufferedReader(java.io.FileReader(in_file));
    line = reader.readLine;
    while(line ~= empty)
        line_tokens = java.util.StringTokenizer(line);
        while(line_tokens.hasMoreTokens)
            token = line_tokens.nextToken;
            if(token.equalsIgnoreCase(java.lang.String('Set')))  %if this is a Set line
                token = line_tokens.nextToken; %read the next word in the line
                if(str2num(token) == current_set)   %if the sweep is in the current set
                    
                else %else if it isn't
                    current_set = str2num(token);                
                end
                while(line_tokens.hasMoreTokens) %and spend the rest of the tokens
                    token = line_tokens.nextToken;
                end
            elseif(~token.equalsIgnoreCase(java.lang.String(''))) %this is a number line
                %place the float in the float file
                float_writer.write(token);
                float_writer.newLine;
                token = line_tokens.nextToken;  %grab the next word in the line
                bit_writer.write(token); %write it to the bit file
                bit_writer.newLine;
                token = line_tokens.nextToken; %grab the next word
                row = row + 1;
                column = 1;
                int_holder(row, column) = str2num(token); %insert a new row
                
                % int txt writing
                int_writer.write(token);
                int_writer.write(space);
                
                %write all the rest of the ints in the line
                while(line_tokens.hasMoreTokens)
                    token = line_tokens.nextToken;
                    column = column + 1;
                    int_holder(row, column) = str2num(token);
                    int_writer.write(token);
                    int_writer.write(space);
                end
                %add a new line to the int file and flush the writer
                %buffers
                int_writer.newLine;
                float_writer.flush;
                bit_writer.flush;
                int_writer.flush;
            end
        end       
        line = reader.readLine;
    end
catch
    
end

% binary file operations
int_holder = transpose(int_holder); 
fwrite(fbin, int_holder, 'integer*4');
fclose(fbin);
save 'file_name' file_name;

% After splitting the 'TEXT' file, this part loads up the 'float.txt' file
% and inserts the markers making the 'float.txt' have the same format as
% the F32 file. The markers are -2 to start a new Set, -1 for each new
% Sweep. Between -2 and -1, the markers are inserted for Sweep Length,
% Number of Stimulus Parameters  and the actual stimulus parameters. This
% information is in the variable 'f32param' calculated when the F32 file is
% read. 
load f32param;
data=importdata(in_file,'r');% Reading the 'TEXT' file.
k=0;
counter=0;

m=double('Set 1');% Converting the string 'Set 1' to a double value.
for i=1:size(data,1)
      if  length(data{i})~=0 & double(data{i}(1:length(m)))==m   
       k=k+1;
        if(f32param~=0)
        ar(k:k+f32param-1)=-4; % inserting a pseudo marker -4 for spike times.
        end
        k=k+f32param;
        ar(k)=-2; % Inserting the marker -2
        if length(m)==5
        m=m+[0 0 0 0 1];
        else
            m=m+[0 0 0 0 0 1];
        end
        if counter==0 & m==[83 101 116  32 58]
            m=[ 83 101 116 32 49 48];
            counter=1;
        end
        if counter==1 & m==[83   101   116    32    49    58]
            m=[83   101   116    32    50    48];
            counter=2;
        end
        
      end
    
    if length(data{i})==0
        k=k+1;
        ar(k)=-1; % Inserting the marker -1
    elseif double(data{i}(1:3))==[83 101 116]
        
        else
            k=k+1;
            ar(k)=-3; % Inserting the pseudo marker -3 for F32 parameters.
        end
    end
   n=find(ar==-2);
   ar(n)=-1;
   ar(n-(f32param+1))=-2;
len=length(ar);
arfinal=ar'; % The final array with the markers inserted. -2-4-4..-1.....-3-3-3-3-3-3-3.........-2-4-4...-1
             % the -4's will be replaced by F32 parameters and the -3's
             % will be replaced by the actual spike times. 
Time_Stamps = importdata('float.txt');

w=0;
for i=1:length(arfinal)
    if arfinal(i)==-3
        w=w+1;
        timestamps_m(i)=Time_Stamps(w);%Replacing -3's with spike times.
    else timestamps_m(i)=arfinal(i);
    end
end
timestamps_marker=timestamps_m';% the final array with the markers and spike times.
save 'SpikeTimes_Marked.mat' timestamps_marker;


int_writer.close;
float_writer.close;
bit_writer.close; 
        