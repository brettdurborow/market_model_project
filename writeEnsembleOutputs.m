function OUT = writeEnsembleOutputs(outFileName, outSheetName, monthlyShareMx, dateGrid, MODEL, ASSET)  

    rowNum = 1;
    cTab0 = [{'InputFile:', MODEL.FileName}; ...
             {'InputSaveDate:', MODEL.FileDate}; ...
             {'InputAssetSheet:', MODEL.AssetSheet}; ...
             {'InputChangeEventsSheet:', MODEL.ChangeEventSheet}; ...
             {'CountrySelected:', MODEL.CountrySelected}; ...
             {'Scenario:', MODEL.ScenarioSelected}];
    xlswrite(outFileName, cTab0, outSheetName, sprintf('A%d', rowNum));         
    rowNum = rowNum + size(cTab0, 1) + 1;
    
    OUT = computeOutputs(MODEL, ASSET, dateGrid, monthlyShareMx);
    
    cTab1 = buildCellTable('Net Revenue', ASSET, OUT.Y.YearVec, OUT.Y.NetRevenues);
    cTab2 = buildCellTable('Units', ASSET, OUT.Y.YearVec, OUT.Y.Units);
    cTab3 = buildCellTable('Point Share', ASSET, OUT.Y.YearVec, OUT.Y.PointShare);
    cTab4 = buildCellTable('Patient Share', ASSET, OUT.Y.YearVec, OUT.Y.PatientShare);
    cTab5 = buildCellTable('Price Per DOT', ASSET, OUT.Y.YearVec, OUT.Y.PricePerDot);
    cTab6 = buildCellTable('GTN', ASSET, OUT.Y.YearVec, OUT.Y.GTN);

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


function cTab = buildCellTable(name, ASSET, yearVec, yearStatMx)

    [Na, Nd] = size(yearStatMx);
    cTab = cell(Na+2, Nd + 6);
    % Columns: AssetName, LOE_Date, PTRS, Company, Data, Cumulative, Peak
    cTab(1,1) = {name};
    cTab(2, :) = [{'AssetName', 'LOE_Date', 'PTRS', 'Company'}, num2cell(yearVec), {'Cumulative', 'Peak'}];
    cTab(3:end, 1) = ASSET.Assets_Rated;
%     cTab(3:end, 2) = num2cell(year(ASSET.LOE_Date) + (month(ASSET.LOE_Date) - 1) / 12);
    cTab(3:end, 2) = num2cell(datenumToYearFraction(ASSET.LOE_Date));
    cTab(3:end, 3) = ASSET.Scenario_PTRS;
    cTab(3:end, 4) = ASSET.Company1;
    cTab(3:end, 5:Nd+4) = num2cell(yearStatMx);  % The actual data
    cTab(3:end, end-1) = num2cell(sum(yearStatMx, 2));
    cTab(3:end, end) = num2cell(max(yearStatMx, [], 2));    

end