function celltab = formatTab_Outputs(cMODEL, cASSET, cESTAT, BENCH)
% format output for Tableau
% Outputs of all simulations in the set

    colHead = {'Country', 'Scenario Run', 'Run Date', 'Asset', ...
               'Output Metric', 'Period', 'Period Type', 'Branded Net Revenues', ...
               'Branded Point Share', 'Branded Patient Share', 'Branded Units', ...
               'Molecule Point Share', 'Molecule Patient Share', 'PTRS %', 'Constraints'};
              
    oStats = {'Mean', 'StdErr', 'Pct01', 'Pct05', 'Pct10', 'Pct15', 'Pct20', ...
              'Pct25', 'Pct30', 'Pct35', 'Pct40', 'Pct45', 'Pct50', 'Pct55', ...
              'Pct60', 'Pct65', 'Pct70', 'Pct75', 'Pct80', 'Pct85', 'Pct90', ...
              'Pct95', 'Pct99'};
          
    oStatsBrief = {'Mean', 'StdErr', 'Pct10', 'Pct25', 'Pct50', 'Pct75', 'Pct90'};
    
    % Produce Regional Revenue-only monthly sims
    [cMODEL_R, cASSET_R, cRESTAT_R] = bumpUpRegions(cMODEL, cASSET, cESTAT);
   
    nAsset = 0;  % Count the number of rows to preallocate
    for m = 1:length(cASSET)
        nAsset = nAsset + length(cASSET{m}.Assets_Rated);
    end
    nAsset_R = 0;
    for m = 1:length(cASSET_R)
        nAsset_R = nAsset_R + length(cASSET_R{m}.Assets_Rated);        
    end
    nPeriod = 2040 - 2014 + 1;
    nRows = nAsset * length(oStatsBrief) * nPeriod + nAsset * length(oStats) * 2;
    nRows_R = nAsset_R * length(oStatsBrief) * nPeriod + nAsset_R * length(oStats) * 2;
    
    celltab = cell(nRows + nRows_R + 100, length(colHead));
    celltab(1,:) = colHead;

    rr = 1;
    for m = 1:length(cMODEL)
        MODEL = cMODEL{m};
        ASSET = cASSET{m};
        ESTAT = cESTAT{m};
        runTime = datestr(BENCH.RunTime(m), 'yyyy-mm-dd HH:MM:SS'); 
        
        dateGrid = ESTAT.DateGrid;
                
        for q = 1:length(oStats)
            monthlyShareMxB = ESTAT.Branded.(oStats{q});
            monthlyShareMxM = ESTAT.Molecule.(oStats{q});
            OUTB = computeOutputs(MODEL, ASSET, dateGrid, monthlyShareMxB);
            OUTM = computeOutputs(MODEL, ASSET, dateGrid, monthlyShareMxM);
            ixYear = find(OUTB.Y.YearVec >= 2014 & OUTB.Y.YearVec <= 2040);  % Ignore years out of this range
            
            for n = 1:length(ASSET.Assets_Rated)
                
                if ismember(oStats{q}, oStatsBrief)  % For yearly data, write brief stats only
                    for p = 1:length(ixYear)
                        rr = rr + 1;
                        celltab{rr, 1} = MODEL.CountrySelected;
                        celltab{rr, 2} = MODEL.ScenarioSelected;
                        celltab{rr, 3} = runTime;
                        celltab{rr, 4} = ASSET.Assets_Rated{n};
                        celltab{rr, 5} = oStats{q};
                        celltab{rr, 6} = OUTB.Y.YearVec(ixYear(p));
                        celltab{rr, 7} = 'Year';
                        celltab{rr, 8} = OUTB.Y.NetRevenues(n, ixYear(p));
                        celltab{rr, 9} = OUTB.Y.PointShare(n, ixYear(p));
                        celltab{rr, 10} = OUTB.Y.PatientShare(n, ixYear(p));
                        celltab{rr, 11} = OUTB.Y.Units(n, ixYear(p));
                        celltab{rr, 12} = OUTM.Y.PointShare(n, ixYear(p));
                        celltab{rr, 13} = OUTM.Y.PatientShare(n, ixYear(p));
                        celltab{rr, 14} = ASSET.Scenario_PTRS{n};
                        celltab{rr, 15} = 'None';
                    end
                end
                
                % Cume and Peak values for years up to and including the year after LOE
                ix = (OUTB.Y.YearVec >= 2014) & (OUTB.Y.YearVec <= (ASSET.LOE_Year{n} + 1));

                % Peak Values -----------------------------
                rr = rr + 1;
                celltab{rr, 1} = MODEL.CountrySelected;
                celltab{rr, 2} = MODEL.ScenarioSelected;
                celltab{rr, 3} = runTime;
                celltab{rr, 4} = ASSET.Assets_Rated{n};
                celltab{rr, 5} = oStats{q};
                celltab{rr, 6} = '';  % no text in a numeric "Year" column
                celltab{rr, 7} = 'Peak';
                if sum(ix) > 0
                    peak8 = nanmax(OUTB.Y.NetRevenues(n, ix));
                    peak9 = nanmax(OUTB.Y.PointShare(n, ix));
                    peak10 = nanmax(OUTB.Y.PatientShare(n, ix));
                    peak11 = nanmax(OUTB.Y.Units(n, ix));
                    peak12 = nanmax(OUTM.Y.PointShare(n, ix));
                    peak13 = nanmax(OUTM.Y.PatientShare(n, ix));
                    
                    celltab(rr, 8:13) = {peak8, peak9, peak10, peak11, peak12, peak13};
                else
                    celltab(rr, 8:13) = {0, 0, 0, 0, 0, 0};                    
                end
                celltab{rr, 14} = ASSET.Scenario_PTRS{n};
                celltab{rr, 15} = 'None';
                
                % Cume Values -----------------------------
                rr = rr + 1;
                celltab{rr, 1} = MODEL.CountrySelected;
                celltab{rr, 2} = MODEL.ScenarioSelected;
                celltab{rr, 3} = runTime;
                celltab{rr, 4} = ASSET.Assets_Rated{n};
                celltab{rr, 5} = oStats{q};
                celltab{rr, 6} = '';  % no text in a numeric "Year" column               
                celltab{rr, 7} = 'Cume';
                if sum(ix) > 0
                    cume8  = nansum(OUTB.Y.NetRevenues(n, ix));
                    cume11 = nansum(OUTB.Y.Units(n, ix));

                    celltab(rr, 8:13) = {cume8, nan, nan, cume11, nan, nan};
                else
                    celltab(rr, 8:13) = {0, nan, nan, 0, nan, nan};               
                end
                celltab{rr, 14} = ASSET.Scenario_PTRS{n};
                celltab{rr, 15} = 'None';
            end
            
        end
    end  % Normal (non-regional) simulation outputs
    
    % Now write Regional simulation outputs -------------------------------
    % RESTAT is different from ESTAT used above.  It's already in terms of revenue and units
    % Don't need to call computeOutputs() here
    
    for m = 1:length(cMODEL_R)        
        MODEL = cMODEL_R{m};
        ASSET = cASSET_R{m};
        RESTAT = cRESTAT_R{m};
        runTime = datestr(BENCH.RunTime(end), 'yyyy-mm-dd HH:MM:SS'); 
        
        yearVec = RESTAT.Branded.Y.YearVec;
                
        for q = 1:length(oStats)
            ixYear = find(yearVec >= 2014 & yearVec <= 2040);  % Ignore years out of this range
            
            for n = 1:length(ASSET.Assets_Rated)
                
                if ismember(oStats{q}, oStatsBrief)  % For yearly data, write brief stats only
                    for p = 1:length(ixYear)
                        rr = rr + 1;
                        celltab{rr, 1} = MODEL.CountrySelected;
                        celltab{rr, 2} = MODEL.ScenarioSelected;
                        celltab{rr, 3} = runTime;
                        celltab{rr, 4} = ASSET.Assets_Rated{n};
                        celltab{rr, 5} = oStats{q};
                        celltab{rr, 6} = yearVec(ixYear(p));
                        celltab{rr, 7} = 'Year';
                        celltab{rr, 8} = RESTAT.Branded.Y.NetRevenues.(oStats{q})(n, ixYear(p));
                        celltab{rr, 9} = nan;
                        celltab{rr, 10} = nan;
                        celltab{rr, 11} = RESTAT.Branded.Y.Units.(oStats{q})(n, ixYear(p));
                        celltab{rr, 12} = nan;
                        celltab{rr, 13} = nan;
                        celltab{rr, 14} = nan;
                        celltab{rr, 15} = 'None';
                    end                
                end
                
                % Cume and Peak values for years up to and including the year after LOE
                ix = (yearVec >= 2014) & (yearVec <= (ASSET.LOE_Year{n} + 1));

                % Peak Values -----------------------------
                rr = rr + 1;
                celltab{rr, 1} = MODEL.CountrySelected;
                celltab{rr, 2} = MODEL.ScenarioSelected;
                celltab{rr, 3} = runTime;
                celltab{rr, 4} = ASSET.Assets_Rated{n};
                celltab{rr, 5} = oStats{q};
                celltab{rr, 6} = '';  % no text in a numeric "Year" column
                celltab{rr, 7} = 'Peak';
                if sum(ix) > 0
                    peak8  = nanmax(RESTAT.Branded.Y.NetRevenues.(oStats{q})(n, ix));
                    peak11 = nanmax(RESTAT.Branded.Y.Units.(oStats{q})(n, ix));                   
                    celltab(rr, 8:13) = {peak8, nan, nan, peak11, nan, nan};
                else
                    celltab(rr, 8:13) = {0, nan, nan, 0, nan, nan};                    
                end
                celltab{rr, 14} = nan;
                celltab{rr, 15} = 'None';
                
                % Cume Values -----------------------------
                rr = rr + 1;
                celltab{rr, 1} = MODEL.CountrySelected;
                celltab{rr, 2} = MODEL.ScenarioSelected;
                celltab{rr, 3} = runTime;
                celltab{rr, 4} = ASSET.Assets_Rated{n};
                celltab{rr, 5} = oStats{q};
                celltab{rr, 6} = '';  % no text in a numeric "Year" column               
                celltab{rr, 7} = 'Cume';
                if sum(ix) > 0
                    cume8  = nansum(RESTAT.Branded.Y.NetRevenues.(oStats{q})(n, ix));
                    cume11 = nansum(RESTAT.Branded.Y.Units.(oStats{q})(n, ix));

                    celltab(rr, 8:13) = {cume8, nan, nan, cume11, nan, nan};
                else
                    celltab(rr, 8:13) = {0, nan, nan, 0, nan, nan};               
                end
                celltab{rr, 14} = nan;
                celltab{rr, 15} = 'None';
                
            end
            
        end
    end
    
    
    

    celltab = celltab(1:rr, :); % Remove any trailing blanks
end    