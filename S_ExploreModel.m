

ASSET.Launch_Date = datenum(cell2mat(ASSET.Launch_Year), cell2mat(ASSET.Launch_Month), 1);
ASSET.LOE_Date = datenum(cell2mat(ASSET.LOE_Year), cell2mat(ASSET.LOE_Month), 1);



%%  Tab: "Step 2 Class Order of Entry"

N = 8;
order = 1:N;
a = -2.3529121588474;
elasticity = 0.2;

% rewrite the log equation to enable a direct analytical solution
f1 = exp(a + elasticity * log(order))
f2 = exp(a) * exp(elasticity * log(order))
f3 = exp(a) * order .^ elasticity

a_solve = log(1.0 / sum(order .^ elasticity));  % Solve for a given N and elasticity

%% Launch Simulation

rng(100);  % set random number seed.  Remove this after debugging

Na = length(ASSET.Scenario_PTRS);
isLaunch = rand(Na,1) <= cell2mat(ASSET.Scenario_PTRS);


%% Class Rank

uClass = unique(ASSET.Therapy_Class);
isCountrySelected = strcmp(MODEL.CountrySelected, ASSET.Country);

firstLaunch = nan(size(uClass));
for m = 1:length(uClass)
    ix = strcmp(uClass{m}, ASSET.Therapy_Class) & isCountrySelected & isLaunch;
    if sum(ix) > 0
        firstLaunch(m) = min(ASSET.Launch_Date(ix));
    end    
end
[sorted, ix] = sort(firstLaunch);
classRank = nan(size(uClass));
ix2 = ix(~isnan(sorted));
classRank(ix2) = 1:length(ix2);  % NaN values for classes that are not launching in this simulation




%%

% For each country, for each date, for each class, rank the assets by order of entry, 

%%  Debug Profile model vs Order-of-Entry models.  
%   Should never have

eventDate = eventDates(50);

sharePerAssetOE = orderOfEntryModel(MODEL, ASSET, CLASS, isLaunch, eventDate, elastClass, elastAsset);
sharePerAssetP = profileModel(MODEL, ASSET, CHANGE, CLASS, isLaunch, eventDate);

ixOE = ~isnan(sharePerAssetOE);
ixP =  ~isnan(sharePerAssetP);

ixErr = find(ixOE ~= ixP)
[sharePerAssetOE(ixErr), sharePerAssetP(ixErr)]  % show the ones that don't match

nansum(sharePerAssetOE + sharePerAssetP) / 2

%%

oldShare = [0.1253774471081500;
    0.1090536960816170;
    0.0976355240765358;
    0.1491951472232190;
    0.1293004326485950;
    0.1298125842872940;
    0.1298125842872940;
    0.1298125842872940];


adjustment = [0.7; 0.7; 0.01; 0.5; 1; 0.5; 1; 0.5];

newShare = reDistribute(oldShare, adjustment)

newShare = reDistribute(newShare, adjustment)


%%  Applying Factors

% Market Access Filter

ixLOE = eventDate >= ASSET.LOE_Date;

marketAccessFilter = repmat(MODEL.WillingToPayForTreatment, size(isLaunch));
marketAccessFilter(~ixLOE) = cell2mat(ASSET.Branded_Access_Barriers(~ixLOE));

patientBarriers = zeros(size(isLaunch));
patientBarriers(isLaunch) = cell2mat(ASSET.Patient_Barriers(isLaunch));

adjustmentFactor = marketAccessFilter .* patientBarriers;
adjustmentFactor = adjustmentFactor / max(adjustmentFactor);



%%

function newShare = reDistribute(oldShare, adjustment)

    if abs(sum(oldShare)-1) > length(oldShare) * eps
        error('Expected oldShare to sum to 1');
    end
    
    Na = length(adjustment);

    A = nan(Na);
    
    for m = 1:Na
        for n = 1:Na
            if m == n
                A(m,n) = adjustment(m);
            else
                A(m,n) = (1-adjustment(n)) * oldShare(m) / (1-oldShare(n));
            end            
        end
    end

    newShare = A * oldShare;
    newShare = newShare / sum(newShare);

end









