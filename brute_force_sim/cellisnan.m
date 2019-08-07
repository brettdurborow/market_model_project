function ix = cellisnan(cellarray)
% cellarray can be scalar, vector, or matrix
% returns logical array the same size as c, with a true value for each cell
% containing a nan of length 1, false otherwise

[RR, CC] = size(cellarray);
ix = false(RR, CC);


for rr = 1:RR
    for cc = 1:CC
        if length(cellarray{rr, cc}) == 1 && ismissing(cellarray{rr, cc})
            ix(rr, cc) = true;
        end
    end
end