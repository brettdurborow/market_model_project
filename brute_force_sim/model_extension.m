%% The objectives of this code is to:
%
%    1) Showcase the calibration of the starting shares by adjusting the
%    profile elasticity.
%
%    2) 
%  
ProfileElasticity=3
load('Market_Model_Assumptions.mat');
modelID=1;

[Tm,Ta,Td,eventTable,dateTable,Country,Asset,Class,Company]=preprocess_data(modelID,cMODEL(end),cASSET(end));

eventDates=datenum(eventTable.date);

share = profile_Model(Ta,Class,eventDates,ProfileElasticity);

CLASS=therapyClassRank(Ta,Class,true);
sharePerAsset = orderOfEntryModel(Ta, CLASS, eventDates,Tm.ClassOeElasticity,Tm.ProductOeElasticity)

function sharePerAsset = orderOfEntryModel(Ta, CLASS, eventDates,ClassOeElasticity,ProductOeElasticity)

Nevents=length(eventDates);
% Extract the class names and launch dates to improve performance
therapyClassNames=CLASS.Therapy_Class;
assetTherapyClass = Ta.Therapy_Class;
assetLaunchDate = Ta.Launch_Date;

%% for each Therapy Class, compute the Per-Class share
ixC=CLASS.First_Launch_Date<=eventDates';

% This is the new order of entry ranking. Classes who enter the market at
% the same time get that rank of share, rahter than a slightly smaller
% share based on averaging the share 
sharePerClass = (CLASS.First_Launch_Rank.^ClassOeElasticity).*ixC;
sharePerClass = sharePerClass./sum(sharePerClass);
sharePerClass(~ixC) = nan;

%% for each Asset within a Therapy Class, compute the per-Asset-within-Class share
ixA= assetLaunchDate<=eventDates';


sharePerAssetWithinClass = nan(size(Ta.Assets_Rated));
sharePerAsset = nan(size(Ta.Assets_Rated));

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


function share = profile_Model(Ta,Class,eventDates,ProfileElasticity)
% profile_Model is a vectorized version of the original profile model.
% Instead of looping over each event we do everything in one step.
% Elimitanting the nead 

ixA=Ta.Launch_Date<=eventDates';
score = (Ta.Efficacy + Ta.S_T + Ta.Delivery).*ixA;
elasticScore = (score ./ sum(score)) .^ ProfileElasticity;

bestInClass=zeros(height(Class),length(eventDates));
shareWithinClass=zeros(height(Class),length(eventDates));
for ID=Class.ID'
    iC=Ta.Class_ID==ID;
    bestInClass(ID,:)=max(elasticScore(iC,:),[],1);
    shareWithinClass(iC,:)=elasticScore(iC,:)./sum(elasticScore(iC,:),1);
end
shareWithinClass(isnan(shareWithinClass))=0;
classShare=bestInClass./sum(bestInClass);
productShare=zeros(size(elasticScore));
for ID=Class.ID'
    iC=Ta.Class_ID==ID;
    productShare(iC,:)=classShare(ID,:).*shareWithinClass(iC,:);
end

share = nan(size(ixA));
share(ixA) = productShare(ixA);
end

function oeVec = oeShareEqualRank(rankVec, elasticity)
% Compute market share based on order of market entry, using an exponential model.
% if elasticity is 0, share is divided equally among the entrants.  
% if elasticity is >0, later entrants receive more share than earlier ones
% if elasticity is <0, earlier entrants receive more share than later ones
%


oeVec=rankVec;
return

    ixOk = ~isnan(rankVec);
    okRank = rankVec.*ixOk;
    [N ,M] = size(okRank);  % number of competitors that launched
    
    order = repmat((1:N)',1,M);
    a_solve = log(1.0 ./ sum(order .^ elasticity));  % share weights must add to 1.0
    share = exp(a_solve).* order .^ elasticity;
    
    shareVec = nan(size(okRank));
    uRank = unique(okRank(:,end));
    p = 1;
    for m = 1:size(uRank,1)
        ix = find(okRank == uRank(m));
        q = p + length(ix) - 1;
        aveShare = sum(share(p:q)) / (q-p+1);
        shareVec(ix) = aveShare;
        p = q + 1;
    end
    
    oeVec = nan(size(rankVec));
    oeVec(ixOk) = shareVec;
    
end