function cCNSTR = getConstraints(cASSET)   
    %% Find the assets that are unpredictable across all regions.
    % They are the ones with PTRS between p1% and 100%
    % Since PTRS can vary across regions, use the average PTRS for each 
    % asset that's unpredictable in at least one country.
    % Don't allow follow-on Assets to be treated as unpredictable
    % Do force Phase3 and Phase2b assets to be included in the constraint set, 
    % unless they have PTRS of 100%

    % We are first going to calculate the individual Janssen asset launches
    cJanssenAssets = cell(size(cASSET));
    cJanssenProb = cell(size(cASSET));
    for m=1:length(cASSET)
        ASSET = cASSET{m};
        ixJanssen = ASSET.Company1 == "Janssen";
        cJanssenAssets{m} = ASSET.Assets_Rated(ixJanssen);
        cJanssenProb{m} = ASSET.Scenario_PTRS(ixJanssen);
    end
    % Find the unique asset and calculate their probability
    janssenAssets=unique(vertcat(cJanssenAssets{:}));
    janssenProb=mean(horzcat(cJanssenProb{:}),2);
    % Sort the Janssen assets on their probability
    [janssenProb,ixProb]=sort(janssenProb,'ascend');
    janssenAssets=janssenAssets(ixProb);
    
    p0 = 0.10;
    p1 = 1.0;
    
    cRiskyAssets = cell(size(cASSET));
    cRiskyProb = cell(size(cASSET));
    for m = 1:length(cASSET)
        ASSET = cASSET{m};
        ixFollowOn = ~cellfun(@(C) isequaln(C, nan), ASSET.Follow_On);
        % Needs new code for follow on.
        ixPhase3 = contains(ASSET.Phase, '3');
        ixPhase2b = contains(ASSET.Phase, '2b');
        ixRisky = ASSET.Scenario_PTRS >= p0 & ASSET.Scenario_PTRS < p1 & ~ixFollowOn;
        ixRisky = ixRisky | ixPhase3 | ixPhase2b;
        cRiskyAssets{m} = ASSET.Assets_Rated(ixRisky);
        cRiskyProb{m} = ASSET.Scenario_PTRS(ixRisky);
    end
    riskyAssets = unique(vertcat(cRiskyAssets{:}));
    riskyProb = zeros(size(riskyAssets));

    % Most Assets occur in multiple regions.  
    % Average their probability over the regions where they occur.
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
    ixOmit = riskyProb < p0 | riskyProb >= p1;
    riskyProb = riskyProb(~ixOmit);
    riskyAssets = riskyAssets(~ixOmit);
    [riskyProb, ix] = sort(riskyProb, 'ascend');
    riskyAssets = riskyAssets(ix);
    
    [Lia, Locb] = ismember(riskyAssets, ASSET.Assets_Rated);
    riskyPhase = ASSET.Phase(Locb);

    %% Find the set of constrained scenarios we wish to run
    %  Limit constraint sets to 1 + 2*n where n = number of assets with prob > 0.10

    NONE = 0;  ON = 1;  OFF = 2;  % possible constraint values
    
    conSetLen = 1 + 2 * length(riskyAssets) +length(janssenAssets) +1;
    cCNSTR = cell(conSetLen, 0);
    cCNSTR{1,1} = makeConstraint(1, riskyAssets, zeros(size(riskyAssets)));
 
    nn = 1;
    
    % First set the individual Janssen assets.
    for m=1:length(janssenAssets)
        constraintValues = zeros(size(janssenAssets));
        constraintValues(m) = ON;
        prob = janssenProb(m);
        nn = nn + 1;
        cCNSTR{nn,1} = struct('ConstraintCode',-m,...
            'ConstraintName',sprintf('Janssen_%s',regexprep(janssenAssets(m),'\s','_')),...
            'Probability',prob,'ConstraintAssets',janssenAssets,...
            'ConstraintValues',constraintValues);
        
    end
    
    % The probability of all Janssen assets launching should be less than
    % any of the individual asset launch probabilities, so we append to the
    % beginning of the list
    nn=nn+1;
    cCNSTR{nn,1}=struct('ConstraintCode',-length(janssenAssets)-1,...
            'ConstraintName','Janssen_All',...
            'Probability',prod(janssenProb),'ConstraintAssets',janssenAssets,...
            'ConstraintValues',ones(size(janssenAssets)));
            
    % Switch each risky asset on and off in isolation, one at a time
    for m = length(riskyAssets):-1:1
        constraintValues = zeros(size(riskyAssets));
        constraintValues(m) = ON;
        prob = riskyProb(m);
        nn = nn + 1;        
        cCNSTR{nn,1} = makeConstraint(prob, riskyAssets, constraintValues);
        
        constraintValues(m) = OFF;
        prob = 1 - riskyProb(m);
        if prob >= p0
            nn = nn + 1;
            cCNSTR{nn,1} = makeConstraint(prob, riskyAssets, constraintValues);
        end
    end
    
    % For just the Ph3 and Ph2b assets, find ALL combinations with prob > 0.1
    ixPhase2b3Reg = find(contains(riskyPhase, '3') | contains(riskyPhase, '2b') ...
                 | contains(upper(riskyPhase), 'REG'));
    Len2b3 = length(ixPhase2b3Reg);
    Mmax = base2num(2 * ones(1, Len2b3), 3);
    for m = 1:Mmax
        constraintValues = zeros(size(riskyAssets));
        constraintValues(ixPhase2b3Reg) = num2base(m, 3, Len2b3);
        prob = prod([riskyProb(constraintValues == ON); 1-riskyProb(constraintValues == OFF)]);
        if prob >= p0
            nn = nn + 1;
            cCNSTR{nn,1} = makeConstraint(prob, riskyAssets, constraintValues);            
        end
    end
    
    cCNSTR = uniqueCNSTR(cCNSTR);
end

%% Helper Functions
    
function CNSTR = makeConstraint(prob, riskyAssets, constraintValues)
    CNSTR.ConstraintCode = base2num(constraintValues, 3);
    CNSTR.ConstraintName = sprintf('CNSTR_%d', CNSTR.ConstraintCode);
    CNSTR.Probability = prob;
    CNSTR.ConstraintAssets = riskyAssets;
    CNSTR.ConstraintValues = constraintValues;
end

function cCNSTR = uniqueCNSTR(cCNSTR)
    cCodes = cell2mat(cellfun(@(C) C.ConstraintCode, cCNSTR, 'UniformOutput', false));
    [~, ia, ~] = unique(cCodes);
    if length(ia) < length(cCodes)  % if we neede to remove any duplicates
        cCNSTR = cCNSTR(ia);
    end
end


    
    
    
    
    
    
    
    
    
    
    
    
    