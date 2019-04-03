function [celltab, fmt] = formatTab_Outputs(cMODEL, cASSET, cESTAT, BENCH)
% format output for Tableau
% Outputs of all simulations in the set

    colHead = {'Country', 'Scenario Run', 'Run Date', 'Asset', ...
               'Output Metric', 'Period', 'Period Type', 'Branded Net Revenues', ...
               'Branded Point Share', 'Branded Patient Share', 'Branded Units', ...
               'Molecule Point Share', 'Molecule Patient Share', 'PTRS %', ...
               'Constraints', 'Company1', 'Company2', 'Class', ...
               'Branded Net Revenues (NRA)', 'Branded Point Share (NRA)', ...
               'Branded Patient Share (NRA)', 'Branded Units (NRA)', ...
               'Molecule Point Share (NRA)', 'Molecule Patient Share (NRA)',...
               'Branded Gross Sales','Generic Units','Molecule Units','Branded Patient Volume',...
               'Branded Gross Sales (NRA)','Generic Units (NRA)','Molecule Units (NRA)','Branded Patient Volume (NRA)'};
           
    fmt = '%s,%s,%s,%s,%s,%d,%s,%.12g,%.8g,%.8g,%.12g,%.8g,%.8g,%.8g,%s,%s,%s,%s,%.12g,%.8g,%.8g,%.12g,%.8g,%.8g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g\n';
      
    
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
                        celltab{rr, 14} = ASSET.Scenario_PTRS(n);
                        celltab{rr, 15} = MODEL.ConstraintName;
                        celltab{rr, 16} = ASSET.Company1(n);
                        celltab{rr, 17} = ASSET.Company2(n);
                        celltab{rr, 18} = ASSET.Therapy_Class{n};
                        
                        % New output: Gross Sales: Branded+Molecule
                        celltab{rr,25} = OUTB.Y.GrossRevenues(n,ixYear(p));
                        % New output: Generic units = Molecule_Units - Branded_Units
                        celltab{rr,26} = OUTM.Y.Units(n, ixYear(p))-OUTB.Y.Units(n, ixYear(p));
                        % New output: Molecule_Units
                        celltab{rr,27} = OUTM.Y.Units(n, ixYear(p));
                        % New output: Patient volume = patient_share*treated_population
                        celltab{rr,28} = OUTB.Y.PatientVolume(n, ixYear(p));
                    end
                end
                
                % Cume and Peak values for years up to and including the year after LOE
                ix = (OUTB.Y.YearVec >= 2014) & (OUTB.Y.YearVec <= (ASSET.LOE_Year(n) + 1));

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
                    
                    % New outputs: Maximum of gross Branded revenues
                    peak25 = nanmax(OUTB.Y.GrossRevenues(n,ix));
                    % New outputs: Maximum of generic units
                    peak26 = nanmax(OUTM.Y.Units(n, ix)-OUTB.Y.Units(n, ix));
                    % New outputs: Maximum of Molecule units
                    peak27 = nanmax(OUTM.Y.Units(n, ix));
                    % New outputs: Maximum of Branded patient volume
                    peak28 = nanmax(OUTB.Y.PatientVolume(n, ix));
                    
                    celltab(rr, [8:13,25:28]) = {peak8, peak9, peak10, peak11, peak12, peak13 ,peak25,peak26,peak27,peak28};
                else
                    celltab(rr, [8:13,25:28]) = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0};                    
                end
                celltab{rr, 14} = ASSET.Scenario_PTRS(n);
                celltab{rr, 15} = MODEL.ConstraintName;
                celltab{rr, 16} = ASSET.Company1(n);
                celltab{rr, 17} = ASSET.Company2(n);
                celltab{rr, 18} = ASSET.Therapy_Class{n};                
                                
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

                    % New outputs: cumulative gross Branded revenues
                    cume25 = nansum(OUTB.Y.GrossRevenues(n,ix));
                    % New outputs: Cumulative generic units
                    cume26 = nansum(OUTM.Y.Units(n, ix)-OUTB.Y.Units(n, ix));
                    % New outputs: Cumulative Molecule units
                    cume27 = nansum(OUTM.Y.Units(n, ix));
                    % New outputs: Cumulative Branded patient volume
                    cume28 = nansum(OUTB.Y.PatientVolume(n, ix));
         
                    celltab(rr, [8:13,25:28]) = {cume8, nan, nan, cume11, nan, nan,cume25,cume26,cume27,cume28};
                else
                    celltab(rr, [8:13,25:28]) = {0, nan, nan, 0, nan, nan,0,0,0,0};               
                end
                celltab{rr, 14} = ASSET.Scenario_PTRS(n);
                celltab{rr, 15} = MODEL.ConstraintName;
                celltab{rr, 16} = ASSET.Company1(n);
                celltab{rr, 17} = ASSET.Company2(n);
                celltab{rr, 18} = ASSET.Therapy_Class{n};                
                

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
                        celltab{rr, 14} = ASSET.Scenario_PTRS(n);
                        celltab{rr, 15} = MODEL.ConstraintName;
                        celltab{rr, 16} = ASSET.Company1(n);
                        celltab{rr, 17} = ASSET.Company2(n);
                        celltab{rr, 18} = ASSET.Therapy_Class{n}; 
                        celltab{rr, 19} = RESTAT.Branded.Y.NetRevenuesNRA.(oStats{q})(n, ixYear(p));
                        celltab{rr, 22} = RESTAT.Branded.Y.UnitsNRA.(oStats{q})(n, ixYear(p)); %PL: it is possible that this will be later overwritten
                        
                        % New outputs
                        celltab{rr,25} = RESTAT.Branded.Y.GrossRevenues.(oStats{q})(n,ixYear(p));
                        celltab{rr,26} = nan;% OUTM.Y.Units(n, ixYear(p))-OUTB.Y.Units(n, ixYear(p)); %Generic units
                        celltab{rr,27} = nan;% OUTM.Y.Units(n, ixYear(p)); % Molecule units
                        celltab{rr,28} = RESTAT.Branded.Y.PatientVolume.(oStats{q})(n, ixYear(p));
                        
                        if isnan(ASSET.Scenario_PTRS(n))
                            celltab{rr, 14} = celltab{rr, 8} / celltab{rr, 19};  % back into PTRS for regions
                        end
                    end                
                end
                
                % Cume and Peak values for years up to and including the year after LOE
                ix = (yearVec >= 2014) & (yearVec <= (ASSET.LOE_Year(n) + 1));

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
                    
                    % New output Branded Gross Sales
                    peak25 = nanmax(RESTAT.Branded.Y.GrossRevenues.(oStats{q})(n,ix));
                    peak28 = nanmax(RESTAT.Branded.Y.PatientVolume.(oStats{q})(n, ix));
                    celltab(rr, [8:13,25:28]) = {peak8, nan, nan, peak11, nan, nan, peak25,nan,nan, peak28};
                else
                    celltab(rr, [8:13,25:28]) = {0, nan, nan, 0, nan, nan,0,nan,nan,0};                    
                end
                celltab{rr, 14} = ASSET.Scenario_PTRS(n);
                celltab{rr, 15} = MODEL.ConstraintName;
                celltab{rr, 16} = ASSET.Company1(n);
                celltab{rr, 17} = ASSET.Company2(n);
                celltab{rr, 18} = ASSET.Therapy_Class{n};                
                
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
                    % New output: Branded gross sales
                    cume25 = nansum(RESTAT.Branded.Y.GrossRevenues.(oStats{q})(n,ix));
                    cume28 = nansum(RESTAT.Branded.Y.PatientVolume.(oStats{q})(n, ix));
                    celltab(rr, [8:13,25:28]) = {cume8, nan, nan, cume11, nan, nan,cume25,nan,nan,cume28};
                else
                    celltab(rr, [8:13,25:28]) = {0, nan, nan, 0, nan, nan,0,nan,nan,0};               
                end
                celltab{rr, 14} = ASSET.Scenario_PTRS(n);
                celltab{rr, 15} = MODEL.ConstraintName;
                celltab{rr, 16} = ASSET.Company1(n);
                celltab{rr, 17} = ASSET.Company2(n);
                celltab{rr, 18} = ASSET.Therapy_Class{n};                
                
            end
            
        end
    end

    celltab = celltab(1:rr, :); % Remove any trailing blanks
    
    
    % Add "Calculated" Columns (NRA or non-risk-adjusted values)
    ixR = find(cellisempty(celltab(:,19)));  % Regions already have a value for RevenuesNRA.  
    cD = 14; % Denominator column: PTRS%
    cN = 8; % Numerator column: Branded Net Revenues
    celltab(ixR,19) = num2cell(cell2mat(celltab(ixR, cN)) ./ cell2mat(celltab(ixR, cD)));
    
    cN = 9; % Numerator column: Branded Point Share
    celltab(ixR,20) = num2cell(cell2mat(celltab(ixR, cN)) ./ cell2mat(celltab(ixR, cD)));
    
    cN = 10; % Numerator column: Branded Patient Share
    celltab(ixR,21) = num2cell(cell2mat(celltab(ixR, cN)) ./ cell2mat(celltab(ixR, cD)));
    
    cN = 11; % Numerator column: Branded Units
    celltab(ixR,22) = num2cell(cell2mat(celltab(ixR, cN)) ./ cell2mat(celltab(ixR, cD)));
    
    cN = 12; % Numerator column: Molecule Point Share
    celltab(ixR,23) = num2cell(cell2mat(celltab(ixR, cN)) ./ cell2mat(celltab(ixR, cD)));
    
    cN = 13; % Numerator column: Molecule Patient Share
    celltab(ixR,24) = num2cell(cell2mat(celltab(ixR, cN)) ./ cell2mat(celltab(ixR, cD)));
    
    cN = 25; % New output: Numerator column: Branded Gross Sales;
    celltab(ixR,29) = num2cell(cell2mat(celltab(ixR, cN)) ./ cell2mat(celltab(ixR, cD)));
    
    
    cN = 26; % New output: Numerator column: Generic Units
    celltab(ixR,30) = num2cell(cell2mat(celltab(ixR, cN)) ./ cell2mat(celltab(ixR, cD)));
    
    
    cN = 27; % New output: Numerator column: Molecule units
    celltab(ixR,31) = num2cell(cell2mat(celltab(ixR, cN)) ./ cell2mat(celltab(ixR, cD)));
    
    cN = 28; % New output: Numerator column: Patient volume
    celltab(ixR,32) = num2cell(cell2mat(celltab(ixR, cN)) ./ cell2mat(celltab(ixR, cD)));

    
    % Blank-out the NRA values for Percentiles and StdErr (they only make sense for Mean)
    ixOk = strcmpi(celltab(:,5), 'Mean');
    ixOk(1) = true; % keep header row
    celltab(~ixOk, 19:24) = {[]};
    
end    