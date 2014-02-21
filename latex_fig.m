function latex_fig(varargin)
% latex_fig    Export a figure with text objects rendered via LaTeX
%              ver 0.11
%
%    Examples:
%      latex_fig(gcf,'output.pdf')
%      latex_fig(...,'-crop',[left bottom width height])
%      latex_fig(...,'-latexpackages',{'\usepackage{amssymb}',...
%                      '\newcommand{\abs}[1]{\left\lvert#1\right\rvert}'})
%      latex_fig(...,'-png','-jgp','-pdf,'-eps','-r300','-q80')
%      latex_fig(...,'-nocrop')
%      latex_fig(...,'-transparent')
%      latex_fig(...,'-rasterize',[h1, h2, h3, ...])
%    
%    The latex_fig function was developed to overcome some of the
%    shortcomings in MATLAB's LaTeX interpreter and also to simplify the
%    creation of combined figures that hold both vector graphics.
% 
%    Inputs:
%    'filename'         The output file name. If the filename contains a 
%                       valid graphics extension, this output format will 
%                       be used (in addition to any other listed graphics
%                       extensions).
%    Options:
%    figure_num         
%                       A valid figure handle specifying which figure 
%                       should be exported. The default is to use the
%                       current figure (the output of "gcf");
%    '-latexpackages', {'\usepackage{amssymb}', ... }
%                       A cell array of strings listing commands to be
%                       included in the preamble of the LaTeX document.
%                       Typically this may be a list of "\usepackage{}"
%                       commands, but it may also include user-defined
%                       macros and other settings.
%    '-crop', [x,y,w,h]
%                       Bounding box position in relative coordinates. The
%                       default is [0,0,1,1]. The first two coordinates
%                       specify the left and bottom of the window and the
%                       second two coordinates specify the relative width
%                       and height. Negative numbers may be used for first
%                       two coordinates to expand the bounding box left and
%                       down and numbers greater than 1 for width and
%                       height will increase the output size.
%    '-format'          
%                       The output format. Multiple formats may be
%                       specified. Valid formats include '-png', '-jpg',
%                       '-pdf', '-tif', '-eps'.
%    '-q<val>'             
%                       The quality of jpeg ouputs with <val> being an
%                       integer from 1-100. The default is '-q90'. Values
%                       below '-q75' will typically be noticably degraded.
%    '-r<val>'            
%                       Resolution (in pixels per inch) for rasterized
%                       objects and output formats. The default is to use
%                       the native screen resolution.
%    '-a<val>'          The level of anti-aliasing to use for rasterized
%                       plot objects. <val> should be a positive integer.
%                       The default is '-a1', corresponding to no anti-
%                       aliasing. Choose '-a3' or '-a4' for a high level of
%                       anti aliasing.
%    '-nocrop'          
%                       Do not attempt to auto crop the figure.
%    '-transparent'     
%                       Use a transparent figure background. Axis and
%                       legend backgrounds must be turned off separately
%                       with commands like "set(gca,'color','none')".
%    '-rasterize', [h1,h2,...]
%                       Rasterize the list of plot objects. This is useful
%                       for saving PDF files that contained complex
%                       rasterized objects like surface and patch plots as
%                       well as vector graphics objects like lines and
%                       text.
%    '-renderer'        
%                       The renderer to be used for rasterized objects. The
%                       default is '-opengl'. Valid options include
%                       '-opengl', '-painters', and '-zbuffer'. Note that
%                       only '-opengl' supports partial transparency (alpha
%                       values). '-painters' is used for all vector
%                       graphics rendering, this cannot be changed.
% 
%    Dependencies:
%    - A system installation of LaTeX, including pdflatex and the packages
%        "psfrag", "graphicx", "calc", "overpic", and any other packages
%        you may wish to include.
%    - Conversion tools (depending on the desired output format) including
%        "dvipdf", "dvips", "pdf2ps", and ImageMagick's "convert". The
%        ImageMagick tools are only needed if you wish to ouput rasterized
%        final formats such as jpg, png, or eps.
%      
%      


    if (ispc)
        error('Sorry, Windows is not supported.');
    end

    %variables for temporary file names:
    TMP_DIR = '/tmp/';
    LATEX_FILE = sprintf('%stmp%08d',TMP_DIR,floor(1e8*rand));
    EPS_FILE = sprintf('%stmp%08d',TMP_DIR,floor(1e8*rand));

    %Parse inputs
    options = parse_inputs(varargin);
    
    %add to PATH environment variable if on a mac (locations for Latex and dvips tools)
    if (ismac)
        setenv('PATH', [getenv('PATH') ':/usr/texbin:/usr/local/bin']);
    end
    
    drawnow

    %replace all latex interpreter text objects with psfrag tags, render the
    %eps file, use psfrag to replace the tags, convert the dvi

    %handles for all text objects
    h=findall(options.handle,'type','text');
    %eliminate empty or white space text objects
    I=[];
    for i=1:numel(h)
        str = get(h(i),'string');
        if isempty(str) || (ischar(str) && ~isempty(regexpi(str(:)','^\s*$')))
            I=[I i];
        end
    end
    h(I)=[];

    %structure to hold original text and interpreter so they can be reset later
    original.interpreter=cell(numel(h),1);
    original.text = cell(numel(h),1);
    original.align = cell(numel(h),1);
    original.fontsize = cell(numel(h),1);

    %structure to hold new text and psfrag tags
    new.text = cell(numel(h),1);
    new.tag = cell(numel(h),1);

    for i=1:numel(h)
        %turn off interpreter so psfrag tags can be rendered as plain text
        original.interpreter{i} = get(h(i),'interpreter');
        set(h(i),'interpreter','none');

        %Get the alignment properties:
        va = get(h(i),'VerticalAlignment');
        ha = get(h(i),'HorizontalAlignment');
        original.align{i} = strcat(va(1),ha(1));

        %Font size
        original.fontsize{i} = get(h(i),'fontsize');

        %modify original text string to LaTeX format:
        original.text{i} = get(h(i),'string');

        %Deal with font sizes:
        str = prepend_font_size(original.fontsize{i},original.text{i});
        
        if iscell(str)
            if numel(str)==1
                str=str{1};
            else
                %use vbox and hbox for cells (multi-line text)
                strc = '\vbox{';
                for n = 1:length(str)
                    strc = [strc '\makebox[1\paperwidth][c]{' str{n} '}\\ '];
                end
                str = [strc(1:end-3) '}'];
            end
        end
        if size(str,1)>1
            strc = '\vbox{';
            for n = 1:size(str,1)
                strc = [strc '\makebox[1\paperwidth][c]{' str(n,:) '}\\ '];
            end
            str = [strc(1:end-3) '}'];
        end
        new.text{i}=str;

        %set the psfrag tag
        new.tag{i} = sprintf('psfrag%05d',i);
        set(h(i),'string',new.tag{i});
    end


    %generate latex file to process the psfrag tags
    FILE_CONTENTS = latex_file_gen(options.packages,new.tag,new.text,original.align,EPS_FILE);

    %write the latex file:
    FID = fopen([LATEX_FILE '.tex'],'w');
    fprintf(FID,'%s',FILE_CONTENTS);
    fclose(FID);

    %%%%%%%%%%%%%%%%%%%%%%%%%%
    %  Generate_image files  %
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %include the proper background/axis colors
    set(options.handle,'InvertHardCopy','off');
    
    %crop by resizing/positioning the figure if necessary:
    hCH = get(options.handle,'children'); %handles to to children of the figure
    for i=1:numel(hCH)
        posCH{i} = get(hCH(i),'position'); %current positions
    end
    posFIG = get(options.handle,'position');
    if ~all(options.crop == [0 0 1 1])
        %adjust figure size:
        set(options.handle,'position',posFIG.*[1 1 options.crop(3:4)]);

        %adjust object positions:
        for i=1:numel(hCH)
            set(hCH(i),'position',(posCH{i} - [options.crop(1:2) 0 0])./repmat(options.crop(3:4),1,2));
        end
    end
    for i=1:numel(hCH)
        posCHnew{i} = get(hCH(i),'position'); %new positions
    end

    %get current settings
    fig_opts.Units = get(options.handle,'Units');
    fig_opts.Position = get(options.handle,'Position');
    fig_opts.PaperUnits = get(options.handle,'PaperUnits');
    fig_opts.PaperPositionMode = get(options.handle,'PaperPositionMode');
    fig_opts.PaperSize = get(options.handle,'PaperSize');
    fig_opts.PaperPosition = get(options.handle,'PaperPosition');

    %fix size
    set(options.handle, ...
        'Units', 'centimeters', ...
        'PaperUnits', 'centimeters', ...
        'PaperPositionMode', 'manual');
    posFIGnew = get(options.handle,'Position');
    set(options.handle, ...
        'PaperSize', [posFIGnew(3) posFIGnew(4)], ...
        'PaperPosition', [0 0 posFIGnew(3) posFIGnew(4)] ...
        );
    
    %if the plot objects should be rasterized, generate a png without the
    %axes on:
    if options.rasterize
        %get handles to all visible objects
        hVIS = findall(options.handle,'visible','on');
        
        %handles to lights:
        hLIGHT=findall(options.handle,'type','light');
        
        %turn off all, then turn on just the objects to be rasterized
        set(hVIS,'visible','off');
        set(options.rasterHandles,'visible','on');
        set(hLIGHT,'visible','on'); %lights on
        set(options.handle,'visible','on');
        
        %adjust figure size:
        set(options.handle,'position',posFIGnew);
        %adjust object positions:
        for i=1:numel(hCH)
            set(hCH(i),'position',posCHnew{i});
        end
        
        %set parent axes to transparent:
        for i=1:numel(options.rasterHandles)
            PARENT_HANDLE(i) = get(options.rasterHandles(i),'parent');
            COLOR{i} = get(PARENT_HANDLE(i),'color');
            set(PARENT_HANDLE(i),'color','none');
        end
        
        %export the rasterized figure to png
        [img alph] = transparent_png( options.handle, ...
                                      options.aa, ...
                                      options.renderer, ...
                                      options.resolution, ...
                                      true );
        imwrite(img,[EPS_FILE '.png'],'Alpha',alph);

        %turn visible objects back on, raster objects off
        set(hVIS,'visible','on');
        set(options.rasterHandles,'visible','off');
        
        %adjust figure size:
        set(options.handle,'position',posFIGnew);
        %adjust object positions:
        for i=1:numel(hCH)
            set(hCH(i),'position',posCHnew{i});
        end
        
        %reset parent axes:
        for i=1:numel(options.rasterHandles)
            set(PARENT_HANDLE(i),'color',COLOR{i});
        end
        
    end

    %print to eps
    if options.nocrop
        print([EPS_FILE '.eps'],options.handle,'-loose','-painters','-depsc2',sprintf('-r%d',round(get(0,'screenpixelsperinch'))));
    else
        print([EPS_FILE '.eps'],options.handle,'-painters','-depsc2',sprintf('-r%d',round(get(0,'screenpixelsperinch'))));
    end
    
    if options.rasterize
        %turn raster objects back on
        set(options.rasterHandles,'visible','on');
    end
    
    %remove the background from the eps if necessary:
    if (options.transparent || options.rasterize) && ~strcmp(lower(get(options.handle,'color')),'none')
        eps_remove_background([EPS_FILE '.eps']);
    end

    %reset figure
    set(options.handle,'Units',fig_opts.Units);
    set(options.handle,'Position',fig_opts.Position);
    set(options.handle,'PaperUnits',fig_opts.PaperUnits);
    set(options.handle,'PaperPositionMode',fig_opts.PaperPositionMode);
    set(options.handle,'PaperSize',fig_opts.PaperSize);
    set(options.handle,'PaperPosition',fig_opts.PaperPosition);
    for i=1:numel(h)
        set(h(i),'string',original.text{i},'interpreter',original.interpreter{i});
    end

    %reset figure/axis positions:
    set(options.handle,'position',posFIG);
    for i=1:numel(hCH)
        set(hCH(i),'position',posCH{i});
    end

    %avoid a linux bug with ghostscript
    if (isunix)
        setenv('LD_LIBRARY_PATH','""');
    end
    
    %process through latex to produce a dvi file
    [s,r]=system(sprintf('cd %s; latex -interaction=nonstopmode %s.tex',TMP_DIR,LATEX_FILE));
    if s
        error('Error processing latex file.\n\n%s',r);
    end
    %convert the dvi to pdf
    [s,r]=system(sprintf('dvipdf %s.dvi %s.pdf', ...
        LATEX_FILE,EPS_FILE));
    if s
        warning('Error converting DVI to PDF.\n%s',r);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%   convert to the desired output formats   %%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if options.rasterize
        formats=fieldnames(options.format);
        for i=1:length(formats)
            fmt = formats{i};
            if strcmp(fmt,'eps') && options.format.eps
                %warn about rasterized EPS files
                warning(['Outputing EPS files produced with the ' ...
                    '''-rasterize'' option is strongly discouraged. They ' ...
                    'will be fully rasterized and typically have poor ' ...
                    'resolution. Use PDF files to preserve text and line ' ...
                    'objects or PNG/JPG for fully rasterized images.']);
            end
            if ~strcmp(fmt,'pdf') && options.format.(fmt)
                [s,r]=system(sprintf('convert -density %d %s.pdf %s.png -background white -composite %s.%s', ...
                    options.resolution,...
                    EPS_FILE,...
                    EPS_FILE,...
                    options.filename,...
                    fmt));
            end
            if s
                warning('Error converting to %s.\n%s',fmt,r);
            end
        end
        
        if options.format.pdf==1
            %make a new latex file for png/pdf overlay only if pdf output is
            %desired, other formats are be handled via ImageMagick composites
            FILE_CONTENTS = latex_overlay_file_gen(EPS_FILE);

            %write the latex file:
            FID = fopen([LATEX_FILE '.tex'],'w');
            fprintf(FID,'%s',FILE_CONTENTS);
            fclose(FID);

            %compile
            [s,r]=system(sprintf('cd %s; pdflatex -interaction=nonstopmode %s.tex',TMP_DIR,LATEX_FILE));
            if s
                error('Error processing latex file.\n\n%s',r);
            end
        end
    else
        for i=1:length(options.fmtList)
            fmt = options.fmtList{i};
            if strcmp(fmt,'eps') && options.format.eps
                %DVI to EPS
                [s,r]=system(sprintf('dvips %s.dvi -o %s.eps', ...
                    LATEX_FILE,options.filename));
            elseif ~strcmp(fmt,'pdf') && options.format.(fmt)
                [s,r]=system(sprintf('convert -density %d %s.pdf %s.png', ...
                    options.resolution, ...
                    LATEX_FILE, ...
                    options.filename));
            end
            if s
                warning('Error converting to %s.\n%s',fmt,r);
            end
        end
    end
    
    if options.format.pdf==1
        %rename pdf
        [s,r]=system(sprintf('mv %s.pdf %s.pdf', ...
            LATEX_FILE,options.filename));
    end
    
    %remove temporary files:
    delete(sprintf('%s.*',LATEX_FILE));
    delete(sprintf('%s.*',EPS_FILE));
    
    
end

function options = parse_inputs(inputs)

    %create options struct with the necessary fields:
    options = struct( ...
        'filename', [], ...
        'packages',[], ...
        'crop',[0 0 1 1], ...
        'handle',[], ...
        'quality',90, ...
        'nocrop',false, ...
        'transparent',false, ...
        'rasterize',false, ...
        'renderer','-opengl', ...
        'resolution', get(0,'ScreenPixelsPerInch'), ...
        'aa', 1 ...
        );
    options.format = struct( ...
        'pdf', false, ...
        'eps', false, ...
        'png', false, ...
        'jpg', false, ...
        'tiff', false ...
        );

    %make sure there is actually a figure available:
    if isempty(findobj('type','figure'))
        error('No figures available.');
    end

    if numel(inputs)<1
        error('Output file name required.');
    end

    i=1;
    while i<=numel(inputs)
        if ischar(inputs{i})
            switch lower(inputs{i})
                case {'-opengl','-zbuffer','-painters'}
                    options.renderer = lower(inputs{i});
                    i=i+1;
                case '-rasterize'
                    options.rasterize = true;
                    options.rasterHandles = inputs{i+1};
                    i=i+2;
                case '-transparent'
                    options.transparent = true;
                    i=i+1;
                case '-latexpackages'
                    options.packages = inputs{i+1};
                    i=i+2;
                case {'-loose','-nocrop'}
                    options.nocrop = true;
                    i=i+1;
                case '-crop'
                    if ~isnumeric(inputs{i+1}) || numel(inputs{i+1})~=4
                        error('Invalid -crop option.\nMust have format [left bottom width height] in normalized units.');
                    end
                    options.crop = inputs{i+1};
                    i=i+2;
                case '-figure'
                    if ~isnumeric(inputs{i+1}) || ~any(inputs{i+1}==findobj('type','figure'))
                        warning('Invalid figure handle passed to -figure option, using current figure instead.')
                        options.handle = gcf;
                    else
                        options.handle = inputs{i+1};
                    end
                    i=i+2;
                case '-pdf'
                    options.format.pdf=true;
                    i=i+1;
                case '-eps'
                    options.format.eps=true;
                    i=i+1;
                case '-png'
                    options.format.png=true;
                    i=i+1;
                case {'-jpg','-jpeg'}
                    options.format.jpg=true;
                    i=i+1;
                case {'-tif','-tiff'}
                    options.format.tiff=true;
                    i=i+1;
                otherwise
                    % use regular expressions to check other options:
                    if ~isempty( regexpi(lower(inputs{i}),['^[\' filesep '\w][\' filesep '\w\.\-_]*$']))
                        % file name
                        options.filename = inputs{i};
                    elseif ~isempty(regexpi(lower(inputs{i}),'^-q([1-9]|[1-9][0-9]|100)$'))
                        % quality option
                        options.quality=sscanf(inputs{i},'-q%d',inf);
                    elseif ~isempty(regexpi(lower(inputs{i}),'^-r[0-9]*$'))
                        % resolution option
                        options.resolution=sscanf(inputs{i},'-r%d',inf);
                    elseif ~isempty(regexpi(lower(inputs{i}),'^-a[0-9]+$'))
                        % anti aliasing
                        options.aa=sscanf(inputs{i},'-a%d',inf);
                    else
                        warning('Unrecognized option or invalid file name: ''%s''',inputs{i});
                    end
                    i=i+1;
            end
        else
            % figure handle
            if ishandle(inputs{i}) && strcmp(get(inputs{i},'type'),'figure')
                options.handle = inputs{i};
            else
                warning('Unrecognized option or figure number.');
            end
            i=i+1;
        end
    end

    %make sure the file name is defined
    if isempty(options.filename) || ~ischar(options.filename)
        error('Invalid file name');
    end
    
    %nocrop option will be enabled if rasterize flag is present
    if options.rasterize && ~options.nocrop
        options.nocrop=true;
        warning('Enabling "-nocrop" option for rasterized image to eliminate issues with different cropping sizes.');
    end

    %make sure the figure handle is defined
    if isempty(options.handle)
        options.handle = gcf;
    end

    %try to choose format based on filename and stip the suffix from the
    %filename
    I = strfind(options.filename,'.');
    if ~isempty(I)
        switch lower(options.filename(I(end):end))
            case '.pdf'
                options.format.pdf=1;
                options.filename(I(end):end)=[];
            case '.eps'
                options.format.eps=true;
                options.filename(I(end):end)=[];
            case '.png'
                options.format.png=true;
                options.filename(I(end):end)=[];
            case {'.jpg','.jpeg'}
                options.format.jpg=true;
                options.filename(I(end):end)=[];
            case {'.tif','.tiff'}
                options.format.tiff=true;
                options.filename(I(end):end)=[];
        end
    end

    %be sure at least one format is selected
    n=0;
    formats=fieldnames(options.format);
    for i=1:numel(formats)
        n=n+options.format.(formats{i});
    end
    if n==0;
        error('No output format specified.');
    end
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function FILE_CONTENTS = latex_file_gen(packages,tags,text,align,EPS_FILE)
    %generate the contents for a latex file to process the psfrag tags
    % inputs:
    %   packages =  a string or cell array of strings containing any lines to
    %               be inserted into the latex header (e.g. \usepackage{...}
    %               statements
    %   tags =      a cell array of psfrag tags
    %   text =      a cell array of the latex command that should replace each
    %               psfrag tag
    %   align =     a cell array of alignment options for each tag, must be a
    %               two character string for the horizonat and vertical
    %               alignment


    FILE_CONTENTS=sprintf(repmat('%s\n',1,5),...
        '\documentclass[10pt]{article}',...
        '\usepackage{graphicx}',...
        '\usepackage{psfrag}',...
        '\pagestyle{empty}',...
        '\usepackage{calc}');

    %additional header content such as \usepackage statements
    if ~isempty(packages)
        if ~iscell(packages)
            FILE_CONTENTS = [FILE_CONTENTS sprintf('%s\n',packages)];
        else
            for i=1:numel(packages)
                FILE_CONTENTS = [FILE_CONTENTS sprintf('%s\n',packages{i})];
            end
        end
    end

    FILE_CONTENTS = [FILE_CONTENTS sprintf(repmat('%s\n',1,11),...
        ['\def\mygraphic{\includegraphics{',EPS_FILE,'.eps}}'],...
        '\newlength\graphicheight',...
        '\setlength\graphicheight{\heightof{\mygraphic}}',...
        '\newlength\graphicwidth',...
        '\setlength\graphicwidth{\widthof{\mygraphic}}',...
        '\usepackage[paperwidth=\graphicwidth, paperheight=\graphicheight,',...
        ' top=0in, left=0in, bottom=0in, right=0in]{geometry}',...
        '\begin{document}',...
        '\begin{figure}',...
        '\noindent' )];

    %psfrag tags
    for i=1:numel(tags)
        FILE_CONTENTS = [FILE_CONTENTS sprintf('\\psfrag{%s}[%s][%s]{%s}\n',tags{i},align{i},align{i},text{i})];
    end

    FILE_CONTENTS = [ FILE_CONTENTS sprintf('%s\n%s\n%s\n',...
        ['\includegraphics{',EPS_FILE,'.eps}'],...
        '\end{figure}',...
        '\end{document}' )];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%this function copied from export_fig
function eps_remove_background(fname)
    % Remove the background of an eps file
    % Open the file
    fh = fopen(fname, 'r+');
    if fh == -1
        error('Not able to open file %s.', fname);
    end
    % Read the file line by line
    while true
        % Get the next line
        l = fgets(fh);
        if isequal(l, -1)
            break; % Quit, no rectangle found
        end
        % Check if the line contains the background rectangle
        if isequal(regexp(l, ' *0 +0 +\d+ +\d+ +rf *[\n\r]+', 'start'), 1)
            % Set the line to whitespace and quit
            l(1:regexp(l, '[\n\r]', 'start', 'once')-1) = ' ';
            fseek(fh, -numel(l), 0);
            fprintf(fh, l);
            break;
        end
    end
    % Close the file
    fclose(fh);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function FILE_CONTENTS = latex_overlay_file_gen(filename)
    % Generate the contents for a latex file to overlay the pdf axes on the
    % rasterized plot contents

    FILE_CONTENTS=sprintf(repmat('%s\n',1,19),...
        '\documentclass[10pt]{article}',...
        '\usepackage{graphicx}',...
        '\usepackage{calc}',...
        '\pagestyle{empty}',...
        sprintf('\\def\\mygraphic{\\includegraphics{%s.pdf}}',filename),...
        '\newlength\graphicheight',...
        '\setlength\graphicheight{\heightof{\mygraphic}}',...
        '\newlength\graphicwidth',...
        '\setlength\graphicwidth{\widthof{\mygraphic}}',...
        '\usepackage[paperwidth=\graphicwidth, paperheight=\graphicheight,',...
        '  top=0in, left=0in, bottom=0in, right=0in]{geometry}',...
        '\usepackage[abs]{overpic}',...
        '\begin{document}',...
        '\noindent',...
        '\begin{overpic}[scale=1,unit=1mm,width=1\textwidth]',...
        sprintf('  {%s.pdf}',filename),...
        sprintf('  \\put(0,0){\\includegraphics[width=1\\textwidth]{%s.png}}',filename),...
        '\end{overpic}',...
        '\end{document}'...
    );
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [img alph] = transparent_png(handle,aa,renderer,ppi,transparent)
% [img alph] = transparent_png(handle,aa,renderer,ppi)
% 
% Return a png image array and corresponding alpha values.
% Options:
%   handle      figure handle to use
%   aa          anti-aliasing level (1 means no anti-aliasing)
%   renderer    '-opengl', '-zbuffer', or '-painters'
%   ppi         pixels per inch for the image

set(handle,'invertHardcopy','off');

%make save the background color and compute the necessary magnification:
magnify = aa*ppi/get(0,'screenpixelsperinch');

if transparent
    %current color
    COLOR = get(handle,'color');
    POS = get(handle,'position');
    %white background:
    set(handle,'color','w','position',POS);
end
% drawnow
tmpimg = print2array(handle,magnify,renderer);
img = downscale( tmpimg, aa );

if transparent
    %black background:
    set(handle,'color','k','position',POS);
%     drawnow
    tmpimg = print2array(handle,magnify,renderer);
    img2 = downscale( tmpimg, aa );

    %reset background
    set(handle,'color',COLOR,'position',POS);
end

if nargout==2
    if transparent
        %alpha values:
        alph = uint8(255-sum(img-img2,3)/3);
    else
        alph = uint8(255*ones(size(img,1),size(img,2)));
    end
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%this function is based on a similar function in export_fig with some
%improvements for better speed if the image processing toolbox is not
%available
function img = downscale(img, factor)
% Scale down an image by a factor of "factor"
if factor == 1
    %don't scale
    return
end
try
    % Faster, but requires image processing toolbox
    img = imresize(img, 1/factor, 'bilinear');
catch
    % No image processing toolbox - resize manually
    ff = ceil(factor);
    if mod(ff,2)
        x=-ff:ff;
    else
        x=-ff+.5:ff;
    end
    I=1:numel(x);
    x = x/(x(end)*.6);
    x = exp(-x.^2);
    %normalize
    x = single(x/sum(x));
    
    %pad the image
    npad = (numel(I)-ff)/2;
    img = cat(1, img(ones(1,npad),:,:), img, img(size(img,1)*ones(1,npad),:,:));
    img = single(cat(2, img(:,ones(1,npad),:), img, img(:,size(img,2)*ones(1,npad),:)));
    
    img_out = single(zeros(floor((size(img,1)-2*npad)/factor),floor((size(img,2)-2*npad)/factor),size(img,3)));
    
    ii=floor(factor*(0:size(img_out,1)-1));
    jj=floor(factor*(0:size(img_out,2)-1));
    for i=I
    for j=I
        img_out = img_out + x(i)*x(j)*img(i+ii,j+jj,:);
    end
    end
    img = uint8(img_out);
end
end

function str = prepend_font_size(ptSize,text);
% Deal with font sizes by roughly translating font sizes in points to
% LaTeX font size commands
if ptSize>=20.75
    str=strcat('\Huge~', text);
elseif ptSize>=17.25
    str=strcat('\huge~', text);
elseif ptSize>=14.75
    str=strcat('\LARGE~', text);
elseif ptSize>=12.875
    str=strcat('\Large~', text);
elseif ptSize>=10.875
    str=strcat('\large~', text);
elseif ptSize>=9.5
    str=strcat('\normalsize~', text);
elseif ptSize>=8.75
    str=strcat('\small~', text);
elseif ptSize>=8.25
    str=strcat('\footnotesize~', text);
elseif ptSize>=7.5
    str=strcat('\scriptsize~', text);
else
    str=strcat('\tiny ', text);
end
end
