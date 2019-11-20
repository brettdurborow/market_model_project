function sharePerAsset = orderOfEntryModelvec(MODEL, ASSET, CLASS, isLaunch, eventDates)%Ta, CLASS, eventDates,ClassOeElasticity,ProductOeElasticity)

Nevents=length(eventDates);
Nassets=length(ASSET.Assets_Rated);

% Extract the class names and launch dates to improve performance
therapyClassNames=CLASS.Therapy_Class;
assetTherapyClass = ASSET.Therapy_Class;
assetLaunchDate = ASSET.Launch_Date;

isLaunchC=ismember(CLASS.Therapy_Class,ASSET.Therapy_Class(isLaunch));


%% for each Therapy Class, compute the Per-Class share
ixC=(CLASS.First_Launch_Date<=eventDates') & isLaunchC;

% Replicate the class Ranking for the model computation
sharePerClass = (CLASS.First_Launch_Rank.^MODEL.ClassOeElasticity).*ixC;
sharePerClass = sharePerClass./sum(sharePerClass);
sharePerClass(~ixC) = nan;

%% for each Asset within a Therapy Class, compute the per-Asset-within-Class share
ixA= (assetLaunchDate<=eventDates') & isLaunch;


sharePerAsset = nan(Nassets,Nevents);
fxC=find(isLaunchC);
for m = 1:length(fxC)
    
    thisClass = therapyClassNames(fxC(m));
    thisClassShare = sharePerClass(fxC(m),:);
    
    ix = (thisClass == assetTherapyClass) & ixA;
    ixD1 = sum(ix,1)>0;
    ixD2 = sum(ix,2)>0;
    if sum(ixD2) == 0
        error('Unable to find assets belonging to class %s on date %s', thisClass, datestr(eventDates));
    end
    
    [~,~,assetRank] = unique(assetLaunchDate(ixD2));
    sharePerAssetWithinClass=(assetRank.^CLASS.In_Class_Product_Elasticity(fxC(m))).*ix(ixD2,:);
    sharePerAssetWithinClass=sharePerAssetWithinClass./sum(sharePerAssetWithinClass,1);
    sharePerAssetWithinClass(~ix(ixD2,:))=nan;
    
    sharePerAsset(ixD2,:)=sharePerAssetWithinClass.*thisClassShare;
    %sharePerAssetWithinClass(ix) = oeShare(assetRank, CLASS.InClassProductElasticity);
    %sharePerAsset = sharePerAssetWithinClass(ix) * thisClassShare;
end



end