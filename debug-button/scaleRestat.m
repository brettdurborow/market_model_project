function RESTAT2 = scaleRestat(RESTAT1, factor)

    RESTAT2 = struct;
    RESTAT2.Branded.M.DateGrid = RESTAT1.Branded.M.DateGrid;
    RESTAT2.Branded.Y.YearVec = RESTAT1.Branded.Y.YearVec;
    
    intervalnames = {'Y', 'M'};
    metricnames = {'NetRevenues', 'Units', 'GTN','NetRevenuesNRA', 'UnitsNRA'};
    statnames = fieldnames(RESTAT1.Branded.M.NetRevenues);
    for n = 1:length(statnames)
        for p = 1:length(metricnames)
            for q = 1:length(intervalnames)            
                RESTAT2.Branded.(intervalnames{q}).(metricnames{p}).(statnames{n}) = ...
                    RESTAT1.Branded.(intervalnames{q}).(metricnames{p}).(statnames{n}) * factor;
            end
        end
    end
    
end