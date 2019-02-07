function [cMODEL_R, cASSET_R, cRESTAT_R] = bumpUpRegions(cMODEL, cASSET, cESTAT)
% Check to see if EU5 countries are all represented in the input cells.
% If so, compute the "bump-up" estimates for each derived region, and store
% them in the output cells.  We only need Yearly Branded Revenues
% (not Shares, and not Molecule Revenues), and Monthly Branded Units

% Strictly speaking, if each country is "independent", then the we need a 
% different workflow than the underlying country simulations.  Need to compute 
% a "SimCube" for revenue (not share) for EU5.  Then compute percentiles on 
% Revenue only, and scale it down to get Regional revenues for each percentile.
% This will take a prohibitive amount of memory.
%
% If we assume the countries are statistically independent, then we can 
% estimate the PDF of revenue for each country from its perceentiles.  Then
% to sum the country revenues, we would convolve the PDF's, and take percentiles
% of these new PDF's.  But we don't believe that they countries are independent
% at all, so we will take a third approach:
%
% We are simplifying things by assuming that assets are perfectly
% correlated and identically distributed across countries.  So we assume that 
% an asset launches in country B iff it also launches in country A.  Under this 
% assumption we can just sum the percentiles to get the percentile of the sum.  
%

% For each new ESTAT, we need to generate a synthetic MODEL and ASSET with
% a subset of fields populated:
% MODEL.CountrySelected, ScenarioSelected
% ASSET.Assets_Rated, Scenario_PTRS

    % First, check to see that EU5 countries are present in the inputs
    strEU5 = {'DE'; 'FR'; 'ES'; 'IT'; 'UK'};
    strCountries = cell(size(cMODEL));
    for m = 1:length(cMODEL)
        strCountries{m} = cMODEL{m}.CountrySelected;
    end
    [Lia, Locb] = ismember(strEU5, strCountries);
    
	isOkEu5 = all(Lia);
    if ~isOkEu5
        warning('Unable to find these EU5 countries in simulation: %s.\n...Unable to compute Regional revenues', ...
                strjoin(strEU5(~Lia), ', '));
        return;
    end
    
    % Compute Revenue and Units for each Percentile for each Country
    cRESTAT = cell(size(cMODEL));
    statnames = fieldnames(cESTAT{1}.Branded);        
    for m = 1:length(cMODEL)
        dateGrid = cESTAT{m}.DateGrid;        
        OUT = computeOutputs(cMODEL{m}, cASSET{m}, dateGrid, cESTAT{m}.Branded.(statnames{1}));  % Just to get the YearVec
        yearVec = OUT.Y.YearVec;
        
        RESTAT = struct;
        RESTAT.Branded.M.DateGrid = dateGrid;
        RESTAT.Branded.Y.YearVec = yearVec;        
        scenario_PTRS_M = repmat(cASSET{m}.Scenario_PTRS, 1, length(dateGrid));
        scenario_PTRS_Y = repmat(cASSET{m}.Scenario_PTRS, 1, length(yearVec));

        for n = 1:length(statnames)
            monthlyShareMx = cESTAT{m}.Branded.(statnames{n});
            OUT = computeOutputs(cMODEL{m}, cASSET{m}, dateGrid, monthlyShareMx);
            RESTAT.Branded.M.NetRevenues.(statnames{n}) = OUT.M.NetRevenues;
            RESTAT.Branded.Y.NetRevenues.(statnames{n}) = OUT.Y.NetRevenues;
            RESTAT.Branded.M.Units.(statnames{n}) = OUT.M.Units;
            RESTAT.Branded.Y.Units.(statnames{n}) = OUT.Y.Units;
            
            RESTAT.Branded.M.NetRevenuesNRA.(statnames{n}) = OUT.M.NetRevenues ./ scenario_PTRS_M;
            RESTAT.Branded.Y.NetRevenuesNRA.(statnames{n}) = OUT.Y.NetRevenues ./ scenario_PTRS_Y;
            RESTAT.Branded.M.UnitsNRA.(statnames{n}) = OUT.M.Units ./ scenario_PTRS_M;            
            RESTAT.Branded.Y.UnitsNRA.(statnames{n}) = OUT.Y.Units ./ scenario_PTRS_Y;  
        end

        cRESTAT{m} = RESTAT;
    end
            
    % We found all the EU5 countries, compute sum of revenues for the EU5
    ASSET_EU5 = cASSET{Locb(1)};
    RESTAT_EU5 = cRESTAT{Locb(1)};
    MODEL_EU5 = cMODEL{Locb(1)};
    for m = 2:length(Locb)  % Locb is index into cMODEL, cASSET, cESTAT matching this EU5 country
        [ASSET_EU5, RESTAT_EU5] = sumRestat(ASSET_EU5, RESTAT_EU5, cASSET{Locb(m)}, cRESTAT{Locb(m)});
        MODEL_EU5 = makeMODEL('EU5', MODEL_EU5, cMODEL{Locb(m)});
    end
        
    cMODEL_R = cell(9, 1);
    cASSET_R = cell(9, 1);
    cRESTAT_R = cell(9, 1);
    
    
    rr = 1;
    cMODEL_R{rr} = MODEL_EU5;
    cASSET_R{rr} = ASSET_EU5;
    cRESTAT_R{rr} = RESTAT_EU5;
    
    % Use sum of EU5 revenues to compute "bumped-up" regionals
    SIMULATION = cMODEL{1};  % use values from the "simulation" input sheet
    
    % Canada ----------------------------------
    RESTAT_CA = scaleRestat(RESTAT_EU5, SIMULATION.CA_Bump_Up_from_EU5);
    
    rr = rr + 1;
    cMODEL_R{rr} = makeMODEL('CA', MODEL_EU5);
    cASSET_R{rr} = ASSET_EU5;    
    cRESTAT_R{rr} = RESTAT_CA;

    % Rest of AP ----------------------------------
    RESTAT_ROAP = scaleRestat(RESTAT_EU5, SIMULATION.Rest_of_AP_Bump_Up_from_EU5);
    
    rr = rr + 1;
    cMODEL_R{rr} = makeMODEL('ROAP', MODEL_EU5);
    cASSET_R{rr} = ASSET_EU5;    
    cRESTAT_R{rr} = RESTAT_ROAP;
    
    % Rest of EMEA ----------------------------------
    RESTAT_ROEMEA = scaleRestat(RESTAT_EU5, SIMULATION.Rest_of_EMEA_Bump_Up_from_EU5);
    
    rr = rr + 1;
    cMODEL_R{rr} = makeMODEL('ROEMEA', MODEL_EU5);
    cASSET_R{rr} = ASSET_EU5;    
    cRESTAT_R{rr} = RESTAT_ROEMEA;
        
    % Latin America ----------------------------------
    RESTAT_LA = scaleRestat(RESTAT_EU5, SIMULATION.LA_Bump_Up_from_EU5);
    
    rr = rr + 1;
    cMODEL_R{rr} = makeMODEL('LA', MODEL_EU5);
    cASSET_R{rr} = ASSET_EU5;    
    cRESTAT_R{rr} = RESTAT_LA;
    
    % EMEA ----------------------------------
    [ASSET_EMEA, ESTATREV_EMEA] = sumRestat(ASSET_EU5, RESTAT_EU5, ASSET_EU5, RESTAT_ROEMEA);
    
    rr = rr + 1;
    cMODEL_R{rr} = makeMODEL('EMEA', MODEL_EU5);
    cASSET_R{rr} = ASSET_EMEA;    
    cRESTAT_R{rr} = ESTATREV_EMEA;
        
    % North America ----------------------------------    
    % Canada + US
    ixUS = find(strcmpi('US', strCountries));
    if length(ixUS) == 1
        [ASSET_NA, RESTAT_NA] = sumRestat(ASSET_EU5, RESTAT_CA, cASSET{ixUS}, cRESTAT{ixUS});
        rr = rr + 1;
        cMODEL_R{rr} = makeMODEL('NA', MODEL_EU5, cMODEL{ixUS});
        cASSET_R{rr} = ASSET_NA;    
        cRESTAT_R{rr} = RESTAT_NA;
    end
    
    % Asia Pacific ----------------------------------    
    % JP + Rest of Asia Pacific
    ixJP = find(strcmpi('JP', strCountries));
    if length(ixJP) == 1
        [ASSET_AP, RESTAT_AP] = sumRestat(ASSET_EU5, RESTAT_ROAP, cASSET{ixJP}, cRESTAT{ixJP});
        rr = rr + 1;
        cMODEL_R{rr} = makeMODEL('AP', MODEL_EU5, cMODEL{ixJP});
        cASSET_R{rr} = ASSET_AP;    
        cRESTAT_R{rr} = RESTAT_AP;
    end
    
    % World Wide --------------------------------------
    % WW = NA + AP + LA + EMEA
    if isOkEu5 && (length(ixUS) == 1) && (length(ixJP) == 1)
        [ASSET_WW, RESTAT_WW] = sumRestat(ASSET_NA, RESTAT_NA, ASSET_AP, RESTAT_AP);
        [ASSET_WW, RESTAT_WW] = sumRestat(ASSET_WW, RESTAT_WW, ASSET_EU5, RESTAT_LA);
        [ASSET_WW, RESTAT_WW] = sumRestat(ASSET_WW, RESTAT_WW, ASSET_EU5, ESTATREV_EMEA);
        rr = rr + 1;
        MODEL_WW = makeMODEL('WW', MODEL_EU5, cMODEL{ixUS});
        MODEL_WW = makeMODEL('WW', MODEL_WW, cMODEL{ixJP});
        cMODEL_R{rr} = MODEL_WW;
        cASSET_R{rr} = ASSET_WW;    
        cRESTAT_R{rr} = RESTAT_WW;        
    end
    

end

function MODEL = makeMODEL(countryName, MODEL1, MODEL2)
    MODEL = struct;
    MODEL.CountrySelected = countryName;
    
    % Handle ConstraintName.  Make sure they match
    if nargin == 1
        error('makeMODEL() must have at least two inputs');
    elseif nargin == 2
        MODEL.ConstraintName = MODEL1.ConstraintName;
    elseif nargin == 3
        if strcmp(MODEL1.ConstraintName, MODEL2.ConstraintName)
            MODEL.ConstraintName = MODEL1.ConstraintName;
        else
            MODEL.ConstraintName = 'INCONSISTENT';
        end
    end
    
    % Make sure scenario selected is consistent across geographies
    if nargin == 1
        error('makeMODEL() must have at least two inputs');
    elseif nargin == 2
        MODEL.ScenarioSelected = MODEL1.ScenarioSelected;
    elseif nargin == 3
        if strcmp(MODEL1.ScenarioSelected, MODEL2.ScenarioSelected)
            MODEL.ScenarioSelected = MODEL1.ScenarioSelected;
        else
            MODEL.ScenarioSelected = 'INCONSISTENT';
        end
    end
end



