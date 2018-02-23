
%% Read assumptions from Excel file on disk
doPlots = true;
tStart = tic;

% fileName = '.\Data\MATLABv33_ps1.xlsb';
% fileName = '.\Data\aMDD MM v1.6-ES (protected).xlsb';
fileName = '.\Data\aMDD MM v1.6-ES (Inputs).xlsb';

[MODEL, ASSET, CHANGE] = importAssumptions(fileName);

fprintf('Imported Data, elapsed time = %1.1f sec\n', toc(tStart));


Na = length(ASSET.Scenario_PTRS);
Nchange = length(CHANGE.Scenario_PTRS);


%% Run many realizations, collect stats at the end

numIterations = 1000;
numWorkers = 3;
[dateGrid, SimCubeBranded, SimCubeMolecule] = marketModelMonteCarlo(MODEL, ASSET, CHANGE, numIterations, numWorkers);

Nsim = size(SimCubeBranded, 1);
fprintf('Ran %d simulations, elapsed time = %1.1f sec\n', Nsim, toc(tStart));

STAT = computeSimStats(SimCubeBranded);

fprintf('Computed Percentile Statistics, elapsed time = %1.1f sec\n', toc(tStart));

outFileName = sprintf('Output\\S_ModelOutputs_%s.xlsx', datestr(now, 'yyyy-mm-dd_HHMMSS'));
EOUT_Branded = writeEnsembleOutputs(outFileName, 'Branded', SimCubeBranded, dateGrid, MODEL, ASSET);
EOUT_Molecule = writeEnsembleOutputs(outFileName, 'Molecule', SimCubeMolecule, dateGrid, MODEL, ASSET);

%% Produce various outputs for a single realization

simNum = 1;

sharePerAssetMonthlySeries = squeeze(SimCubeBranded(simNum, :, :));

uClass = unique(ASSET.Therapy_Class);
Nc = length(uClass);
Nt = size(sharePerAssetMonthlySeries, 2);
sharePerClassMonthlySeries = zeros(Nc, Nt);

for m = 1:Nc
    ix = find(strcmpi(uClass(m), ASSET.Therapy_Class));
    sharePerClassMonthlySeries(m,:) = nansum(EOUT_Branded.Mean.PointShare(ix, :), 1);    
end

OUT = computeOutputs(MODEL, ASSET, dateGrid, sharePerAssetMonthlySeries);

[annualDates, annualBrandedShare] = annualizeMx(dateGrid, EOUT_Branded.Mean.PointShare, 'mean');


if doPlots
    figure; plot(dateGrid, 1-nansum(EOUT_Molecule.Mean.PointShare)); datetick; grid on; timeCursor(false);
            title('Sum-To-One Error');
    
    figure; semilogy(dateGrid, EOUT_Molecule.Mean.PointShare); datetick; grid on; title('Share Per Asset');
            legend(ASSET.Assets_Rated, 'Location', 'EastOutside'); timeCursor(false);

    figure; hA = area(dateGrid, EOUT_Molecule.Mean.PointShare'); datetick; grid on; axis tight;
            title('Share Per Asset - Molecule Mean Monthly'); 
            legend(hA(end:-1:1), ASSET.Assets_Rated(end:-1:1), 'Location', 'EastOutside'); timeCursor(false);
            
    figure; hA = area(dateGrid, EOUT_Branded.Mean.PointShare'); datetick; grid on; axis tight;
            title('Share Per Asset - Branded Mean Monthly'); 
            legend(hA(end:-1:1), ASSET.Assets_Rated(end:-1:1), 'Location', 'EastOutside'); timeCursor(false);
            
    figure; hA = area(annualDates, annualBrandedShare'); grid on; axis tight;
            title('Share Per Asset - Branded Mean Annually'); 
            legend(hA(end:-1:1), ASSET.Assets_Rated(end:-1:1), 'Location', 'EastOutside'); timeCursor(false);

    figure; hA = area(dateGrid, sharePerClassMonthlySeries'); datetick; grid on; axis tight;
            title('Share Per Class - Branded Mean Monthly'); 
            legend(hA(end:-1:1), uClass(end:-1:1), 'Location', 'EastOutside'); timeCursor(false);            
    
    figure; semilogy(dateGrid, EOUT_Branded.Mean.Units); datetick; grid on; 
            title('Units per Asset - Branded Mean Monthly');
            legend(ASSET.Assets_Rated, 'Location', 'EastOutside'); timeCursor(false);

    figure; semilogy(dateGrid, EOUT_Branded.Mean.NetRevenues); datetick; grid on; 
            title('Net Revenues per Asset - Branded Mean Monthly');
            legend(ASSET.Assets_Rated, 'Location', 'EastOutside'); timeCursor(false);

end


%% Plot one Asset


if doPlots
    aNum = 9;  % asset number to plot
    figure; 
    plot(dateGrid, STAT.Percentile90(aNum,:), dateGrid, STAT.Percentile50(aNum,:), dateGrid, STAT.Percentile10(aNum,:));
    legend({'90th %ile', '50th %ile', '10th %ile'});
    title(sprintf('Monthly Share Percentiles: %s', ASSET.Assets_Rated{aNum}));
    datetick; grid on; timeCursor(false);
        
    figure; cdfplot(SimCubeBranded(:, aNum, Nt)); 
    title(sprintf('CDF of final share over %d sims for Asset %d.  PTRS=%1.1f%%', Nsim, aNum, ASSET.Scenario_PTRS{aNum} * 100));
   
end


tElapsed = toc(tStart);
fprintf('Run complete, elapsed time = %1.2f sec\n', tElapsed);
