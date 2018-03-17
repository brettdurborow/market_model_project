function [cMODEL_R, cASSET_R, cESTATREV_R] = bumpUpRegions(cMODEL, cASSET, cESTAT)
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
    
    % Compute a revenue value for each Percentile for each Country
    cESTATREV = cell(size(cMODEL));
    fnamesB = fieldnames(cESTAT{1}.Branded);        
    fnamesM = fieldnames(cESTAT{1}.Molecule);
    dateGrid = cESTAT{1}.DateGrid;
    for m = 1:length(cMODEL)
        ESTATREV = struct;
        ESTATREV.DateGrid = dateGrid;
        for n = 1:length(fnamesB)
            monthlyShareMx = cESTAT{m}.Branded.(fnamesB{n});
            OUT = computeOutputs(cMODEL{m}, cASSET{m}, dateGrid, monthlyShareMx, false);
            ESTATREV.Branded.(fnamesB{n}) = OUT.M.NetRevenues;
        end
        for n = 1:length(fnamesM)
            monthlyShareMx = cESTAT{m}.Molecule.(fnamesM{n});
            OUT = computeOutputs(cMODEL{m}, cASSET{m}, dateGrid, monthlyShareMx, false);
            ESTATREV.Molecule.(fnamesM{n}) = OUT.M.NetRevenues;
        end
        cESTATREV{m} = ESTATREV;
    end
            
    % We found all the EU5 countries, compute sum of revenues for the EU5
    ASSET_EU5 = cASSET{Locb(1)};
    ESTATREV_EU5 = cESTATREV{Locb(1)};
    for m = 2:length(Locb)  % Locb is index into cMODEL, cASSET, cESTAT matching this EU5 country
        [ASSET_EU5, ESTATREV_EU5] = sumEstat(ASSET_EU5, ESTATREV_EU5, cASSET{Locb(m)}, cESTATREV{Locb(m)});
    end
    ASSET_EU5.Scenario_PTRS = '';
        
    cMODEL_R = cell(9, 1);
    cASSET_R = cell(9, 1);
    cESTATREV_R = cell(9, 1);
    
    
    rr = 1;
    cMODEL_R{rr} = makeMODEL('EU5');
    cASSET_R{rr} = ASSET_EU5;
    cESTATREV_R{rr} = ESTATREV_EU5;
    
    % Use sum of EU5 revenues to compute "bumped-up" regionals
    SIMULATION = cMODEL{1};  % use values from the "simulation" input sheet
    
    % Canada ----------------------------------
    ESTATREV_CA = scaleEstat(ESTATREV_EU5, SIMULATION.CA_Bump_Up_from_EU5);
    
    rr = rr + 1;
    cMODEL_R{rr} = makeMODEL('CA');
    cASSET_R{rr} = ASSET_EU5;    
    cESTATREV_R{rr} = ESTATREV_CA;

    % Rest of AP ----------------------------------
    ESTATREV_ROAP = scaleEstat(ESTATREV_EU5, SIMULATION.Rest_of_AP_Bump_Up_from_EU5);
    
    rr = rr + 1;
    cMODEL_R{rr} = makeMODEL('ROAP');
    cASSET_R{rr} = ASSET_EU5;    
    cESTATREV_R{rr} = ESTATREV_ROAP;
    
    % Rest of EMEA ----------------------------------
    ESTATREV_ROEMEA = scaleEstat(ESTATREV_EU5, SIMULATION.Rest_of_EMEA_Bump_Up_from_EU5);
    
    rr = rr + 1;
    cMODEL_R{rr} = makeMODEL('ROEMEA');
    cASSET_R{rr} = ASSET_EU5;    
    cESTATREV_R{rr} = ESTATREV_ROEMEA;
        
    % Latin America ----------------------------------
    ESTATREV_LA = scaleEstat(ESTATREV_EU5, SIMULATION.LA_Bump_Up_from_EU5);
    
    rr = rr + 1;
    cMODEL_R{rr} = makeMODEL('LA');
    cASSET_R{rr} = ASSET_EU5;    
    cESTATREV_R{rr} = ESTATREV_LA;
    
    % EMEA ----------------------------------
    [ASSET_EMEA, ESTATREV_EMEA] = sumEstat(ASSET_EU5, ESTATREV_EU5, ASSET_EU5, ESTATREV_ROEMEA);
    
    rr = rr + 1;
    cMODEL_R{rr} = makeMODEL('EMEA');
    cASSET_R{rr} = ASSET_EMEA;    
    cESTATREV_R{rr} = ESTATREV_EMEA;
        
    % North America ----------------------------------    
    % Canada + US
    ixUS = find(strcmpi('US', strCountries));
    if length(ixUS) == 1
        [ASSET_NA, ESTATREV_NA] = sumEstat(ASSET_EU5, ESTATREV_CA, cASSET{ixUS}, cESTATREV{ixUS});
        rr = rr + 1;
        cMODEL_R{rr} = makeMODEL('NA');
        cASSET_R{rr} = ASSET_NA;    
        cESTATREV_R{rr} = ESTATREV_NA;
    end
    
    % Asia Pacific ----------------------------------    
    % JP + Rest of Asia Pacific
    ixJP = find(strcmpi('JP', strCountries));
    if length(ixJP) == 1
        [ASSET_AP, ESTATREV_AP] = sumEstat(ASSET_EU5, ESTATREV_ROAP, cASSET{ixJP}, cESTATREV{ixJP});
        rr = rr + 1;
        cMODEL_R{rr} = makeMODEL('AP');
        cASSET_R{rr} = ASSET_AP;    
        cESTATREV_R{rr} = ESTATREV_AP;
    end
    
    % World Wide --------------------------------------
    % WW = NA + AP + LA + EMEA
    if isOkEu5 && (length(ixUS) == 1) && (length(ixJP) == 1)
        [ASSET_WW, ESTATREV_WW] = sumEstat(ASSET_NA, ESTATREV_NA, ASSET_AP, ESTATREV_AP);
        [ASSET_WW, ESTATREV_WW] = sumEstat(ASSET_WW, ESTATREV_WW, ASSET_EU5, ESTATREV_LA);
        [ASSET_WW, ESTATREV_WW] = sumEstat(ASSET_WW, ESTATREV_WW, ASSET_EU5, ESTATREV_EMEA);
        rr = rr + 1;
        cMODEL_R{rr} = makeMODEL('WW');
        cASSET_R{rr} = ASSET_WW;    
        cESTATREV_R{rr} = ESTATREV_WW;        
    end
    

end

function MODEL = makeMODEL(countryName)
    MODEL = struct;
    MODEL.CountrySelected = countryName;
    MODEL.ScenarioSelected = '';
end



