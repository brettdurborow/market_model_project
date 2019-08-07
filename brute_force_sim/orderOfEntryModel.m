function sharePerAsset = orderOfEntryModel(MODEL, ASSET, CLASS, isLaunch, eventDates)

Nevents=length(eventDates);
% Extract the class names and launch dates to improve performance
therapyClassNames=CLASS.Therapy_Class;
assetTherapyClass = ASSET.Therapy_Class;
assetLaunchDate=ASSET.Launch_Date;
ProductOeElasticity = MODEL.ProductOeElasticity;
%% for each Therapy Class, compute the Per-Class share
ixC=repmat(CLASS.First_Launch_Date,1,Nevents)<=repmat(eventDates',length(CLASS.First_Launch_Date),1);

%ixC = CLASS.First_Launch_Date <= eventDate;  % classes active on eventDate
classRank = repmat(CLASS.First_Launch_Rank,1,length(eventDates));
classRank(~ixC) = nan;

sharePerClass = oeShare(classRank, MODEL.ClassOeElasticity);  % same size as fields in CLASS struct

%% for each Asset within a Therapy Class, compute the per-Asset-within-Class share
ixA= repmat(assetLaunchDate,1,Nevents)<=repmat(eventDates',length(assetLaunchDate),1) & isLaunch;

%     ixA = MODEL.CountrySelected == ASSET.Country ...
%           & isLaunch ...
%           & ASSET.Launch_Date <= eventDate;  % assets in-country, launched and active on eventDate
      
    sharePerAssetWithinClass = nan(size(ASSET.Assets_Rated));
    sharePerAsset = nan(size(ASSET.Assets_Rated));
    
    fxC = find(ixC);
    for m = 1:length(fxC)
        %thisClass = CLASS.Therapy_Class(fxC(m));
        thisClass = therapyClassNames(fxC(m));
        thisClassShare = sharePerClass(fxC(m));
        
        ix = (thisClass == assetTherapyClass) & ixA;
        if sum(ix) == 0
            error('Unable to find assets belonging to class %s on date %s', thisClass, datestr(eventDate));
        end
        
        %[~,~,assetRank] = unique(ASSET.Launch_Date(ix));
        [~,~,assetRank] = unique(assetLaunchDate(ix));
        sharePerAssetWithinClass(ix) = oeShare(assetRank, ProductOeElasticity);
        sharePerAsset(ix) = sharePerAssetWithinClass(ix) * thisClassShare;
    end
    
    

end

