function [celltab, fmt] = formatTab_CAP(cMODEL, cASSET, cESTAT, BENCH)
% format output for Tableau
% CAP = by Country, by Asset, by Period

    colHead = {'Country', 'Scenario Run', 'Run Date', 'Asset', 'Company1', ...
                'Period', 'GTN', 'Price', 'Efficacy', 'S&T', 'Delivery', ...
                'Barrier' 'Acceptability'};
            
%     fmt = '%s,%s,%s,%s,%s,%d,%f,%f,%f,%f,%f,%f,%f\n';  % for writing to CSV
    fmt = '%s,%s,%s,%s,%s,%d,%.8g,%.8g,%.8g,%.8g,%.8g,%.8g,%.8g\n';  % for writing to CSV

    nRows = 0;
    for m = 1:length(cASSET)
        ASSET = cASSET{m};
        nRows = nRows + length(ASSET.Assets_Rated);
    end
    celltab = cell(nRows+1, length(colHead));
    celltab(1,:) = colHead;

    rr = 1;
    for m = 1:length(cMODEL)
        MODEL = cMODEL{m};
        ASSET = cASSET{m};
        ESTAT = cESTAT{m};
        runTime = datestr(BENCH.RunTime(m), 'yyyy-mm-dd HH:MM:SS'); 
        
        % For this report, we just want the yearly outputs that don't depend
        % on share. Run computeOutputs() once, and ignore the share-dependent
        % fields
        dateGrid = ESTAT.DateGrid;
        monthlyShareMx = ESTAT.Branded.Mean;  
        OUT = computeOutputs(MODEL, ASSET, dateGrid, monthlyShareMx);
        
        ixYear = find(OUT.Y.YearVec >= 2014 & OUT.Y.YearVec <= 2040);  % Ignore years out of this range
        
        for n = 1:length(ASSET.Assets_Rated)            
            for p = 1:length(ixYear)
                rr = rr + 1;
                celltab{rr, 1} = MODEL.CountrySelected;
                celltab{rr, 2} = MODEL.ScenarioSelected;
                celltab{rr, 3} = runTime;
                celltab{rr, 4} = ASSET.Assets_Rated{n};
                celltab{rr, 5} = ASSET.Company1{n};
                celltab{rr, 6} = OUT.Y.YearVec(ixYear(p));
                celltab{rr, 7} = OUT.Y.GTN(n, ixYear(p));
                celltab{rr, 8} = OUT.Y.PricePerDot(n, ixYear(p));
                % ToDo: The following fields are subject to ChangeEvents.  Refactor to capture this.
                celltab{rr, 9}  = ASSET.Efficacy{n};
                celltab{rr, 10} = ASSET.S_T{n};
                celltab{rr, 11} = ASSET.Delivery{n};
                celltab{rr, 12} = ASSET.Barriers{n};
                celltab{rr, 13} = ASSET.S_T{n} + ASSET.Delivery{n};
            end
        end
    end
end