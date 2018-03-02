function [ASSET, MODEL, CHANGE] = importAssetSheet(fileName, assetSheet, ceSheet, SIMULATION)

    fileInfo = dir(fileName);

    [~,~,raw]  = xlsread(fileName, assetSheet);
    raw = removeEmptyTrailing(raw);
    
    raw2 = {};
    try
        if ~isempty(ceSheet)
            [~,~,raw2] = xlsread(fileName, ceSheet);
            raw2 = removeEmptyTrailing(raw2);
        end
    catch
        warning('Error when reading file %s and sheet %s', fileName, ceSheet);
    end
    
    ixHeader = find(strcmpi('Country', raw(:,1)));  % Find header row for big Asset table

    %% Model-wide assumptions

    [ixRow, ~] = find(strcmpi('Country  Selected >>', raw));

    MODEL = struct;
    MODEL.FileName = fileName;
    MODEL.FileDate = fileInfo.date;
    MODEL.AssetSheet = assetSheet;
    MODEL.ChangeEventSheet = ceSheet;
    MODEL.CountrySelected = raw{ixRow, 3};
    MODEL.ScenarioSelected = raw{ixRow, 10};

    MODEL.ProfileWeight = raw{ixRow+1, 3};
    MODEL.OrderOfEntryWeight = raw{ixRow+2, 3};
    
    MODEL.ProfileElasticity = raw{ixRow, 24};
    MODEL.ClassOeElasticity = raw{ixRow+1, 24};
    MODEL.ProductOeElasticity = raw{ixRow+2, 24};
    MODEL.BarrierElasticity = raw{ixRow+3, 24};
    
    % Find & parse Patient Population stats for the selected country
