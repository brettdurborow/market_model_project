
%% Read assumptions from Excel file on disk
doPlots = false;
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

%% Run many realizations, collect stats at the end

rng(100);  % set random number seed.  Remove this after debugging

Nsim = 1000;
SimSet = cell(Nsim,1);
for m = 1:Nsim
    SIM = marketModelOneRealization(MODEL, ASSET, CHANGE, doPlots);
    SimSet{m} = SIM;
end



%% Produce various outputs

OUT = computeOutputs(MODEL, ASSET, SIM.DateGrid, SIM.SharePerAssetMonthlySeries);

if doPlots
    figure; semilogy(SIM.DateGrid, OUT.Units); datetick; grid on; title('Units');
            legend(ASSET.Assets_Rated, 'Location', 'EastOutside'); timeCursor(false);

    figure; semilogy(SIM.DateGrid, OUT.NetRevenues); datetick; grid on; title('Net Revenues');
            legend(ASSET.Assets_Rated, 'Location', 'EastOutside'); timeCursor(false);

end

tElapsed = toc(tImport);
fprintf('Run complete, elapsed time = %1.2f sec\n', tElapsed);
