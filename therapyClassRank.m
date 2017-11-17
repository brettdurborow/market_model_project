function CLASS = therapyClassRank(MODEL, ASSET, isLaunch)


    uClass = unique(ASSET.Therapy_Class);
    isCountrySelected = strcmp(MODEL.CountrySelected, ASSET.Country);

    firstLaunch = nan(size(uClass));
    for m = 1:length(uClass)
        ix = strcmp(uClass{m}, ASSET.Therapy_Class) & isCountrySelected & isLaunch;
        if sum(ix) > 0
            firstLaunch(m) = min(ASSET.Launch_Date(ix));
        end    
    end
    
    CLASS = struct;
    CLASS.Therapy_Class = uClass;
    CLASS.First_Launch_Date = firstLaunch;
    CLASS.First_Launch_Rank = rankWithDuplicates(firstLaunch);
    
end