%     [ixR, ixC] = find(strcmpi('Pop', raw(1:ixHeader,:)));
%     if ~strcmpi(raw{ixR+1, ixC}, 'SubPop') || ~strcmpi(raw{ixR+2, ixC}, 'PCP Factor') || ~strcmpi(raw{ixR+3, ixC}, 'Tdays')
%         error('Expected table with "Pop", "SubPop", "PCP Factor", "Tdays" to appear in Assets sheet');
%     end
%     ixCountryCol = find(strcmpi(MODEL.CountrySelected, raw(ixR-1, ixC+1:end)));
%     if isempty(ixCountryCol)
%         error('Could not find country code: "%s" in patient population stats table on Assets sheet', MODEL.CountrySelected);
%     end
%     MODEL.Pop = raw{ixR, ixC+ixCountryCol};
%     MODEL.SubPop = raw{ixR+1, ixC+ixCountryCol};
%     MODEL.PCP_Factor = raw{ixR+2, ixC+ixCountryCol};
%     MODEL.Tdays = raw{ixR+3, ixC+ixCountryCol};

    ix = find(strcmpi(MODEL.CountrySelected, SIMULATION.Country));
    if length(ix) ~= 1
        error('Error in file: "%s", sheet: "%s". Expected 1 occurence of country: %s.  Found %d', ...
                fileName, assetSheet, MODEL.CountrySelected, length(ix));
    end
    MODEL.Pop = SIMULATION.Pop{ix};
    MODEL.SubPop = SIMULATION.SubPop{ix};
    MODEL.PCP_Factor = SIMULATION.PCP_Factor{ix};
    MODEL.Tdays = SIMULATION.Tdays{ix};
    MODEL.Rest_of_EMEA_Bump_Up_from_EU5 = SIMULATION.Rest_of_EMEA_Bump_Up_from_EU5;
    MODEL.Rest_of_AP_Bump_Up_from_EU5 = SIMULATION.Rest_of_AP_Bump_Up_from_EU5;
    MODEL.CA_Bump_Up_from_EU5 = SIMULATION.CA_Bump_Up_from_EU5;
    MODEL.LA_Bump_Up_from_EU5 = SIMULATION.LA_Bump_Up_from_EU5;
        
    fnames = fieldnames(MODEL);
    for m = 1:length(fnames)
        if isnan(MODEL.(fnames{m}))
            error('Missing value in field: %s.  Please check input worksheet.', fnames{m});
        end
    end


    %% Assets
    

    ASSET = struct;
    ASSET = parseColumn(ASSET, raw, ixHeader, assetSheet, fileName, 'Country');
    ASSET = parseColumn(ASSET, raw, ixHeader, assetSheet, fileName, 'Assets Rated');
    ASSET = parseColumn(ASSET, raw, ixHeader, assetSheet, fileName, 'Company1');
    ASSET = parseColumn(ASSET, raw, ixHeader, assetSheet, fileName, 'Company2');
    ASSET = parseColumn(ASSET, raw, ixHeader, assetSheet, fileName, 'FORCE', 'Force', false);
    ASSET = parseColumn(ASSET, raw, ixHeader, assetSheet, fileName, 'Phase');
    ASSET = parseColumn(ASSET, raw, ixHeader, assetSheet, fileName, 'Starting Share');
    ASSET = parseColumn(ASSET, raw, ixHeader, assetSheet, fileName, 'Starting Share Year');
    ASSET = parseColumn(ASSET, raw, ixHeader, assetSheet, fileName, 'Starting Share Month');
    ASSET = parseColumn(ASSET, raw, ixHeader, assetSheet, fileName, MODEL.ScenarioSelected, 'Scenario_PTRS');
    
    ASSET = parseColumn(ASSET, raw, ixHeader, assetSheet, fileName, 'Follow On');
    ASSET = parseColumn(ASSET, raw, ixHeader, assetSheet, fileName, 'Barriers');
    ASSET = parseColumn(ASSET, raw, ixHeader, assetSheet, fileName, 'Calibration');

    ASSET = parseColumn(ASSET, raw, ixHeader, assetSheet, fileName, 'Therapy Class');

    ASSET = parseColumn(ASSET, raw, ixHeader, assetSheet, fileName, 'Launch Year');
    ASSET = parseColumn(ASSET, raw, ixHeader, assetSheet, fileName, 'Launch Month');

    ASSET = parseColumn(ASSET, raw, ixHeader, assetSheet, fileName, 'LOE Year');
    ASSET = parseColumn(ASSET, raw, ixHeader, assetSheet, fileName, 'LOE Month');
    
    ASSET = parseColumn(ASSET, raw, ixHeader, assetSheet, fileName, 'Efficacy');
    ASSET = parseColumn(ASSET, raw, ixHeader, assetSheet, fileName, 'S&T');
    ASSET = parseColumn(ASSET, raw, ixHeader, assetSheet, fileName, 'Delivery');    
   
    ASSET = parseColumn(ASSET, raw, ixHeader, assetSheet, fileName, 'Product p');
    ASSET = parseColumn(ASSET, raw, ixHeader, assetSheet, fileName, 'Product q');
    ASSET = parseColumn(ASSET, raw, ixHeader, assetSheet, fileName, 'Class p');
    ASSET = parseColumn(ASSET, raw, ixHeader, assetSheet, fileName, 'Class q');
    
    ASSET = parseColumn(ASSET, raw, ixHeader, assetSheet, fileName, 'LOE p');
    ASSET = parseColumn(ASSET, raw, ixHeader, assetSheet, fileName, 'LOE q');
    ASSET = parseColumn(ASSET, raw, ixHeader, assetSheet, fileName, 'LOE %', 'LOE_Pct');
    
    ASSET = parseColumn(ASSET, raw, ixHeader, assetSheet, fileName, 'Avg Therapy Days');
    ASSET = parseColumn(ASSET, raw, ixHeader, assetSheet, fileName, 'Launch Price / DOT', 'Launch_Price_DOT');
    ASSET = parseColumn(ASSET, raw, ixHeader, assetSheet, fileName, 'Price Change');
    ASSET = parseColumn(ASSET, raw, ixHeader, assetSheet, fileName, 'Price Ceiling / Floor', 'Price_Ceiling_Floor');
    ASSET = parseColumn(ASSET, raw, ixHeader, assetSheet, fileName, 'GTN %', 'GTN_Pct');
    ASSET = parseColumn(ASSET, raw, ixHeader, assetSheet, fileName, 'GTN Change');
    ASSET = parseColumn(ASSET, raw, ixHeader, assetSheet, fileName, 'GTN Ceiling / Floor', 'GTN_Ceiling_Floor');
    ASSET = parseColumn(ASSET, raw, ixHeader, assetSheet, fileName, 'Units per DOT');
    
    
    ix = strcmpi(MODEL.CountrySelected, ASSET.Country);
    ASSET = structSelect(ASSET, ix, 1);  % Return only the country being modeled
    
    Nrows = length(ASSET.Country);
    
    fieldsToCheck = {'Country', 'Assets_Rated', 'Starting_Share', 'Starting_Share_Year', ...
        'Starting_Share_Month', 'Scenario_PTRS', 'Barriers', 'Calibration', ...
        'Therapy_Class', 'Launch_Year', 'Launch_Month', ...
        'LOE_Year', 'LOE_Month', 'Product_p', 'Product_q', ...
        'Class_p', 'Class_q', 'LOE_p', 'LOE_q', 'LOE_Pct'};
    
    validateFields(ASSET, assetSheet, fieldsToCheck, Nrows);
    validateFollowOn(ASSET, assetSheet);
    
    
