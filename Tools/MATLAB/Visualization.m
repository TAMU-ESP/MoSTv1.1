%% MotionSynthesis Visualization*
%-- Description: display template data with correlation between
%-- text data files and avi video files, enable annotation function and
%-- play function to assist researcher or user to observe body movement.
%-- Designed by Xianan Wang, 2/20/2014, for motionsynthesis
%%
% <http://www.motionsynthesis.org>

function Visualization(~)
    close all;
    clear all;
    vs = initial();
    process(vs);
end

function vs = initial()
    vs.datadir='.';
    vs.first_frame = 11;
    vs.frames_per_second = 15; %-- Video 15 Frame Per Second
    vs.data_per_second = 200;
    vs.vid_playing=false;
    vs.files=[];
    vs.andir_list={};
    vs.andir_sel=2;
    vs.andir_h=[];
    vs.anmodified = false; %-- modified or not: yes:true; not;false
    vs.an_default = 'default';
    vs.filter_size=10;
    vs.sens_h={};
    vs.sel_sensors=(1:6);
    vs.vid_h = {};
    vs.tools_h={};
    vs.scroll_h=[]; %-- Horizontal Scrollbar object
    vs.marker_h={}; %-- Marker object
    vs.marker_pos=1; %-- Marker position
    vs.an_rect_h=[];
    vs.an_h={};
    vs.tb_height = 0;
    vs.ncams=1;
    vs.sel_file=1; %-- Select file through pop-up menu
    vs.sel_file_h=[];
    vs.data_len = 0;
    vs.motes=[];
    vs.sel_motes = [];
    vs.title='motionsynthesis_visualization';
    vs.margins=5; % margin size in pixels
    vs.framelist = [];
    vs.axis_pref = 1; % 1 is 'full', 2 is 'tight', 3 is 'adaptive'
    vs.jump_small=10;
    vs.jump_big=100;
    vs.bounds=[0 1]; % the zoom bounds
    vs.ylim=[]; %[sensors]x[2]
    vs.first_click=[];
    vs.clicked=false;
    vs.sel_show=false; % show selection rectangle
    vs.sel_h={}; % the selection rectangles
    vs.sel_color=[0.75 0.75 0.75];
    vs.annotations=[];
    vs.annote_colors=[1 0 0;0 1 0;0 0 1;0 0 0;1 1 0;0 1 1;1 0 1;.5 .5 .5;1 .5 .5;.5 1 .5;.5 .5 1];
    vs.annote_max = size(vs.annote_colors,1);
    vs.maxBtn_h = [];
    vs.cur_annote=1;
    vs.delete_mode = false;
    vs.saveBtn_h=[];
    vs.switchbound = 1;
    vs.sensors={
        1, 'Acc X', -2^15, 2^15;
        2, 'Acc Y', -2^15, 2^15;
        3, 'Acc Z', -2^15, 2^15;
        4, 'Gyro X', -2^15, 2^15;
        5, 'Gyro Y', -2^15, 2^15;
        6, 'Gyro Z', -2^15, 2^15;
        7, 'Magnetometer X', -2^15, 2^15;
        8, 'Magnetometer Y', -2^15, 2^15;
        9, 'Magnetometer Z', -2^15, 2^15};
end

% main processing and display part
function process(vs)
    vs = fileStructure(vs); % Get the files in the current directory
    fileDisplay(vs);
end

% create GUI
function fileDisplay(vs)
    %-- Create and populate the figure ---    
    fh = createFig(vs);
    vs = get(fh,'UserData');

    %-- vs.sel_file = fnum;
    set(vs.sel_file_h, 'Value', vs.sel_file);

    %--- Reset the things that need to be reset ---
    vs.andir_list={};
    vs.andir_sel=2;
    vs.anmodified = false;
    vs.bounds=[0 1]; % the zoom bounds
    vs.annotations=[];
    vs.cur_annote=1;
    vs.delete_mode = false;
    vs.marker_pos = 1; % reset marker position

    %-- Save changes
    set(fh, 'UserData', vs);
    
    %-- Read annotationlist and display annotation onto GUI
    loadAnnotationList();
    
    %-- Setting Marker Position
    setMarkerPos(vs.marker_pos);
    %-- Transfer fh to vs
end

%-- build up data structure
function vs = fileStructure(vs)
        
    %-- define path
    package = ['..',filesep,'..' filesep 'UserSpace'];
    [subject,header,list,motionfile,dpath] = inputPlug(package);
    ndir = dpath;
    vdir = ['..' filesep '..' filesep 'data' filesep 'Videos'];
    adir = dpath;
    vs.ndir = ndir;
    vs.vdir = vdir;
    vs.adir = dpath;
    vs.subject = subject;
    vs.motionfile = motionfile{1};

    %-- acquire file list
    nfiles = dir(ndir);
    nfiles=nfiles(~[nfiles.isdir]);
    nfiles={nfiles.name};
    motionfileformat = strcat(motionfile{:},'_n([0-9]+)\.txt$');
    nf=regexp(nfiles, motionfileformat{:}, 'tokens');
    
    motes = zeros(0,1);
    for i = 1:numel(nf)
        if(~isempty(nf{i}))
            motes = cat(1,motes,str2double(nf{i}{:}{:}));
        end
    end
    
    %-- find out available mote list
    motes = unique(motes);
    vs.motes = motes;
    vs.sel_motes = 1:numel(motes);

    % Go through and create file list
    %-- build up file structure and Pop-out menu selections
    files = [];
    %-- files introduction:
    %-- name: name tag shows on the pop_out menu
    %-- f: data txt file name
    %-- vf: video avi file name
    %-- af: annotation txt file name
    files.name = subject{:};
    files.f=cell(numel(motes),1);
    files.vf=cell(1,1);
    files.af=[];
    
    miss_txt = cell(0,1); %-- storge missing items,
    miss_avi = cell(0,1);
    
    for i = 1:numel(motes);
        fname = sprintf('%s_n%02i.txt',motionfile{1}{:},motes(i,1));
        check = [ndir fname];
        files.f{i} = fname;
        if(~exist(check,'file'))
            miss_txt = cat(1,miss_txt,fname);
        end
        files.f{i} = fname;
    end

    temp = cell(numel(list{2},1));
    for i = 1:numel(list{1})
        vfname = sprintf('%s_c01.avi',list{1}{i});
        check = [vdir filesep vfname];
        if(~exist(check,'file'))
            miss_avi = cat(1,miss_avi,vfname);
        end
        temp{i} = vfname;
    end
    miss_avi = unique(miss_avi);

    refer = unique(temp);
    files.refer = refer;
    for i = 1:numel(temp)
        files.vf{i} = find(strcmp(temp{i},refer));
    end

    %-- create annotation file list, currently only one permitted
    afname = [motionfile{:}{:} '_annotation.txt'];
    files.af=afname;
    
    if(~isempty(miss_txt)||(~isempty(miss_avi))||~exist([adir afname],'file'))
        fileID = fopen([ndir 'missfiles.txt'],'wt+');
        fprintf(fileID,'Please import following items:\r\n');
        for i = 1:numel(miss_txt)
            fprintf(fileID,'%s;\r\n',miss_txt{i});
        end
        for i = 1:numel(miss_avi)
            fprintf(fileID,'%s;\r\n',miss_avi{i});
        end
        if(~exist([adir afname],'file'))
            fprintf(fileID,'Annotation file is missing;\r\n');
        end
        title = 'Error Report';
        message = 'Input data is not complete. Please refer to selected folder for more information';
        uiwait(msgbox(message,title,'error'));
        error('Input data is not complete');
    end
    
    %-- upload shared data
    vs.files = files;
    vs.list = list;
    vs.sel_sensors = header';
