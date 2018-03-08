function celltab = formatTab_Outputs(cMODEL, cASSET, cESTAT, BENCH)
% format output for Tableau
% Outputs of all simulations in the set

    colHead = {'Country', 'Scenario Run', 'Run Date', 'Asset', ...
               'Output Metric', 'Period', 'Net Revenues', 'Branded Point Share', ...
               'Branded Patient Share', 'Branded Units', 'PTRS %'};

            
    oMetrics = {'Pct10', 'Pct25', 'Pct50', 'Pct75', 'Pct90', 'Mean', 'StdErr'};           
    metNames = {'Percentile 10', 'Percentile 25', 'Percentile 50', ...
                'Percentile 75', 'Percentile 90', 'Mean', 'Standard Error'};           
   
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
                
        for q = 1:length(oMetrics)
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
                    celltab{rr, 5} = metNames{q};
                    celltab{rr, 6} = OUT.Y.YearVec(ixYear(p));
                    celltab{rr, 7} = OUT.Y.NetRevenues(n, ixYear(p));
                    celltab{rr, 8} = OUT.Y.PointShare(n, ixYear(p));
                    celltab{rr, 9} = OUT.Y.PatientShare(n, ixYear(p));
                    celltab{rr, 10} = OUT.Y.Units(n, ixYear(p));
                    celltab{rr, 11} = ASSET.Scenario_PTRS{n};
                end
                
                % Cume and Peak values for years up to and including the year after LOE
                
                
            end
            
        end
    end





end    