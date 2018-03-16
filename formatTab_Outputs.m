function celltab = formatTab_Outputs(cMODEL, cASSET, cESTAT, BENCH)
% format output for Tableau
% Outputs of all simulations in the set

    colHead = {'Country', 'Scenario Run', 'Run Date', 'Asset', ...
               'Output Metric', 'Period', 'Period Type', 'Net Revenues', ...
               'Branded Point Share', 'Branded Patient Share', 'Branded Units', ...
               'PTRS %'};
              
    oStats = {'Mean', 'StdErr', 'Pct01', 'Pct05', 'Pct10', 'Pct15', 'Pct20', ...
              'Pct25', 'Pct30', 'Pct35', 'Pct40', 'Pct45', 'Pct50', 'Pct55', ...
              'Pct60', 'Pct65', 'Pct70', 'Pct75', 'Pct80', 'Pct85', 'Pct90', ...
              'Pct95', 'Pct99'};
          
    oStatsBrief = {'Mean', 'StdErr', 'Pct10', 'Pct25', 'Pct50', 'Pct75', 'Pct90'};
   
    nAsset = 0;  % Count the number of rows to preallocate
    for m = 1:length(cASSET)
        ASSET = cASSET{m};
        nAsset = nAsset + length(ASSET.Assets_Rated);
    end
    nStats = length(oStats) + 2;
    nPeriod = 2040 - 2014 + 1;
    nRows = nAsset * nStats * nPeriod + 1;
    
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
                
                if ismember(oStats{q}, oStatsBrief)  % only write brief stats for each year
                    for p = 1:length(ixYear)
                        rr = rr + 1;
                        celltab{rr, 1} = MODEL.CountrySelected;
                        celltab{rr, 2} = MODEL.ScenarioSelected;
                        celltab{rr, 3} = runTime;
                        celltab{rr, 4} = ASSET.Assets_Rated{n};
                        celltab{rr, 5} = oStats{q};
                        celltab{rr, 6} = OUT.Y.YearVec(ixYear(p));
                        celltab{rr, 7} = 'Year';
                        celltab{rr, 8} = OUT.Y.NetRevenues(n, ixYear(p));
                        celltab{rr, 9} = OUT.Y.PointShare(n, ixYear(p));
                        celltab{rr, 10} = OUT.Y.PatientShare(n, ixYear(p));
                        celltab{rr, 11} = OUT.Y.Units(n, ixYear(p));
                        celltab{rr, 12} = ASSET.Scenario_PTRS{n};
                    end
                end
                
                % Cume and Peak values for years up to and including the year after LOE
                rr = rr + 1;
                celltab(rr,:) = celltab(rr-1,:);
                celltab{rr,6} = '';  % no text in a numeric "Year" column
                celltab{rr,7} = 'Peak';
                ix = (OUT.Y.YearVec >= 2014) & (OUT.Y.YearVec <= (ASSET.LOE_Year{n} + 1));
                if sum(ix) > 0
                    peak8 = nanmax(OUT.Y.NetRevenues(n, ix));
                    peak9 = nanmax(OUT.Y.PointShare(n, ix));
                    peak10 = nanmax(OUT.Y.PatientShare(n, ix));
                    peak11 = nanmax(OUT.Y.Units(n, ix));

                    celltab(rr, 8:11) = {peak8, peak9, peak10, peak11};
                else
                    celltab(rr, 8:11) = {0, 0, 0, 0};                    
                end                
                
                rr = rr + 1;
                celltab(rr,:) = celltab(rr-1,:);
                celltab{rr,6} = '';  % no text in a numeric "Year" column               
                celltab{rr,7} = 'Cume';
                if sum(ix) > 0
                    cume8  = nansum(OUT.Y.NetRevenues(n, ix));
                    cume11 = nansum(OUT.Y.Units(n, ix));

                    celltab(rr, 8:11) = {cume8, nan, nan, cume11};
                else
                    celltab(rr, 8:11) = {0, nan, nan, 0};               
                end
                
            end
            
        end
    end
    celltab = celltab(1:rr, :); % Remove any trailing blanks


end    