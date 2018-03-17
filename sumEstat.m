function [ASSET3, ESTAT3] = sumEstat(ASSET1, ESTAT1, ASSET2, ESTAT2)
    % NOTE: Assumes that asset sheets underlying ESTAT1 and ESTAT2 have exact
    % same set of assets in exact same order

    if length(ESTAT1.DateGrid) ~= length(ESTAT2.DateGrid) || ...
            any(ESTAT1.DateGrid ~= ESTAT2.DateGrid)
        error('Mismatch between dates of ESTAT1 and ESTAT2');   
    end
    
    C = union(ASSET1.Assets_Rated, ASSET2.Assets_Rated, 'stable');
    ASSET3.Assets_Rated = C;
    [i1, Loc1] = ismember(C, ASSET1.Assets_Rated);
    [i2, Loc2] = ismember(C, ASSET2.Assets_Rated);
    
    ESTAT3 = struct;
    ESTAT3.DateGrid = ESTAT1.DateGrid;
    ESTAT3.Branded = struct;
    ESTAT3.Molecule = struct;
    
    fnamesB = fieldnames(ESTAT1.Branded);
    fnamesM = fieldnames(ESTAT1.Molecule);
    for m = 1:length(C)
        if i1(m) && i2(m)
            for n = 1:length(fnamesB)
                ESTAT3.Branded.(fnamesB{n})(m,:) = ESTAT1.Branded.(fnamesB{n})(Loc1(m),:) + ESTAT2.Branded.(fnamesB{n})(Loc2(m),:);
            end
            for n = 1:length(fnamesM)
                ESTAT3.Molecule.(fnamesM{n})(m,:) = ESTAT1.Molecule.(fnamesM{n})(Loc1(m),:) + ESTAT2.Molecule.(fnamesM{n})(Loc2(m),:);
            end
        elseif i1(m)
            for n = 1:length(fnamesB)
                ESTAT3.Branded.(fnamesB{n})(m,:) = ESTAT1.Branded.(fnamesB{n})(Loc1(m),:);
            end
            for n = 1:length(fnamesM)
                ESTAT3.Molecule.(fnamesM{n})(m,:) = ESTAT1.Molecule.(fnamesM{n})(Loc1(m),:);
            end
        elseif i2(m)
            for n = 1:length(fnamesB)
                ESTAT3.Branded.(fnamesB{n})(m,:) = ESTAT2.Branded.(fnamesB{n})(Loc2(m),:);
            end
            for n = 1:length(fnamesM)
                ESTAT3.Molecule.(fnamesM{n})(m,:) = ESTAT2.Molecule.(fnamesM{n})(Loc2(m),:);
            end
        else
            error('This state should never happen');            
        end

    end


end