%% Change Events

    CHANGE = struct;

    if isempty(raw2)
        CHANGE.Asset = {};
        CHANGE.Scenario_PTRS = {};        
        CHANGE.Launch_Year = {};  
        CHANGE.Launch_Month = {};  
        CHANGE.LOE_Year = {};  
        CHANGE.LOE_Month = {};          
    else
        [ixHeader, ~] = find(strcmpi('Country', raw2));

        CHANGE = parseColumn(CHANGE, raw2, ixHeader, ceSheet, fileName, 'Country');
        CHANGE = parseColumn(CHANGE, raw2, ixHeader, ceSheet, fileName, 'Asset');
        CHANGE = parseColumn(CHANGE, raw2, ixHeader, ceSheet, fileName, 'Event');
        CHANGE = parseColumn(CHANGE, raw2, ixHeader, ceSheet, fileName, 'Company');
        CHANGE = parseColumn(CHANGE, raw2, ixHeader, ceSheet, fileName, 'Phase');
        CHANGE = parseColumn(CHANGE, raw2, ixHeader, ceSheet, fileName, 'Benchmark PTRS');
        CHANGE = parseColumn(CHANGE, raw2, ixHeader, ceSheet, fileName, MODEL.ScenarioSelected, 'Scenario_PTRS');
        CHANGE = parseColumn(CHANGE, raw2, ixHeader, ceSheet, fileName, 'Barriers');
        CHANGE = parseColumn(CHANGE, raw2, ixHeader, ceSheet, fileName, 'Calibration');
        CHANGE = parseColumn(CHANGE, raw2, ixHeader, ceSheet, fileName, 'Therapy Class');
        CHANGE = parseColumn(CHANGE, raw2, ixHeader, ceSheet, fileName, 'Launch Year');
        CHANGE = parseColumn(CHANGE, raw2, ixHeader, ceSheet, fileName, 'Launch Month');
        CHANGE = parseColumn(CHANGE, raw2, ixHeader, ceSheet, fileName, 'LOE Year');
        CHANGE = parseColumn(CHANGE, raw2, ixHeader, ceSheet, fileName, 'LOE Month');
        CHANGE = parseColumn(CHANGE, raw2, ixHeader, ceSheet, fileName, 'Efficacy');
        CHANGE = parseColumn(CHANGE, raw2, ixHeader, ceSheet, fileName, 'S&T');
        CHANGE = parseColumn(CHANGE, raw2, ixHeader, ceSheet, fileName, 'Delivery');

        ix = strcmpi(MODEL.CountrySelected, CHANGE.Country);
        CHANGE = structSelect(CHANGE, ix, 1);  % Return only the country being modeled
        Nrows = length(CHANGE.Country);

        ix = ~cellisempty(CHANGE.Asset) & ~cellisnan(CHANGE.Asset);  % remove empty rows
        CHANGE = structSelect(CHANGE, ix, 1);    

        fieldsToCheck = {'Country', 'Asset', 'Scenario_PTRS', 'Barriers', ...
            'Calibration', 'Therapy_Class', 'Launch_Year', 'Launch_Month', ...
            'LOE_Year', 'LOE_Month', 'Efficacy', 'S&T', 'Delivery'};

        validateFields(CHANGE, ceSheet, fieldsToCheck, Nrows);
    
    end    
    
    %% Remove those assets and change events with FORCE == 'OFF'
    ixF = strcmpi(ASSET.Force, 'OFF');
    ASSET = structSelect(ASSET, ~ixF, 1);
    if ~isempty(CHANGE.Scenario_PTRS)
        ixCF = ismember(CHANGE.Asset, ASSET.Assets_Rated(ixF));
        CHANGE = structSelect(CHANGE, ~ixCF, 1);
    end
    
    %% Postprocess some DATE fields to get them in the expected datatype
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

