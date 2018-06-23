function cCNSTR = getConstraints(cASSET)   
    %% Find the assets that are unpredictable across all countries.
    % They are the ones with PTRS between p1% and 100%
    % Since PTRS can vary across countries, use the average PTRS for each 
    % asset that's unpredictable in at least one country.
    % Don't allow follow-on Assets to be treated as unpredictable
    % Do force Phase3 assets to be included in the constraint set
    
    p1 = 0.01;
    p2 = 1.0;
    q1 = 0.4;
    
    cRiskyAssets = cell(size(cASSET));
    cRiskyProb = cell(size(cASSET));
    for m = 1:length(cASSET)
        ASSET = cASSET{m};
        ixFollowOn = ~cellfun(@(C) isequaln(C, nan), ASSET.Follow_On);
        ixPhase3 = contains(ASSET.Phase, '3');
        ixRisky = cell2mat(ASSET.Scenario_PTRS) >= p1 & cell2mat(ASSET.Scenario_PTRS) < p2 & ~ixFollowOn;
        ixRisky = ixRisky | ixPhase3;
        cRiskyAssets{m} = ASSET.Assets_Rated(ixRisky);
        cRiskyProb{m} = cell2mat(ASSET.Scenario_PTRS(ixRisky));
    end
    riskyAssets = unique(vertcat(cRiskyAssets{:}));
    riskyProb = zeros(size(riskyAssets));

    for n = 1:length(riskyAssets)
        num = 0;
        den = 0;
        for m = 1:length(cRiskyAssets)
            ix = find(strcmp(riskyAssets{n}, cRiskyAssets{m}));
            if length(ix) == 1
                den = den + 1;
                num = num + cRiskyProb{m}(ix);
            end
        end
        riskyProb(n) = num / den;
    end
    [riskyProb, ix] = sort(riskyProb, 'ascend');
    riskyAssets = riskyAssets(ix);
    ixIsRisky = find(ismember(ASSET.Assets_Rated, riskyAssets));

    %% Find the set of constrained scenarios we wish to run
    %  Limit constraint sets to 1 + 2*n where n = number of assets with prob > 0.10

    NONE = 0;  ON = 1;  OFF = 2;  % possible constraint values
    
    CNSTR.Assets_Rated = riskyAssets;
    CNSTR.Scenario_PTRS = riskyProb;
    
    conSetLen = 1 + 2 * length(riskyAssets);
    cCNSTR = cell(conSetLen, 0);
    cCNSTR{1,1} = makeConstraint(1, riskyAssets, zeros(size(riskyAssets)));
    nn = 1;
    for m = length(riskyAssets):-1:1
        constraintValues = zeros(size(riskyAssets));
        constraintValues(m) = ON;
        prob = riskyProb(m);
        nn = nn + 1;        
        cCNSTR{nn,1} = makeConstraint(prob, riskyAssets, constraintValues);
        
        constraintValues(m) = OFF;
        prob = 1 - riskyProb(m);
        nn = nn + 1;
        cCNSTR{nn,1} = makeConstraint(prob, riskyAssets, constraintValues);        
    end
    
end

%% Helper Functions
    
function CNSTR = makeConstraint(prob, riskyAssets, constraintValues)
    CNSTR.ConstraintName =  makeConstraintName(riskyAssets, constraintValues);
    CNSTR.Probability = prob;
    CNSTR.ConstraintAssets = riskyAssets;
    CNSTR.ConstraintValues = constraintValues;
end

function name = makeConstraintName(constraintAssets, constraintValues)
    NONE = 0;  ON = 1;  OFF = 2;  % possible constraint values
    name = sprintf('CNSTR_%d', base2num(constraintValues, 3));
end

%%
    % Limit constraint sets to 1 + 2*n where n = number of assets with prob > 0.10


%     NONE = 0;
%     ON = 1;
%     OFF = 2;
%     constraintStates = [NONE, ON, OFF];
% 
%     CNSTR.Assets_Rated = riskyAssets;
%     CNSTR.Scenario_PTRS = riskyProb;
% 
%     conVecLen = length(CNSTR.Assets_Rated);
%     base = length(constraintStates);
%     conSetCount = base ^ conVecLen;
%     cCNSTR = cell(0,0);
%     for m = 1:conSetCount
%         conVec = num2base(m-1, base, conVecLen);
% 
%         prob = 1;
%         for n = 1:length(conVec)
%             if conVec(n) == ON
%                 prob = prob * CNSTR.Scenario_PTRS(n);
%             elseif conVec(n) == OFF
%                 prob = prob * (1 - CNSTR.Scenario_PTRS(n));
%             end
%         end
% 
%         CNSTR.ConstraintVec = conVec;
%         CNSTR.Probability = prob;
%         if CNSTR.Probability >= q1
%             name = '';
%             for n = 1:length(CNSTR.Assets_Rated)
%                 if CNSTR.ConstraintVec(n) == ON
%                     name = [name, '+', upper(CNSTR.Assets_Rated{n}(1:3))];
%                 elseif CNSTR.ConstraintVec(n) == OFF
%                     name = [name, '-', upper(CNSTR.Assets_Rated{n}(1:3))];
%                 end    
%             end
%             CNSTR.ConstraintName = name;
%             cCNSTR{end+1, 1} = CNSTR;    
%         end
%     end


    
    
    
    
    
    
    
    
    
    
    
    
    
    
    