end

function fh=createFig(vs)
    fh = findobj('Tag', 'VideoSegment');
    %--- position in screen ---
    if(isempty(fh))
        fh = figure;
        scrnSz = get(0, 'ScreenSize');
        figPos = scrnSz + [50 50 -100 -100];
        set(fh, 'Position', figPos);
    else
        % vs = get(fh, 'UserData');
        clf(fh);
        ch = get(0, 'Children');
        idx = find(ch==fh,1);
        ch = [ch(idx); ch(1:idx-1); ch(idx+1:end)];
        set(0,'Children', ch);
    end

    set(fh,'pointer','fullcrosshair');
    
    %-- create the graphs
    vs.sens_h=[];
    vs.an_h={};
    vs.databoundary_h = {};
    vs.sel_h={};
    for g_idx = 1:numel(vs.sel_sensors)
        h = axes('Parent', fh, 'Position', [0 0 1 1]);
        s = vs.sel_sensors(g_idx);
        title(h,sprintf(vs.sensors{s,2}, g_idx));
        vs.sens_h{g_idx} = h;	
    end

    %-- create the video
    vs.vid_h={};
    for idx = 1:numel(vs.files.vf)
        refer_no = vs.files.vf{idx};
        vpath = [vs.vdir filesep vs.files.refer{refer_no}];
        if(exist(vpath,'file') == 0)
            break; 
        end
    end
    vh = axes('Parent', fh, 'Position', [0 0 1 1]);
    vs.vid_h{1} = vh;
    
    %--- create the toolbar ---
    curH = 18;
    curX=0;
    curY=vs.margins;
    h={};

    %*** Directory Chooser ***
    curW = 50;
    h{1} = uicontrol(fh,'Style','pushbutton', 'String', 'Folder', 'Position', [curX curY curW curH], 'Callback', @dirBtn);
    curX = curX + curW+2;

    
    %*** File button ***
    curW=75;
    h{3} = uicontrol(fh,'Style','pushbutton', 'String','Sequence','Position', [curX curY curW curH], 'Callback', @dirSequenceBtn );
    vs.sel_file_h=h{3};
    curX = curX + curW+2;
    
    curW=250;
    h{2} = uicontrol(fh,'Style','text','String',vs.subject{:},'Position',[curX curY curW curH]);
    curX = curX + curW+1;

    %*** Mote selection button ***
    curW = 100;
    h{4} = uicontrol(fh,'Style','pushbutton', 'String', 'Sensors', 'Position', [curX curY curW curH], 'Callback', @sensorsBtn);
    curX = curX + curW+2;

    %*** Sensor selection button ***
    curW = 100;
    h{4} = uicontrol(fh,'Style','pushbutton', 'String', 'Modalities', 'Position', [curX curY curW curH], 'Callback', @modalitiesBtn);
    curX = curX + curW+2;

    %*** Axis pref ***
    curW=40;
    h{5} = uicontrol(fh,'Style','text','String','Axis','Position',[curX curY curW curH]);
    curX = curX + curW+1;
    curW=70;
    h{6} = uicontrol(fh,'Style','popupmenu', 'String', {'Full', 'Tight', 'Adaptive'}, 'Value', vs.axis_pref, 'Position', [curX curY curW curH], 'Callback', @axisBtn );
    curX = curX + curW+2;

    %*** Zoom out ****
    curW = 50;
    h{9} = uicontrol(fh,'Style','pushbutton', 'String', 'Zoom Out', 'Position', [curX curY curW curH], 'Callback', @zoomOutBtn);
    curX = curX + curW+2;

    %*** Current Annotation ***
    curW = curH;
    h{10} = axes('Parent', fh,'Units', 'Pixels', 'Position',[curX curY curW curH]);
    vs.an_rect_h = rectangle('Parent', h{10}, 'Position',[0 0 curW curH], 'FaceColor', vs.annote_colors(1,:));
    axis(h{10}, 'off');
    curX = curX + curW+2;

    %*** Max Annotation pref ***
    curW=65;
    h{11} = uicontrol(fh,'Style','text','String','Cycle after','Position',[curX curY curW curH]);
    curX = curX + curW+1;
    curW=40;
    h{12} = uicontrol(fh,'Style','popupmenu', 'String', num2cell(1:size(vs.annote_colors,1)), 'Value', vs.annote_max, 'Position', [curX curY curW curH], 'Callback', @maxBtn );
    vs.maxBtn_h = h{12};
    curX = curX + curW+2;

    %*** Save button ***
    curW = 50;
    h{13} = uicontrol(fh,'Style','pushbutton', 'String', 'Save', 'Position', [curX curY curW curH], 'Callback', @saveBtn);
    vs.saveBtn_h=h{13};
    curX = curX + curW+2;
    
    %*** Help ***
    curW=50;
    h{15} = uicontrol(fh,'Style','pushbutton', 'String', 'Help', 'Value', 1, 'Position', [curX curY curW curH], 'Callback', @helpFcn );
    %-- curX = curX + curW+2;

    vs.tb_height = curH;
    vs.tools_h = h;

    %--- Scrollbar ---
    curX=vs.margins;
    curY = curY + (curH) + vs.margins;
    vs.scroll_h = uicontrol(fh,'Style','slider','Position',[curX curY 300 curH], 'Callback', @scrollBar);
    vs.tb_height = vs.tb_height + curH + vs.margins;


    %--- save the variables ---
    set(fh, 'UserData', vs);
    
    %--- set name, and some callbacks ---
    set(fh, 'Name', vs.title, 'NumberTitle', 'off', 'ResizeFcn', @resizeFunc, 'Units', 'pixels', 'Tag', 'VideoSegment', 'keyPressFcn', @keyPressFcn);
    set(fh, 'WindowButtonDownFcn', @WindowButtonDownFcn, 'WindowButtonMotionFcn', @WindowButtonMotionFcn, 'WindowButtonUpFcn', @WindowButtonUpFcn);
    set(fh, 'CloseRequestFcn', @closeFunc);

    %--- Add the data ---
    drawData(fh); % set initial selection
    loadAnnotationList();

    resizeFunc(fh,[]);
    updateAnnoteLabel();
