function ea_ants_applytransforms(options)
% Wrapper for antsApplyTransforms in terms of reapplying normalizations to
% pre- and postop imaging.

ea_libs_helper;

basedir = [fileparts(mfilename('fullpath')), filesep];

if ispc
    applyTransforms = [basedir, 'antsApplyTransforms.exe'];
elseif isunix
    applyTransforms = [basedir, 'antsApplyTransforms.', computer];
end

subdir=[options.root,options.patientname,filesep];

switch options.modality
    case 1 % MR
        fis{1}=[subdir,options.prefs.prenii_unnormalized];
        fis{2}=[subdir,options.prefs.tranii_unnormalized];
        fis{3}=[subdir,options.prefs.cornii_unnormalized];
        fis{4}=[subdir,options.prefs.sagnii_unnormalized];
        ofis{1}=[subdir,options.prefs.gprenii];
        ofis{2}=[subdir,options.prefs.gtranii];
        ofis{3}=[subdir,options.prefs.gcornii];
        ofis{4}=[subdir,options.prefs.gsagnii];
        lfis{1}=[options.prefs.prenii];
        lfis{2}=[options.prefs.tranii];
        lfis{3}=[options.prefs.cornii];
        lfis{4}=[options.prefs.sagnii];
    case 2 % CT
        fis{1}=[subdir,options.prefs.prenii_unnormalized];
        fis{2}=[subdir,options.prefs.ctnii_coregistered];
        ofis{1}=[subdir,options.prefs.gprenii];
        ofis{2}=[subdir,options.prefs.gctnii];
        lfis{1}=[options.prefs.prenii];
        lfis{2}=[options.prefs.ctnii];
end

for fi=1:length(fis)
    % generate gl*.nii files
    [~,lprebase]=fileparts(options.prefs.prenii);
    cmd = [applyTransforms,' --verbose 1' ...
           ' --dimensionality 3 --float 1' ...
           ' -i ',ea_path_helper(fis{fi}), ...
           ' -o ',ea_path_helper(ofis{fi}), ...
           ' -r ',[options.earoot,'templates',filesep,'mni_hires.nii']...
           ' -t ',ea_path_helper([subdir,lprebase]),'1Warp.nii.gz'...
           ' -t ',ea_path_helper([subdir,lprebase]),'0GenericAffine.mat'];
    if ~ispc
        system(['bash -c "', cmd, '"']);
    else
        system(cmd);
    end   
    % generate l*.nii files
    matlabbatch{1}.spm.util.imcalc.input = {[options.earoot,'templates',filesep,'bb.nii,1']
        [ofis{fi},',1']
        };
    matlabbatch{1}.spm.util.imcalc.output = lfis{fi};
    matlabbatch{1}.spm.util.imcalc.outdir = {subdir};
    matlabbatch{1}.spm.util.imcalc.expression = 'i2';
    matlabbatch{1}.spm.util.imcalc.var = struct('name', {}, 'value', {});
    matlabbatch{1}.spm.util.imcalc.options.dmtx = 0;
    matlabbatch{1}.spm.util.imcalc.options.mask = 0;
    matlabbatch{1}.spm.util.imcalc.options.interp = 1;
    matlabbatch{1}.spm.util.imcalc.options.dtype = 4;
    cfg_util('run',{matlabbatch});
    clear matlabbatch
end
