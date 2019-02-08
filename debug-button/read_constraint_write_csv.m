function read_constraint_write_cvs(tmpdir,CNSTR,cCNSTR,outFolder,BENCH)

% For this constraint we will load data for all countries and write the
% output into the output folder
numCountries=length(tmpdir);

cMODEL=cell(numCountries,1);
cASSET=cell(numCountries,1);
cESTAT=cell(numCountries,1);
tic
for m=1:length(tmpdir)
    S=load(tmpdir(m)+filesep+CNSTR.ConstraintName);
    cMODEL{m}=S.MODEL2;
    cASSET{m}=S.ASSET2;
    cESTAT{m}=S.ESTAT;
end
outFolderSub=string(outFolder)+filesep+CNSTR.ConstraintName;
if ~exist(outFolderSub)
    mkdir(outFolderSub);
end

[~, cFileNames] = writeTablesCsv(outFolderSub, cMODEL, cASSET, cESTAT, cCNSTR, BENCH);
toc

    