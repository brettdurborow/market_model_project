function celltab = formatTab_Outputs(cMODEL, cASSET, cESTAT, BENCH)
% format output for Tableau
% Outputs of all simulations in the set

    colHead = {'Country', 'Scenario Run', 'Run Date', 'Asset', ...
               'Output Metric', 'Period', 'Net Revenues', 'Branded Point Share', ...
               'Branded Patient Share', 'Branded Units', 'PTRS %'};
              
    oStats = {'Mean', 'StdErr', 'Pct01', 'Pct05', 'Pct10', 'Pct15', 'Pct20', ...
              'Pct25', 'Pct30', 'Pct35', 'Pct40', 'Pct45', 'Pct50', 'Pct55', ...
              'Pct60', 'Pct65', 'Pct70', 'Pct75', 'Pct80', 'Pct85', 'Pct90', ...
              'Pct95', 'Pct99'};
   
    nAsset = 0;  % Count the number of rows to preallocate
    for m = 1:length(cASSET)
        ASSET = cASSET{m};
        nAsset = nAsset + length(ASSET.Assets_Rated);
    end
    nMetric = 7;
    nPeriod = 26;
    nRows = nAsset * nMetric * nPeriod + 1;
    
    celltab = cell(nRows, length(colHead));
    celltab(1,:) = colHead;

    rr = 1;
    for m = 1:length(cMODEL)
        MODEL = cMODEL{m};
        ASSET = cASSET{m};
        ESTAT = cESTAT{m};
        runTime = datestr(BENCH.RunTime(m), 'yyyy-mm-dd HH:MM:SS'); 
        
        dateGrid = ESTAT.DateGrid;
                
        for q = 1:length(oStats)
            monthlyShareMx = ESTAT.Branded.(oStats{q});  
            OUT = computeOutputs(MODEL, ASSET, dateGrid, monthlyShareMx);
            ixYear = find(OUT.Y.YearVec >= 2014 & OUT.Y.YearVec <= 2040);  % Ignore years out of this range
            
            for n = 1:length(ASSET.Assets_Rated)            
                for p = 1:length(ixYear)
                    rr = rr + 1;
                    celltab{rr, 1} = MODEL.CountrySelected;
                    celltab{rr, 2} = MODEL.ScenarioSelected;
                    celltab{rr, 3} = runTime;
                    celltab{rr, 4} = ASSET.Assets_Rated{n};
                    celltab{rr, 5} = oStats{q};
                    celltab{rr, 6} = OUT.Y.YearVec(ixYear(p));
                    celltab{rr, 7} = OUT.Y.NetRevenues(n, ixYear(p));
                    celltab{rr, 8} = OUT.Y.PointShare(n, ixYear(p));
                    celltab{rr, 9} = OUT.Y.PatientShare(n, ixYear(p));
                    celltab{rr, 10} = OUT.Y.Units(n, ixYear(p));
                    celltab{rr, 11} = ASSET.Scenario_PTRS{n};
                end
                
                % Cume and Peak values for years up to and including the year after LOE
                rr = rr + 1;
                celltab(rr,:) = celltab(rr-1,:);
                celltab{rr,6} = 'Peak';
                ix = (OUT.Y.YearVec >= 2014) & (OUT.Y.YearVec <= (ASSET.LOE_Year{n} + 1));
                if sum(ix) > 0
                    peak7 = nanmax(OUT.Y.NetRevenues(n, ix));
                    peak8 = nanmax(OUT.Y.PointShare(n, ix));
                    peak9 = nanmax(OUT.Y.PatientShare(n, ix));
                    peak10 = nanmax(OUT.Y.Units(n, ix));

                    celltab(rr, 7:10) = {peak7, peak8, peak9, peak10};
                else
                    celltab(rr, 7:10) = {0, 0, 0, 0};                    
                end                
                
                rr = rr + 1;
                celltab(rr,:) = celltab(rr-1,:);
                celltab{rr,6} = 'Cume';
                if sum(ix) > 0
                    cume7  = nansum(OUT.Y.NetRevenues(n, ix));
                    cume10 = nansum(OUT.Y.Units(n, ix));

                    celltab(rr, 7:10) = {cume7, nan, nan, cume10};
                else
                    celltab(rr, 7:10) = {0, nan, nan, 0};               
                end
                
            end
            
        end
    end





end    