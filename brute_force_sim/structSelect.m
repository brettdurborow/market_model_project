function uv = structSelect(st, ix, dim)
    % function uv = structSelectSort(st, ix, sortField)
    %
    % struct st should contain several named fields, each of the same length Len.
    %
    % This function creats a new struct uv, with the same named fields, but with
    % each field downselected by the index ix.
    %    if ix is a logical index, then ix *must* be Len elements long.
    %    if ix is a find style index, then max(ix) must be <= Len
    %
    % If sortField is non-empty, the resulting downselected fields will all be sorted
    % according to the ascending order of sortField.
    
    fnames = fieldnames(st);
    
    if ~isempty(ix) && islogical(ix)
        Len = length(ix);
    else
        lengths = zeros(length(fnames), 1);
        for m = 1:length(fnames)
            lengths(m) = size(st.(fnames{m}), dim);
        end
        lengths = lengths(lengths>1);
        Len = mode(lengths);
    end
     
    for m = 1:length(fnames)
        if size(st.(fnames{m}), dim) == Len
            if dim == 1
                uv.(fnames{m}) = st.(fnames{m})(ix,:);
            elseif dim == 2
                uv.(fnames{m}) = st.(fnames{m})(:,ix);
            end
        else
            uv.(fnames{m}) = st.(fnames{m});
        end
    end