function SIM = marketModelOneRealization(MODEL, ASSET, CHANGE, doPlots)

    %% Launch/Not-Launch based on scenario probability

    Na = length(ASSET.Scenario_PTRS);
    isLaunch = rand(Na,1) <= cell2mat(ASSET.Scenario_PTRS);
    %isLaunch = cell2mat(ASSET.Launch_Simulation) == 1;       % Temporary - make it match the Excel sheet

    Nchange = length(CHANGE.Scenario_PTRS);
    isChange = rand(Nchange,1) <= cell2mat(CHANGE.Scenario_PTRS);


    %% Run the "Order of Entry" model and "Profile" model.  
    %  Combine them using their respective weights.

    % Elasticity assumptions
    elastClass = MODEL.ClassOeElasticity;  % 0.2 
    elastAsset = MODEL.ProductOeElasticity;  % -0.5

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

    [dateGrid, sharePerAssetMonthlySeries] = bassDiffusionNested(ASSET, eventDates, sharePerAssetEventSeries);

    SIM = struct;
    SIM.EventDates = eventDates;
    SIM.SharePerAssetEventSeries = sharePerAssetEventSeries;
    SIM.DateGrid = dateGrid;
    SIM.SharePerAssetMonthlySeries = sharePerAssetMonthlySeries;
    
    
    if doPlots
        figure; semilogy(dateGrid, sharePerAssetMonthlySeries); datetick; grid on; title('Share Per Asset');
                legend(ASSET.Assets_Rated, 'Location', 'EastOutside'); timeCursor(false);

        figure; plot(dateGrid, 1-nansum(sharePerAssetMonthlySeries)); datetick; grid on; timeCursor(false);
    end


end