end



%% Helper Functions

function DATA = parseColumn(DATA, xlsRaw, ixHeader, sheetName, fileName, columnName, fieldName, isExact)
    if nargin < 8
        isExact = true;
    end
    if isExact
        ixCol = find(strcmpi(columnName, xlsRaw(ixHeader, :)));
    else
        ixCol = find(strncmpi(columnName, xlsRaw(ixHeader, :), length(columnName)));
    end
    if length(ixCol) ~= 1
        error('Error in sheet %s of file: "%s". Expected one occurrence of column: "%s".  Found %d', ...
            sheetName, fileName, columnName, length(ixCol));
    end
    colOut = xlsRaw(ixHeader+1:end, ixCol);
    if ~exist('fieldName', 'var') || isempty(fieldName)
        fieldName = cleanFieldName(cleanFieldName(xlsRaw{ixHeader, ixCol}));
    end
    DATA.(fieldName) = colOut;
end

function raw = removeEmptyTrailing(raw)
    [Nr, Nc] = size(raw);
    ixNullRow = false(Nr,1);
    for m = Nr:-1:1
        if all(cellisnan(raw(m,:)))
            ixNullRow(m) = true;
        else
            break;  % stop at last non-empty row
        end
    end
    ixNullCol = false(1,Nc);
    for m = Nc:-1:1
        if all(cellisnan(raw(:,m)))
            ixNullCol(m) = true;
        else
            break;  % stop at first non-empty column
        end        
    end
    raw = raw(~ixNullRow, ~ixNullCol);
end

function validateFields(DATA, sheetName, fieldNames, Nrows)
    validMx = false(Nrows, length(fieldNames));
    for m = 1:length(fieldNames)
        validMx(:,m) = ~cellisnan(DATA.(fieldNames{m}));
    end
    ixAll = all(validMx, 2);
    ixAny = any(validMx, 2);
    ixErr = ixAny & ~ixAll;
    if any(ixErr)
        ixErrCol = any(~validMx(ixErr,:), 1);
        error('Found missing data in sheet: "%s". Please ensure each row is either empty or complete. Problem columns: %s', ...
            sheetName, strjoin(fieldNames(ixErrCol), ', '));
    end
end

function validateFollowOn(DATA, sheetName)
    followOn = DATA.Follow_On(~cellisnan(DATA.Follow_On));
    assetNames = DATA.Assets_Rated;
    ix = find(~ismember(followOn, assetNames));
    if ~isempty(ix)
        error('Found a problem in sheet: "%s".  Follow-on name does not exist in the "Assets Rated" column: %s', ...
            sheetName, strjoin(followOn(ix), ', '));
    end
end

function textOut = cleanFieldName(textIn) % create a valid struct field name
    ascii = int32(strtrim(textIn));      
    ixNum = ascii >= 48 & ascii <= 57;  % 0 ... 9
    ixUpper = ascii >= 65 & ascii <= 90;   % A ... Z
    ixLower = ascii >= 97 & ascii <= 122';  % a ... z
    ixOk = ixNum | ixUpper | ixLower;
    ascii(~ixOk) = int32('_');
    textOut = char(ascii);
    if ixNum(1)
        textOut = ['a', textOut];
    end
end