function share = profileModel(MODEL, ASSET, CLASS, isLaunch, eventDate)
    %% for each active Asset within a Therapy Class
    % Replaces strcmp(MODEL.CountrySelected, ASSET.Country)
    ixA = (MODEL.CountrySelected == ASSET.Country) ...
          & isLaunch ...
          & (ASSET.Launch_Date <= eventDate);  % assets in-country, launched and active on eventDate

    score = ASSET.Efficacy(ixA) + ...
            ASSET.S_T(ixA) + ...
            ASSET.Delivery(ixA);
    therapyClass = ASSET.Therapy_Class(ixA);
    % Get class names to avoid slow tabular.dotParenReference
    therapyClassNames=CLASS.Therapy_Class;
    
    
    %% Find the share per asset as the product of the share within a class
    % and the share of the entire class
    
    elasticScore = (score / nansum(score)) .^ MODEL.ProfileElasticity;
    
    bestInClass = nan(size(therapyClassNames));
    shareWithinClass = nan(size(elasticScore));
    
    for m = 1:length(bestInClass)
        thisClass = therapyClassNames(m);
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
    for m = 1:length(therapyClassNames)
        thisClass = therapyClassNames(m);
        ixClass = thisClass == therapyClass;
        productShare(ixClass) = classShare(m) * shareWithinClass(ixClass);        
    end
    
    share = nan(size(ixA));
    share(ixA) = productShare;
    
end