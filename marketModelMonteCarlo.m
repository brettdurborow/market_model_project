function [dateGrid, SimCubeBranded, SimCubeMolecule] = marketModelMonteCarlo(MODEL, ASSET, CHANGE, numIterations, numWorkers)

    if nargout < 3
        saveMemory = true;
        SimCubeMolecule = [];
    else
        saveMemory = false;
    end

    rng(100);  % set random number seed.  Remove this after debugging

%     isLaunch = cell2mat(ASSET.Launch_Simulation) == 1;   % Temporary - make it match the Excel sheet
%     isChange = true(size(CHANGE.Scenario_PTRS));  % Temporary - force changes to happen
    Na = length(ASSET.Scenario_PTRS);
    Nchange = length(CHANGE.Scenario_PTRS);
    isLaunch = rand(Na,1) < cell2mat(ASSET.Scenario_PTRS);
    isChange = rand(Nchange,1) < cell2mat(CHANGE.Scenario_PTRS);     
    SIM = marketModelOneRealization(MODEL, ASSET, CHANGE, isLaunch, isChange, false);  % one once to initialize
    dateGrid = SIM.DateGrid;
    Nt = length(dateGrid);
    Na = length(ASSET.Scenario_PTRS);
    Nchange = length(CHANGE.Scenario_PTRS);
   
    probVecAsset = cell2mat(ASSET.Scenario_PTRS);
    probVecChange = cell2mat(CHANGE.Scenario_PTRS);
    
    D = parallel.pool.DataQueue;
    hW = waitbar(0, 'Monte Carlo Loop: Starting');
    afterEach(D, @myUpdateWaitbar);

    simNum = 0;
    tRemainVec = zeros(numIterations, 1);
    SimCubeBranded = zeros(numIterations, Na, Nt);  % 3D data cube for percentile calcs
    if ~saveMemory
        SimCubeMolecule = zeros(numIterations, Na, Nt);
    end
    
    if numWorkers > 1
        % Setup parallel execution ------------------------------------
        myPool = gcp('nocreate');
        if isempty(myPool)
            parpool(numWorkers);
        elseif myPool.NumWorkers ~= numWorkers
            delete(myPool);
            parpool(numWorkers);
        else
            % pool already exists with right number of workers.  Just use it.
        end
        
        tStart = tic;
        parfor m = 1:numIterations
            isLaunch = rand(Na,1) < probVecAsset;
            isChange = rand(Nchange,1) < probVecChange;    

            SIM = marketModelOneRealization(MODEL, ASSET, CHANGE, isLaunch, isChange, false);

            if ~isempty(SIM)
                SimCubeBranded(m, :, :) = SIM.BrandedMonthlyShare;
                if ~saveMemory
                    SimCubeMolecule(m, :, :) = SIM.SharePerAssetMonthlySeries;
                end
            end
            send(D, 0);
        end
    else
        % Single-Threaded Execution ------------------------------------
        tStart = tic;
        for m = 1:numIterations
            isLaunch = rand(Na,1) < probVecAsset;
            isChange = rand(Nchange,1) < probVecChange;    

            SIM = marketModelOneRealization(MODEL, ASSET, CHANGE, isLaunch, isChange, false);

            if ~isempty(SIM)
                SimCubeBranded(m, :, :) = SIM.BrandedMonthlyShare;
                if ~saveMemory
                    SimCubeMolecule(m, :, :) = SIM.SharePerAssetMonthlySeries;
                end
            end
            send(D, 0);
        end
        
        
    end
    close(hW);
    
    
    function myUpdateWaitbar(~)
        simNum = simNum + 1;
        tElapsed = toc(tStart);
        tRemain = max(1, round((numIterations - simNum) * tElapsed / simNum));
        tRemainVec(simNum) = tRemain;
        tRemainEst = min(tRemainVec(max(1, simNum-2*numWorkers):simNum));
        msg = sprintf('Monte Carlo Loop: Approx %d seconds remaining', tRemainEst);
        waitbar(simNum / numIterations, hW, msg);        
    end


end