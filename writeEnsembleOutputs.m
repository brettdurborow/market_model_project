function EOUT = writeEnsembleOutputs(outFileName, outSheetName, SimCube, dateGrid, MODEL, ASSET)


%     tmp = squeeze(mean(SimCube, 1));
%     tmp = squeeze(median(SimCube, 1));
%     tmp = squeeze(prctile(SimCube, 95, 1));
%     tmp = squeeze(prctile(SimCube, 65, 1));
%     tmp = squeeze(prctile(SimCube, 5, 1));
%         
%     figure; hA = area(dateGrid, tmp'); datetick; grid on; axis tight;
%             title('Share Per Asset'); 
%             legend(hA(end:-1:1), ASSET.Assets_Rated(end:-1:1), 'Location', 'EastOutside'); timeCursor(false);

    
%     mean(netRev(simCube)) = netRev(mean(simCube))
    
%     [Nr, Na, Nd] = size(SimCube); % Realizations, Assets, Dates
%     NetRevCube = nan(Nr, Na, Nd);
%     for m = 1:Nr
%         sharePerAssetMonthlySeries = squeeze(SimCube(m,:,:));
%         OUT = computeOutputs(MODEL, ASSET, dateGrid, sharePerAssetMonthlySeries);
%         NetRevCube(m, :, :) = OUT.NetRevenues;        
%     end
%     
%     NetRevP05_a = squeeze(prctile(NetRevCube, 5, 1));
%     
%     ShareP05 = squeeze(prctile(SimCube, 5, 1));
%     OUT = computeOutputs(MODEL, ASSET, dateGrid, ShareP05);
%     NetRevP05_b = OUT.NetRevenues;
%             
%     figure; plot(dateGrid, NetRevP05_a' - NetRevP05_b'); datetick; grid on; axis tight;
%     figure; plot(dateGrid, sum(NetRevP05_a - NetRevP05_b)); datetick; grid on; axis tight;
%     
%     [yearVec, statMx] = annualizeMx(dateGrid, NetRevP05_b, 'sum');
%     figure; plot(yearVec, statMx); grid on; 
%     
%     name = 'Net Revenues 5th Percentile';
%     cTab = buildCellTable(name, ASSET, yearVec, statMx, 'sum');
    

    rowNum = 1;
    cTab0 = [{'InputFile:', MODEL.FileName}; ...
             {'InputSaveDate:', MODEL.FileDate}; ...
             {'Scenario:', MODEL.ScenarioSelected}];
    xlswrite(outFileName, cTab0, outSheetName, sprintf('A%d', rowNum));         
    rowNum = rowNum + size(cTab0, 1) + 1;
    
    data = squeeze(mean(SimCube, 1));
    OUT = computeOutputs(MODEL, ASSET, dateGrid, data);
    EOUT.Mean = OUT;
    cTab1 = buildCellTable('Net Revenue: Mean', ASSET, dateGrid, OUT.NetRevenues, 'sum');
    cTab2 = buildCellTable('Units: Mean', ASSET, dateGrid, OUT.Units, 'sum');
    cTab3 = buildCellTable('Point Share: Mean', ASSET, dateGrid, OUT.PointShare, 'mean');
    cTab4 = buildCellTable('Patient Share: Mean', ASSET, dateGrid, OUT.PatientShare, 'mean');
    cTab5 = buildCellTable('Price Per DOT: Mean', ASSET, dateGrid, OUT.PricePerDot, 'mean');
    cTab6 = buildCellTable('GTN: Mean', ASSET, dateGrid, OUT.GTN, 'mean');

    Nr = size(cTab1, 1) + 1;
    xlswrite(outFileName, cTab1, outSheetName, sprintf('A%d', rowNum)); 
    rowNum = rowNum + Nr;
    xlswrite(outFileName, cTab2, outSheetName, sprintf('A%d', rowNum)); 
    rowNum = rowNum + Nr;
    xlswrite(outFileName, cTab3, outSheetName, sprintf('A%d', rowNum)); 
    rowNum = rowNum + Nr;
    xlswrite(outFileName, cTab4, outSheetName, sprintf('A%d', rowNum)); 
    rowNum = rowNum + Nr;
    xlswrite(outFileName, cTab5, outSheetName, sprintf('A%d', rowNum)); 
    rowNum = rowNum + Nr;
    xlswrite(outFileName, cTab6, outSheetName, sprintf('A%d', rowNum)); 
    
    % Variables:  
        % Mean Net Revenues
        % Mean Branded Point Share
        % Mean Branded Patient Share
        % Mean Branded Units        
    % Statistics: Mean, 10, 25, 50 75, 90
    % Annual averages
    % Across years: Cumulative and Peak
    % the revenue table has the PTRS and the company 
    

end


function cTab = buildCellTable(name, ASSET, dateGrid, statMx, method)
    [yearVec, yearStatMx] = annualizeMx(dateGrid, statMx, method);

    [Na, Nd] = size(yearStatMx);
    cTab = cell(Na+2, Nd + 6);
    % Columns: AssetName, LOE_Date, PTRS, Company, Data, Cumulative, Peak
    cTab(1,1) = {name};
    cTab(2, :) = [{'AssetName', 'LOE_Date', 'PTRS', 'Company'}, num2cell(yearVec), {'Cumulative', 'Peak'}];
    cTab(3:end, 1) = ASSET.Assets_Rated;
    cTab(3:end, 2) = num2cell(year(ASSET.LOE_Date) + month(ASSET.LOE_Date) / 12);
    cTab(3:end, 3) = ASSET.Scenario_PTRS;
    cTab(3:end, 4) = ASSET.Company1;
    cTab(3:end, 5:Nd+4) = num2cell(yearStatMx);  % The actual data
    cTab(3:end, end-1) = num2cell(sum(yearStatMx, 2));
    cTab(3:end, end) = num2cell(max(yearStatMx, [], 2));    

end