end


function resizeFunc(src, ~)
    fh = src;
    vs = get(fh, 'UserData');

    fPos = get(fh, 'Position');
    width=fPos(3);
    height=fPos(4);

    axBnds = vs.margins*[1 1 -2 -2] + [0 0 width height]; % bounds for the axis

    %--- Start by Resizing video ---
    vSz=[0 0];
    curY = height;
    %-- curX = width - vSz(1) - vs.margins;
    
    vf = vs.files.vf{1};
    vpath = [vs.vdir filesep vs.files.refer{vf}];
    mobj = VideoReader(vpath);
    if (not(isempty(mobj.NumberOfFrames)))
        m = read(mobj,1);
    else
        m = zeros(480,640,3);
    end
    h = vs.vid_h{1};

    lSz = size(m)/2;    % by Mahdi for VibMotion files
    lSz = lSz([2 1]); % set X Y appropriately

    curX = width - lSz(1) - vs.margins;
    curY = curY - lSz(2) - vs.margins;

    set(h, 'Units', 'pixels', 'Position', [curX curY lSz(1) lSz(2)]);

    vSz = max([vSz; lSz]);
    
    axBnds(3) = axBnds(3) - vs.margins - vSz(1);

    %--- Now, Move the toolbar ---
    axBnds(4) = axBnds(4) - vs.margins - vs.tb_height;
    axBnds(2) = axBnds(2) + vs.tb_height + vs.margins;


    %--- Then Resize the graphs ---
    curY=axBnds(2)+axBnds(4) + vs.margins;
    %-- curX=axBnds(1);
    curH = floor((axBnds(4)-(numel(vs.sens_h)+1)*vs.margins)/numel(vs.sens_h)); % calculate height of each axis
    for idx=1:numel(vs.sens_h)
        h = vs.sens_h{idx};
        curY = curY - vs.margins - curH;
        x=[axBnds(1) curY axBnds(3) curH];
        set(h, 'Units', 'pixels');
        xd=get(h,'TightInset');
        x = x + [xd(1:2) -xd(3:4)-xd(1:2)];
        %get(h,'Position')
        set(h,'Position', x);
    end
    axBnds = x;

    %--- Resize scrollbars ---
    h = vs.scroll_h;
    x = get(h,'Position');
    x = [axBnds(1) x(2) axBnds(3) x(4)];
    set(h, 'Position', x);

end

function closeFunc(src, ~)
    if(~saveCheck)
        delete(src);
    end
end

% called for the experiment selection menu
function dirSequenceBtn(~,~)
    vs = initial();
    process(vs);
end

