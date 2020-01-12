cd ../..
path = pwd;
uspacedir = strcat(path,'\UserSpace\');
matlabdir = strcat(path,'\Tools\MATLAB\');
cd(matlabdir)
diary_name = loop_proc(uspacedir);
data_synth(diary_name,path);
