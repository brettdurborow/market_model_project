function SIM = marketModelOneRealization(MODEL, ASSET, CHANGE, isLaunch, isChange, doDebug)



    %% Run the "Order of Entry" model and "Profile" model.  
    %  Combine them using their respective weights.

    if sum(isLaunch) == 0
        SIM = [];
        return;
    end
    
    Na = length(ASSET.Scenario_PTRS);

    
    % Elasticity assumptions
    elastClass = MODEL.ClassOeElasticity;  % 0.2 
    elastAsset = MODEL.ProductOeElasticity;  % -0.5

    CLASS = therapyClassRank(MODEL, ASSET, isLaunch);

    eventDates = unique([ASSET.Launch_Date; ASSET.LOE_Date; ASSET.Starting_Share_Date; CHANGE.Launch_Date; CHANGE.LOE_Date]);
    sharePerAssetEventSeries = zeros(Na, length(eventDates));  % row for each asset, col for each date

    if doDebug
        dbgAssetOE = zeros(Na, length(eventDates));
        dbgAssetP = zeros(Na, length(eventDates));
        dbgAssetAdjFactor = zeros(Na, length(eventDates));
        dbgAssetTargetShare = zeros(Na, length(eventDates));
    end
    
    for m = 1:length(eventDates)

        eventDate = eventDates(m);
        sharePerAssetOE = orderOfEntryModel(MODEL, ASSET, CLASS, isLaunch, eventDate, elastClass, elastAsset);
        sharePerAssetP = profileModel(MODEL, ASSET, CHANGE, CLASS, isLaunch, isChange, eventDate);

        sharePerAsset = (sharePerAssetOE * MODEL.OrderOfEntryWeight + sharePerAssetP * MODEL.ProfileWeight) ...
                        / (MODEL.OrderOfEntryWeight + MODEL.ProfileWeight);

        adjustmentFactor = applyFactors(MODEL, ASSET, CHANGE, isLaunch, isChange, eventDate);
        newSharePerAsset = reDistribute(sharePerAsset, adjustmentFactor);

        sharePerAssetEventSeries(:, m) = newSharePerAsset;
        
        if doDebug
            dbgAssetOE(:,m) = sharePerAssetOE;
            dbgAssetP(:,m) = sharePerAssetP;
            dbgAssetAdjFactor(:,m) = adjustmentFactor;
            dbgAssetTargetShare(:,m) = newSharePerAsset;
        end
    end

    %% Bass Diffusion Model to fill in times between events
    
    [dateGrid, sharePerAssetMonthlySeries, sharePerClassMonthlySeries, DBG] = bassDiffusionClass(ASSET, CLASS, isLaunch, eventDates, sharePerAssetEventSeries, doDebug);

%     [dateGrid, sharePerAssetMonthlySeries, DBG] = bassDiffusionNested(ASSET, eventDates, sharePerAssetEventSeries, doDebug);
    
    [brandedMonthlyShare, genericMonthlyShare] = bassBrandedShare(dateGrid, sharePerAssetMonthlySeries, ASSET);

    SIM = struct;
    SIM.EventDates = eventDates;
    SIM.SharePerAssetEventSeries = sharePerAssetEventSeries;
    SIM.DateGrid = dateGrid;
    SIM.SharePerAssetMonthlySeries = sharePerAssetMonthlySeries;
    SIM.BrandedMonthlyShare = brandedMonthlyShare;
    SIM.GenericMonthlyShare = genericMonthlyShare;
    
    if doDebug
        dateHead = num2cell(year(eventDates) + month(eventDates) / 12); 
        DBG.AssetOrderOfEntry = mx2celltab(dateHead, ASSET.Assets_Rated, dbgAssetOE);
        DBG.AssetProfile = mx2celltab(dateHead, ASSET.Assets_Rated, dbgAssetP);
        DBG.AssetAdjFactor = mx2celltab(dateHead, ASSET.Assets_Rated, dbgAssetAdjFactor);
        DBG.AssetTargetShare = mx2celltab(dateHead, ASSET.Assets_Rated, dbgAssetTargetShare);
        
        dbgClassOE = zeros(length(CLASS.Therapy_Class), length(eventDates));
        dbgClassP = zeros(length(CLASS.Therapy_Class), length(eventDates));
        dbgClassAdjFactor = zeros(length(CLASS.Therapy_Class), length(eventDates));
        dbgClassTargetShare = zeros(length(CLASS.Therapy_Class), length(eventDates));
        for m = 1:length(CLASS.Therapy_Class)
            ix = strcmpi(CLASS.Therapy_Class{m}, ASSET.Therapy_Class);
            if sum(ix) > 0
                dbgClassOE(m,:) = nansum(dbgAssetOE(ix,:), 1);
                dbgClassP(m,:) = nansum(dbgAssetP(ix,:), 1);
                dbgClassAdjFactor(m,:) = nansum(dbgAssetAdjFactor(ix,:), 1);
                dbgClassTargetShare(m,:) = nansum(dbgAssetTargetShare(ix,:), 1);
            end
        end
        DBG.ClassOrderOfEntry = mx2celltab(dateHead, CLASS.Therapy_Class, dbgClassOE);
        DBG.ClassProfile = mx2celltab(dateHead, CLASS.Therapy_Class, dbgClassP);
        DBG.ClassAdjFactor = mx2celltab(dateHead, CLASS.Therapy_Class, dbgClassAdjFactor);
        DBG.ClassTargetShare = mx2celltab(dateHead, CLASS.Therapy_Class, dbgClassTargetShare);
        
        SIM.DBG = DBG;
    end
    
end

function celltab = mx2celltab(colHead, rowHead, dataMx)
    celltab = [[{''}, colHead(:)']; [rowHead(:), num2cell(dataMx)]];
end