function [dateGrid, SimCubeBranded, SimCubeMolecule, tExec] = marketModelMonteCarlo(MODEL, ASSET, CHANGE, numIterations, numWorkers)

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
    isLaunch = rand(Na,1) < ASSET.Scenario_PTRS;
    isChange = rand(Nchange,1) < cell2mat(CHANGE.Scenario_PTRS);     
    SIM = marketModelOneRealization(MODEL, ASSET, CHANGE, isLaunch, isChange, false);  % one once to initialize
    dateGrid = SIM.DateGrid;
    Nt = length(dateGrid);
    Na = length(ASSET.Scenario_PTRS);

    hW = waitbar(0, 'Monte Carlo Loop: Starting');

    simNum = 0;
    tRemainVec = zeros(numIterations, 1);
    SimCubeBranded = zeros(Na, Nt,numIterations);  % 3D data cube for percentile calcs
    if ~saveMemory
        SimCubeMolecule = zeros(Na, Nt,numIterations);
    end
    
    if numWorkers > 1
        % Only do parallel sends if in parallel mode #PL
        D = parallel.pool.DataQueue;
        afterEach(D, @myUpdateWaitbar);
        
        % Setup parallel execution ------------------------------------
        myPool = gcp('nocreate');
        if isempty(myPool)
            parpool(numWorkers);
            pause(5); % Don't bias the first run's execution timer 
        elseif myPool.NumWorkers ~= numWorkers
            delete(myPool);
            parpool(numWorkers);
            pause(5); % Don't bias the first run's execution timer 
        else
            % pool already exists with right number of workers.  Just use it.
        end
        
        tStart = tic;
        parfor m = 1:numIterations
            [isLaunch, isChange] = randomLaunchRealization(ASSET, CHANGE);  

            SIM = marketModelOneRealization(MODEL, ASSET, CHANGE, isLaunch, isChange, false);

            if ~isempty(SIM)
                SimCubeBranded(:, :,m) = SIM.BrandedMonthlyShare;
                if ~saveMemory
                    SimCubeMolecule(:, :,m) = SIM.SharePerAssetMonthlySeries;
                end
            end
            send(D, 0);
        end
    else
        % Single-Threaded Execution ------------------------------------
        tStart = tic;
        for m = 1:numIterations
            [isLaunch, isChange] = randomLaunchRealization(ASSET, CHANGE);

            SIM = marketModelOneRealization(MODEL, ASSET, CHANGE, isLaunch, isChange, false);

            if ~isempty(SIM)
                SimCubeBranded(:, :,m) = SIM.BrandedMonthlyShare;
                if ~saveMemory
                    SimCubeMolecule(:, :,m) = SIM.SharePerAssetMonthlySeries;
                end
            end
            % Omit any calls to parallel code #PL
            myUpdateWaitbar();
            %send(D, 0);
        end
        
        
    end
    tExec = toc(tStart); % Measure just the execution time influenced by numIterations, numWorkers, and Na
    close(hW);
    
    % Nested Function ---------------------------------------
    function myUpdateWaitbar(~)
        simNum = simNum + 1;
        tElapsed = toc(tStart);
        tRemain = max(1, round((numIterations - simNum) * tElapsed / simNum));
        tRemainVec(simNum) = tRemain;
        tRemainEst = min(tRemainVec(max(1, simNum-2*numWorkers):simNum));
        if tRemainEst < 60
            msg = sprintf('%s Monte Carlo Loop: Approx %d seconds remaining', MODEL.CountrySelected, tRemainEst);
        else
            mins = fix(tRemainEst / 60);
            secs = tRemainEst - 60 * mins;
            msg = sprintf('%s Monte Carlo Loop: Approx %d:%02d minutes remaining', MODEL.CountrySelected, mins, secs);
        end
        waitbar(simNum / numIterations, hW, msg);        
    end


end

%% Local Functions -----------------------------------
function [isLaunch, isChange] = randomLaunchRealization(ASSET, CHANGE)

    % Follow-On Assets have a non-NaN value in the column: ASSET.Follow_On
    % Its value is the name of the primary Asset to be followed.  
    isPrimary = ismissing(ASSET.Follow_On);
    % replaces: isPrimary = cellisnan(ASSET.Follow_On);
    
    % First, determine whether Primary assets launch in this realization
    isLaunchPrimary = false(size(ASSET.Scenario_PTRS));
    isLaunchPrimary(isPrimary) = rand(sum(isPrimary), 1) < ASSET.Scenario_PTRS(isPrimary);
   
    % For each follow-on Asset, learn whether its primary asset has launched.
    % If so, launch the follow-on asset.
    ixFollowOn = find(~isPrimary);   
    ix = ismember(ASSET.Follow_On(ixFollowOn), ASSET.Assets_Rated(isLaunchPrimary));    
    isLaunchFO = false(size(ASSET.Scenario_PTRS));
    isLaunchFO(ixFollowOn(ix)) = true;

    isLaunch = isLaunchPrimary | isLaunchFO;
    isChange = rand(length(CHANGE.Scenario_PTRS), 1) < cell2mat(CHANGE.Scenario_PTRS);      
    
end

