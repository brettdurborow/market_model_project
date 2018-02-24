

% % For "class" ranking
% elasticity = 0.2;
% oeVec = oeShare([1 2 2 3], elasticity);
% 
% % For "asset" ranking
% elasticity = -0.5;
% oeVec = oeShare([1 2 3 4 5], elasticity);

%%

%% Read assumptions from Excel file on disk
doPlots = true;
tStart = tic;

fileName = '.\Data\MATLABv33TEST.xlsb';
fileName = '.\Data\aMDD MM v1.6-ES (Inputs).xlsb';

[MODEL, ASSET, CHANGE] = importAssumptions(fileName);

fprintf('Imported Data, elapsed time = %1.1f sec\n', toc(tStart));

Na = length(ASSET.Scenario_PTRS);
Nchange = length(CHANGE.Scenario_PTRS);

%% Run a single controlled realization, to validate model vs. Excel


rng(100);  % set random number seed.  Remove this after debugging

isLaunch = cell2mat(ASSET.Launch_Simulation) == 1;   % Testing purposes
isLaunch = cell2mat(ASSET.Scenario_PTRS) >= 0.5;     % Testing purposes
isChange = false(size(CHANGE.Scenario_PTRS));        % Testing purposes
doDebug = true;
SIM = marketModelOneRealization(MODEL, ASSET, CHANGE, isLaunch, isChange, doDebug);  % one once to initialize
dateGrid = SIM.DateGrid;
Nt = length(dateGrid);

if ~isempty(SIM.DBG)
    outFileName = sprintf('DebugOutput_%s.xlsx', datestr(now, 'yyyy-mm-dd_HHMMSS'));
    xlswrite(outFileName, SIM.DBG.BassClass, 'BassClass');
    xlswrite(outFileName, SIM.DBG.BassClassPrep, 'BassClassPrep');
    
    xlswrite(outFileName, SIM.DBG.ClassOrderOfEntry, 'ClassOrderOfEntry');
    xlswrite(outFileName, SIM.DBG.ClassProfile, 'ClassProfile');
    xlswrite(outFileName, SIM.DBG.ClassAdjFactor, 'ClassAdjFactor');
    xlswrite(outFileName, SIM.DBG.ClassTargetShare, 'ClassTargetShare');
    
    xlswrite(outFileName, SIM.DBG.AssetOrderOfEntry, 'AssetOrderOfEntry');
    xlswrite(outFileName, SIM.DBG.AssetProfile, 'AssetProfile');
    xlswrite(outFileName, SIM.DBG.AssetAdjFactor, 'AssetAdjFactor');
    xlswrite(outFileName, SIM.DBG.AssetTargetShare, 'AssetTargetShare');
end

%% Run many realizations, collect stats at the end

doDebug = false;

rng(100);  % set random number seed.  Remove this after debugging

% isLaunch = cell2mat(ASSET.Launch_Simulation) == 1;   % Temporary - make it match the Excel sheet
% isChange = true(size(CHANGE.Scenario_PTRS));
Na = length(ASSET.Scenario_PTRS);
Nchange = length(CHANGE.Scenario_PTRS);
isLaunch = rand(Na,1) < cell2mat(ASSET.Scenario_PTRS);
isChange = rand(Nchange,1) < cell2mat(CHANGE.Scenario_PTRS);  
SIM = marketModelOneRealization(MODEL, ASSET, CHANGE, isLaunch, isChange, doDebug);  % one once to initialize
dateGrid = SIM.DateGrid;
Nt = length(dateGrid);

Nsim = 10;
SimCube = zeros(Nsim, Na, Nt);  % 3D data cube for percentile calcs
for m = 1:Nsim    
    isLaunch = rand(Na,1) < cell2mat(ASSET.Scenario_PTRS);
%     isLaunch = cell2mat(ASSET.Launch_Simulation) == 1;       % Temporary - make it match the Excel sheet

    isChange = rand(Nchange,1) < cell2mat(CHANGE.Scenario_PTRS);    
    
    SIM = marketModelOneRealization(MODEL, ASSET, CHANGE, isLaunch, isChange, doDebug);
    SimCube(m, :, :) = SIM.SharePerAssetMonthlySeries;
end


fprintf('Ran %d simulations, elapsed time = %1.1f sec\n', Nsim, toc(tStart));

STAT = computeSimStats(SimCube);

fprintf('Computed Percentile Statistics, elapsed time = %1.1f sec\n', toc(tStart));


%% Produce various outputs for a single realization

    simNum = 1;
    sharePerAssetMonthlySeries = squeeze(SimCube(simNum, :, :));

    SIM = marketModelOneRealization(MODEL, ASSET, CHANGE, isLaunch, isChange, doDebug);  % one once to initialize
    sharePerAssetMonthlySeries = SIM.BrandedMonthlyShare;

    uClass = unique(ASSET.Therapy_Class);
    Nc = length(uClass);
    Nt = size(sharePerAssetMonthlySeries, 2);
    sharePerClassMonthlySeries = zeros(Nc, Nt);

    for m = 1:Nc
        ix = find(strcmpi(uClass(m), ASSET.Therapy_Class));
        sharePerClassMonthlySeries(m,:) = nansum(sharePerAssetMonthlySeries(ix, :), 1);    
    end

    OUT = computeOutputs(MODEL, ASSET, dateGrid, sharePerAssetMonthlySeries);

    doPlots = true;  %ToDo: remove this

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
    aNum = 11;  % asset number to plot
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

%% Test Bass diffusion using Michel's example

mathFile = '..\FromMichel\TheMath 2.xlsx';
[~,~,raw]  = xlsread(mathFile, 'Erosion Example');

ixCol = 9:92;
tt_raw = cell2mat(raw(5, ixCol));
loeFactorXLS = cell2mat(raw(2, ixCol));


tt = (tt_raw - tt_raw(1)) + 1/12;
p_LOE = raw{2,7};
q_LOE = raw{2,8};
loeFactorStart = 0;
loeFactorTarget = 0.96;
share = bassDiffusion(tt, p_LOE, q_LOE, loeFactorStart, loeFactorTarget, true);
figure; plot(tt, loeFactorXLS, 'o', tt, share, '-');
legend('XLSX "Erosion Example"', 'MATLAB calculation');

%% New input file format

inputFileName = '.\Data\TheMath 2b.xlsx';
[status, sheets, xlFormat] = xlsfinfo(inputFileName);

assetSheets = {};
for m = 1:length(sheets)
    ascii = double(sheets{m});
    if all(ascii >= 48 & ascii <= 57)
        assetSheets{end + 1} = sheets{m};
    end    
end

% Check for ChangeEvents for each Asset sheet
ceSheets = cell(size(assetSheets));
for m = 1:length(assetSheets)
    ceName = [assetSheets{m}, 'CE'];
    ix = find(strcmpi(sheets, ceName));
    if length(ix) == 1
        ceSheets{m} = sheets{m};
    end
end

tSheets = {'1CE', '2ce', '123Ce', '123CECE'};

assetSheet = '1';
ceSheet = '';
[ASSET, MODEL, CHANGE] = importAssetSheet(inputFileName, assetSheet, ceSheet);

   
[cMODEL, cASSET, cCHANGE] = importAssumptions(inputFileName)
    
    
    
    
