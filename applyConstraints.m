function [MODEL, ASSET, ESTAT] = applyConstraints(CNSTR, MODEL, ASSET, ...
                                SimCubeBranded, SimCubeMolecule, dateGrid)                                                       
    % for a given constraint, compute the ensemble stats from just those rows of
    % the SimCubeBranded and SimCubeMolecule that satisfy the constraint.  

    NONE = 0;  ON = 1;  OFF = 2;  % possible constraint values
    
    MODEL.ConstraintName = CNSTR.ConstraintName;  % goes to output

    Nrealizations = size(SimCubeBranded, 1);  % first dimension is the # of realizations
    ixExclude = false(Nrealizations, 1);
    ixA = find(CNSTR.ConstraintValues);
    
    if isempty(ixA)  % There were no constraints
        ESTAT = computeEnsembleStats(SimCubeBranded, SimCubeMolecule, dateGrid);
    else
        for m = 1:length(ixA)
            ixRow = find(strcmpi(CNSTR.ConstraintAssets{ixA(m)}, ASSET.Assets_Rated));
            if length(ixRow) > 1
                error('Name of constrainted asset should match no more than one asset in ASSET sheet');
            elseif length(ixRow) == 1
                % OR the constraints, so any constraint violated is enough to exclude the realization
                if CNSTR.ConstraintValues(ixA(m)) == ON
                    ASSET.Scenario_PTRS{ixRow} = 1;
                    % find realizations in cube with this asset OFF, and exclude them
                    for n = 1:Nrealizations
                        ixExclude(n) = ixExclude(n) || all(SimCubeBranded(n, ixRow, :) == 0);                
                    end
                elseif CNSTR.ConstraintValues(ixA(m)) == OFF
                    ASSET.Scenario_PTRS{ixRow} = 0;
                    % find realizations in cube with this asset ON, and exclude them
                    for n = 1:Nrealizations
                        ixExclude(n) = ixExclude(n) || any(SimCubeBranded(n, ixRow, :) > 0);                
                    end
                else
                    error('Unrecognized case');
                end
            end
        end
    
        ESTAT = computeEnsembleStats(SimCubeBranded(~ixExclude,:,:), ...
                                     SimCubeMolecule(~ixExclude,:,:), dateGrid);
    end
    
end


