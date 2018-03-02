
%% Read assumptions from Excel file on disk
doPlots = true;
tStart = tic;

% fileName = '.\Data\MATLABv33_ps1.xlsb';
% fileName = '.\Data\aMDD MM v1.6-ES (protected).xlsb';
% fileName = '.\Data\aMDD MM v1.6-ES (Inputs).xlsb';
% fileName = '.\Data\US-MATLAB.xlsx';
fileName = '.\Data\TheMath 2c.xlsx';

[cMODEL, cASSET, cCHANGE] = importAssumptions(fileName);

fprintf('Imported Data, elapsed time = %1.1f sec\n', toc(tStart));


%% Run many realizations, collect stats at the end

numIterations = 100;
numWorkers = 3;

fnames = {'NumIterations', 'NumWorkers', 'ExecutionTime', 'RunTime'};
BENCH = struct;  % intialize the benchmark struct
for m = 1:length(fnames)
    BENCH.(fnames{m}) = nan(size(cMODEL));
end

cESTAT = cell(size(cMODEL));
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

    cESTAT{m} = computeEnsembleStats(SimCubeBranded, SimCubeMolecule, dateGrid);
    fprintf('Country:%s, Computed Ensemble Outputs, elapsed time = %1.1f sec\n', ...
            MODEL.CountrySelected, toc(tStart));
end
endTime = datetime('now', 'TimeZone', 'America/New_York');  % Entire run has same RunTime
BENCH.RunTime = repmat(endTime, size(BENCH.NumIterations));

% outFileName = sprintf('Output\\S_ModelOutputs_%s.xlsx', datestr(endTime, 'yyyy-mm-dd_HHMMSS'));
% OUT_Branded  = writeEnsembleOutputs(outFileName, 'Branded_Mean', ESTAT.Branded.Mean, ESTAT.DateGrid, MODEL, ASSET);
% OUT_Molecule = writeEnsembleOutputs(outFileName, 'Molecule_Mean', ESTAT.Molecule.Mean, ESTAT.DateGrid, MODEL, ASSET);

xlsFileName = fullfile('Output', sprintf('TableauData_%s.xlsx', datestr(endTime, 'yyyy-mm-dd_HHMMSS')));
[cTableau, cSheetNames] = writeTableauXls(xlsFileName, cMODEL, cASSET, cESTAT, BENCH);


%% Plot some outputs across all assets

simNum = 1;

sharePerAssetMonthlySeries = squeeze(SimCubeBranded(simNum, :, :));

uClass = unique(ASSET.Therapy_Class);
Nc = length(uClass);
Nt = size(sharePerAssetMonthlySeries, 2);
sharePerClassMonthlySeries = zeros(Nc, Nt);

for m = 1:Nc
    ix = find(strcmpi(uClass(m), ASSET.Therapy_Class));
    sharePerClassMonthlySeries(m,:) = nansum(OUT_Branded.M.PointShare(ix, :), 1);    
end

OUT = computeOutputs(MODEL, ASSET, dateGrid, sharePerAssetMonthlySeries);

[annualDates, annualBrandedShare] = annualizeMx(dateGrid, OUT_Branded.M.PointShare, 'mean');


if doPlots
    figure; plot(dateGrid, 1-nansum(OUT_Molecule.M.PointShare)); datetick; grid on; timeCursor(false);
            title('Sum-To-One Error');
    
    figure; semilogy(dateGrid, OUT_Molecule.M.PointShare); datetick; grid on; title('Share Per Asset');
            legend(ASSET.Assets_Rated, 'Location', 'EastOutside'); timeCursor(false);

    figure; hA = area(dateGrid, OUT_Molecule.M.PointShare'); datetick; grid on; axis tight;
            title('Share Per Asset - Molecule Mean Monthly'); 
            legend(hA(end:-1:1), ASSET.Assets_Rated(end:-1:1), 'Location', 'EastOutside'); timeCursor(false);
            
    figure; hA = area(dateGrid, OUT_Branded.M.PointShare'); datetick; grid on; axis tight;
            title('Share Per Asset - Branded Mean Monthly'); 
            legend(hA(end:-1:1), ASSET.Assets_Rated(end:-1:1), 'Location', 'EastOutside'); timeCursor(false);
            
    figure; hA = area(annualDates, annualBrandedShare'); grid on; axis tight;
            title('Share Per Asset - Branded Mean Annually'); 
            legend(hA(end:-1:1), ASSET.Assets_Rated(end:-1:1), 'Location', 'EastOutside'); timeCursor(false);

    figure; hA = area(dateGrid, sharePerClassMonthlySeries'); datetick; grid on; axis tight;
            title('Share Per Class - Branded Mean Monthly'); 
            legend(hA(end:-1:1), uClass(end:-1:1), 'Location', 'EastOutside'); timeCursor(false);            
    
    figure; semilogy(dateGrid, OUT_Branded.M.Units); datetick; grid on; 
            title('Units per Asset - Branded Mean Monthly');
            legend(ASSET.Assets_Rated, 'Location', 'EastOutside'); timeCursor(false);

    figure; semilogy(dateGrid, OUT_Branded.M.NetRevenues); datetick; grid on; 
            title('Net Revenues per Asset - Branded Mean Monthly');
            legend(ASSET.Assets_Rated, 'Location', 'EastOutside'); timeCursor(false);

end


%% Plot one Asset across all realizations


if doPlots
    aNum = 9;  % asset number to plot
    figure; 
    plot(dateGrid, ESTAT.Branded.Pct90(aNum,:), dateGrid, ESTAT.Branded.Pct50(aNum,:), dateGrid, ESTAT.Branded.Pct10(aNum,:));
    legend({'90th %ile', '50th %ile', '10th %ile'});
    title(sprintf('Monthly Share Percentiles: %s', ASSET.Assets_Rated{aNum}));
    datetick; grid on; timeCursor(false);
        
    figure; cdfplot(SimCubeBranded(:, aNum, Nt)); 
    title(sprintf('CDF of final share over %d sims for Asset %d.  PTRS=%1.1f%%', Nsim, aNum, ASSET.Scenario_PTRS{aNum} * 100));
   
end


tElapsed = toc(tStart);
fprintf('Run complete, elapsed time = %1.2f sec\n', tElapsed);
