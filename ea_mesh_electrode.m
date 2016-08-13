function [emesh,nmesh]=ea_mesh_electrode(fv,elfv,meshel)
% meshing an electrode and tissue structures bounded by a cylinder

%% load the nucleus data

tic

%% user defined parameters
orig=[10.1,-15.07,-9.978];    % starting point of the electrode axis
etop=[34.39,20.23,43.14];     % end point of the electrode axis
electrodelen=norm(etop-orig); % length of the electrode
electroderadius=0.65;            % radius of the electrode

electrodetrisize=0.2;  % the maximum triangle size of the electrode mesh
bcyltrisize=0.3;       % the maximum triangle size of the bounding cyl
nucleidecimate=0.2;    % downsample the nucleius mesh to 20%

cylz0=-1;     % define the lower end of the bounding cylinder
cylz1=25;     % define the upper end of the bounding cylinder
cylradius=15; % define the radius of the bounding cylinder  
ndiv=50;      % division of circle for the bounding cylinder

ncount=8;     % the number of nuclei meshes inside fv()

v0=(etop-orig)/electrodelen;               % unitary dir
c0=[0 0 0];
v=[0 0 1];

%% loading the electrode surface model

ncyl=[];
fcyl=[];
scyl=[];
seeds=[];

for i=1:length(meshel.ins)
    fcyl=[fcyl; meshel.ins{i}.faces+size(ncyl,1)];
    if(i<length(meshel.ins))
        scyl=[scyl; meshel.ins{i}.endplates+size(ncyl,1)]; % had to rebuild the endplates
    end
    ncyl=[ncyl; meshel.ins{i}.vertices];
    seeds=[seeds; mean(meshel.ins{i}.vertices)];
end
for i=1:length(meshel.con)
    fcyl=[fcyl; meshel.con{i}.faces+size(ncyl,1)];
    scyl=[scyl; meshel.ins{i}.endplates+size(ncyl,1)];
    ncyl=[ncyl; meshel.con{i}.vertices];
    seeds=[seeds; mean(meshel.ins{i}.vertices)];
end

[ncyl, I, J]=unique(ncyl, 'rows');
fcyl=unique(round(J(fcyl)),'rows');
scyl=unique(round(J(scyl)),'rows');

fcyl=num2cell(fcyl,2);
scyl=num2cell(scyl,2);

%% convert the obtain the electrode surface mesh model
[node,elem,face]=s2m(ncyl,{fcyl{:}, scyl{:}},electrodetrisize,100,'tetgen',seeds,[]); % generate a tetrahedral mesh of the cylinders

%plotmesh(node,elem) % plot the electrode mesh for now

%% load the nucleus surfaces
nobj=[];
fobj=[];
nseeds=[];

for i=1:ncount
    no=fv(i).vertices;
    fo=fv(i).faces;
    [no,fo]=meshresample(no,fo,nucleidecimate); % mesh is too dense, reduce the density by 80%
    [no,fo]=meshcheckrepair(no,fo,'meshfix');  % clean topological defects
    fobj=[fobj;fo+size(nobj,1)];
    nobj=[nobj;no];
    nseeds=[nseeds; mean(no)];
end

%% merge the electrode mesh with the nucleus mesh
ISO2MESH_SURFBOOLEAN='cork';   % now intersect the electrode to the nucleus
[nboth,fboth]=surfboolean(node,face(:,[1 3 2]),'resolve',nobj,fobj);
clear ISO2MESH_SURFBOOLEAN;

%% create a bounding box - this causes cork segfault, use below instead
% nbbx=fv(9).vertices;
% fbbx=fv(9).faces;
% seedbbc=nbbx(1,:)*(1-1e-4)+nbbx(end-1,:)*1e-4;  % define a seed point for the bounding cylinder
% [nbcyl,fbcyl]=s2m(nbbx,fbbx,1,10);

%% create a bounding cylinder
c0bbc=c0+cylz0*v;     
c1bbc=c0+cylz1*v;
[nbcyl,fbcyl]=meshacylinder(c0bbc, c1bbc,cylradius,bcyltrisize,10,ndiv);
nbcyl=rotatevec3d(nbcyl,v0,v);
nbcyl=nbcyl+repmat(orig,size(nbcyl,1),1);
seedbbc=nbcyl(1,:)*(1-1e-2)+mean(nbcyl)*1e-2;  % define a seed point for the bounding cylinder

