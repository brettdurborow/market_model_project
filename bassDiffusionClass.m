function [dateGrid, sharePerAssetMonthlySeries, sharePerClassMonthlySeries, DBG] = bassDiffusionClass(ASSET, CLASS, isLaunch, eventDates, sharePerAssetEventSeries, doDebug)
% Find the subset of eventDates corresponding to class launches in the current realization
% Find the target share for each class on each event date
% Over dateGrid, Diffuse the class shares toward their target shares

    DBG = struct;
    Na = length(ASSET.Assets_Rated);
    daysPerMonth = 30.4;
    daysPerYear = 365.25;
    
    startDate = max(ASSET.Starting_Share_Date);  % Should be only one value here, but max is just in case
    [yr0, mo0, dy0] = datevec(startDate);

    monthCount = ceil(120 + (eventDates(end) - startDate) / daysPerMonth);  % 10 years after last event
    dateGrid = datenum(yr0, mo0:mo0+monthCount, 1);  % Grid of monthly dates from startDate to 10 years after last event
    Nd = length(dateGrid);


    %% Class Diffusion

    Nc = length(CLASS.Therapy_Class);

    sharePerClassMonthlySeries = zeros(Nc, Nd);
    classEventDates = [];
    classPVec = [];
    classQVec = [];
    nClass = 0;
    
    for m = 1:Nc
        ixC = find(strcmpi(CLASS.Therapy_Class{m}, ASSET.Therapy_Class) & isLaunch);  % Assets in this class that launched
        if ~isempty(ixC)
            [firstDate, ixD] = min(ASSET.Launch_Date(ixC));  % Initial launch date of this class
            nClass = nClass + 1;
            classEventDates(nClass) = firstDate;
            classPVec(nClass) = ASSET.Class_p{ixC(ixD)};
            classQVec(nClass) = ASSET.Class_q{ixC(ixD)};
            % Initialize starting value for mothly class share series
            sharePerClassMonthlySeries(m,1) = sum(cell2mat(ASSET.Starting_Share(ixC))) / nansum(cell2mat(ASSET.Starting_Share(isLaunch)));  
        end        
    end
    
    % Sort by date
    [classEventDates, ix] = sort(classEventDates);
    classPVec = classPVec(ix);
    classQVec = classQVec(ix);
    
    % Find starting values to initialize the diffusion 
    ix = find(classEventDates <= startDate);
    ixP = find(classEventDates == classEventDates(ix(end)));
    if length(ixP) > 1  % two events happen on same date, pick the one with max P
        [classP, ixM] = max(classPVec(ixP));
        classQ = classQVec(ixM);
    else
        classP = classPVec(ixP);
        classQ = classQVec(ixP);
    end
    
    % Remove pre-start date values
    % Prepend startDate and corresponding P and Q values
    ix = classEventDates > startDate;
    classEventDates = [startDate, classEventDates(ix)];
    classPVec = [classP, classPVec(ix)];
    classQVec = [classQ, classQVec(ix)];

        
    %% Run the class Bass-Diffusion loop
    if doDebug
        dbgBassClass = cell(Nc+6, Nd);
        dbgBassClassPrep = cell(2*Nc+5, Nc);
    end
    
    for m = 1:length(classEventDates)
        eventDate = classEventDates(m);
        if m == length(classEventDates)
            nextDate = dateGrid(end);  % last iteration of the loop
        else
            nextDate = classEventDates(m+1);
        end
        
        if doDebug
            [yr, mo, ~] = datevec(eventDate);
            dbgBassClassPrep{1, m} = yr + mo/12;
            dbgBassClassPrep{2, m} = classPVec(m);
            dbgBassClassPrep{3, m} = classQVec(m);           
        end

        % compute monthly time vector for bass diffusion
        ixStart = find(dateGrid == eventDate, 1);
        ixEnd = find(dateGrid == nextDate, 1);
        tt = (dateGrid(ixStart:ixEnd) - dateGrid(ixStart)) / daysPerYear;
        
        % compute target shares for each asset in this class on this event date
        for n = 1:Nc     
            ixC = find(strcmpi(CLASS.Therapy_Class{n}, ASSET.Therapy_Class) & isLaunch);  % Assets in this class that launched
            if ~isempty(ixC)
                ixE = find(eventDates == classEventDates(m));
                if length(ixE) ~= 1
                    error('Duplicate event dates');
                end
                shareTarget = sum(sharePerAssetEventSeries(ixC, ixE));
                shareStart = sharePerClassMonthlySeries(n, ixStart);
                share = bassDiffusion(tt, classPVec(m), classQVec(m), shareStart, shareTarget, false);
                sharePerClassMonthlySeries(n, ixStart:ixEnd) = share;
                if doDebug
                    dbgBassClassPrep{4+n, m} = shareStart;
                    dbgBassClassPrep{5+Nc+n, m} = shareTarget;
                end
            end
        end
        
        if doDebug        
            dbgBassClass(1, ixStart:ixEnd) = repmat({year(eventDate) + month(eventDate)/12}, 1, length(tt));
            dbgBassClass(2, ixStart:ixEnd) = repmat({year(nextDate) + month(eventDate)/12}, 1, length(tt));
            dbgBassClass(3, ixStart:ixEnd) = repmat({classPVec(m)}, 1, length(tt));
            dbgBassClass(4, ixStart:ixEnd) = repmat({classQVec(m)}, 1, length(tt));
            dbgBassClass(5, ixStart:ixEnd) = num2cell(sum(sharePerClassMonthlySeries(:, ixStart:ixEnd), 1));
            dbgBassClass(6, ixStart:ixEnd) = num2cell(year(dateGrid(ixStart:ixEnd)) + month(dateGrid(ixStart:ixEnd))/12);
            dbgBassClass(7:end, ixStart:ixEnd) = num2cell(sharePerClassMonthlySeries(:, ixStart:ixEnd));
        end
        
    end
    if doDebug
        sideHead = [{'eventDate'; 'nextDate'; 'p'; 'q'; 'sum'; 'gridDate'}; CLASS.Therapy_Class(:)];
        DBG.BassClass = [sideHead, dbgBassClass];
        sideHeadPrep = [{'eventDate'; 'classP'; 'classQ'; '';}; CLASS.Therapy_Class(:); {''}; CLASS.Therapy_Class(:)];
        DBG.BassClassPrep = [sideHeadPrep, dbgBassClassPrep];
    end

    %% Asset Diffusion
    
    sharePerAssetMonthlySeriesRaw = zeros(Na, Nd);
    sharePerAssetMonthlySeriesRaw(isLaunch,1) = cell2mat(ASSET.Starting_Share(isLaunch)) / nansum(cell2mat(ASSET.Starting_Share(isLaunch)));  
        
    % Find Asset event dates
    [assetEventDatesRaw, ix] = sort(ASSET.Launch_Date);
    assetPVecRaw = ASSET.Product_p(ix);
    assetQVecRaw = ASSET.Product_q(ix);
    
    % Find duplicate Asset Event Dates, use one with higher P value
    uDates = unique(assetEventDatesRaw(:))';
    assetEventDates = nan(size(uDates));
    assetPVec = nan(size(uDates));
    assetQVec = nan(size(uDates));
    for m = 1:length(uDates)
        ix = find(uDates(m) == assetEventDatesRaw);
        if length(ix) > 1            
            [~, ixP] = max(cell2mat(assetPVecRaw(ix)));
            assetEventDates(m) = uDates(m);
            assetPVec(m) = assetQVecRaw{ix(ixP)};
            assetQVec(m) = assetQVecRaw{ix(ixP)};
        else
            assetEventDates(m) = assetEventDatesRaw(ix);
            assetPVec(m) = assetPVecRaw{ix};
            assetQVec(m) = assetQVecRaw{ix};
        end
    end
    
    % Find starting values to initialize the diffusion 
    ix = find(assetEventDates <= startDate);
    ixP = find(assetEventDates == assetEventDates(ix(end)));
    if length(ixP) > 1  % two events happen on same date, pick the one with max P
        [assetP, ixM] = max(assetPVec(ixP));
        assetQ = assetQVec(ixM);
    else
        assetP = assetPVec(ixP);
        assetQ = assetQVec(ixP);
    end
    
    % Remove pre-start date values
    % Prepend startDate and corresponding P and Q values
    ix = assetEventDates > startDate;
    assetEventDates = [startDate, assetEventDates(ix)];
    assetPVec = [assetP, assetPVec(ix)];
    assetQVec = [assetQ, assetQVec(ix)];
    
    %% Run the Asset Bass Diffusion Loop
    
    for m = 1:length(assetEventDates)
        eventDate = assetEventDates(m);
        if m == length(assetEventDates)
            nextDate = dateGrid(end);  % last iteration of the loop
        else
            nextDate = assetEventDates(m+1);
        end

        % compute monthly time vector for bass diffusion
        ixStart = find(dateGrid == eventDate, 1);
        ixEnd = find(dateGrid == nextDate, 1);
        tt = (dateGrid(ixStart:ixEnd) - dateGrid(ixStart)) / daysPerYear;
        
        % compute target shares for each asset on this event date
        ixE = find(eventDates == assetEventDates(m));
        if length(ixE) ~= 1
            error('Duplicate event dates');
        end
        for n = 1:Na
            if isLaunch(n)
                shareTarget = sharePerAssetEventSeries(n, ixE);
                shareStart = sharePerAssetMonthlySeriesRaw(n, ixStart);
                share = bassDiffusion(tt, assetPVec(m), assetQVec(m), shareStart, shareTarget, false);
                sharePerAssetMonthlySeriesRaw(n, ixStart:ixEnd) = share;
            end        
        end
    end
    
    %% Blend the Class and Asset diffusion numbers 
    
    sharePerAssetMonthlySeries = zeros(Na, Nd);
    for m = 1:Nc
        ix = find(strcmpi(CLASS.Therapy_Class{m}, ASSET.Therapy_Class));
        
        % COMBINED DIFFUSION -----------------------------------------------------
        % Scale asset shares within a class to sum to class shares in classShareMx
        numer = sharePerClassMonthlySeries(m,:);
        denom = sum(sharePerAssetMonthlySeriesRaw(ix,:), 1);
        if any(numer ~= 0 & denom == 0)
            error('Unexpected values in assetShare and classShare');
        end
        scaleVec = zeros(1, Nd);
        ixNZ = denom ~= 0;
        scaleVec(ixNZ) = numer(ixNZ) ./ denom(ixNZ);
        for n = 1:length(ix)  % Now normalize asset shares to sum to class share
            sharePerAssetMonthlySeries(ix(n),:) = sharePerAssetMonthlySeriesRaw(ix(n),:) .* scaleVec;
        end
    end


end