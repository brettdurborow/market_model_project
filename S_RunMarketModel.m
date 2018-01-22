
%% Read assumptions from Excel file on disk
doPlots = true;
tStart = tic;

fileName = '.\Data\MATLABv33.xlsb';

[MODEL, ASSET, CHANGE] = importAssumptions(fileName);

fprintf('Imported Data, elapsed time = %1.1f sec\n', toc(tStart));

ASSET.Launch_Date = datenum(cell2mat(ASSET.Launch_Year), cell2mat(ASSET.Launch_Month), 1);
ASSET.LOE_Date = datenum(cell2mat(ASSET.LOE_Year), cell2mat(ASSET.LOE_Month), 1);
ASSET.Starting_Share_Date = datenum(cell2mat(ASSET.Starting_Share_Year), cell2mat(ASSET.Starting_Share_Month), 1);
sDates = unique(ASSET.Starting_Share_Date);
if length(sDates) ~= 1
    error('Expected Starting Share Year and Month to be equal across all assets');
end

CHANGE.Launch_Date = datenum(cell2mat(CHANGE.Launch_Year), cell2mat(CHANGE.Launch_Month), 1);
CHANGE.LOE_Date = datenum(cell2mat(CHANGE.LOE_Year), cell2mat(CHANGE.LOE_Month), 1);
CHANGE = structSort(CHANGE, {'Launch_Date'});  % sort by launch date in ascending order

Na = length(ASSET.Scenario_PTRS);
Nchange = length(CHANGE.Scenario_PTRS);


%% Run many realizations, collect stats at the end

% rng(100);  % set random number seed.  Remove this after debugging
% 
% isLaunch = cell2mat(ASSET.Launch_Simulation) == 1;   % Temporary - make it match the Excel sheet
% isChange = true(size(CHANGE.Scenario_PTRS));
% SIM = marketModelOneRealization(MODEL, ASSET, CHANGE, isLaunch, isChange);  % one once to initialize
% dateGrid = SIM.DateGrid;
% Nt = length(dateGrid);
% 
% Nsim = 10000;
% SimSet = cell(Nsim,1);
% SimCube = zeros(Nsim, Na, Nt);  % 3D data cube for percentile calcs
% parfor m = 1:Nsim    
%     isLaunch = rand(Na,1) <= cell2mat(ASSET.Scenario_PTRS);
% %     isLaunch = cell2mat(ASSET.Launch_Simulation) == 1;       % Temporary - make it match the Excel sheet
% 
%     isChange = rand(Nchange,1) <= cell2mat(CHANGE.Scenario_PTRS);    
%     
%     SIM = marketModelOneRealization(MODEL, ASSET, CHANGE, isLaunch, isChange);
%     %SimSet{m} = SIM;
%     SimCube(m, :, :) = SIM.SharePerAssetMonthlySeries;
% end

[SimCube, dateGrid] = marketModelMonteCarlo(MODEL, ASSET, CHANGE);

Nsim = size(SimCube, 1);
fprintf('Ran %d simulations, elapsed time = %1.1f sec\n', Nsim, toc(tStart));

STAT = computeSimStats(SimCube);

fprintf('Computed Percentile Statistics, elapsed time = %1.1f sec\n', toc(tStart));


%% Produce various outputs for a single realization

simNum = 1;

sharePerAssetMonthlySeries = squeeze(SimCube(simNum, :, :));

uClass = unique(ASSET.Therapy_Class);
Nc = length(uClass);
Nt = size(sharePerAssetMonthlySeries, 2);
sharePerClassMonthlySeries = zeros(Nc, Nt);

for m = 1:Nc
    ix = find(strcmpi(uClass(m), ASSET.Therapy_Class));
    sharePerClassMonthlySeries(m,:) = nansum(sharePerAssetMonthlySeries(ix, :), 1);    
end

OUT = computeOutputs(MODEL, ASSET, dateGrid, sharePerAssetMonthlySeries);

if doPlots
    figure; plot(dateGrid, 1-nansum(sharePerAssetMonthlySeries)); datetick; grid on; timeCursor(false);
            title('Sum-To-One Error');
    
    figure; semilogy(dateGrid, sharePerAssetMonthlySeries); datetick; grid on; title('Share Per Asset');
            legend(ASSET.Assets_Rated, 'Location', 'EastOutside'); timeCursor(false);

    figure; hA = area(dateGrid, sharePerAssetMonthlySeries'); datetick; grid on; axis tight;
            title('Share Per Asset'); 
            legend(hA(end:-1:1), ASSET.Assets_Rated(end:-1:1), 'Location', 'EastOutside'); timeCursor(false);

    figure; hA = area(dateGrid, sharePerClassMonthlySeries'); datetick; grid on; axis tight;
            title('Share Per Class'); 
            legend(hA(end:-1:1), uClass(end:-1:1), 'Location', 'EastOutside'); timeCursor(false);            
    
    figure; semilogy(dateGrid, OUT.Units); datetick; grid on; title('Units');
            legend(ASSET.Assets_Rated, 'Location', 'EastOutside'); timeCursor(false);

    figure; semilogy(dateGrid, OUT.NetRevenues); datetick; grid on; title('Net Revenues');
            legend(ASSET.Assets_Rated, 'Location', 'EastOutside'); timeCursor(false);

end


%% Plot one Asset


if doPlots
    aNum = 10;  % asset number to plot
    figure; 
    plot(dateGrid, STAT.Percentile90(aNum,:), dateGrid, STAT.Percentile50(aNum,:), dateGrid, STAT.Percentile10(aNum,:));
    legend({'90th %ile', '50th %ile', '10th %ile'});
    title(sprintf('Monthly Share Percentiles: %s', ASSET.Assets_Rated{aNum}));
    datetick; grid on; timeCursor(false);
        
    figure; cdfplot(SimCube(:, aNum, Nt)); 
    title(sprintf('CDF of final share over %d sims for Asset %d.  PTRS=%1.1f%%', Nsim, aNum, ASSET.Scenario_PTRS{aNum} * 100));
   
end


tElapsed = toc(tStart);
fprintf('Run complete, elapsed time = %1.2f sec\n', tElapsed);
