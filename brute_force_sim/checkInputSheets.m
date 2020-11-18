function [assetSheets, ceSheets, simuSheet] = checkInputSheets(fileName)
% Build a list of Asset sheets in this workbook
[~, sheets, ~] = xlsfinfo(fileName);
%Find simulation sheet
simuSheet = sum(strcmpi(sheets, 'Simulation')) == 1;  % look for a sheet called "Simulation"

% Find asset sheets
assetSheets=cellfun(@(s) ~isempty(s) && length(s)==1 ,regexp(sheets,'^[1-7]$'));
ceSheets=cellfun(@(s) ~isempty(s) && length(s)==3,regexp(sheets,'^[1-7]CE$'));
end
