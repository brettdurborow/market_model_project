function [cMODEL, cASSET, cCHANGE] = importAssumptions(fileName)

    
    [filepath, name, ext] = fileparts(fileName);
    shortName = [name, ext];
    hWait = waitbar(0, sprintf('Opening File: %s', shortName));

    fileInfo = dir(fileName);    
    [status, sheets, xlFormat] = xlsfinfo(fileName);

    % Build a list of Asset sheets in this workbook
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
    
    Nwait = length(assetSheets) + 1;

    
    %% Read the "Simulation" sheet

    sheetName1 = 'Simulation';
    waitbar(1/Nwait, hWait, sprintf('Reading File: %s, Sheet: %s', shortName, sheetName1));
    [~,~,raw]  = xlsread(fileName, sheetName1);
    raw = removeEmptyTrailing(raw);
    
    
    expectedFields1 = {'Pop', 'SubPop', 'PCP Factor', 'Tdays'};
    expectedFields2 = {'Rest of EMEA Bump Up from EU5', 'Rest of AP Bump Up from EU5', ...
                        'CA Bump Up from EU5', 'LA Bump Up from EU5'};
        
    fnames = {'Country'};
    for row = 2:5
        fnames{end+1} = cleanFieldName(raw{row, 1});
    end
    SIMULATION = struct;
    ixE = find(~cellisnan(raw(1,:)), 1, 'last');    
    for m = 1:length(fnames)
        SIMULATION.(fnames{m}) = raw(m, 2:ixE);
    end
    ixBad = [];
    for m = 1:length(expectedFields1)
        if ~ismember(cleanFieldName(expectedFields1{m}), fnames)
            ixBad(end+1) = m;
        end       
    end
    if ~isempty(ixBad)
        error('Error in File: %s. Unable to find expected fields: %s', fileName, strjoin(expectedFields1(ixBad), ', '));
    end
    
    for m = 1:length(expectedFields2)
        [ixR, ixC] = find(strcmpi(expectedFields2{m}, raw));
        if length(ixR) == 1
            SIMULATION.(cleanFieldName(expectedFields2{m})) = raw{ixR, ixC+1};
        else
            error('Error in file: %s.  Unable to find expected field: %s', fileName, expectedFields2{m})
        end
        
    end
    
        
    %% Read and cache the set of Asset and Change Events sheets
    
    cASSET = cell(length(assetSheets), 1);
    cMODEL = cell(length(assetSheets), 1);
    cCHANGE = cell(length(assetSheets), 1);
    for m = 1:length(assetSheets)
        waitbar((m+1)/Nwait, hWait, sprintf('Reading File: %s, Sheet: %s', shortName, assetSheets{m}));
        [ASSET, MODEL, CHANGE] = importAssetSheet(fileName, assetSheets{m}, ceSheets{m}, SIMULATION);
        cASSET{m} = ASSET;
        cMODEL{m} = MODEL;
        cCHANGE{m} = CHANGE;        
    end
    close(hWait);
    
end


%%  Helper functions

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