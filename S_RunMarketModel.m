
%% Read assumptions from Excel file on disk
doPlots = true;
tStart = tic;

fileName = '.\Data\MATLABv33.xlsb';

[MODEL, ASSET, CHANGE] = importAssumptions(fileName);

tImport = tic;
fprintf('Imported Data, elapsed time = %1.1f sec\n', toc(tStart));

ASSET.Launch_Date = datenum(cell2mat(ASSET.Launch_Year), cell2mat(ASSET.Launch_Month), 1);
ASSET.LOE_Date = datenum(cell2mat(ASSET.LOE_Year), cell2mat(ASSET.LOE_Month), 1);
ASSET.Starting_Share_Date = datenum(cell2mat(ASSET.Starting_Share_Year), cell2mat(ASSET.Starting_Share_Month), 1);
sDates = unique(ASSET.Starting_Share_Date);
if length(sDates) ~= 1
    error('Expected Starting Share Year and Month to be equal across all assets');
end

CHANGE.Launch_Date = datenum(cell2mat(CHANGE.Launch_Year), cell2mat(CHANGE.Launch_Month), 1);
CHANGE.LOE_Date = datenum(cell2mat(CHANGE.LOE_Year), cell2mat(CHANGE.LOE_Month), 1);
CHANGE = structSort(CHANGE, {'Launch_Date'});  % sort by launch date in ascending order

%% Launch/Not-Launch based on scenario probability

rng(100);  % set random number seed.  Remove this after debugging

Na = length(ASSET.Scenario_PTRS);
isLaunch = rand(Na,1) <= cell2mat(ASSET.Scenario_PTRS);
isLaunch = cell2mat(ASSET.Launch_Simulation) == 1;       % Temporary - make it match the Excel sheet

Nchange = length(CHANGE.Scenario_PTRS);
isChange = rand(Nchange,1) <= cell2mat(CHANGE.Scenario_PTRS);


%% Run the "Order of Entry" model and "Profile" model.  
%  Combine them using their respective weights.

elastClass = 0.2;   % Elasticity assumptions
elastAsset = -0.5;  

CLASS = therapyClassRank(MODEL, ASSET, isLaunch);

eventDates = unique([ASSET.Launch_Date; ASSET.LOE_Date; ASSET.Starting_Share_Date; CHANGE.Launch_Date; CHANGE.LOE_Date]);
sharePerAssetEventSeries = zeros(Na, length(eventDates));  % row for each asset, col for each date

for m = 1:length(eventDates)

    eventDate = eventDates(m);
    sharePerAssetOE = orderOfEntryModel(MODEL, ASSET, CLASS, isLaunch, eventDate, elastClass, elastAsset);
    sharePerAssetP = profileModel(MODEL, ASSET, CHANGE, CLASS, isLaunch, isChange, eventDate);
    
    sharePerAsset = (sharePerAssetOE * MODEL.OrderOfEntryWeight + sharePerAssetP * MODEL.ProfileWeight) ...
                    / (MODEL.OrderOfEntryWeight + MODEL.ProfileWeight);
    
    adjustmentFactor = applyFactors(MODEL, ASSET, CHANGE, isLaunch, isChange, eventDate);
    newSharePerAsset = reDistribute(sharePerAsset, adjustmentFactor);
    
    sharePerAssetEventSeries(:, m) = newSharePerAsset;
end

%% Bass Diffusion Model to fill in times between events

% startDate = max(ASSET.Starting_Share_Date);
% [yr0, mo0, dy0] = datevec(startDate);
% daysPerMonth = 30.4;
% daysPerYear = 365.25;
% monthCount = ceil(120 + (eventDates(end) - startDate) / daysPerMonth);  % 10 years after last event
% dateGrid = datenum(yr0, mo0:mo0+monthCount, 1);
% ix = dateGrid <= eventDates(end) & dateGrid >= startDate;
% % datestr(dateGrid(~ix))
% dateGrid = dateGrid(ix);  % Grid of monthly dates from first event to last event
% Nd = length(dateGrid);
% 
% sharePerAssetMonthlySeries = zeros(Na, Nd);
% sharePerAssetMonthlySeries(:,1) = cell2mat(ASSET.Starting_Share) / nansum(cell2mat(ASSET.Starting_Share));

