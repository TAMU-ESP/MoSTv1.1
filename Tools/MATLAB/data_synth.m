function data_synth(diary_name,path)

% Data_Synth:  This code does the primary processing for taking the diary
% data and generating output sensor data files.  The input is the name used
% for the diary file.  Several Output Files are generated based on the
% input.  A data file "diary_#" is generated for each node requested.  Data
% is also copied to the split and video folders for use by the 
% Visualization tool

% Set up directories for navigation.  This allows changes to directory
% structure without having to touch every part of the MATLAB file
tempdir = strcat(path,'\Tools\MATLAB\temp\');
outdir = strcat(path,'\UserSpace\',diary_name,'\');
datadir = strcat(path,'\Data\');
matlabdir = strcat(path,'\Tools\MATLAB\');
mkdir(outdir);

%Go through standard_synthesis.txt (a copy of the generated diary with unrolled loops) 
%until reach 'STOP!' and store node/modality data in stopdata.
diary_file = fopen('standard_synthesis.txt'); %open loop free diary
if diary_file == -1
  error('Cannot open file: standard_synthesis.txt');
end
totalNumMovements = -2;

while 1
    stopdata=fgets(diary_file);
    token=strtok(stopdata);
    totalNumMovements = totalNumMovements+1;
    if strcmp(token,'STOP!')
        break;
    end
end;
fclose(diary_file);

% Use strcmp on stopdata to determine which sensors are used after 
% splitting off the sensor node data from the rest.
template={'Right Ankle', 'Waist', 'Right Arm', 'Right Wrist', 'Left Thigh', 'Right Thigh'};
[prev,nodes,post]=strread(stopdata, '%s %s %s', 'delimiter', '{}');
c = strsplit(char(nodes),', ');
nodes_used = find(strcmp(template,c(1)));
for i=2:numel(c)-1
    nodes_used = [nodes_used;find(strcmp(template,c(i)))];
end

% Open Diary for Processing and look for 'START' (deals with potential
% empty lines or unwanted data in generated file)
file = fopen('standard_synthesis.txt');
if file == -1
  error('Cannot open file: standard_synthesis.txt');
end
start = 0;
while ~start 
    tline = fgets(file);
    token = strtok(tline);
    start = strcmp(token, 'START');
end

% Parse the Start Header for protaganist and other data
[start subject date] = strread(tline, '%s %s %s', 'delimiter', ',');

subj = char(subject);  %cell to string conversion

currentWrite = 1;

%Determine the movement to find the appropriate file
%CHANGE TO IMPORT DATA FROM FILE INSTEAD
tline = fgets(file);
token = strtok(tline);
cd('../');
mvmt = {'1', '2', 'Kneeling', 'Step_forward_backward', 'Walking', 'Looking_back_right',...
        'Grasping_floor', 'Turning_90', 'Grasping_shelf', 'Jumping', 'Step_left_right',...
        'Eating', 'Drinking', 'Using_phone', 'Sitting(1)', 'Sitting(2)', 'Standing(1)',...
        'Standing(2)', 'Sit_to_stand', 'Stand_to_sit', 'Sit_to_lie', 'Lie_to_sit',...
        'Basic_sitting','Basic_standing', 'Basic_lying'};
cd('MATLAB');
anntNum = 1;
anntCnt = 0;


% Open empty files for the sequence file and the annotation file
annotation = fopen(strcat(tempdir,'annotation.txt'), 'w');
%fclose(annotation);
sequence = fopen(strcat(tempdir,'sequence.txt'), 'w');
% Input basic data into the sequence file.
fprintf(sequence, '%s%s%s\r\n', char(subject),'  ', char(date));
fprintf(sequence, '%s\r\n', char(post));
fprintf(sequence,'%s\r\n',diary_name);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parse the generated file for movements.  End when the %%%
%%% STOP keyword is reached                               %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp('Building data files') % Output something to console
while 1 
    if strcmp(sprintf('\r\n'), tline) %skip empty line
        tline = fgets(file);
        token = strtok(tline);
        continue;   
    elseif strcmp(token, 'STOP!')  % if stop, break
        token;
        break;
    end
    
    % Parsing Options for Each movement
    duration='';
    [myMvmt remain] = strread(tline, '%s %s', 'delimiter', '/');
    [first_seg last_seg]=strtok(char(remain),', ');
    RBE=first_seg;
    
    if(~isempty(last_seg))
        last_seg=strtok(last_seg,', ');
        duration=strtok(last_seg,'D-');     
    end
   
    % Determine protagonist to access based on RBE
        male=[1 5];
        rMal=randi([1,2]);
        female=[2 4];
        rFel=randi([1,2]);
        switch subj   %find subject
            case 'M1 '
                subNum = num2str(1,'%02d');
            case 'Male '
                subNum = num2str(male(rMal),'%02d');
                if strcmp(RBE, 'B')
                    subNum = '01';
                end
            case 'M2 '
                subNum = num2str(5,'%02d');
            case 'F1 '
                subNum = num2str(4,'%02d');
            case 'F2 '
                subNum = num2str(2,'%02d');
            case 'Female '
                subNum = num2str(female(rFel),'%02d');
                if strcmp(RBE, 'B')
                    subNum = '02';
                end
        end
    
    %store movement number
    array=strcmp(mvmt, token);
    mvmtNum = num2str(find(array==1),'%02d');
    
    % Sequence, video, repetition has not been written for current movement
    write_seq = 0;
    write_rep = 0;
    ran_sel = 0;
    for i = 1:numel(nodes_used)
        j = nodes_used(i);
        
        % Determine Information to find files
        % Node number subject name, ect.
        nodeNum = (num2str(j,'%02d'));

        subject = '';
        
        %find the directory of subject
        switch subNum
            case '01'
                subject = 'M1';
            case '05'
                subject = 'M2';
            case '04'
                subject = 'F1';
            case '02'
                subject = 'F2';
        end
        
        %find directory for specific movement
        if ran_sel == 0;
            if strcmp(RBE,'REx')
                listOfTextFile = dir('*.txt');
                numberOfTextFile = floor(numel(listOfTextFile)/6);
                ran=randi([1,numberOfTextFile]);
            else
                ran=1;
            end
            ran_sel = 1;
        end;
        
        expnum=num2str(ran,'%02d');
        
        % Build FileName for movement data
        fileName = char(sprintf('%s%s\\%s\\m00%s_s%s_m%s_n%s.txt', datadir, subject, token, expnum, subNum, mvmtNum, nodeNum));
        
        %Get number of rows in text file
        Nrows = numel(textread(fileName,'%1c%*[^\n]'));
        
        % Set the current node file as the temp file
        nodeFile = strcat(diary_name,'_n',num2str(j,'%02d'),'.txt');
        
        % Move to temp directory - Data files are stored in this directory
        cd(tempdir)
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%% Handle durational movements:                             %%%
        %%% Determine how many times to loop a file for duration and %%%
        %%% append to appropriate node file for each repetition.     %%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if write_rep == 0
            if (strcmp(duration, ''))
                repetition = 1;
            else
                repetition = round((str2double(duration)*200)/Nrows);
            end
            write_rep = 1;
            repetition = max(repetition,1);
        end
        for i=1:repetition
            %%% System call 'type' and redirect output to nodeFile %%%
            system(sprintf('type %s >> %s', fileName, nodeFile));
        end
        
        % Move back to the Utility Directory
        cd ..
        % Checks if current movement has been written to sequence file
        % If not, writes the movement and updates boolean
        if write_seq == 0
            seq_out = char(sprintf('m00%s_s%s_m%s',expnum, subNum, mvmtNum));
            %for i = 1:repetition
                fprintf(sequence, '%s\r\n', seq_out);
            %end
            write_seq = 1;
            
            %%% Update Annotation %%%
            anntCnt = anntCnt + Nrows*repetition;
            fprintf(annotation, '%d,%d\r\n', anntCnt,anntNum);
            anntNum = anntNum + 1;
            
        end
    end % End for loop that adds movements for each node
   
    % Get the next lines for processing
    tline = fgets(file);
    token = strtok(tline);
    
    disp(sprintf('Written %d out of %d movements', currentWrite, totalNumMovements));
    currentWrite = currentWrite+1;
end  %%% End of Main while loop.  Done with processing %%%
  
disp('Starting to update timestamps and packet numbers')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Update the timestamps and packet numbers for Nodes %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for i = 1:numel(nodes_used)
    k = nodes_used(i);
    nodeFileTmp = char(sprintf('%s%s_n%s.txt',tempdir,diary_name,num2str(k,'%02d')));
    Data = load(nodeFileTmp);
    nodeDataFinalFilePath = char(sprintf('%s%s_n%s.txt',outdir,diary_name,num2str(k,'%02d')));
    % Rewrite TimeStamps and Packet Numbers
    [n,m] = size(Data);
    SubstF= (1:5:(n*5));
    SubstT= (1:1:n);
    Data(:,11)=SubstF;
    Data(:,10)=SubstT;
    Data(:,12)=SubstT;

    nodeDataFinal = fopen(nodeDataFinalFilePath, 'W');
    
    disp(sprintf('Writing data file for node %d', k));
    % Write output to data file with updated timestamps
    for line=1:n
        fprintf(nodeDataFinal,'%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\r\n',...
            Data(line,:));
    end
    
    fclose(nodeDataFinal);
end % End loop for timestamp updates %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        

%copy to data aqusition folder
copyfile(strcat(tempdir,'annotation.txt'), strcat(outdir,diary_name,'_annotation.txt'));
fclose(sequence);
fin_seqfile = strcat(outdir,diary_name,'_sequence.txt');
copyfile(strcat(tempdir,'sequence.txt'), fin_seqfile);

%Cleanup of any left over files
fclose('all');
% Delete all temp files so that there is less clutter on PC
cd(tempdir);
delete('*.txt');
cd(matlabdir);
msgbox('Data Synthesis Complete.','Attention');