function drawData(fh)

    vs = get(fh, 'UserData');
    colors='rgbcmyk';
    sens_base=1-1;

    %--- track marker position
    pos = getMarkerPos();

    %--- Clear each axis ---

    for idx=1:numel(vs.sens_h)
        cla(vs.sens_h{idx});
    end

    %--- Draw the selection rectangles ---
    
    for si=1:numel(vs.sens_h)
        vs.sel_h{si} = rectangle('Position', [0 0 1 1], 'EdgeColor', 'none', 'FaceColor', 'none','Parent',vs.sens_h{si});
    end

    %--- Gather all data ---
    data_len=-1;
    file = vs.files;
    files = file.f(vs.sel_motes);
    didx=1;
    
    adata=cell(numel(files),1);
    %-- Loop for every enabled motes
    timestamp_len = zeros(0,1);
    for idx=1:numel(files)
        f = files;
        adata{idx}=[];
        for i = 1:numel(f)
            npath = [vs.ndir filesep f{i}];
            if(exist(npath,'file') ~= 2) % if f is not a complete path, then continue
                continue;
            end
        end

        %---get the whole data and data databoundary between different files---
        %---eg. if total data includes two files, first file length is 1049, second file length is 1000, then
        %--- databoundary is [0 1049 2049]
        [data,databoundary,~]  = dataReader(vs.ndir,vs.files.f{idx},vs.adir,vs.files.af);
        
        if(size(data,1)<1)
            continue;
        end

        if(data_len==-1)
            data_len = size(data,1);
        else
            data_len = min(size(data,1), data_len);
        end

        if(vs.filter_size > 1) % filter the data
            data(:,1:9) = mov_avg(data(:,1:9), vs.filter_size);
        end
        
        timestamp_len = cat(1,timestamp_len,data(end,11) - data(1,11) + 1);
        adata{didx}=data;
        didx=didx+1;
    end
    timestamp_len = max(timestamp_len);
    vs.timestamp_len = timestamp_len;
    vs.data_len = data_len;
    vs.databoundary = cat(1,0,databoundary);
    vs.adata = adata;
    
    %--- Acquire Video.numberOfFrames;
    numberOfFrames = cell(size(vs.list{1},1),1);
    FrameRate = cell(size(vs.list{1},1),1);
    mobj = cell(numel(vs.files.refer),1);
    for video_idx = 1:numel(vs.files.refer)
        vpath = [vs.vdir filesep vs.files.refer{video_idx}];
        mobj{video_idx} = VideoReader(vpath);
        numberOfFrames{video_idx} = mobj{video_idx}.numberOfFrames;
        FrameRate{video_idx} = mobj{video_idx}.FrameRate;
    end
    vs.numberOfFrames = numberOfFrames;
    vs.FrameRate = FrameRate;
    vs.mobj = mobj;
    vs.total = numel(vs.files.vf);

    %--- Draw all the data ---
    vs.ylim=zeros(numel(vs.sel_sensors),2);
    vs.ylim(:,1)=Inf;
    vs.ylim(:,2)=-Inf;
    for idx=1:numel(adata)
        mnum = vs.sel_motes(idx);

        data = adata{idx};
        if(size(data,1)==0)
            continue;
        end
        data=data(1:data_len,:);
        timestamp = data(end,11) - data(1,11) + 1;
        color = colors(mod(mnum-1,numel(colors))+1);
        for sens=1:numel(vs.sel_sensors)
            s = vs.sel_sensors(sens);
            h = vs.sens_h{sens};
            hold(h, 'on');
            
            plot(data(:,11), data(:,sens_base + s), color, 'Parent', h);
            vs.ylim(sens, 1) = min( [vs.ylim(sens, 1);data(:,sens_base + s)]);
            vs.ylim(sens, 2) = max( [vs.ylim(sens, 2);data(:,sens_base + s)]);        
            set(h, 'XLim', [1 timestamp]);
        end
    end
    
    color = [0.6 0.6 0.6];
    ylim_all = getylim();
    vs.databoundary_h{numel(vs.sens_h),numel(databoundary)} = [];
    for si = 1:numel(vs.sens_h)
        y = [ylim_all(si,1);ylim_all(si,2)];
        for i = 1:numel(databoundary)
        h = plot((1),(1), 'Parent', vs.sens_h{si});
        x = [adata{1}(databoundary(i),11);adata{1}(databoundary(i),11)];
        set(h,'XData',x,'YData',y,'Color', color, 'Marker', 'x', 'LineWidth', 1.5,'LineStyle',':');
        end
        vs.databoundary_h{si,i}=h;
    end

    %--- Load the video ---
    h = vs.vid_h{1};
    mobj = vs.mobj{1};
    vs.video_number = 1;
    if (not(isempty(mobj.NumberOfFrames)))
        m = read(mobj,1);
    else
        m = zeros(480,640,3);
    end
      image(m,'Parent', h); % set to the first frame
      axis(h,'off');


    %--- Draw video frame indicator ---
    mh = cell(numel(vs.sel_sensors), 2);
    for idx = 1:size(mh,1)
        s = vs.sel_sensors(idx);
        mh{idx,1} = plot(vs.marker_pos, vs.sensors{s,4}, 'rv', 'Parent', vs.sens_h{idx}, 'MarkerFaceColor', [1 0 0]);
        mh{idx,2} = plot(vs.marker_pos, vs.sensors{s,3}, 'r^', 'Parent', vs.sens_h{idx}, 'MarkerFaceColor', [1 0 0]);
    end
    vs.marker_h = mh;


    %--- Save data ---
    set(fh, 'UserData', vs);

    updateSlider();
    setAxesZoom();
    drawAnnotations()

    setAxis(); % set the y-axis
    pause(1/4);
    setPos(pos);
end

%-- function of mote button
function sensorsBtn(src, ~)
    fh = get(src, 'Parent');
    vs = get(fh, 'UserData');
    colr = {' Red', ' Green', ' Blue', ' Cyan', ' Purple', ' Yellow'};
    colrLoop = int8(1);
    
    listStr={};
	% Change menu to read 'Sensor' instead of 'mote'
    for mote=vs.motes'
        listStr = {listStr{:} sprintf('Sensor %i%s', mote, colr{colrLoop})};
        colrLoop = colrLoop + 1;
    end

    sel = listdlg('ListString', listStr, 'InitialValue', vs.sel_motes, 'PromptString', 'Select Motes');
    if(isempty(sel))
        return;
    end

    vs.sel_motes = sel;
    set(fh, 'UserData', vs);

    vs.marker_pos
    drawData(fh);
end
    
%-- function of save button
function saveBtn(src,~)
    fh = get(src, 'Parent');
    vs = get(fh, 'UserData');
    saveAnnotations();
    winopen(vs.adir);
end

function modalitiesBtn(src, ~)
    fh = get(src, 'Parent');
    vs = get(fh, 'UserData');

    listStr=vs.sensors(:,2);
    sel = listdlg('ListString', listStr, 'InitialValue', vs.sel_sensors, 'PromptString', 'Select Sensors');
    if(isempty(sel))
        return;
    end

    vs.sel_sensors = sel;
    set(fh, 'UserData', vs);

    createFig(vs);
end

function axisBtn(src, ~)
    fh = get(src, 'Parent');
    vs = get(fh, 'UserData');

    vs.axis_pref = get(src,'Value');
    if(~ismember(vs.axis_pref, (1:3)))
        vs.axis_pref = 1;
    end
    set(fh, 'UserData', vs);

    setAxis();
    drawAnnotations();
end

function maxBtn(src, ~)
    fh = getfh();
    vs = get(fh, 'UserData');

    vs.annote_max = get(src,'Value');
    set(fh, 'UserData', vs);

    setAnnoteLabel(getAnnoteLabel());
end

function zoomOutBtn(src, ~)
    fh = get(src, 'Parent');
    vs = get(fh, 'UserData');

    mid = (vs.bounds(1) + vs.bounds(2))/2;
    amt = (vs.bounds(2) - vs.bounds(1));

    bnds = [mid-amt*2 mid+amt*2];
    if(bnds(1) < 0)
        bnds(1) = 0;
    end
    if(bnds(2) > 1)
        bnds(2) = 1;
    end

    vs.bounds = bnds;
    set(fh, 'UserData', vs);
    updateSlider();
    setAxesZoom();
end

function dirBtn(~, ~)
    winopen(['..' filesep '..' filesep]);
end

%-- set txt file and frame video to position
function newPos = setPos(pos)
    pos = validatePos(pos);
    setMarkerPos(pos);
    setVideoPos(pos);
    newPos = getMarkerPos();
end

% advance marker in txt file and frame video in delta_pos
function newPos = advancePos(delta_pos)
    pos = getMarkerPos();
    newPos = setPos(pos+delta_pos);
end

%-- Acquire current Marker position in txt file
function pos = getMarkerPos()
    fh = getfh();
    vs = get(fh, 'UserData');
    pos = vs.marker_pos;
