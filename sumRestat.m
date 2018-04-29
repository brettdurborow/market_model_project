function [ASSET3, RESTAT3] = sumRestat(ASSET1, RESTAT1, ASSET2, RESTAT2)
    % NOTE: Assumes that asset sheets underlying ESTAT1 and ESTAT2 have exact
    % same set of assets in exact same order
    
    Assets = union(ASSET1.Assets_Rated, ASSET2.Assets_Rated, 'stable');
    [iA1, LocA1] = ismember(Assets, ASSET1.Assets_Rated);
    [iA2, LocA2] = ismember(Assets, ASSET2.Assets_Rated);
    
    DateGrid = union(RESTAT1.Branded.M.DateGrid, RESTAT2.Branded.M.DateGrid);
    [iM1, LocM1] = ismember(DateGrid, RESTAT1.Branded.M.DateGrid);
    [iM2, LocM2] = ismember(DateGrid, RESTAT2.Branded.M.DateGrid);
    
    YearVec = union(RESTAT1.Branded.Y.YearVec, RESTAT2.Branded.Y.YearVec);
    [iY1, LocY1] = ismember(YearVec, RESTAT1.Branded.Y.YearVec);
    [iY2, LocY2] = ismember(YearVec, RESTAT2.Branded.Y.YearVec);
    
    ASSET3.Assets_Rated = Assets;
    
    LOE_Year = nan(size(Assets)); % take the latest LOE_Year of the two countries
    LOE_Year(iA1) = cell2mat(ASSET1.LOE_Year(LocA1(iA1)));
    LOE_Year(iA2) = nanmax(LOE_Year(iA2), cell2mat(ASSET2.LOE_Year(LocA2(iA2))));
    ASSET3.LOE_Year = num2cell(LOE_Year);
    
    ASSET3.Company1 = cell(size(ASSET3.Assets_Rated));
    ASSET3.Company1(iA1) = ASSET1.Company1(LocA1(iA1));
    
    ASSET3.Company2 = cell(size(ASSET3.Assets_Rated));
    ASSET3.Company2(iA1) = ASSET1.Company2(LocA1(iA1));
    
    ASSET3.Therapy_Class = cell(size(ASSET3.Assets_Rated));
    ASSET3.Therapy_Class(iA1) = ASSET1.Therapy_Class(LocA1(iA1));
    
    ASSET3.Scenario_PTRS = cell(size(ASSET3.Assets_Rated));
    ixBoth = iA1 & iA2;
    ixEq = false(size(ixBoth));
    ixEq(ixBoth) = cell2mat(ASSET1.Scenario_PTRS(LocA1(ixBoth))) == ...
                   cell2mat(ASSET2.Scenario_PTRS(LocA2(ixBoth)));
    ASSET3.Scenario_PTRS(ixEq) = ASSET1.Scenario_PTRS(LocA1(ixEq));
    ASSET3.Scenario_PTRS(~ixEq) = {nan};
    
    % ---------------------------------------------------
    RESTAT3 = struct;
    RESTAT3.Branded.M.DateGrid = RESTAT1.Branded.M.DateGrid;
    RESTAT3.Branded.Y.YearVec = RESTAT1.Branded.Y.YearVec;
    
    metricnames = {'NetRevenues', 'Units'};
    statnames = fieldnames(RESTAT1.Branded.M.NetRevenues);
    
    for m = 1:length(metricnames)
        for s = 1:length(statnames)
            MM = zeros(length(Assets), length(DateGrid));
            MM(iA1,iM1) = RESTAT1.Branded.M.(metricnames{m}).(statnames{s})(LocA1(iA1), LocM1(iM1));
            MM(iA2,iM2) = MM(iA2,iM2) + RESTAT2.Branded.M.(metricnames{m}).(statnames{s})(LocA2(iA2), LocM2(iM2));
            RESTAT3.Branded.M.(metricnames{m}).(statnames{s}) = MM;
            
            YM = zeros(length(Assets), length(YearVec));
            YM(iA1,iY1) = RESTAT1.Branded.Y.(metricnames{m}).(statnames{s})(LocA1(iA1), LocY1(iY1));
            YM(iA2,iY2) = YM(iA2,iY2) + RESTAT2.Branded.Y.(metricnames{m}).(statnames{s})(LocA2(iA2), LocY2(iY2));
            RESTAT3.Branded.Y.(metricnames{m}).(statnames{s}) = YM;
        end
    end
        

end