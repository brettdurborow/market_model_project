function st = structSort(st, sortFields, sortOrder)
% Recursive Multi-field Sort for DATASET struct
% Given a DATASET struct (having named fields of equal length and shape),
% sort it by one or more of its fields.  Intent is similar to sortrows(), 
% where ties are broken by sorting on the next field in the list.
% sortOrder is an optional cellstr with same length as sortFields, 
% having values 'ascend' or 'descend'

% NOTE: Currently only works on DATASETs with vector elements 
% (no multidimensional or hierarchical elements allowed)
%
% Should work on DATASET containing logical and numeric arrays but haven't tested yet
%
% ToDo: Can improve speed by refactoring.  Do all sorting with indexes and 
% reorder the actual elements at the very end of the process

    if ~exist('sortOrder', 'var') 
        sortOrder = repmat({'ascend'}, size(sortFields));
    end

    fnames = fieldnames(st);
    if ~all(ismember(sortFields, fnames))
        error('sortFields must all be valid fields of the input struct'); 
    end
    
    % First level sort -----------------------------------
    ix = sortOneArray(st.(sortFields{1}), sortOrder{1});
    for m = 1:length(fnames)
        st.(fnames{m}) = st.(fnames{m})(ix);
    end

    % Next levels sort -----------------------------------    
    for m = 2:length(sortFields)
        st = sortNextLevelInPlace(st, sortFields{m-1}, sortFields{m}, sortOrder{m});
    end    
end


function st = sortNextLevelInPlace(st, sortFieldPrior, sortField, sortOrder)
    fnames = fieldnames(st);
    Len = length(st.(sortFieldPrior));   
    
    if iscellstr(st.(sortFieldPrior))  % cellarray of char vectors
        compareMode = 1;
    elseif iscell(st.(sortFieldPrior))  % we expect cellarray of numeric scalars
        compareMode = 2;
    else
        compareMode = 3;  % numeric or logical vector
    end
    
    m = 1;
    n = 1;
    while n < Len
        % find a block of tied elements (having equal values for prior sort field)
        if compareMode == 1
            while n < Len && strcmp(st.(sortFieldPrior){m}, st.(sortFieldPrior){n})
                n = n + 1;
            end
        elseif compareMode == 2  % cellarray of numeric scalars
            while n < Len && st.(sortFieldPrior){m} == st.(sortFieldPrior){n}  
                n = n + 1;
            end
        else  % numeric or logical vector
            while n < Len && st.(sortFieldPrior)(m) == st.(sortFieldPrior)(n)  
                n = n + 1;
            end
        end
        if n - m > 1  % if there is more than one element in block, there are ties to break
            % select this block's values for the current sort field
            ixB = m:n-1;
            % sort the selected values (return just an index)
            ix = sortOneArray(st.(sortField)(ixB), sortOrder);
            % reorder the tied elements in place using the returned index
            for p = 1:length(fnames)
                st.(fnames{p})(ixB) = st.(fnames{p})(ixB(ix));
            end
        end    
        m = n;       
    end    
end


function ix = sortOneArray(array, sortOrder)
    [~, ix] = sort(array);  % sort direction is not supported by MATLAB on cellstr arrays
    if strcmpi(sortOrder, 'descend')
        ix = flip(ix);
    end
end