end

%-- guarantee position value is validate to locate within txt file range
function pos = validatePos(pos)
    fh = getfh();
    vs = get(fh, 'UserData');
    if(pos < 1)
        pos = 1;
    elseif(pos > vs.timestamp_len)
        pos = vs.timestamp_len;
    end
end

%-- define marker position by input value
function setMarkerPos(pos)
    fh = getfh();
    vs = get(fh, 'UserData');
    pos = validatePos(pos);    
    vs.marker_pos=pos;
    for idx = 1:size(vs.marker_h,1)
        h = vs.marker_h(idx,:);
        set(h{1}, 'XData', pos);
        set(h{2}, 'XData', pos);
    end
    set(fh,'UserData', vs);
end

%-- input txt file position, find frame, and then locate at that frame
function setVideoPos(pos)
    pos = validatePos(pos);
    [frame,video_num,~,~] = videoLocate(pos);
    setVideoFrame(frame,video_num); 
end

%-- input frame, camera name, locate video number and then locate at that
%-- frame
function setVideoFrame(frame, video_number)
    fh = getfh();
    vs = get(fh,'UserData');
    h = vs.vid_h{1};
    frame = round(frame);
    vf = vs.files.vf{video_number};
    mobj = vs.mobj{vf};
    if frame > mobj.numberOfFrames
        frame = mobj.numberOfFrames;
    end
    if (not(isempty(mobj.NumberOfFrames)))
        if (frame > mobj.numberOfFrames)
            frame = mobj.numberOfFrames;
        end
        m = read(mobj,frame);
    else
        m = zeros(480,640,3);
    end
    image(m,'Parent',h);
    axis(h,'off');
end

%-- function: input marker's position in txt file time stamp and return 
%--           frame number, video_num and video_length
%-- input: pos: position in time stamp;
%-- output: frame: frame in video;
%--         video_number: which video did the frame belongs to
%--         video_len: video length in number of frames
function [frame,video_num,video_len,video_tot] = videoLocate(pos)
    fh = getfh();
    vs = get(fh,'UserData');
    pos = timestamp2pos(pos);
    compare_array = pos > [vs.databoundary];
    video_num = find(compare_array == 0);
    video_num = video_num(1) - 1;
    frame_pos = pos - vs.databoundary(video_num);
    frame = (frame_pos/vs.data_per_second) * vs.frames_per_second;
    frame = round(frame);
    if(frame > vs.numberOfFrames{video_num})
        frame = vs.numberOfFrames{video_num};
    elseif frame == 0
        frame = 1;
    end
    video_len = vs.numberOfFrames{video_num};
    video_tot = vs.total;
end

%-- transform timestamp to position
function pos = timestamp2pos(timestamp)
    fh = getfh();
    vs = get(fh,'UserData');
    [~,pos] = min(abs(vs.adata{1}(:,11) - timestamp));
end

%-- the opposite
function timestamp = pos2timestamp(pos)
    fh = getfh();
    vs = get(fh,'UserData');
    timestamp = vs.adata{1}(pos,11);
end

%-- function:   advance in video for given frame steps
%-- input:      steps in video frame
%-- assumption: steps will not overtake one video length
function advanceFrame(frame_step)
    fh = getfh();
    vs = get(fh,'UserData');
    pos_step = 5*(frame_step / vs.frames_per_second) * vs.data_per_second;
    pos = getMarkerPos();
    %-- marker one frame move on position
    pos = pos + pos_step;
    setPos(pos);
end


function fh=getfh()
    fh = findobj('Tag', 'VideoSegment');
end


function avg=mov_avg(data, filter_size)
    filt = ones(filter_size,1);
    avg = conv2(data,filt, 'valid');
        
    half_filter = floor(filter_size/2);
    avg = [repmat(avg(1,:), half_filter,1); avg; repmat(avg(end,:), filter_size-half_filter-1,1)]/filter_size;
end

function setAxis()
    fh = getfh();
    vs = get(fh,'UserData');

    ylim_all = getylim();
    for idx=1:numel(vs.sens_h)
        h = vs.sens_h{idx};

        ylim = ylim_all(idx,:);

        set(h, 'YLim', ylim); % do this so markers can get set without disappearing
        my_eps = (ylim(2) - ylim(1))/1000;
        if(size(vs.marker_h,1) >= idx)
            set(vs.marker_h{idx,1}, 'YData', ylim(2)-my_eps);
            set(vs.marker_h{idx,2}, 'YData', ylim(1)+my_eps);
        end
    end

    drawAnnotations();

end

% disposal of key press event
function keyPressFcn(~,evt)
    fh = getfh();
    vs = get(fh, 'UserData');
    stop_play = false;
    switch(evt.Key)
        case 'rightarrow' % move a little to the right
            stop_play = true;
            if(strcmp(evt.Modifier,'shift'))
                advancePos(1); % if shift is pressed, move just one sample
            else
                advanceFrame(1); % otherwise move several
            end
        case 'leftarrow' % move a little to the left
            stop_play = true;
            if(strcmp(evt.Modifier,'shift'))
                advancePos(-1); % if shift is pressed, move just one sample
            else
                advanceFrame(-1); % otherwise move several
            end
        case 'uparrow' % play the video
            %advancePos(vs.jump_big);
            if(~vs.vid_playing)
                playVideo(1)
            else
                stop_play = true;
            end
        case 'downarrow' % play the video at 1/3 speed
            %advancePos(vs.jump_big);
            if(~vs.vid_playing)
                playVideo(1/3)
            else
                stop_play = true;
            end
        case 'space'
            addAnnotation();
        case 'd'
            vs = get(fh,'UserData');
            vs.delete_mode = ~vs.delete_mode;
            set(fh,'UserData',vs);
            updateAnnoteLabel();
        otherwise
            if(~isempty(evt.Character) && evt.Character <= '9' && evt.Character >= '1')
                label = evt.Character-'0';
                setAnnoteLabel(label);
            end
    end
    
    if(stop_play)
        vs = get(fh,'UserData');
        vs.vid_playing=false;
        set(fh,'UserData',vs);
    end

end

