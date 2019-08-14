function [sharePerAssetMonthlySeries, sharePerClassMonthlySeries, DBG] = bassDiffusionClass(dateGrid,ASSET, CLASS, isLaunch, eventDates, sharePerAssetEventSeries, doDebug)
% Find the subset of eventDates corresponding to class launches in the current realization
% Find the target share for each class on each event date
% Over dateGrid, Diffuse the class shares toward their target shares

    DBG = struct;
    Na = length(ASSET.Assets_Rated);
    Nd = length(dateGrid);

    daysPerYear = 365.25;
    startDate=min(dateGrid);
    %startDate=max(ASSET.Starting_Share_Date);
    
    % Get class names to avoid slow tabular.dotParenReference
    therapyClass = ASSET.Therapy_Class;
    therapyClassNames=CLASS.Therapy_Class;
    %% Class Diffusion

    Nc = length(therapyClassNames);

    sharePerClassMonthlySeries = zeros(Nc, Nd);
    classEventDates = [];%datetime([],'ConvertFrom','datenum');
    classPVec = [];
    classQVec = [];
    nClass = 0;
    
    for m = 1:Nc
        ixC = find((therapyClassNames(m) == therapyClass) & isLaunch);  % Assets in this class that launched
        if ~isempty(ixC)
            [firstDate, ixD] = min(ASSET.Launch_Date(ixC));  % Initial launch date of this class
            nClass = nClass + 1;
            classEventDates(nClass) = firstDate;
            classPVec(nClass) = ASSET.Class_p(ixC(ixD));
            classQVec(nClass) = ASSET.Class_q(ixC(ixD));
            % Initialize starting value for mothly class share series
            sharePerClassMonthlySeries(m,1) = sum(ASSET.Starting_Share(ixC)) / nansum(ASSET.Starting_Share(isLaunch));  
        end        
    end
    
    % Sort by date
    [classEventDates, ix] = sort(classEventDates);
    classPVec = classPVec(ix);
    classQVec = classQVec(ix);
    
    % Find starting values to initialize the diffusion 
    ix = find(classEventDates <= startDate);
    % It can happen that all events are in the future
    if ~isempty(ix)
        % This case is where there are event dates in the past
        ixP = find(classEventDates == classEventDates(ix(end)));
        if length(ixP) > 1  % two events happen on same date, pick the one with max P
            [classP, ixM] = max(classPVec(ixP));
            classQ = classQVec(ixM);
        else
            classP = classPVec(ixP);
            classQ = classQVec(ixP);
        end
    else
        % All class events are in the future, so we have to do something.
        % Check this assumption with Michel Nijs.
        classP=classPVec(1);
        classQ=classQVec(1);
    end
    
    % Remove pre-start date values
    % Prepend startDate and corresponding P and Q values
    ix = classEventDates > startDate;
    classEventDates = [startDate, classEventDates(ix)];
    classPVec = [classP, classPVec(ix)];
    classQVec = [classQ, classQVec(ix)];

        
    %% Run the class Bass-Diffusion loop
    if doDebug
        dbgBassClass = zeros(Nc+6, Nd);
        dbgBassClassPrep = zeros(2*Nc+5, Nc);
    end
    classTarget=nan(Nc,length(classEventDates));
    for m = 1:length(classEventDates)
        eventDate = classEventDates(m);
        if m == length(classEventDates)
            nextDate = dateGrid(end);  % last iteration of the loop
        else
            nextDate = classEventDates(m+1);
        end
        
        if doDebug
            dbgBassClassPrep(1, m) = datenumToYearFraction(eventDate);
            dbgBassClassPrep(2, m) = classPVec(m);
            dbgBassClassPrep(3, m) = classQVec(m);           
        end

        % compute monthly time vector for bass diffusion
        ixStart = find(dateGrid == eventDate, 1);
        ixEnd = find(dateGrid == nextDate, 1);
        if isdatetime(dateGrid)
            tt = years((dateGrid(ixStart:ixEnd) - dateGrid(ixStart)));
        else
            tt = years(days(dateGrid(ixStart:ixEnd) - dateGrid(ixStart)));
            tt1 = (dateGrid(ixStart:ixEnd) - dateGrid(ixStart))/daysPerYear;
        end
        
        fprintf('Nrm tt-tt1: %g\n',norm(tt-tt1));
        % compute target shares for each asset in this class on this event date
        for n = 1:Nc     
            ixC = find((therapyClassNames(n) == therapyClass) & isLaunch);  % Assets in this class that launched
            if ~isempty(ixC)
                ixE = find(eventDates == classEventDates(m));
                if length(ixE) ~= 1
                    error('Duplicate event dates');
                end
                shareTarget = sum(sharePerAssetEventSeries(ixC, ixE));
                shareStart = sharePerClassMonthlySeries(n, ixStart);
                share = bassDiffusion(tt, classPVec(m), classQVec(m), shareStart, shareTarget, false);
                sharePerClassMonthlySeries(n, ixStart:ixEnd) = share;
                
                % Save the target share these only make sense for the
                % future, so defining them only on the event dates should
                % be fine.
                classTarget(n,m)=shareTarget;
                classStart(n,m)=shareStart;
                if doDebug
                    dbgBassClassPrep(4+n, m) = shareStart;
                    dbgBassClassPrep(5+Nc+n, m) = shareTarget;
                end
            end
        end
        % Basically, we need to normalize the class share so that it always
        % adds to one. Somehow, this doesn't work, maybe we have to
        % normalize at the end...
        %sharePerClassMonthlySeries(:,ixStart:ixEnd)=sharePerClassMonthlySeries(:,ixStart:ixEnd)./nansum(sharePerClassMonthlySeries(:,ixStart:ixEnd));
        
        if doDebug        
            dbgBassClass(1, ixStart:ixEnd) = datenumToYearFraction(eventDate);
            dbgBassClass(2, ixStart:ixEnd) = datenumToYearFraction(nextDate);
            dbgBassClass(3, ixStart:ixEnd) = classPVec(m);
            dbgBassClass(4, ixStart:ixEnd) = classQVec(m);
            dbgBassClass(5, ixStart:ixEnd) = sum(sharePerClassMonthlySeries(:, ixStart:ixEnd), 1);
            dbgBassClass(6, ixStart:ixEnd) = datenumToYearFraction(dateGrid(ixStart:ixEnd)) / 12;
            dbgBassClass(7:end, ixStart:ixEnd) = sharePerClassMonthlySeries(:, ixStart:ixEnd);
        end
        
    end
    if doDebug
        sideHead = [{'eventDate'; 'nextDate'; 'p'; 'q'; 'sum'; 'gridDate'}; therapyClassNames(:)];
        %DBG.rowBassClass=sideHead;
        DBG.BassClass = table(sideHead,dbgBassClass);
        sideHeadPrep = [{'eventDate'; 'classP'; 'classQ'; '';}; therapyClassNames(:); {''}; therapyClassNames(:)];
        %DBG.rowBassClassPrep=sideHeadPrep;
        DBG.BassClassPrep = table(sideHeadPrep,dbgBassClassPrep);
    end
    
    % We normalize the class share curve after all the events have been
    % done
    %sharePerClassMonthlySeries = sharePerClassMonthlySeries./nansum(sharePerClassMonthlySeries);
    %% Asset Diffusion
    
    sharePerAssetMonthlySeriesRaw = zeros(Na, Nd);
    sharePerAssetMonthlySeriesRaw(isLaunch,1) = ASSET.Starting_Share(isLaunch) / nansum(ASSET.Starting_Share(isLaunch));  
        
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
            [~, ixP] = max(assetPVecRaw(ix));
            assetEventDates(m) = uDates(m);
            assetPVec(m) = assetQVecRaw(ix(ixP));
            assetQVec(m) = assetQVecRaw(ix(ixP));
        else
            assetEventDates(m) = assetEventDatesRaw(ix);
            assetPVec(m) = assetPVecRaw(ix);
            assetQVec(m) = assetQVecRaw(ix);
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
        
        if isnumeric(dateGrid)
            tt = (dateGrid(ixStart:ixEnd) - dateGrid(ixStart)) / daysPerYear;
        else
            %tt = years((dateGrid(ixStart:ixEnd) - dateGrid(ixStart)));
            tt = (dateGrid(ixStart:ixEnd) - dateGrid(ixStart))/daysPerYear;
        end
        
        
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
        ix = find(therapyClassNames(m) == therapyClass);
        
        % COMBINED DIFFUSION -----------------------------------------------------
        % Scale asset shares within a class to sum to class shares in classShareMx
        numer = sharePerClassMonthlySeries(m,:);
        denom = sum(sharePerAssetMonthlySeriesRaw(ix,:), 1);
        if any(numer ~= 0 & denom == 0)
            keyboard
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

function tab = mx2tab(colHead, rowHead, dataMx)
    tab = struct('colNames',colHead,'rowNames',rowHead,'data',dataMx);
    %[[{''}, colHead(:)']; [rowHead(:), num2cell(dataMx)]];
end