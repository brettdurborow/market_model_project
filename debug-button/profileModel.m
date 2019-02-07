function share = profileModel(MODEL, ASSET, CHANGE, CLASS, isLaunch, isChange, eventDate)

    %% for each active Asset within a Therapy Class
    % Replaces strcmp(MODEL.CountrySelected, ASSET.Country)
    ixA = MODEL.CountrySelected == ASSET.Country ...
          & isLaunch ...
          & ASSET.Launch_Date <= eventDate;  % assets in-country, launched and active on eventDate

    score = ASSET.Efficacy(ixA) + ...
            ASSET.S_T(ixA) + ...
            ASSET.Delivery(ixA);
    therapyClass = ASSET.Therapy_Class(ixA);
    
    
    %% Handle ChangeEvents if there are any

    
    for m = 1:length(CHANGE.Asset)
        if isChange(m) && CHANGE.Launch_Date(m) <= eventDate  % if this change is active
            ix = find(strcmp(CHANGE.Asset{m}, ASSET.Assets_Rated(ixA)) & strcmp(MODEL.CountrySelected, ASSET.Country(ixA)));
            
            if isempty(ix)
                error('ChangeEvents sheet contains unrecognized asset: "%s"', CHANGE.Asset{m});
            elseif length(ix) > 1
                error('Asset name: "%s" in ChangeEvents sheet matches multiple rows in "Assets" sheet', CHANGE.Asset{m});
            end
            if isLaunch(ix)  % only apply the change if the product was launched in the first place
                %score(ix) = CHANGE.Total_Preference_Score{m};
                score(ix) = CHANGE.Efficacy{m} + CHANGE.S_T{m} + CHANGE.Delivery{m};
                therapyClass{ix} = CHANGE.Therapy_Class{m};
            end
        end
    end
    
    
    %% Find the share per asset as the product of the share within a class
    % and the share of the entire class
    
    elasticScore = (score / nansum(score)) .^ MODEL.ProfileElasticity;
    
    bestInClass = nan(size(CLASS.Therapy_Class));
    shareWithinClass = nan(size(elasticScore));
    for m = 1:length(bestInClass)
        thisClass = CLASS.Therapy_Class(m);
        ixClass = thisClass == therapyClass;
        if sum(ixClass) > 0
            eScoreRaw=elasticScore(ixClass);
            bestInClass(m) = max(eScoreRaw(~isnan(eScoreRaw)));
            %bestInClass(m) = nanmax(elasticScore(ixClass));
            if all(elasticScore(ixClass) == 0)
                shareWithinClass(ixClass) = 0;
            else
                shareWithinClass(ixClass) = elasticScore(ixClass) / sum(elasticScore(ixClass));
            end
        end
    end
    
    classShare = bestInClass / nansum(bestInClass);
    
    productShare = nan(size(elasticScore));
    for m = 1:length(CLASS.Therapy_Class)
        thisClass = CLASS.Therapy_Class(m);
        ixClass = thisClass == therapyClass;
        productShare(ixClass) = classShare(m) * shareWithinClass(ixClass);        
    end
    
    share = nan(size(ixA));
    share(ixA) = productShare;
    
end