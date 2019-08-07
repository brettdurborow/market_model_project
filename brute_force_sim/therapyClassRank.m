function CLASS = therapyClassRank(ASSET, isLaunch)
% In this function, we are will compute a table containing the class first
% launch date and the first launch rank (including duplicates).

    [uClass,~,iC]= unique(ASSET.Therapy_Class, 'sorted');

    firstLaunch = nan(size(uClass));
    for m = 1:length(uClass)
        ix = (iC==m) & isLaunch;
        if sum(ix) > 0
            firstLaunch(m) = min(ASSET.Launch_Date(ix));
        end    
    end
    
    [~,~,launchRank]=unique(firstLaunch);
    CLASS = table(uClass,firstLaunch,launchRank,...
        'VariableNames',["Therapy_Class","First_Launch_Date","First_Launch_Rank"]);
   
end