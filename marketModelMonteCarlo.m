function [SimCube, dateGrid] = marketModelMonteCarlo(MODEL, ASSET, CHANGE, numIterations, numWorkers)


    rng(100);  % set random number seed.  Remove this after debugging

    isLaunch = cell2mat(ASSET.Launch_Simulation) == 1;   % Temporary - make it match the Excel sheet
    isChange = true(size(CHANGE.Scenario_PTRS));
    SIM = marketModelOneRealization(MODEL, ASSET, CHANGE, isLaunch, isChange);  % one once to initialize
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
    SimCube = zeros(numIterations, Na, Nt);  % 3D data cube for percentile calcs
    tStart = tic;
    
    myPool = gcp('nocreate');
    if isempty(myPool)
        parpool(numWorkers);
    elseif myPool.NumWorkers ~= numWorkers
        delete(myPool);
        parpool(numWorkers);
    else
        % pool already exists with right number of workers.  Just use it.
    end        
    
    parfor m = 1:numIterations
        isLaunch = rand(Na,1) < probVecAsset;
        isChange = rand(Nchange,1) < probVecChange;    

        SIM = marketModelOneRealization(MODEL, ASSET, CHANGE, isLaunch, isChange);

        SimCube(m, :, :) = SIM.SharePerAssetMonthlySeries;
        send(D, 0);
    end
    close(hW);
    
    
    function myUpdateWaitbar(~)
        simNum = simNum + 1;
        tElapsed = toc(tStart);
        tRemain = round((numIterations - simNum) * tElapsed / simNum);
        msg = sprintf('Monte Carlo Loop: Approx %d seconds remaining', tRemain);
        waitbar(simNum / numIterations, hW, msg);        
    end


end