function [MODEL, ASSET, CHANGE] = importAssumptions(fileName)


    sheetName1 = 'Assets';
    [~,~,raw]  = xlsread(fileName, sheetName1);
    sheetName2 = 'ChangeEvents';
    [~,~,raw2] = xlsread(fileName, sheetName2);
    
    raw = removeEmptyTrailing(raw);
    raw2 = removeEmptyTrailing(raw2);

    ixHeader = find(strcmpi('Country', raw(:,1)));  % Find header row for big Asset table

    
    %% Model-wide assumptions

    [ixRow, ~] = find(strcmpi('Scenario Selected >>', raw));

    MODEL = struct;
    MODEL.CountrySelected = raw{ixRow, 3};
    MODEL.ScenarioSelected = raw{ixRow, 11};
    MODEL.ProfileWeight = raw{ixRow+1, 3};
    MODEL.OrderOfEntryWeight = raw{ixRow+2, 3};
%     MODEL.WillingToPayForTreatment = raw{ixRow+1, 9};  % No longer used
    MODEL.ProfileElasticity = raw{ixRow, 26};
    MODEL.ClassOeElasticity = raw{ixRow+1, 26};
    MODEL.ProductOeElasticity = raw{ixRow+2, 26};
    
    % Find & parse Patient Population stats for the selected country
    [ixR, ixC] = find(strcmpi('Pop', raw(1:ixHeader,:)));
    if ~strcmpi(raw{ixR+1, ixC}, 'SubPop') || ~strcmpi(raw{ixR+2, ixC}, 'PCP Factor') || ~strcmpi(raw{ixR+3, ixC}, 'Tdays')
        error('Expected table with "Pop", "SubPop", "PCP Factor", "Tdays" to appear in Assets sheet');
    end
    ixCountryCol = find(strcmpi(MODEL.CountrySelected, raw(ixR-1, ixC+1:end)));
    if isempty(ixCountryCol)
        error('Could not find country code: "%s" in patient population stats table on Assets sheet', MODEL.CountrySelected);
    end
    MODEL.Pop = raw{ixR, ixC+ixCountryCol};
    MODEL.SubPop = raw{ixR+1, ixC+ixCountryCol};
    MODEL.PCP_Factor = raw{ixR+2, ixC+ixCountryCol};
    MODEL.Tdays = raw{ixR+3, ixC+ixCountryCol};
        
    fnames = fieldnames(MODEL);
    for m = 1:length(fnames)
        if isnan(MODEL.(fnames{m}))
            error('Missing value in field: %s.  Please check input worksheet.', fnames{m});
        end
    end

    %% Assets
    

    ASSET = struct;
    ASSET = parseColumn(ASSET, raw, ixHeader, 'Country');
    ASSET = parseColumn(ASSET, raw, ixHeader, 'Assets Rated');
    ASSET = parseColumn(ASSET, raw, ixHeader, 'Phase');
    ASSET = parseColumn(ASSET, raw, ixHeader, 'Starting Share');
    ASSET = parseColumn(ASSET, raw, ixHeader, 'Starting Share Year');
    ASSET = parseColumn(ASSET, raw, ixHeader, 'Starting Share Month');
    ASSET = parseColumn(ASSET, raw, ixHeader, 'Benchmark PTRS');
    ASSET = parseColumn(ASSET, raw, ixHeader, MODEL.ScenarioSelected, 'Scenario_PTRS');
    
    ASSET = parseColumn(ASSET, raw, ixHeader, 'Launch Simulation');

    ASSET = parseColumn(ASSET, raw, ixHeader, 'Patient Barriers', 'Patient_Barriers', false);
    ASSET = parseColumn(ASSET, raw, ixHeader, 'Branded Access Barriers');

    ASSET = parseColumn(ASSET, raw, ixHeader, 'Therapy Class');

    ASSET = parseColumn(ASSET, raw, ixHeader, 'Launch Year');
    ASSET = parseColumn(ASSET, raw, ixHeader, 'Launch Month');

    ASSET = parseColumn(ASSET, raw, ixHeader, 'LOE Year');
    ASSET = parseColumn(ASSET, raw, ixHeader, 'LOE Month');

    ASSET = parseColumn(ASSET, raw, ixHeader, 'Total Preference Score');
    
    ASSET = parseColumn(ASSET, raw, ixHeader, 'Product p');
    ASSET = parseColumn(ASSET, raw, ixHeader, 'Product q');
    ASSET = parseColumn(ASSET, raw, ixHeader, 'Class p');
    ASSET = parseColumn(ASSET, raw, ixHeader, 'Class q');
    
    ASSET = parseColumn(ASSET, raw, ixHeader, 'LOE p');
    ASSET = parseColumn(ASSET, raw, ixHeader, 'LOE q');
    ASSET = parseColumn(ASSET, raw, ixHeader, 'LOE %', 'LOE_Pct');
    
    ASSET = parseColumn(ASSET, raw, ixHeader, 'Avg Therapy Days');
    ASSET = parseColumn(ASSET, raw, ixHeader, 'Launch Price / DOT', 'Launch_Price_DOT');
    ASSET = parseColumn(ASSET, raw, ixHeader, 'Price Change');
    ASSET = parseColumn(ASSET, raw, ixHeader, 'Price Ceiling / Floor', 'Price_Ceiling_Floor');
    ASSET = parseColumn(ASSET, raw, ixHeader, 'GTN %', 'GTN_Pct');
    ASSET = parseColumn(ASSET, raw, ixHeader, 'GTN Change');
    ASSET = parseColumn(ASSET, raw, ixHeader, 'GTN Ceiling / Floor', 'GTN_Ceiling_Floor');
    ASSET = parseColumn(ASSET, raw, ixHeader, 'Units per DOT');
    
    ix = strcmpi(MODEL.CountrySelected, ASSET.Country);
    ASSET = structSelect(ASSET, ix, 1);  % Return only the country being modeled
    
    Nrows = length(ASSET.Country);
    
    fieldsToCheck = {'Country', 'Assets_Rated', 'Starting_Share', 'Starting_Share_Year', ...
        'Starting_Share_Month', 'Scenario_PTRS', 'Patient_Barriers', ...
        'Branded_Access_Barriers', 'Therapy_Class', 'Launch_Year', 'Launch_Month', ...
        'LOE_Year', 'LOE_Month', 'Total_Preference_Score', ...
        'Product_p', 'Product_q', 'Class_p', 'Class_q', 'LOE_p', 'LOE_q', 'LOE_Pct'};
    
    validateFields(ASSET, sheetName2, fieldsToCheck, Nrows);    
    
    %% Change Events

    [ixHeader, ~] = find(strcmpi('Country', raw2));

    CHANGE = struct;
    CHANGE = parseColumn(CHANGE, raw2, ixHeader, 'Country');
    CHANGE = parseColumn(CHANGE, raw2, ixHeader, 'Asset');
    CHANGE = parseColumn(CHANGE, raw2, ixHeader, 'Event');
    CHANGE = parseColumn(CHANGE, raw2, ixHeader, 'Company');
    CHANGE = parseColumn(CHANGE, raw2, ixHeader, 'Phase');
    CHANGE = parseColumn(CHANGE, raw2, ixHeader, 'Benchmark PTRS');
    CHANGE = parseColumn(CHANGE, raw2, ixHeader, MODEL.ScenarioSelected, 'Scenario_PTRS');
    CHANGE = parseColumn(CHANGE, raw2, ixHeader, 'Patient Barriers', 'Patient_Barriers', false);
    CHANGE = parseColumn(CHANGE, raw2, ixHeader, 'Branded Access Barriers');
    CHANGE = parseColumn(CHANGE, raw2, ixHeader, 'Therapy Class');
    CHANGE = parseColumn(CHANGE, raw2, ixHeader, 'Launch Year');
    CHANGE = parseColumn(CHANGE, raw2, ixHeader, 'Launch Month');
    CHANGE = parseColumn(CHANGE, raw2, ixHeader, 'LOE Year');
    CHANGE = parseColumn(CHANGE, raw2, ixHeader, 'LOE Month');
    CHANGE = parseColumn(CHANGE, raw2, ixHeader, 'Total Preference Score');
    
    ix = strcmpi(MODEL.CountrySelected, CHANGE.Country);
    CHANGE = structSelect(CHANGE, ix, 1);  % Return only the country being modeled
    Nrows = length(CHANGE.Country);

    ix = ~cellisempty(CHANGE.Asset) & ~cellisnan(CHANGE.Asset);  % remove empty rows
    CHANGE = structSelect(CHANGE, ix, 1);    
    
    fieldsToCheck = {'Country', 'Asset', 'Scenario_PTRS', 'Patient_Barriers', ...
        'Branded_Access_Barriers', 'Therapy_Class', 'Launch_Year', 'Launch_Month', ...
        'LOE_Year', 'LOE_Month', 'Total_Preference_Score'};
    
    validateFields(CHANGE, sheetName2, fieldsToCheck, Nrows);
    
end

%%

function DATA = parseColumn(DATA, xlsRaw, ixHeader, columnName, fieldName, isExact)
    if nargin < 6
        isExact = true;
    end
    if isExact
        ixCol = find(strcmpi(columnName, xlsRaw(ixHeader, :)));
    else
        ixCol = find(strncmpi(columnName, xlsRaw(ixHeader, :), length(columnName)));
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