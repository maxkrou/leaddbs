% function dedirs_ge_16 gives DE_scheme with b0s if amount of b0s is given
% SuS April 2008 (copied from original tensor.dat file)

function DE_scheme = dedirs_ge_16(nob0s)

if nargin == 0
    DE_scheme = [0.733571208539 -0.509367037098 -0.449909439244;...
        -0.527936513082 0.197513112343 0.825997341768;...
        0.210490445990 0.934016014999 -0.288631002964;...
        -0.394388830898 0.876999734693 0.274461136430;...
        0.901500079093 0.427890594987 -0.064863287901;...
        -0.126116414468 -0.264945505828 -0.955980401966;...
        -0.807197676003 -0.422051151370 -0.412679945579;...
        0.264549795600 -0.885039709623 0.383038011218;...
        -0.616921323093 -0.639391147814 0.458897636963;...
        -0.969209372877 0.238904864368 0.059646100528;...
        -0.080651424152 -0.925976042468 -0.368868156063;...
        0.393234069013 0.625539858854 0.673844827799;...
        0.874906967098 -0.244744309460 0.417897142739;...
        0.175293851258 -0.219349658857 0.959769656152;...
        -0.509883948542 0.523218324223 -0.682833028065;...
        0.478759086918 0.286782058057 -0.829786591763];
elseif nargin == 1
    DE_scheme = [zeros(nob0s,3);...
        0.733571208539 -0.509367037098 -0.449909439244;...
        -0.527936513082 0.197513112343 0.825997341768;...
        0.210490445990 0.934016014999 -0.288631002964;...
        -0.394388830898 0.876999734693 0.274461136430;...
        0.901500079093 0.427890594987 -0.064863287901;...
        -0.126116414468 -0.264945505828 -0.955980401966;...
        -0.807197676003 -0.422051151370 -0.412679945579;...
        0.264549795600 -0.885039709623 0.383038011218;...
        -0.616921323093 -0.639391147814 0.458897636963;...
        -0.969209372877 0.238904864368 0.059646100528;...
        -0.080651424152 -0.925976042468 -0.368868156063;...
        0.393234069013 0.625539858854 0.673844827799;...
        0.874906967098 -0.244744309460 0.417897142739;...
        0.175293851258 -0.219349658857 0.959769656152;...
        -0.509883948542 0.523218324223 -0.682833028065;...
        0.478759086918 0.286782058057 -0.829786591763];
elseif nargin > 1
    disp('Error: too many input arguments');
end
DE_scheme = [DE_scheme(:,2) DE_scheme(:,1) -DE_scheme(:,3)];
