
%% Read assumptions from Excel file on disk
doPlots = true;
tStart = tic;

fileName = '.\Data\MATLABv33.xlsb';

[MODEL, ASSET, CHANGE] = importAssumptions(fileName);

tImport = tic;
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

rng(100);  % set random number seed.  Remove this after debugging

Nsim = 10;
SimSet = cell(Nsim,1);
for m = 1:Nsim    
%     isLaunch = rand(Na,1) <= cell2mat(ASSET.Scenario_PTRS);
    isLaunch = cell2mat(ASSET.Launch_Simulation) == 1;       % Temporary - make it match the Excel sheet

    isChange = rand(Nchange,1) <= cell2mat(CHANGE.Scenario_PTRS);    
    
    SIM = marketModelOneRealization(MODEL, ASSET, CHANGE, isLaunch, isChange);
    SimSet{m} = SIM;
end

STAT = computeSimStats(SimSet);

%% Plot one Asset


if doPlots
    aNum = 9;  % asset number to plot
    figure; 
    plot(SIM.DateGrid, STAT.Percentile90(aNum,:), SIM.DateGrid, STAT.Percentile50(aNum,:), SIM.DateGrid, STAT.Percentile10(aNum,:));
    legend({'90th %ile', '50th %ile', '10th %ile'});
    title(sprintf('Monthly Share Percentiles: %s', ASSET.Assets_Rated{aNum}));
    datetick; grid on; timeCursor(false);
        
end

%% Produce various outputs for a single realization

simNum = 1;
SIM = SimSet{simNum};
dateGrid = SIM.DateGrid;
sharePerAssetMonthlySeries = SIM.SharePerAssetMonthlySeries;

uClass = unique(ASSET.Therapy_Class);
Nc = length(uClass);
Nt = size(sharePerAssetMonthlySeries, 2);
sharePerClassMonthlySeries = zeros(Nc, Nt);

for m = 1:Nc
    ix = find(strcmpi(uClass(m), ASSET.Therapy_Class));
    sharePerClassMonthlySeries(m,:) = nansum(sharePerAssetMonthlySeries(ix, :), 1);    
end

OUT = computeOutputs(MODEL, ASSET, SIM.DateGrid, SIM.SharePerAssetMonthlySeries);

if doPlots
    figure; plot(dateGrid, 1-nansum(sharePerAssetMonthlySeries)); datetick; grid on; timeCursor(false);
    
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

tElapsed = toc(tImport);
fprintf('Run complete, elapsed time = %1.2f sec\n', tElapsed);