function WindowButtonDownFcn(~, ~)

    fh = getfh();
    vs = get(fh,'UserData');

    x=floor(getPointPos());
    first_click = x;
    sel_show = false;
    clicked=true;
    
    setPos(x);

    stype = get(fh,'SelectionType');

    if(strcmp(stype,'alt'))
        if(~vs.delete_mode)
            addAnnotation();
            clicked=false;
        else
            sel_show = true;
        end
    elseif(strcmp(stype, 'extend'))
        sel_show = true;
    end

    vs = get(fh,'UserData');
    vs.first_click = first_click;
    vs.clicked = clicked;
    vs.sel_show = sel_show;
    vs.vid_playing=false;
    set(fh,'UserData',vs);

    drawSelRect();

end

function WindowButtonMotionFcn(~, ~)
    fh = getfh();
    vs = get(fh, 'UserData');

    if(vs.clicked)
        drawSelRect();
        drawnow();
    end
end

function WindowButtonUpFcn(src, ~)
    fh = getfh();
    vs = get(fh, 'UserData');

    vs.clicked = false;
    vs.sel_show = false;
    set(fh, 'UserData', vs);

    sel = get(src,'SelectionType');
    if(strcmp(sel, 'extend'))
        x=floor(getPointPos());
        setZoom(vs.first_click, x);
    elseif(strcmp(sel,'alt'))
        if(vs.delete_mode)
            deleteAnnotations(vs.first_click, floor(getPointPos()));
            vs = get(fh,'UserData');
            vs.delete_mode = false;
            set(fh,'UserData',vs);
            updateAnnoteLabel();
        end
    end
    %drawSelRect();
end

function pos = getPointPos()
    fh = getfh();
    vs = get(fh, 'UserData');

    pos=get(vs.sens_h{1}, 'CurrentPoint');
    pos = pos(1);

end

% set zoom from sample 1 to vs.sample 2
function setZoom(s1, s2)
    fh = getfh();
    vs = get(fh, 'UserData');

    if(s1 < 1)
        s1=1; % first sample must be >= 1
    end
    if(s2 > vs.timestamp_len)
        s2 = vs.timestamp_len; % second must not be beyond data
    end
    if(s1 >= s2) % in this case, zoom out completely
        vs.bounds=[0 1];
    elseif(vs.timestamp_len < 2)
        vs.bounds = [0 1];
    else % ok, set the bounds for real
        vs.bounds=[s1-1 s2-1]/(vs.timestamp_len-1);
    end

    % save the data
    set(fh,'UserData',vs);

    % set the slider
    updateSlider();

    % Set Axes
    setAxesZoom();
end

function setAxesZoom()
    fh = getfh();
    vs = get(fh, 'UserData');
    sbnds = round(vs.bounds*(vs.timestamp_len - 1) + 1); % find the sample bounds
    for idx=1:numel(vs.sens_h)
        h = vs.sens_h{idx};
        set(h, 'XLim', sbnds);
    end
    setAxis();
end

function scrollBar(src, ~)
    fh = getfh();
    vs = get(fh, 'UserData');
    
    x = get(src, 'Value');
    if(x < 0)
        x = 0;
    elseif(x > 1)
        x=1;
    end

    % determine zoomPos;
    amt = vs.bounds(2) - vs.bounds(1);
    vs.bounds = [0 amt]+x*(1-amt);

    % save data
    set(fh, 'UserData', vs);

    %update slider
    setAxesZoom();
end

function updateSlider()
    fh = getfh();
    vs = get(fh, 'UserData');

    bjump_size = vs.bounds(2) - vs.bounds(1);
    sjump_size = 0.01;

    val = vs.bounds(1)/(1-bjump_size);

    set(vs.scroll_h, 'SliderStep', [sjump_size bjump_size], 'Value', val, 'Min', 0, 'Max', 1);
    if(bjump_size == 1)
        set(vs.scroll_h, 'Enable', 'off');
        set(vs.tools_h{9}, 'Enable', 'off'); % zoom button
    else
        set(vs.scroll_h, 'Enable', 'on');
        set(vs.tools_h{9}, 'Enable', 'on'); % zoom button
    end
end

%-- function:   get current marker pos Label
%-- output:     label
function label = getAnnoteLabel()
    fh = getfh();
    vs = get(fh, 'UserData');
    label = vs.cur_annote;
end

function color = getAnnoteColor()
    fh = getfh();
    vs = get(fh, 'UserData');

    label = vs.cur_annote;
    color = vs.annote_colors(label,:);
end

function setAnnoteLabel(label)
    fh = getfh();
    vs = get(fh, 'UserData');

    n = vs.annote_max;

    while(label < 0)
        label = label + n;
    end
    label = mod(label-1,n)+1;

    vs.cur_annote = label;

    set(fh,'UserData',vs);
    updateAnnoteLabel();
end

% update the square
function updateAnnoteLabel()
    fh = getfh();
    vs = get(fh, 'UserData');

    if(vs.delete_mode)
        color=[1 1 1];
    else
        color = getAnnoteColor();
    end
    set(vs.an_rect_h, 'FaceColor', color);

end

% adds annotation at the current position
function addAnnotation()
    fh = getfh();
    vs = get(fh, 'UserData');
    % don't allow annotation adding if in delete mode
    if(vs.delete_mode)
        return;
    end
    pos = getMarkerPos();
    label = getAnnoteLabel();

    vs.annotations=[vs.annotations; timestamp2pos(pos) label];

    vs.anmodified=true;
    set(fh,'UserData',vs);

    drawAnnotations();
    setAnnoteLabel(getAnnoteLabel()+1);
end

% deletes annotations between the two time periods
function deleteAnnotations(x1, x2)
    fh = getfh();
    vs = get(fh, 'UserData');

    % make sure x1 is the smaller one
    if(x1 > x2)
        t=x2;
        x2=x1;
        x1=t;
    end

    vs.anmodified=true;
    x1 = timestamp2pos(x1);
    x2 = timestamp2pos(x2);
    vs.annotations((vs.annotations(:,1) >= x1) & (vs.annotations(:,1) <= x2),:)=[];
    set(fh,'UserData',vs);
    drawAnnotations();
end

