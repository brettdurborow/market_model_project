

riskyAssets = cell(size(cASSET));
for m = 1:length(cASSET)
    ASSET = cASSET{m};
    ix = find(cell2mat(ASSET.Scenario_PTRS) >= 0.5 & cell2mat(ASSET.Scenario_PTRS) < 1);
    riskyAssets{m} = ASSET.Assets_Rated(ix);
end
riskyAssets = unique(vertcat(riskyAssets{:}));

%%

ASSET = cASSET{7};

NONE = 0;
ON = 1;
OFF = 2;
constraintStates = [NONE, ON, OFF];

CNSTR.Assets_Rated = riskyAssets;
[Lia, Locb] = ismember(CNSTR.Assets_Rated, ASSET.Assets_Rated);
CNSTR.Scenario_PTRS = nan(size(CNSTR.Assets_Rated));
CNSTR.Scenario_PTRS(Lia) = cell2mat(ASSET.Scenario_PTRS(Locb));

conVecLen = length(CNSTR.Assets_Rated);
base = length(constraintStates);
conSetCount = base ^ conVecLen;
ConSet = cell(conSetCount, 1);
for m = 1:conSetCount
    conVec = num2base(m-1, base, conVecLen);
    
    prob = 1;
    for n = 1:length(conVec)
        if conVec(n) == ON
            prob = prob * CNSTR.Scenario_PTRS(n);
        elseif conVec(n) == OFF
            prob = prob * (1 - CNSTR.Scenario_PTRS(n));
        end
    end
    
    CNSTR.ConstraintVec = conVec;
    CNSTR.Probability = prob;
    ConSet{m} = CNSTR;    
end

%%

ConSetFiltered = cell(0,1);
for m = 1:length(ConSet)
    CNSTR = ConSet{m};
    if CNSTR.Probability > 0.4
        name = '';
        for n = 1:length(CNSTR.Assets_Rated)
            if CNSTR.ConstraintVec(n) == ON
                name = [name, '+', upper(CNSTR.Assets_Rated{n}(1:3))];
            elseif CNSTR.ConstraintVec(n) == OFF
                name = [name, '-', upper(CNSTR.Assets_Rated{n}(1:3))];
            end    
        end
        CNSTR.ConstraintName = name;
        ConSetFiltered{end+1, 1} = CNSTR;
    end
end

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    