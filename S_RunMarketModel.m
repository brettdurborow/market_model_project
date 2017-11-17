
%% Read assumptions from Excel file on disk

fileName = '.\Data\MATLAB_ps1.xlsb';

% [MODEL, ASSET, CHANGE] = importAssumptions(fileName);

ASSET.Launch_Date = datenum(cell2mat(ASSET.Launch_Year), cell2mat(ASSET.Launch_Month), 1);
ASSET.LOE_Date = datenum(cell2mat(ASSET.LOE_Year), cell2mat(ASSET.LOE_Month), 1);

CHANGE.Launch_Date = datenum(cell2mat(CHANGE.Launch_Year), cell2mat(CHANGE.Launch_Month), 1);
CHANGE.LOE_Date = datenum(cell2mat(CHANGE.LOE_Year), cell2mat(CHANGE.LOE_Month), 1);
CHANGE = structSort(CHANGE, {'Launch_Date'});  % sort by launch date in ascending order

%% Launch/Not-Launch based on scenario probability

rng(100);  % set random number seed.  Remove this after debugging

Na = length(ASSET.Scenario_PTRS);
isLaunch = rand(Na,1) <= cell2mat(ASSET.Scenario_PTRS);

Nc = length(CHANGE.Scenario_PTRS);
isChange = rand(Nc,1) <= cell2mat(CHANGE.Scenario_PTRS);


%% Run the "Order of Entry" model and "Profile" model.  
%  Combine them using their respective weights.

elastClass = 0.2;   % Elasticity assumptions
elastAsset = -0.5;  

CLASS = therapyClassRank(MODEL, ASSET, isLaunch);

eventDates = unique([ASSET.Launch_Date; ASSET.LOE_Date; CHANGE.Launch_Date; CHANGE.LOE_Date]);
sharePerAssetSeries = nan(length(isLaunch), length(eventDates));  % row for each asset, col for each date

for m = 1:length(eventDates)

    eventDate = eventDates(m);
    sharePerAssetOE = orderOfEntryModel(MODEL, ASSET, CLASS, isLaunch, eventDate, elastClass, elastAsset);
    sharePerAssetP = profileModel(MODEL, ASSET, CHANGE, CLASS, isLaunch, isChange, eventDate);
    
    sharePerAsset = (sharePerAssetOE * MODEL.OrderOfEntryWeight + sharePerAssetP * MODEL.ProfileWeight) ...
                    / (MODEL.OrderOfEntryWeight + MODEL.ProfileWeight);
    
    adjustmentFactor = applyFactors(MODEL, ASSET, CHANGE, isLaunch, isChange, eventDate);
    newSharePerAsset = reDistribute(sharePerAsset, adjustmentFactor);
    
    sharePerAssetSeries(:, m) = sharePerAsset;
end

%% Apply factors for Market Access and Patient Barriers