% function; based on vs.annotations to draw annotation marker on GUI
function drawAnnotations()
    fh = getfh();
    vs = get(fh, 'UserData');

    if(isempty(vs.annotations))
        vs.annotations = zeros(0,2);
    end

    % figure out the maximum annotation that needs to be supported
    amax = max(vs.annotations(:,2));
    smax = numel(vs.sens_h);
    if(size(vs.annotations,1)>0 && (size(vs.an_h,1)<smax || size(vs.an_h,2) < amax))
        vs.an_h{smax,amax}=[];
    end

    % actually draw the marker line
    for label = 1:size(vs.an_h,2)
        if(label > size(vs.annote_colors,1))
            break; % can't draw something without a color
        end
        color = vs.annote_colors(label,:);

        an = vs.annotations(vs.annotations(:,2)==label,:);
        if(~isempty(an))
            for i = 1:size(an,1)
                an(i) = pos2timestamp(an(i));
            end
        end

        % figure out x and y vectors
        x = zeros(3,size(an,1));
        y0=x;
        if(size(x,2)>0)
            x(1,:) = an(:,1);
            x(2,:) = an(:,1);
            x(3,:) = nan;
        end
        x = reshape(x,[],1);

        ylim_all = getylim();
        for si = 1:size(vs.an_h,1)
            sh = vs.sens_h{si};
            ylim = ylim_all(si,:);

            h = vs.an_h{si,label};
            if(isempty(h) || ~ishandle(h))
                h = plot((1),(1), 'Parent', sh);
            end

            y=y0;
            if(size(y,2) > 0)
                y(1,1:size(an)) = ylim(1);
                y(2,1:size(an)) = ylim(2);
                y(1,(size(an)+1):end) = (ylim(1)+ylim(2))/2;
                y(2,(size(an)+1):end) = nan;

                y(3,:) = nan;
            end
            y = reshape(y,[],1);

            set(h,'XData',x,'YData',y,'Color', color, 'Marker', 'x', 'LineWidth', 1.5);
            vs.an_h{si,label}=h;
        end
    end

    % save data
    set(fh,'UserData',vs);

    if(vs.anmodified)
        val = 'on';
    else
        val = 'off';
    end
    set(vs.saveBtn_h,'Enable', val);

end

function drawSelRect()
    fh=getfh();
    vs = get(fh,'UserData');

    %--- figure out the bounds ---
    bounds=[0 0 0 0];
    ylim = getylim();

    x1=getPointPos();
    x2 = vs.first_click;
    if(x2 < x1)
        t=x2;
        x2 = x1;
        x1=t;
    end
    bounds(1) = x1;
    bounds(3) = x2 - x1;

    if(vs.sel_show )
        faceColor = vs.sel_color;
    else
        faceColor = 'none';
    end
    if(bounds(3) <1)
        faceColor = 'none';
        bounds(3)=1;
        bounds(4)=1;
    end

    %--- Loop through sensors, setting the selection rectangles ---
    for si=1:numel(vs.sel_h)
        h = vs.sel_h{si};

        bounds(2) = ylim(si,1);
        bounds(4) = ylim(si,2)-ylim(si,1);

        set(h,'Position', bounds, 'FaceColor', faceColor);
    end


    vs.sel_show=false; % show selection rectangle
    vs.sel_h={}; % the selection rectangles
    vs.sel_color=[0.75 0.75 0.75];
end

%-- acquire limit databoundary on y axis according to axis_preference
function ylim = getylim()
    fh = getfh();
    vs = get(fh,'UserData');

    if(vs.axis_pref==1)
        ylim = cell2mat(vs.sensors(vs.sel_sensors,3:4));
    elseif(vs.axis_pref==2)
        ylim = vs.ylim;
    else
        ylim = vs.ylim;
        for idx=1:numel(vs.sens_h)            
            h = vs.sens_h{idx};
            xlim = get(h,'XLim');
            yl=[Inf -Inf];
            
            hc_all = get(h, 'Children');
            
            for hc_idx = 1:numel(hc_all)
                hc = hc_all(hc_idx);
                if(~strcmp('line', get(hc,'Type')) || ismember(hc, [cell2mat(vs.marker_h) cell2mat(vs.an_h)]))
                    continue;
                end
                
                xd = get(hc,'XData');
                yd = get(hc,'YData');
                
                yd = yd(xd <= xlim(2) & xd >= xlim(1));
                yl(1) = min([yd, yl(1)]);
                yl(2) = max([yd, yl(2)]);
            end
            if(yl(1) < yl(2))
                ylim(idx,:) = yl;
            end
        end
    end
end

% This function can be called either on loading a new file
% or even just periodically.
%
% The goal is to load the list of annotation sets. The annotation set
% 'default' must always exist and be second on the list. The first in the
% list is "new..." and can't be actively selected. See
% 'loadAnnotations()' 
function loadAnnotationList()
    fh = getfh();
    vs = get(fh,'UserData');

    must_load = false;

    %--- Make sure directories exist ---
    origin_dir = [vs.datadir filesep 'annotations'];

    %save old selection
    if(vs.andir_sel > 1 && vs.andir_sel <= numel(vs.andir_list))
        oldsel = vs.andir_list{vs.andir_sel};
    else
        oldsel = ''; % The old thing had to disappear
    end
    
    % create list of names
    new_annotation_folder = dir(origin_dir);
    new_annotation_folder = new_annotation_folder([new_annotation_folder.isdir]);
    new_annotation_folder = new_annotation_folder(~ismember({new_annotation_folder.name},{'.','..','default'}));
    vs.andir_list={'New...', vs.an_default, 'annotations',new_annotation_folder.name};

    %--- select the proper item ---
    sel = find(strcmp(oldsel, vs.andir_list),1, 'first');
    if(isempty(sel))
        vs.anmodified = false; % having to switch
        sel = 3; %-- select datapackage as default annotation source
        must_load = true;
    else
        vs.andir_sel = sel;
    end
    set(fh, 'UserData',vs);

    set(vs.andir_h, 'String', vs.andir_list, 'Value', vs.andir_sel);
    
    if(must_load)
        loadAnnotations(sel); % load the annotations
    end

end

