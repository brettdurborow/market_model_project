function [ASSET3, RESTAT3] = sumRestat(ASSET1, RESTAT1, ASSET2, RESTAT2)
    % NOTE: Assumes that asset sheets underlying ESTAT1 and ESTAT2 have exact
    % same set of assets in exact same order

    if length(RESTAT1.Branded.M.DateGrid) ~= length(RESTAT2.Branded.M.DateGrid) || ...
            any(RESTAT1.Branded.M.DateGrid ~= RESTAT2.Branded.M.DateGrid) || ...
            length(RESTAT1.Branded.Y.YearVec) ~= length(RESTAT2.Branded.Y.YearVec) || ...
            any(RESTAT1.Branded.Y.YearVec ~= RESTAT2.Branded.Y.YearVec)
        error('Mismatch between dates of ESTAT1 and ESTAT2');   
    end
    
    C = union(ASSET1.Assets_Rated, ASSET2.Assets_Rated, 'stable');
    [i1, Loc1] = ismember(C, ASSET1.Assets_Rated);
    [i2, Loc2] = ismember(C, ASSET2.Assets_Rated);

    ASSET3.Assets_Rated = C;
    LOE_Year = nan(size(C));
    LOE_Year(i1) = cell2mat(ASSET1.LOE_Year(Loc1(i1)));
    LOE_Year(i2) = nanmax(LOE_Year(i2), cell2mat(ASSET2.LOE_Year(Loc2(i2))));
    ASSET3.LOE_Year = num2cell(LOE_Year);  % take the latest LOE_Year of the two countries
    
    RESTAT3 = struct;
    RESTAT3.Branded.M.DateGrid = RESTAT1.Branded.M.DateGrid;
    RESTAT3.Branded.Y.YearVec = RESTAT1.Branded.Y.YearVec;
    
    intervalnames = {'Y', 'M'};
    metricnames = {'NetRevenues', 'Units'};
    statnames = fieldnames(RESTAT1.Branded.M.NetRevenues);
    
    for m = 1:length(C)
        if i1(m) && i2(m)
            for n = 1:length(statnames)
                for p = 1:length(metricnames)
                    for q = 1:length(intervalnames)
                        RESTAT3.Branded.(intervalnames{q}).(metricnames{p}).(statnames{n})(m,:) = ...
                            RESTAT1.Branded.(intervalnames{q}).(metricnames{p}).(statnames{n})(Loc1(m),:) + ...
                            RESTAT2.Branded.(intervalnames{q}).(metricnames{p}).(statnames{n})(Loc2(m),:);
                    end
                end
            end
        elseif i1(m)
           for n = 1:length(statnames)
                for p = 1:length(metricnames)
                    for q = 1:length(intervalnames)                    
                        RESTAT3.Branded.(intervalnames{q}).(metricnames{p}).(statnames{n})(m,:) = ...
                            RESTAT1.Branded.(intervalnames{q}).(metricnames{p}).(statnames{n})(Loc1(m),:);
                    end
                end
            end
        elseif i2(m)
            for n = 1:length(statnames)
                for p = 1:length(metricnames)
                    for q = 1:length(intervalnames)                    
                        RESTAT3.Branded.(intervalnames{q}).(metricnames{p}).(statnames{n})(m,:) = ...
                            RESTAT2.Branded.(intervalnames{q}).(metricnames{p}).(statnames{n})(Loc2(m),:);
                    end
                end
            end
        else
            error('This state should never happen!');
        end
    end
    
    

end