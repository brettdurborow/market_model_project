function vec = cappedGrowth(dateGrid, launchYear, startVal, growthRate, cap)

    [yr, ~, ~] = datevec(dateGrid);
    
    yearsSinceLaunch = yr - launchYear;
    ix = yearsSinceLaunch >= 0;

    yearlyVal = startVal * (1 + growthRate) .^ yearsSinceLaunch(ix);
    if growthRate > 0 
        yearlyVal = min(yearlyVal, cap);  % cap the growth at a max value
    else
        yearlyVal = max(yearlyVal, cap);  % cap the shrinkage at a min value
    end

    vec = zeros(size(dateGrid));
    vec(ix) = yearlyVal;
end