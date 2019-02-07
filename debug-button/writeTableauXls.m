function [cTableau, cSheetNames] = writeTableauXls(xlsFileName, cMODEL, cASSET, cESTAT, BENCH)
% caTables is a cellarray of cellarrays.  Each element is a celltab 
% ready to be written to Excel
% caSheetNames must be the same length as caTables.

    cTableau = {};
    cSheetNames = {};
    
    cTableau{end+1} = formatTab_C(cMODEL, BENCH);  % Create output tables for Tableau
    cSheetNames{end+1} = 'Country';
    
    cTableau{end+1} = formatTab_CA(cMODEL, cASSET, BENCH);  % Create output tables for Tableau
    cSheetNames{end+1} = 'Asset';
    
    cTableau{end+1} = formatTab_CAP(cMODEL, cASSET, cESTAT, BENCH);
    cSheetNames{end+1} = 'Period';
    
    cTableau{end+1} = formatTab_Outputs(cMODEL, cASSET, cESTAT, BENCH);
    cSheetNames{end+1} = 'Outputs';
    
    for m = 1:length(cTableau)
        xlswrite(xlsFileName, cTableau{m}, cSheetNames{m});   
    end
end