% For each date, find the prior market share target, the next future market share target, 
% and the proper p and q.  Compute the interpolated market share using the Bass diffusion model

% ToDo: figure out the right logic for Bass diffusion: how do handle class p and q, 
% product p and q, LOE p and q (for class and for product), etc.  This is not yet well-defined.
% But does it really change the result very much?  Target shares are more important.  
% Bass diffusion only controls how quickly they are reached.

% Find for each Therapy Class (Nc < Na), the aggregate share over all assets in the class
% Find for each Therapy Class the p and q values, by finding max p and corresponding q among in-class assets
% For each Therapy Class, find monthly share via Bass Diffusion using p and q and start + end shares
% For each Asset within the Class, find monthly share via Bass Diffusion, s.t. asset share sums to class share on each date
% For each Asset within the Class, find Branded vs. Generic share via Bass Diffusion, s.t. B + S sum to asset share


% tmp = [];
% m0 = find(eventDates >= startDate, 1, 'first');
% for m = m0:length(eventDates) - 1
%     eventDate = eventDates(m);
%     nextDate =  eventDates(m+1);
%     
%     pVec = [];
%     qVec = [];
%     
%     ix0 = find(ASSET.Launch_Date == eventDate);
%     if ~isempty(ix0)
%         [pLaunch, ix_p] = max([ASSET.Product_p{ix0}]);
%         qLaunch = ASSET.Product_q{ix0(ix_p)};
%         pVec = [pVec, pLaunch];
%         qVec = [qVec, qLaunch];
%     end
%     
%     ix1 = find(ASSET.LOE_Date == eventDate);
%     if ~isempty(ix1)
%         [pLoe, ix_p] = max([ASSET.LOE_p{ix1}]);
%         qLoe = ASSET.LOE_q{ix1(ix_p)};
%         pVec = [pVec, pLoe];
%         qVec = [qVec, qLoe];
%     end
%     
%     [pMax, ix_p] = max(pVec);
%     qMax = qVec(ix_p);
%     tmp(end+1) = pMax;
%     
%     pMax = 0.22;
%     qMax = 0.28;
%     
%     ixStart = find(dateGrid == eventDate, 1);
%     ixEnd = find(dateGrid == nextDate, 1);
%     tt = (dateGrid(ixStart:ixEnd) - dateGrid(ixStart)) / daysPerYear;
%     for n = 1:Na
%         s0 = sharePerAssetMonthlySeries(n, ixStart);
%         s1 = sharePerAssetEventSeries(n, m);
%         share = bassDiffusion(tt, pMax, qMax, s0, s1, false);
%         sharePerAssetMonthlySeries(n, ixStart:ixEnd) = share;
%     end
% end

[dateGrid, sharePerAssetMonthlySeries] = bassDiffusionNested(ASSET, eventDates, sharePerAssetEventSeries);

if doPlots
    figure; semilogy(dateGrid, sharePerAssetMonthlySeries); datetick; grid on; title('Share Per Asset');
            legend(ASSET.Assets_Rated, 'Location', 'EastOutside'); timeCursor(false);

    figure; plot(dateGrid, 1-nansum(sharePerAssetMonthlySeries)); datetick; grid on; timeCursor(false);
end

%% Produce various outputs

OUT = computeOutputs(MODEL, ASSET, dateGrid, sharePerAssetMonthlySeries);

if doPlots
    figure; semilogy(dateGrid, OUT.Units); datetick; grid on; title('Units');
            legend(ASSET.Assets_Rated, 'Location', 'EastOutside'); timeCursor(false);

    figure; semilogy(dateGrid, OUT.NetRevenues); datetick; grid on; title('Net Revenues');
            legend(ASSET.Assets_Rated, 'Location', 'EastOutside'); timeCursor(false);

end

tElapsed = toc(tImport);
fprintf('Run complete, elapsed time = %1.2f sec\n', tElapsed);
