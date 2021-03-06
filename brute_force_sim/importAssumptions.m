function [cMODEL, cASSET, Tc,cDEBUG] = importAssumptions(fileName)

    
    [filepath, name, ext] = fileparts(fileName);
    shortName = [name, ext];
    hWait = waitbar(0, sprintf('Opening File: %s', shortName));
    cleanWaitbar=onCleanup(@()delete(hWait));
    
    fileInfo = dir(fileName);    
    [status, sheets, xlFormat] = xlsfinfo(fileName);

    % Find sheets matching a single string digit in range 1 thru 7
    ind_assetSheets= cellfun(@(s) ~isempty(s) && length(s)==1 ,regexp(sheets,'^[0-9]*$'));
    assetSheets=sheets(ind_assetSheets);
    
    % Assert that there is at least one Asset sheet
    assert(~isempty(assetSheets),'[ERROR]: There must be at least one Asset sheet named 1,2,..., etc.')
    
    Nwait = length(assetSheets) + 1;
    
    sanitizer=@(f) regexprep(f,{'^([0-9])','\W'},{'a$1','_'});
    %% Read the "Simulation" sheet
    sheetName1 = 'Simulation';
    % first, make sure it exists
    assert(any(strcmp(sheets,sheetName1)),'[ERROR]: The sheet Simulation must exist in the input Excel file')
    
    waitbar(1/Nwait, hWait, sprintf('Reading File: %s, Sheet: %s', shortName, sheetName1));
    [~,~,raw]  = xlsread(fileName, sheetName1);
    raw = removeEmptyTrailing(raw);
    
    
    expectedFields1 = {'Pop', 'SubPop', 'PCP Factor', 'Tdays','aMDD_Price','SubPop Growth'...
        ,'SubPop Floor Ceiling','PCP Factor Growth','PCP Factor Floor Ceiling',...
        'Tdays Growth','Tdays Floor Ceiling','Pop Growth','Pop Floor Ceiling',...
        'Concomitant Rate','Concomitant Growth','Concomitant Floor Ceiling',...
        'Market DOT','Market DOT Growth','Market DOT Floor Ceiling'};
    expectedFields2 = {'Rest of EMEA Bump Up from EU5', 'Rest of AP Bump Up from EU5', ...
        'CA Bump Up from EU5', 'LA Bump Up from EU5'};
    fnames = vertcat({'Country'},sanitizer(raw(2:20,1)));

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
    
    cDEBUG = cell(length(assetSheets), 1);
    %fprintf('timing asset sheets\n')
    %tic
    for m = 1:length(assetSheets)
        waitbar((m+1)/Nwait, hWait, sprintf('Reading File: %s, Sheet: %s', shortName, assetSheets{m}),hWait);
        [ASSET, MODEL, DEBUG] = importAssetSheet(fileName, assetSheets{m}, SIMULATION);
        cASSET{m} = convert_asset(ASSET);
        cMODEL{m} = MODEL;
        cDEBUG{m} = DEBUG;
    end
    
    % Read Class sheet and convert to table:
    [A,B]=xlsread(fileName,'Class');
    Tc=table(string(B(2:end,1)),string(B(2:end,2)),A(:,1),A(:,2),A(:,3),'VariableNames',{'Country','Therapy_Class','Starting_Share','InClassOEProductElasticity','InClassPMProductElasticity'});
    
    % We have to further assume that the class starting share is not
    % normalized. Thus, we normalize it here.
    for country=unique(Tc.Country,'stable')'
        normalization_factor=sum(Tc.Starting_Share(Tc.Country==country));
        Tc.Starting_Share(Tc.Country==country)=Tc.Starting_Share(Tc.Country==country)/normalization_factor;
    end
    
    %toc    
end


%%  Helper functions


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
