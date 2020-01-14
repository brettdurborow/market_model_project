function [ASSET, MODEL, debug] = importAssetSheet(fileName, assetSheet, SIMULATION)

    fileInfo = dir(fileName);

    [~,~,raw]  = xlsread(fileName, assetSheet);
    raw = removeEmptyTrailing(raw);
    
    ixHeader = find(strcmpi('Country', raw(:,1)));  % Find header row for big Asset table

    %% Model-wide assumptions

    [ixRow, ~] = find(strcmpi('Country  Selected >>', raw));

    MODEL = struct;
    MODEL.FileName = fileName;
    MODEL.FileDate = fileInfo.date;
    MODEL.AssetSheet = assetSheet;
    MODEL.CountrySelected = raw{ixRow, 3};
    MODEL.ScenarioSelected = raw{ixRow, 10};

    MODEL.ProfileWeight = raw{ixRow+1, 3};
    MODEL.OrderOfEntryWeight = raw{ixRow+2, 3};
    
    MODEL.ProfileElasticity = raw{ixRow, 24};
    MODEL.ClassOeElasticity = raw{ixRow+1, 24};
    % 5-Nov-2019: in-class elasticity is being replaced with values being
    % read from the 'Class' sheet.
    %MODEL.ProductOeElasticity = raw{ixRow+2, 24};
    MODEL.BarrierElasticity = raw{ixRow+3, 24};
    
    ix = find(strcmpi(MODEL.CountrySelected, SIMULATION.Country));
    if length(ix) ~= 1
        error('Error in file: "%s", sheet: "%s". Expected 1 occurence of country: %s.  Found %d', ...
                fileName, assetSheet, MODEL.CountrySelected, length(ix));
    end
    MODEL.Pop = SIMULATION.Pop{ix};
    MODEL.SubPop = SIMULATION.SubPop{ix};
    MODEL.PCP_Factor = SIMULATION.PCP_Factor{ix};
    MODEL.Tdays = SIMULATION.Tdays{ix};
    % New additional columns to model
    MODEL.aMDD_Price = SIMULATION.aMDD_Price{ix};
    MODEL.SubPop_Growth = SIMULATION.SubPop_Growth{ix};
    MODEL.SubPop_Floor_Ceiling = SIMULATION.SubPop_Floor_Ceiling{ix};
    MODEL.PCP_Factor_Growth = SIMULATION.PCP_Factor_Growth{ix};
    MODEL.PCP_Factor_Floor_Ceiling = SIMULATION.PCP_Factor_Floor_Ceiling{ix};
    MODEL.Tdays_Growth = SIMULATION.Tdays_Growth{ix};
    MODEL.Tdays_Floor_Ceiling = SIMULATION.Tdays_Floor_Ceiling{ix};
    MODEL.Pop_Growth = SIMULATION.Pop_Growth{ix};    MODEL.Tdays_Growth = SIMULATION.Tdays_Growth{ix};
    MODEL.Tdays_Floor_Ceiling = SIMULATION.Tdays_Floor_Ceiling{ix};
    MODEL.Pop_Growth = SIMULATION.Pop_Growth{ix};
    MODEL.Pop_Floor_Ceiling = SIMULATION.Pop_Floor_Ceiling{ix};
    MODEL.Concomitant_Rate = SIMULATION.Concomitant_Rate{ix};
    MODEL.Concomitant_Growth = SIMULATION.Concomitant_Growth{ix};
    MODEL.Concomitant_Floor_Ceiling = SIMULATION.Concomitant_Floor_Ceiling{ix};
    MODEL.Market_DOT = SIMULATION.Market_DOT{ix};
    MODEL.Market_DOT_Growth = SIMULATION.Market_DOT_Growth{ix};
    MODEL.Market_DOT_Floor_Ceiling = SIMULATION.Market_DOT_Floor_Ceiling{ix};

    % Entries having only the one entry for all countries
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
    
    %!RC
    % MODEL.ScenarioSelected -> "Scenario PTRS"
    originalFieldNames = ["Country", "Assets Rated","FORCE" "Company1","Company2",...
        "Phase","Starting Share", "Starting Share Year","Starting Share Month",...
        "Follow On", "Barriers", "Calibration", ...
        "Therapy Class", "Launch Year", "Launch Month", "LOE Year", "LOE Month",...
        "Efficacy", "S&T", "Delivery", "Product p", "Product q", ...
        "Class p", "Class q", "LOE p", "LOE q", "LOE %",...
        "Avg Therapy Days","Launch Price / DOT","Price Change","Price Ceiling / Floor",...
        "GTN %","GTN Change","GTN Ceiling / Floor","Units per DOT","Unique ID"];
    
    %Convert the fieldnames to usable struct indices
    newFieldNames=regexprep(originalFieldNames,...
        ["/ ","[\s&]","[%]","FORCE"],...
        ["","_","Pct","Force_toggle"]);
    
       
    % Convert the header row to string and check for matches with the fields
    Header=string(raw(ixHeader,:));
    ind_Scenario= Header==string(MODEL.ScenarioSelected);
    ind_Header=find(Header.contains(originalFieldNames));
    
    % Extract the data from the cells and convert to struct
    % Basically, we have a 2d cell array, and we want to convert the string
    % data into strings and the numeric data into numeric!
    rawAsset=raw(ixHeader+1:end,ind_Header);
    
    asset=struct;
    asset.Scenario_PTRS=raw(ixHeader+1:end,ind_Scenario);
    for i=1:length(newFieldNames)
        asset.(newFieldNames(i))=raw(ixHeader+1:end,ind_Header(i));
    end
    
    % The following selects those columns with the debugging keyword and
    % will assert that it may only contain PTRS values of either 0 or 1. So
    % that only 1 iteration is needed.
    debugKeyword="Scenario";
    ind_debug=find(Header.startsWith(debugKeyword));
    debugNames=Header(ind_debug);
    
    % Strip out the invalid characters for the name
    debugFields=regexprep(debugNames,["\s\+\s","\s","[\+=]"],["_","_","_"]);
    
    % Select and populate the debug structure
    debug=struct('Scenario_names',debugFields,'Scenario_PTRS',logical(cell2mat(raw(ixHeader+1:end,ind_debug))));
    
    ix = string(asset.Country) == MODEL.CountrySelected;
    asset = structSelect(asset, ix, 1);  % Return only the country being modeled
    
    Nrows = length(asset.Country);
    
    fieldsToCheck = {'Country', 'Assets_Rated', 'Starting_Share', 'Starting_Share_Year', ...
        'Starting_Share_Month', 'Scenario_PTRS', 'Barriers', 'Calibration', ...
        'Therapy_Class', 'Launch_Year', 'Launch_Month', 'LOE_Year', 'LOE_Month',...
        'Efficacy', 'S_T', 'Delivery', 'Product_p', 'Product_q', ...
        'Class_p', 'Class_q', 'LOE_p', 'LOE_q', 'LOE_Pct'};
    
    validateFields(asset, assetSheet, fieldsToCheck, Nrows);
    asset = validateFollowOn(asset, assetSheet);
   
    %This asset section needs to be replaced completely!!!!
    ASSET = struct;
    ASSET = parseColumn(ASSET, raw, ixHeader, assetSheet, fileName, 'Country');
    ASSET = parseColumn(ASSET, raw, ixHeader, assetSheet, fileName, 'Assets Rated');
    ASSET = parseColumn(ASSET, raw, ixHeader, assetSheet, fileName, 'Company1');
    ASSET = parseColumn(ASSET, raw, ixHeader, assetSheet, fileName, 'Company2');
    ASSET = parseColumn(ASSET, raw, ixHeader, assetSheet, fileName, 'FORCE', 'Force_toggle', false);
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
    ASSET = parseColumn(ASSET, raw, ixHeader, assetSheet, fileName, 'Unique ID');
    
    ix = strcmpi(MODEL.CountrySelected, ASSET.Country);
    ASSET = structSelect(ASSET, ix, 1);  % Return only the country being modeled
    
    Nrows = length(ASSET.Country);
    
    fieldsToCheck = {'Country', 'Assets_Rated', 'Starting_Share', 'Starting_Share_Year', ...
        'Starting_Share_Month', 'Scenario_PTRS', 'Barriers', 'Calibration', ...
        'Therapy_Class', 'Launch_Year', 'Launch_Month', 'LOE_Year', 'LOE_Month',...
        'Efficacy', 'S_T', 'Delivery', 'Product_p', 'Product_q', ...
        'Class_p', 'Class_q', 'LOE_p', 'LOE_q', 'LOE_Pct'};
    
    validateFields(ASSET, assetSheet, fieldsToCheck, Nrows);
    ASSET = validateFollowOn(ASSET, assetSheet);

    % Convert Force_toggle output to be missing rather than NaN
    ASSET.Force_toggle=string(ASSET.Force_toggle);
    
    %% Postprocess some DATE fields to get them in the expected datatype
    ASSET.Launch_Date = datenum(cell2mat(ASSET.Launch_Year), cell2mat(ASSET.Launch_Month), 1);
    ASSET.LOE_Date = datenum(cell2mat(ASSET.LOE_Year), cell2mat(ASSET.LOE_Month), 1);
    ASSET.Starting_Share_Date = datenum(cell2mat(ASSET.Starting_Share_Year), cell2mat(ASSET.Starting_Share_Month), 1);
    sDates = unique(ASSET.Starting_Share_Date);
    if length(sDates) ~= 1
        error('Expected Starting Share Year and Month to be equal across all assets');
    end    
    
    % Attach the original set of assets to the debug
    debug.asset=convert_asset(ASSET);
 
    %% Remove those assets and change events with FORCE == 'OFF'
    ixF = strcmpi(ASSET.Force_toggle, 'OFF');
    ASSET = structSelect(ASSET, ~ixF, 1);
    %debug.Scenario_PTRS(ixF,:)=[];

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
    errStrVec = false(1, length(fieldNames));
    for m = 1:length(fieldNames)
        validMx(:,m) = ~cellisnan(DATA.(fieldNames{m}));
        
        ixStr = cellfun(@isstr, DATA.(fieldNames{m}));  % find rows that are char data
        ixErrStr = regexpi(DATA.(fieldNames{m})(ixStr), 'error'); % for those that are, find the ones with the word "error" in them
        errStrVec(m) = any(~cellfun(@isempty, ixErrStr));
    end
    ixAll = all(validMx, 2);
    ixAny = any(validMx, 2);
    ixErr = ixAny & ~ixAll;
    if any(ixErr)
        ixErrCol = any(~validMx(ixErr,:), 1);
        error('Found missing data in sheet: "%s". Please ensure each row is either empty or complete. Problem columns: %s', ...
            sheetName, strjoin(fieldNames(ixErrCol), ', '));
    end
    if any(errStrVec)
        error('Found "ERROR" messages in sheet: "%s".  Please check values in columns: %s', ...
            sheetName, strjoin(fieldNames(errStrVec), ', '));
    end
end

function DATA = validateFollowOn(DATA, sheetName)
    ixFO = ~cellisnan(DATA.Follow_On);
    followOn = DATA.Follow_On(ixFO);
    assetNames = DATA.Assets_Rated;
    [Lia, Locb] = ismember(followOn, assetNames);   
    if ~all(Lia)
        error('Found a problem in sheet: "%s".  Follow-on name does not exist in the "Assets Rated" column: %s', ...
            sheetName, strjoin(followOn(~Lia), ', '));
    end
    DATA.Scenario_PTRS(ixFO) = DATA.Scenario_PTRS(Locb);
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