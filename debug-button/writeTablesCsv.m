function [cTables, cFileNames] = writeTablesCsv(outFolder, cMODEL, cASSET, cESTAT, cCNSTR, BENCH)
% Produces several output tables from the simulation results.
% Creates a new folder, then writes a CSV file for each table.

    cTables = {};
    cFileNames = {};
    cFormats = {};
    
    [cTables{end+1}, cFormats{end+1}] = formatTab_C(cMODEL, BENCH);  % Create output tables for Tableau
    cFileNames{end+1} = fullfile(outFolder, 'Country.csv');
    
    [cTables{end+1}, cFormats{end+1}] = formatTab_CA(cMODEL, cASSET, BENCH);  % Create output tables for Tableau
    cFileNames{end+1} = fullfile(outFolder, 'Asset.csv');
    
    [cTables{end+1}, cFormats{end+1}] = formatTab_CAP(cMODEL, cASSET, cESTAT, BENCH);
    cFileNames{end+1} = fullfile(outFolder, 'Period.csv');
    
    [cTables{end+1}, cFormats{end+1}] = formatTab_Outputs(cMODEL, cASSET, cESTAT, BENCH);
    cFileNames{end+1} = fullfile(outFolder, 'Outputs.csv');
    
    [cTables{end+1}, cFormats{end+1}] = formatTab_CNSTR(cCNSTR);  % Create output tables for Tableau
    cFileNames{end+1} = fullfile(outFolder, 'Constraints.csv');
    
    if ~exist(outFolder, 'dir')
        mkdir(outFolder)
    end
    
    for m = 1:length(cTables)
        celltab2csv(cFileNames{m}, cTables{m}, cFormats{m});   
    end
end