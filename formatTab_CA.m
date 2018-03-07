function celltab = formatTab_CA(cMODEL, cASSET, BENCH)
% format output for Tableau
% CA = by Country, by Asset

    if length(cMODEL) ~= length(cASSET)
        error('Expected two equal-length cell arrays of structs as inputs');
    end
    
    colHead = {'Country', 'Scenario Run', 'Run Date', 'Asset', ...
               'Company1', 'Company2', 'Launch', 'LOE Date', 'Class', ...
               'PTRS', 'Phase', 'Starting Share', 'Starting Share Date', ...
               'Follow On Asset', 'Asset p', 'Asset q', 'Class p', 'Class q', ...
               'LOE %', 'LOE p', 'LOE q', 'Therapy Days'};
             
    nRows = 0;
    for m = 1:length(cASSET)
        ASSET = cASSET{m};
        nRows = nRows + length(ASSET.Assets_Rated);
    end
    celltab = cell(nRows+1, length(colHead));
    celltab(1,:) = colHead;
           
    rr = 1;
    for m = 1:length(cASSET)
        MODEL = cMODEL{m};
        ASSET = cASSET{m};
        runTime = datestr(BENCH.RunTime(m), 'yyyy-mm-dd HH:MM:SS'); 
        
        launchDates = round(datenumToYearFraction(ASSET.Launch_Date) * 100);
        loeDates = round(datenumToYearFraction(ASSET.LOE_Date) * 100);
        startingShareDates = round(datenumToYearFraction(ASSET.Starting_Share_Date) * 100);        
        
        for n = 1:length(ASSET.Assets_Rated)
            rr = rr + 1;
            celltab{rr, 1} = ASSET.Country{n};
            celltab{rr, 2} = MODEL.ScenarioSelected;
            celltab{rr, 3} = runTime;
            celltab{rr, 4} = ASSET.Assets_Rated{n};
            celltab{rr, 5} = ASSET.Company1{n};
            celltab{rr, 6} = ASSET.Company2{n};
            celltab{rr, 7} = sprintf('%d', launchDates(n));
            celltab{rr, 8} = sprintf('%d', loeDates(n));
            celltab{rr, 9} = ASSET.Therapy_Class{n};
            celltab{rr, 10} = ASSET.Scenario_PTRS{n};
            celltab{rr, 11} = ASSET.Phase{n};
            celltab{rr, 12} = ASSET.Starting_Share{n};
            celltab{rr, 13} = sprintf('%d', startingShareDates(n));
            celltab{rr, 14} = ASSET.Follow_On{n};
            celltab{rr, 15} = ASSET.Product_p{n};
            celltab{rr, 16} = ASSET.Product_q{n};
            celltab{rr, 17} = ASSET.Class_p{n};
            celltab{rr, 18} = ASSET.Class_q{n};
            celltab{rr, 19} = ASSET.LOE_Pct{n};
            celltab{rr, 20} = ASSET.LOE_p{n};
            celltab{rr, 21} = ASSET.LOE_q{n};
            celltab{rr, 22} = ASSET.Avg_Therapy_Days{n};            
        end
    end

end