function loadAnnotations(sel_num)
    cancel = saveCheck();
    fh=getfh();
    vs=get(fh,'UserData');

    if(cancel) % ok, switch the annotations back
        set(vs.andir_h, 'Value', vs.andir_sel);
    else % user didn't cancel, we should load the annotations

        if(sel_num==1) % the user wants to create a new annotation
            aname = inputdlg('Create a new annotation set','Create Annotation',1,{'untitled1'}); % ask for file name
            if(numel(aname) > 0)
                aname = aname{1};
            end
            isgood=regexp(aname,'^[A-Za-z]+[-A-Za-z0-9_]*$'); %is the file good?
            if(isempty(isgood) || ~isgood)
                aname = vs.an_default;
            else
                andir = [vs.datadir filesep 'annotations' filesep aname];
                if(exist(andir,'dir')==0)
                    mkdir(andir);
                end
                % vs.andir_list = {vs.andir_list{:},aname};
            end

            % now select it for loading
            vs=get(fh,'UserData');
            vs.andir_sel=2;
            vs.andir_list={'',aname};
            set(fh,'UserData',vs);
            loadAnnotationList();
            vs=get(fh,'UserData');
            loadAnnotations(vs.andir_sel);

            return;

        end
        if(sel_num < 2 || sel_num > numel(vs.andir_list))
            sel_num = 2;
        end
        vs.anmodified = false; % we're loading, so reset the modification stuff
        vs.andir_sel = sel_num;

        % find the filename
        aname = vs.andir_list{vs.andir_sel};
        if(sel_num == 3)
            andir = [vs.datadir filesep aname];
        else
            andir = [vs.datadir filesep 'annotations' filesep aname];
        end
        afname = [andir filesep vs.files.af];

        if(exist(afname,'file')==0)
            vs.annotations=zeros(0,2);
        else
            s = dir(afname);
            if s.bytes ~= 0
                vs.annotations=dlmread(afname,',');
            else
                vs.annotations = zeros(0,2);
            end
        end
%         if (~isempty(vs.annotations))
%             vs.annote_max = max(vs.annotations(:,2));
%         else
%             vs.annote_max = 12;
%         end
        set(vs.maxBtn_h,'Value',vs.annote_max);

        set(fh,'UserData',vs);
    end
    set(vs.andir_h, 'Value', vs.andir_sel);
    drawAnnotations();
end

function saveAnnotations()
    fh=getfh();
    vs=get(fh,'UserData');

    if(vs.anmodified==false)
        return; % nothing to do
    end
   
    % get the filename
    afname = [vs.adir filesep vs.motionfile{:} '_markers.txt'];

    % save the annotations
    an = sortrows(vs.annotations,1);
    an = an(an(:,1) >= 1 & an(:,1) <= vs.data_len,:);
    for i = 1:size(an,1)
        an(i,2) = i;
    end
    dlmwrite(afname,an,'newline','pc');

    vs.anmodified = false;
    set(fh,'UserData',vs);

    drawAnnotations();
end

%-- function:   save annotation button
% if cancel is true, the action that initiated this should be canceled,
% else it should proceed
function cancel = saveCheck()
    fh=getfh();
    vs = get(fh,'UserData');

    cancel = false;
    if(~vs.anmodified)
        return; % nothing to save
    end

    rep = true;
    while(rep)
        rep = false;
        res=questdlg('Do you wish to save annotations?','Save Annotations','Save','Revert','Cancel','Save');
        switch(res)
            case 'Save'
                saveAnnotations();
            case 'Revert'
                vs = get(fh,'UserData');
                vs.anmodified=false;
                set(fh,'UserData',vs);
            case 'Cancel'
                cancel = true;
            otherwise
                rep=true; % repeat again
        end
    end

end

function helpFcn(~, ~)
    winopen(['..' filesep '..' filesep 'Manual' filesep 'Visualization_tutorial.txt']);
end


function playVideo(rate_factor)
    fh = getfh();
    vs = get(fh,'UserData');
    vs.vid_playing = true;
    set(fh,'UserData',vs);
    rate = 15*rate_factor;
    td = [];
    td.rate = rate;
    period=round(1000/rate)/1000;
    t = timer('ExecutionMode','fixedRate', 'Period', period, 'UserData', td, 'TimerFcn', @playVideoFcn);
    start(t);
end

function playVideoFcn(src, ~)
    fh = getfh();
    vs = get(fh,'UserData');
    
    if(vs.vid_playing)
        old_pos = getMarkerPos();
        advanceFrame(1);
        drawnow();
        pos = getMarkerPos();
    end
    
    if(~vs.vid_playing || pos==old_pos)
        stop(src);
        delete(src);
    end

end

% Function: prepare total consecutive data for a series of data file
% data stands for consecutive data
% databoundary stands for the gap between different files
function [data,databoundary,len] = dataReader(nfolder,nfname,afolder,afname)
   npath = [nfolder filesep nfname];
   data = dlmread(npath,'\t');
   apath = [afolder filesep afname];
   fileID = fopen(apath);
   annotation = textscan(fileID,'%f,%f');
   databoundary = annotation{1};
   len = databoundary - cat(1,0,databoundary(1:end-1,1));
end

%-- predefined process module, get needed input content
%-- input: defined input package path
%-- output: video_list,file_header,mote_list
function [subject,header,list,motionfile,dpath] = inputPlug(input_path)

    %-- Locate sequence file
    while(1)
        [filename,dpath,~] = uigetfile('*sequence.txt','Please Select Sequence File',input_path);
        sequence_name = filename;
        if(~isempty(sequence_name))
            break;
        end
    end
    
    %-- read in sequence file
    diary_path = [dpath filesep sequence_name];
    fileID = fopen(diary_path);
    formatSpec = '%s %s';
    subject = textscan(fileID,'%s',1,'delimiter','\n');
    line = textscan(fileID,'%s',1,'delimiter','\n');
    line = line{:};
    header = zeros(0,1);
    if(~isempty(strfind(line{:},'Acc X')))
        header = cat(1,header,1);
    end
    if(~isempty(strfind(line{:},'Acc Y')))
        header = cat(1,header,2);
    end
    if(~isempty(strfind(line{:},'Acc Z')))
        header = cat(1,header,3);
    end
    if(~isempty(strfind(line{:},'Gyr X')))
        header = cat(1,header,4);
    end
    if(~isempty(strfind(line{:},'Gyr Y')))
        header = cat(1,header,5);
    end
    if(~isempty(strfind(line{:},'Gyr Z')))
        header = cat(1,header,6);
    end
    if(~isempty(strfind(line{:},'Magnetometer X')))
        header = cat(1,header,7);
    end
    if(~isempty(strfind(line{:},'Magnetometer Y')))
        header = cat(1,header,8);
    end
    if(~isempty(strfind(line{:},'Magnetometer Z')))
        header = cat(1,header,9);
    end
    motionfile = textscan(fileID,'%s',1,'delimiter','\n');
    list = textscan(fileID,formatSpec);
end





