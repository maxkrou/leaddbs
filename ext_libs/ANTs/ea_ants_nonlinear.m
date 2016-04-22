function ea_ants_nonlinear(varargin)
% Wrapper for ANTs nonlinear registration

fixedimage=varargin{1};
movingimage=varargin{2};
outputimage=varargin{3};

if nargin>3
    masks=varargin{4};
end

[outputdir, outputname, ~] = fileparts(outputimage);
if outputdir 
    outputbase = [outputdir, filesep, outputname];
else
    outputbase = ['.', filesep, outputname];
end

if ~iscell(fixedimage) && ischar(fixedimage)
    fim{1}=fixedimage;
    fixedimage=fim;
    clear fim
elseif iscell(fixedimage)
else
        ea_error('Please supply variable fixedimage as either char or cellstring');
end

if ~iscell(movingimage) && ischar(movingimage)
    movim{1}=movingimage;
    movingimage=movim;
    clear movim
elseif iscell(movingimage)
else
    ea_error('Please supply variable fixedimage as either char or cellstring');
end

for fi=1:length(fixedimage)
    fixedimage{fi} = ea_path_helper(fixedimage{fi});
end
for fi=1:length(movingimage)
    movingimage{fi} = ea_path_helper(movingimage{fi});
end

if length(fixedimage)~=length(movingimage)
    ea_error('Please supply pairs of moving and fixed images (can be repetitive).');
end
outputimage = ea_path_helper(outputimage);

basedir = [fileparts(mfilename('fullpath')), filesep];

if ispc
    HEADER = [basedir, 'PrintHeader.exe'];
    ANTS = [basedir, 'antsRegistration.exe'];
elseif isunix
    HEADER = [basedir, 'PrintHeader.', computer];
    ANTS = [basedir, 'antsRegistration.', computer];
end

if ~ispc
    [~, imgsize] = system(['bash -c "', HEADER, ' ',fixedimage{1}, ' 2"']);
else
    [~, imgsize] = system([HEADER, ' ', fixedimage{1}, ' 2']);
end
imgsize = cellfun(@(x) str2double(x),ea_strsplit(imgsize,'x'));

if any(imgsize>256)
    rigidconvergence='[1000x500x250x0,1e-6,10]';
    rigidshrinkfactors='12x8x4x2';
    rigidsoomthingssigmas='4x3x2x1vox';
    
    affineconvergence='[1000x500x250x0,1e-6,10]';
    affineshrinkfactors='12x8x4x2';
    affinesoomthingssigmas='4x3x2x1vox';
else
    rigidconvergence='[1000x500x250x0,1e-6,10]';
    rigidshrinkfactors='8x4x2x1';
    rigidsoomthingssigmas='3x2x1x0vox';
    
    affineconvergence='[1000x500x250x0,1e-6,10]';
    affineshrinkfactors='8x4x2x1';
    affinesoomthingssigmas='3x2x1x0vox';
end

rigidstage = [' --initial-moving-transform [', fixedimage{1}, ',', movingimage{1}, ',1]' ...
    ' --transform Rigid[0.1]' ...
    ' --convergence ', rigidconvergence, ...
    ' --shrink-factors ', rigidshrinkfactors, ...
    ' --smoothing-sigmas ', rigidsoomthingssigmas];

for fi=1:length(fixedimage)
    if nargin<3
        rigidstage=[rigidstage,...
            ' --metric MI[', fixedimage{fi}, ',', movingimage{fi}, ',1,32,Regular,0.25]'];
    else
        rigidstage=[rigidstage,...
            ' --metric IGDM[', fixedimage{fi}, ',', movingimage{fi},',',masks{fi,1},',',masks{fi,2}, ',1,32,Regular,0.25]'];
    end
end


affinestage = [' --transform Affine[0.1]'...
    ' --convergence ', affineconvergence, ...
    ' --shrink-factors ', affineshrinkfactors ...
    ' --smoothing-sigmas ', affinesoomthingssigmas];


for fi=1:length(fixedimage)
    if nargin<3
        affinestage=[affinestage,...
            ' --metric MI[', fixedimage{fi}, ',', movingimage{fi}, ',1,32,Regular,0.25]'];
    else
        affinestage=[affinestage,...
            ' --metric IGDM[', fixedimage{fi}, ',', movingimage{fi},',',masks{fi,1},',',masks{fi,2}, ',1,32,Regular,0.25]'];
    end
end


synstage = [' --transform SyN[0.3]'...
    ' --convergence ', affineconvergence, ...
    ' --shrink-factors ', affineshrinkfactors ...
    ' --smoothing-sigmas ', affinesoomthingssigmas];

for fi=1:length(fixedimage)
    if nargin<3
        synstage=[synstage,...
            ' --metric MI[', fixedimage{fi}, ',', movingimage{fi}, ',1,32,Regular,0.25]'];
    else
        synstage=[synstage,...
            ' --metric MI[', fixedimage{fi}, ',', movingimage{fi},',',masks{fi,1},',',masks{fi,2},  ',1,32,Regular,0.25]'];
    end
end

ea_libs_helper
cmd = [ANTS, ' --verbose 1' ...
             ' --dimensionality 3 --float 1' ...
             ' --output [',ea_path_helper(outputbase), ',', outputimage, ']' ...
             ' --interpolation Linear' ...
             ' --use-histogram-matching 1' ...
             ' --winsorize-image-intensities [0.005,0.995]', ...
             ' --write-composite-transform 1', ...
             rigidstage, affinestage, synstage];
if ~ispc
    system(['bash -c "', cmd, '"']);
else
    system(cmd);
end
