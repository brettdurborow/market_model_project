
%% Read assumptions from Excel file on disk
doPlots = true;
tStart = tic;

% fileName = '.\Data\MATLABv33_ps1.xlsb';
% fileName = '.\Data\aMDD MM v1.6-ES (protected).xlsb';
% fileName = '.\Data\aMDD MM v1.6-ES (Inputs).xlsb';
% fileName = '.\Data\US-MATLAB.xlsx';
% fileName = '.\Data\MDD MM LRFP2018.xlsx';
fileName = '.\Data\MDD MM LRFP2018.xlsm';
% fileName = '.\Data\TheMath 2c.xlsx';

[cMODEL, cASSET, cCHANGE] = importAssumptions(fileName);
cCNSTR = getConstraints(cASSET);
fprintf('Imported Data, elapsed time = %1.1f sec\n', toc(tStart));


%% Run many realizations, collect stats at the end

numIterations = 100;
numWorkers = 3;

fnames = {'NumIterations', 'NumWorkers', 'ExecutionTime', 'RunTime'};
BENCH = struct;  % intialize the benchmark struct
for m = 1:length(fnames)
    BENCH.(fnames{m}) = nan(size(cMODEL));
end

runTime = datetime('now', 'TimeZone', 'America/New_York');  % Entire run has same RunTime
outFolder = fullfile('Output', sprintf('ModelOut_%s', datestr(runTime, 'yyyy-mm-dd_HHMMSS')));
if ~exist(outFolder, 'dir')
    mkdir(outFolder)
end

ccMODEL = cell(length(cMODEL), length(cCNSTR));
ccASSET = cell(length(cMODEL), length(cCNSTR));
ccESTAT = cell(length(cMODEL), length(cCNSTR));
for m = 1:length(cMODEL)
    MODEL = cMODEL{m};
    ASSET = cASSET{m};
    CHANGE = cCHANGE{m};

    [dateGrid, SimCubeBranded, SimCubeMolecule, tExec] = marketModelMonteCarlo(MODEL, ASSET, CHANGE, numIterations, numWorkers);

    % Parameters of the overall simulation for performance benchmarking
    BENCH.NumIterations(m) = numIterations;
    BENCH.NumWorkers(m) = numWorkers;
    BENCH.ExecutionTime(m) = tExec;  % Does not include time to setup worker pool on first call

    Nsim = size(SimCubeBranded, 1);
    fprintf('Country:%s, Ran %d iterations, elapsed time = %1.1f sec\n', ...
            MODEL.CountrySelected, Nsim, toc(tStart));

    for n = 1:length(cCNSTR)
        [a, b, c] = applyConstraints(cCNSTR{n}, MODEL, ASSET, SimCubeBranded, SimCubeMolecule, dateGrid);
        ccMODEL{m,n} = a;
        ccASSET{m,n} = b;
        ccESTAT{m,n} = c;
    end
    
    MODEL = ccMODEL{m,1}; % First column is the unconstrained simulation
    ASSET = ccASSET{m,1};
    ESTAT = ccESTAT{m,1};

%     outFileName = fullfile(outFolder, sprintf('S_ModelOutputs_%s.xlsx', datestr(runTime, 'yyyy-mm-dd_HHMMSS')));
%     warning('off', 'MATLAB:xlswrite:AddSheet'); % Suppress the annoying warnings
%     OUT_Branded  = writeEnsembleOutputs(outFileName, [MODEL.CountrySelected, '_Branded_Mean'], ESTAT.Branded.Mean, ESTAT.DateGrid, MODEL, ASSET);
%     OUT_BrStdEr  = writeEnsembleOutputs(outFileName, [MODEL.CountrySelected, '_Branded_StdErr'], ESTAT.Branded.StdErr, ESTAT.DateGrid, MODEL, ASSET);
%     OUT_Molecule = writeEnsembleOutputs(outFileName, [MODEL.CountrySelected, '_Molecule_Mean'], ESTAT.Molecule.Mean, ESTAT.DateGrid, MODEL, ASSET);
        
    fprintf('Country:%s, Computed Ensemble Outputs, elapsed time = %1.1f sec\n', ...
            MODEL.CountrySelected, toc(tStart));
end
BENCH.RunTime = repmat(runTime, size(BENCH.NumIterations));


cMODEL = ccMODEL(:,1);  % First column is the unconstrained simulation
cASSET = ccASSET(:,1);
cESTAT = ccESTAT(:,1);

xlsFileName = fullfile(outFolder, sprintf('TableauData_%s.xlsx', datestr(runTime, 'yyyy-mm-dd_HHMMSS')));
[~, cSheetNames] = writeTableauXls(xlsFileName, cMODEL, cASSET, cESTAT, BENCH);

%% Write out the constraints

clear cESTAT SimCubeBranded SimCubeMolecule

cESTATc = cell(size(cCNSTR));
cMODELc = cell(size(cCNSTR));
cASSETc = cell(size(cCNSTR));
for n = 1:length(cESTATc)
   cESTATc{n} = ccESTAT(:,n); 
   cMODELc{n} = ccMODEL(:,n);
   cASSETc{n} = ccASSET(:,n);
end

ticBytes(gcp);
nWork = 3;
startVec =  1:nWork:length(cCNSTR);
endVec = startVec + nWork - 1;
endVec(end) = length(cCNSTR);
for m = 1:length(startVec)
    parfor n = startVec(m):endVec(m)
        cname = cCNSTR{n}.ConstraintName;
        outFolderSub = fullfile(outFolder, cname);

        [cTables, cFileNames] = writeTablesCsv(outFolderSub, cMODELc{n}, cASSETc{n}, cESTATc{n}, cCNSTR, BENCH);
    end
end
tocBytes(gcp)

tElapsed = toc(tStart);
fprintf('Run complete, elapsed time = %1.2f sec\n', tElapsed);