%% cut the electrode+nucleus mesh by the bounding cylinder
ISO2MESH_SURFBOOLEAN='cork';
[nboth2,fboth2]=surfboolean(nbcyl,fbcyl(:,[1 3 2]),'first',nboth,fboth);
clear ISO2MESH_SURFBOOLEAN;

%% remove duplicated nodes in the surface
[nboth3,fboth3]=meshcheckrepair(nboth2,fboth2,'dup');
[nboth4,fboth4]=meshcheckrepair(nboth3,fboth3,'deep');

%% define seeds along the electrode axis
[t,baryu,baryv,faceidx]=raytrace(orig,v0,nboth4,fboth4);
t=sort(t(faceidx));
t=(t(1:end-1)+t(2:end))*0.5;
seedlen=length(t);
electrodeseeds=repmat(orig(:)',seedlen,1)+repmat(v0(:)',seedlen,1).*repmat(t(:)-1,1,3);
%% create tetrahedral mesh of the final combined mesh (seeds are ignored, tetgen 1.5 automatically find regions)
[nmesh,emesh]=s2m(nboth3,fboth3,1,5);

%% plot the final tetrahedral mesh
figure
hold on;
plotmesh(nmesh,emesh,'linestyle','none','facealpha',0.2)

%% remapping the region labels
etype=emesh(:,end);
labels=unique(etype);

eleccoord=rotatevec3d(nmesh-repmat(orig,size(nmesh,1),1),v,v0); % convert the centroids to the electrode cylinder coordinate

maxradius=zeros(length(labels),1);
zrange=zeros(length(labels),2);
centroids=zeros(length(labels),3);
for i=1:length(labels)
    centroids(i,:)=mean(meshcentroid(nmesh,emesh(etype==labels(i),1:3)));
    cc=(meshcentroid(eleccoord,emesh(etype==labels(i),1:3))); % centroids of each label
    maxradius(i)=sqrt(max(sum(cc(:,1:2).*cc(:,1:2),2)));
    zrange(i,:)=[min(cc(:,3)) max(cc(:,3))];
end

electrodelabel=find(zrange(:,1)>0 & zrange(:,2)<electrodelen & maxradius<=electroderadius); % select labels that are 

% further compare zrange to seeds variable to get insulating/conducting
% material right:
condins=zeros(length(meshel.ins)+length(meshel.con),1);
condins(1:length(meshel.ins))=2; % insulation
condins(length(meshel.ins)+1:length(meshel.ins)+length(meshel.con))=1; % conducting
elcentroids=centroids(electrodelabel,:);

iscontact=zeros(length(electrodelabel),1);
for comp=1:length(elcentroids)

    for con=1:4
        
        in=ea_intriangulation(elfv(con).vertices,elfv(con).faces,elcentroids(comp,:));
        if in
            iscontact(comp)=1;
            break
        end
        
        
    end

end

contactlabels=electrodelabel(logical(iscontact));
insulationlabels=electrodelabel(logical(~iscontact));
%plotmesh(seeds, 'y*'); % all region centroids


%plotmesh(centroids, 'ro'); % all region centroids
%plotmesh(centroids(electrodelabel,:),'k*'); % all electrode segments

[maxr, wmlabels]=max(maxradius);   % the label for the bounding cyl is identified with the max radius

gmlabels=setdiff(labels,[wmlabels; electrodelabel]); % the remaining ones are from nuclei meshes.


tissuetype=emesh(:,5);
tissuetype(ismember(emesh(:,5),gmlabels))=1;
tissuetype(ismember(emesh(:,5),wmlabels))=2;
tissuetype(ismember(emesh(:,5),contactlabels))=3;
tissuetype(ismember(emesh(:,5),insulationlabels))=4;

emesh(:,5)=tissuetype;
% until now, electrodelabel stores the regions inside the electrode;
%            bcyllabel stores the region for the bounding cylinder
%            nucleuslabel stores the regions for the nuclei

%gmidx=ismember(etype,gmlabels);

%plotmesh(nmesh,emesh(gmidx,:),'facealpha',0.5,'edgealpha',0.1);

toc
