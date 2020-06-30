function  sheetNames=extractExcelSheets(file)
% extractExcelSheets is a function to extract the expected sheet data from
% the given excel file.

% Firstly, we require java to unzip xlsx (probably xlsm, too) files
if ~usejava('jvm')
    error(message('MATLAB:xlsread:noJVM'))
end

% Unzip the XLSX file (a ZIP file) to a temporary location
baseDir = tempname;
cleanupBaseDir = onCleanup(@()rmdir(baseDir,'s'));
unzip(file, baseDir);

% Get the all of the sheet names 
sheetNames= sheetNameToIndex(baseDir);
ind_simSheet = find(strcmp(sheetNames,'Simulation'));

% Find sheets names consisting only of numbers
ind_assetSheets= find(cellfun(@(s) ~isempty(s) && length(s)==1 ,regexp(sheetNames,'^[0-9]*$')));
assetSheetNames=sheetNames(ind_assetSheets);

% Sheets that are needed:
% Simulation and at least 1 country
assert(length(ind_simSheet)==1,'[ERROR]: Input file must contain a Simulation sheet');
assert(~isempty(ind_assetSheets),'[ERROR]: Input file must contain at least one Country sheet');

%Read simulation sheet
workSheetFile = fullfile(baseDir, 'xl', 'worksheets', sprintf('sheet%d.xml', ind_simSheet));
sheetData = fileread(workSheetFile);
[parsedSheetData, range] = extractDataAndRange(sheetData);

for i=1:length(ind_assetSheets)
    workSheetFile = fullfile(baseDir, 'xl', 'worksheets', sprintf('sheet%d.xml', ind_assetSheets(i)));
    sheetData = fileread(workSheetFile);
    [parsedSheetData, range] = extractDataAndRange(sheetData);
    
end


end

function sheetNames= sheetNameToIndex(baseDir)
    
    % Look up a worksheet by name (string)
    workbook_xml_rels = fileread(fullfile(baseDir, 'xl', '_rels', 'workbook.xml.rels'));
    workbook_xml = fileread(fullfile(baseDir, 'xl', 'workbook.xml')); 
    
    % From getSheetNames
    sheetIDs = regexp(workbook_xml_rels, ...
                 ['<Relationship[^>]+Id="(?<rid>[^>]+?)"[^>]+(Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet"[^>]+Target="worksheets/[^>]+?.xml"|' ...
                 'Target="worksheets/[^>]+?.xml"[^>]+Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet")[^>]*/>'], ...
                 'names' );
  
    match = regexp(workbook_xml, '<sheet[^>]+name="(?<sheetName>[^"]*)"[^>]*r:id="(?<rid>[^>]+?)"[^>]*/>|<sheet[^>]*r:id="(?<rid>[^>]+?)"[^>]*name="(?<sheetName>[^"]*)"[^>]*/>', 'names');
    
    validSheetIndices = zeros(size(sheetIDs));
    count = 1;
    
    % Match rIDs found in the header with rIDs for sheets in the file.
    % Only return the sheet names of sheet rIDs that are found in the
    % header.
    for i = 1:numel(sheetIDs)
       for j = 1:numel(match)
           if isequal(sheetIDs(i).rid, match(j).rid)
               validSheetIndices(count) = j;
               count = count + 1;
           end
       end
    end
    
    indices = sort(validSheetIndices);
    
    sheetNames = {match(indices).sheetName};
end

function [parsedSheetData, range] = extractDataAndRange(sheetData)
    
    % Use regexp to extract Data from XML tags.
    % CELL class in OpenXML format
    % http://msdn.microsoft.com/en-us/library/documentformat.openxml.spreadsheet.cell.aspx
    parsedSheetData = regexp(sheetData, ...
        ['<c' ...                                            % Begin of cell node
        '\s+r="(?<ranges>[A-Z]+\d+)"' ...                    % "Cell reference" aka range (required)
        '\s*(?:s="\d+")?' ...                          % Style - may contain date format (optional, unused)
        '\s*(?<types>t="(\w+)")?\s*>' ...                    % Cell data type - (optional) http://msdn.microsoft.com/en-us/library/documentformat.openxml.spreadsheet.cellvalues%28office.14%29.aspx
        '\s*(?:<f.*?(>.*?</f>|/>))?' ...            % Formula (optional)
        '\s*<v(?<valAttrib>.*?)(?#4)(/)?>(?<values>(?(4)|.*?))(?(4)|</v>)' ... % Values and value_attributes (required) % 4 is the token number for '/'
        '\s*</c>' ], ...                                     % End of cell node
        'names');
    
    % Determine range of entire sheet (if not passed in by caller)
    span = regexp(sheetData, '<dimension[^>]+ref="(?<start>[A-Z]+\d+)(?<end>:[A-Z]+\d+)?"[^>]*>', 'names', 'once');
    if isempty(span.end)
        span.end = [':' span.start];
    end
    range = [span.start span.end];
    
end

