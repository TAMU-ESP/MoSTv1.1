function [diary] = loop_proc(path)

% This function handles processing of a diary for Loop handling
% It brings up a text box to allow selection of the diary file
% to be processed.  All loops are unpacked into a single sequential file
% The diary name is output for the next conversion step

% Syntax for calling java methods in matlab is method(object, arg1, ...,argn)

[filename] = uigetfile(strcat(path,'*.txt'), 'Select diary text file');
% Get the filename without extension for the output (diary) 
[dir,diary,ext] = fileparts(filename);

import java.util.LinkedList
filename = strcat(path,filename);
fid = fopen(filename);
linkList1 = LinkedList();
stop=0;
linkList2=LinkedList();

open(filename);

%start processing
start =0;
while ~start %find starting point of your diary
    lineIn = fgets(fid);
    token = strtok(lineIn);
    start = strcmp(token, 'START');
end

%keep first line of synthesis
firstLine=lineIn;

while ~stop %until find STOP
    lineIn = fgets(fid);
    token = strtok(lineIn);
    if strcmp(sprintf('\r\n'), lineIn) %skip empty line
        continue;
    elseif strcmp(token, 'STOP!')  % if stop, break
        lastLine=lineIn;
        break;
    else
        addLast(linkList1,lineIn);
    end
end;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parse linked list to determine how many loops are in the file %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
loops=0;
for n=0:size(linkList1)-1
    temp=get(linkList1,n);
    if temp(1)=='['
        loops=loops+1;
    end;
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% While loops remain in the file, the following process %%%
%%% is performed on each set of enclosed loops            %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
countNested=0;
while (loops ~=0)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% Parse linked list, incrementing countNested when '[' found  %%%
    %%% and decrementing countNested when ']' found. Index of first %%%
    %%% bracket stored in startBracketIndex and the index of its     %%%
    %%% related closing bracket is stored in endBracketIndex        %%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    deepestNestedLoop = 0;
    for i=0:size(linkList1)-1
       lineFromList=get(linkList1,i);
       if lineFromList(1)=='['
           countNested=countNested+1;
           if countNested >= deepestNestedLoop
                deepestNestedLoopIndex = i;
                deepestNestedLoop = countNested;
           end
       elseif lineFromList(1)==']'
           if countNested == deepestNestedLoop
               deepestNestedLoopEndIndex = i;
           end
           countNested=countNested-1;
       end;
    end;
    
    %%% HCM trying to use deepest nested loop
    tmp = get(linkList1,deepestNestedLoopIndex);
    iter = tmp(2:end);
    
    %%% Add that which is before the loop to linkList2 %%%
    for m=0:deepestNestedLoopIndex-1
       addLast(linkList2,get(linkList1,m));
    end;
  
   %%% For each iteration of the loop, add the contents to linkList2 %%%
   for j=1:str2num(iter)
       for k=deepestNestedLoopIndex+1:deepestNestedLoopEndIndex-1;
           addLast(linkList2, get(linkList1,k));
       end;
   end;
   
   %%% Append everything outside of the loop
   for j=deepestNestedLoopEndIndex+1:size(linkList1)-1
       addLast(linkList2, linkList1.get(j));
   end;
   
   clear(linkList1);
   linkList1=clone(linkList2);
   clear(linkList2);
   loops=0;
   
    for n=0:size(linkList1)-1
        temp=get(linkList1,n);
        if temp(1)=='['
        loops=loops+1;
        end;
    end;   
end

fid1 = fopen('standard_synthesis.txt', 'w');
fprintf(fid1,'%s',firstLine);
while linkList1.size()>0
    fprintf(fid1,'%s',getFirst(linkList1));
    removeFirst(linkList1);
end;
fprintf(fid1,'%s',lastLine);
fclose(fid1);

disp('finished loop_proc - loops unrolled into standard_synthesis.txt')