function y = rankWithDuplicates(x)

    [sorted, ix] = sort(x);
    y = nan(size(x));
    thisRank = 1;
    for m = 1:length(sorted)-1
        if ~isnan(sorted(m))
            y(ix(m)) = thisRank;
            if sorted(m+1) ~= sorted(m)
                thisRank = thisRank + 1;
            end
        end        
    end
    
    m = length(sorted);
    if ~isnan(sorted(m))
        y(ix(m)) = thisRank;
    end
    
end