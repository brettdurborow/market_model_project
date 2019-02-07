function ix = cellisempty(cellarray)
% cellarray can be scalar, vector, or matrix
% returns logical array the same size as c, with a true value for each cell
% containing a single [] or ''




[RR, CC] = size(cellarray);
ix = false(RR, CC);


for rr = 1:RR
    for cc = 1:CC
        if isempty(cellarray{rr, cc})
            ix(rr, cc) = true;
        end
    end
end

% This works too, but the nested loop appears quicker
% ix0 = cellfun(@isempty, cellarray, 'UniformOutput', false);
% len = cellfun(@length, ix0);
% ix = (len == 1) & cellfun(@(x)x, ix0);