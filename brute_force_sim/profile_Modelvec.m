function share = profile_Modelvec(MODEL,ASSET,CLASS,isLaunch,eventDates)
% profile_Model is a vectorized version of the original profile model.
% Instead of looping over each event we do everything in one step.

therapyClassNames=CLASS.Therapy_Class;

% First sompute a logical array for the when the assets are active
ixA=(ASSET.Launch_Date<=eventDates') & isLaunch;

% Evaluate the score and distribute
scores = (ASSET.Efficacy + ASSET.S_T + ASSET.Delivery);

% Compute the exponential model 
elasticScore = scores.*ixA;
elasticScore = elasticScore./sum(elasticScore,1);
%elasticScore = elasticScore.^MODEL.ProfileElasticity;
elasticScore(~ixA)=nan;
bestInClass=nan(height(CLASS),length(eventDates));
shareWithinClass=nan(size(elasticScore));
for ID=1:height(CLASS)
    iC=ASSET.Therapy_Class==therapyClassNames(ID);
    bestInClass(ID,:)=max(elasticScore(iC,:).^MODEL.ProfileElasticity,[],1);
    shareWithinClass(iC,:)=elasticScore(iC,:).^CLASS.InClassPMProductElasticity(ID)./sum(elasticScore(iC,:).^CLASS.InClassPMProductElasticity(ID),1,'omitnan');
end
%shareWithinClass(isnan(shareWithinClass))=0;
classShare=bestInClass./sum(bestInClass,1,'omitnan');
productShare=nan(size(elasticScore));
for ID=1:height(CLASS)
    iC=ASSET.Therapy_Class==therapyClassNames(ID);
    productShare(iC,:)=classShare(ID,:).*shareWithinClass(iC,:);
end

share = nan(size(ixA));
share(ixA) = productShare(ixA);
end