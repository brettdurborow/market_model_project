function [dateGrid, sharePerAssetMonthlySeries] = bassDiffusionNested(ASSET, eventDates, sharePerAssetEventSeries)
% For each date, find the prior market share target, the next future market share target, 
% and the proper p and q.  Compute the interpolated market share using the Bass diffusion model


% Find for each Therapy Class (Nc < Na), the aggregate share over all assets in the class
% Find for each Therapy Class the p and q values, by finding max p and corresponding q among in-class assets
% For each Therapy Class, find monthly share via Bass Diffusion using p and q and start + end shares
% For each Asset within the Class, find monthly share via Bass Diffusion, s.t. asset share sums to class share on each date
% For each Asset within the Class, find Branded vs. Generic share via Bass Diffusion, s.t. B + S sum to asset share

% NOTE: this function assumes all dates start on 1st of month
%       this function also assumes that ASSET.Starting_Share_Date is a member of eventDates (so eventDates must be constructed this way)

    Na = length(ASSET.Assets_Rated);
    daysPerMonth = 30.4;
    daysPerYear = 365.25;

    startDate = max(ASSET.Starting_Share_Date);
    [yr0, mo0, dy0] = datevec(startDate);

    monthCount = ceil(120 + (eventDates(end) - startDate) / daysPerMonth);  % 10 years after last event
    dateGrid = datenum(yr0, mo0:mo0+monthCount, 1);  % Grid of monthly dates from startDate to 10 years after last event
    Nd = length(dateGrid);

    sharePerAssetMonthlySeries = zeros(Na, Nd);
    sharePerAssetMonthlySeries(:,1) = cell2mat(ASSET.Starting_Share) / nansum(cell2mat(ASSET.Starting_Share));

    m0 = find(eventDates == startDate, 1, 'first');  % eventDates must contain startDate
    for m = m0:length(eventDates)
        eventDate = eventDates(m);
        if m == length(eventDates)
            nextDate = dateGrid(end);  % last iteration of the loop
        else
            nextDate = eventDates(m+1);
        end

        ixStart = find(dateGrid == eventDate, 1);
        ixEnd = find(dateGrid == nextDate, 1);
        tt = (dateGrid(ixStart:ixEnd) - dateGrid(ixStart)) / daysPerYear;
        shareStartVec = sharePerAssetMonthlySeries(:,ixStart);
        shareTargetVec = sharePerAssetEventSeries(:, m); % col index corresponds to eventDate vector
        
        shareMx = bassDiffusionOneEvent(ASSET, tt, eventDate, nextDate, shareStartVec, shareTargetVec);
        sharePerAssetMonthlySeries(:, ixStart:ixEnd) = shareMx;
    end

end


function shareMx = bassDiffusionOneEvent(ASSET, tt, eventDate, nextDate, shareStartVec, shareTargetVec)
    
       
    Na = length(shareStartVec);
    uClass = unique(ASSET.Therapy_Class);
    Nc = length(uClass);
    
    % Find p and q for Therapy Class diffusion, from most recent event
    ix0 = find(eventDate == ASSET.Launch_Date);
    if isempty(ix0) % if event isn't a launch, then use most recent prior launch date
        tmpDate = max(ASSET.Launch_Date(ASSET.Launch_Date <= eventDate));
        ix0 = find(tmpDate == ASSET.Launch_Date);  
    end
    [pMaxClass, ix1] = max([ASSET.Class_p{ix0}]);
    qMaxClass = ASSET.Class_q{ix0(ix1)};        
    
    classShareMx = zeros(Nc, length(tt));
    shareMx = zeros(Na, length(tt)); 

    for m = 1:Nc
        ix = find(strcmpi(uClass(m), ASSET.Therapy_Class));
        s0 = sum(shareStartVec(ix));
        s1 = sum(shareTargetVec(ix));
        classShareMx(m,:) = bassDiffusion(tt, pMaxClass, qMaxClass, s0, s1, false);
        
        
        % Find p and q for assets within this Therapy Class, from most recent intra-class event
        ix0 = find(eventDate == ASSET.Launch_Date(ix));
        if isempty(ix0)
            tmpDates = ASSET.Launch_Date(ix);
            tmpDate = max(tmpDates(tmpDates <= eventDate));
            if ~isempty(tmpDate)
                ix0 = find(tmpDate == tmpDates);
            end
        end
        [pMax, ix1] = max([ASSET.Product_p{ix(ix0)}]);
        
        if ~isempty(pMax)
            qMax = ASSET.Product_q{ix(ix0(ix1))};
                    
            for n = 1:length(ix)
                s0 = shareStartVec(ix(n));
                s1 = shareTargetVec(ix(n));
                share = bassDiffusion(tt, pMax, qMax, s0, s1, false);  
                shareMx(ix(n), :) = share;
            end
            scaleVec = classShareMx(m,:) ./ sum(shareMx(ix,:), 1);
            for n = 1:length(ix)  % Now normalize asset shares to sum to class share
                shareMx(ix(n),:) = shareMx(ix(n),:) .* scaleVec;
            end
            
        end
        
    end
    
%     for n = 1:Na
%         share = bassDiffusion(tt, pMax, qMax, shareStartVec(n), shareTargetVec(n), false);
%         shareMx(n, :) = share;
%     end
    
    
end
