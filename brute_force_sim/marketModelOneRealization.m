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
    nClasses=length(CLASS.Therapy_Class);
    eventDates = unique([ASSET.Launch_Date; ASSET.LOE_Date; ASSET.Starting_Share_Date; CHANGE.Launch_Date; CHANGE.LOE_Date]);
    nEvents = length(eventDates);

    sharePerAssetEventSeries = zeros(Na,nEvents);  % row for each asset, col for each date
    
    if doDebug
        dbgAssetOE = zeros(Na,nEvents);
        dbgAssetP = zeros(Na,nEvents);
        dbgAssetAdjFactor = zeros(Na,nEvents);
        dbgAssetTargetShare = zeros(Na,nEvents);
        dbgAssetUnadjTargetShare = zeros(Na,nEvents);
    end
    
    for m = 1:nEvents

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
            dbgAssetUnadjTargetShare(:,m) = sharePerAsset;
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
        % all of the following arrays hacve their first row the event date
        % converted to a fractional year. Thus, we can convert this data to
        % a 
       
        %dateHead = num2cell(year(eventDates) + month(eventDates) / 12); 
        dateHead = datenumToYearFraction(eventDates);
        
        % Store everything in table for writing
        %DBG.Asset=table(dbgAssetOE,dbgAssetP,dbgAssetAdjFactor,dbgAssetTargetShare,dbgAssetUnadjdbgAssetOE(:,ix)TargetShare,'RowNames',ASSET.Assets_Rated);
        DBG.EventDates=dateHead';
        DBG.AssetOrderOfEntry = dbgAssetOE;
        DBG.AssetProfile = dbgAssetP;
        DBG.AssetAdjFactor = dbgAssetAdjFactor;
        DBG.AssetTargetShare = dbgAssetTargetShare;
        DBG.AssetUnadjTargetShare = dbgAssetUnadjTargetShare;
        
        dbgClassOE = zeros(nClasses,nEvents);
        dbgClassP = zeros(nClasses,nEvents);
        dbgClassAdjFactor = zeros(nClasses,nEvents);
        dbgClassTargetShare = zeros(nClasses,nEvents);
        dbgClassUnadjTargetShare = zeros(nClasses,nEvents);
        for m = 1:nClasses
            ix = CLASS.Therapy_Class(m) == ASSET.Therapy_Class;
            if sum(ix) > 0
                dbgClassOE(m,:) = nansum(dbgAssetOE(ix,:), 1);
                dbgClassP(m,:) = nansum(dbgAssetP(ix,:), 1);
                dbgClassTargetShare(m,:) = nansum(dbgAssetTargetShare(ix,:), 1);
                
                %Possible removal
                dbgClassAdjFactor(m,:) = nanmean(dbgAssetAdjFactor(ix,:), 1);
                dbgClassUnadjTargetShare(m,:) = nansum(dbgAssetUnadjTargetShare(ix,:), 1);
            end
        end
        
        %DBG.Class=table(dbgClassOE,dbgClassP,dbgClassAdjFactor,dbgClassTargetShare,dbgClassUnadjTargetShare,'RowNames',CLASS.Therapy_Class);
        DBG.ClassNames = CLASS.Therapy_Class;
        DBG.ClassOrderOfEntry = dbgClassOE;
        DBG.ClassProfile = dbgClassP;
        DBG.ClassAdjFactor = nan*dbgClassAdjFactor;
        DBG.ClassTargetShare = dbgClassTargetShare;
        DBG.ClassUnadjTargetShare =  dbgClassUnadjTargetShare;
        SIM.DBG = DBG;
    end
    
end

function tab = mx2tab(colHead, rowHead, dataMx)
    tab = struct('colNames',colHead,'rowNames',rowHead,'data',dataMx);
    %[[{''}, colHead(:)']; [rowHead(:), num2cell(dataMx)]];
end