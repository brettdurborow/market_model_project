function sharePerAsset = orderOfEntryModel(MODEL, ASSET, CLASS, isLaunch, eventDate, elastClass, elastAsset)



    %% for each Therapy Class, compute the Per-Class share
    
    ixC = CLASS.First_Launch_Date <= eventDate;  % classes active on eventDate
    classRank = CLASS.First_Launch_Rank;
    classRank(~ixC) = nan;
    
    sharePerClass = oeShare(classRank, elastClass);  % same size as fields in CLASS struct
    
    %% for each Asset within a Therapy Class, compute the per-Asset-within-Class share
    
    ixA = MODEL.CountrySelected == ASSET.Country ...
          & isLaunch ...
          & ASSET.Launch_Date <= eventDate;  % assets in-country, launched and active on eventDate
      
    sharePerAssetWithinClass = nan(size(ASSET.Assets_Rated));
    sharePerAsset = nan(size(ASSET.Assets_Rated));
        
    fxC = find(ixC);
    for m = 1:length(fxC)
        thisClass = CLASS.Therapy_Class(fxC(m));
        thisClassShare = sharePerClass(fxC(m));
        
        ix = (thisClass == ASSET.Therapy_Class) & ixA;
        if sum(ix) == 0
            error('Unable to find assets belonging to class %s on date %s', thisClass, datestr(eventDate));
        end
        
        assetRank = rankWithDuplicates(ASSET.Launch_Date(ix));
        sharePerAssetWithinClass(ix) = oeShare(assetRank, elastAsset);
        sharePerAsset(ix) = sharePerAssetWithinClass(ix) * thisClassShare;
    end
    
    

end

