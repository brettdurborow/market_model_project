function celltab2csv(filename, celltab, fmt)

    [Nr, Nc] = size(celltab);

    fmt1 = [repmat('%s,', [1, Nc-1]), '%s\n'];
    if nargin < 3 
        fmt = fmt1;
    end
    
    cFmt = strsplit(fmt, ',');
    for m = 1:length(cFmt)
        % Remove NaN values so they write as empty
        ix = cellisnan(celltab(:, m));
        celltab(ix,m) = cell(sum(ix),1);
        
        if ~isempty(strfind(cFmt{m}, 's'))  % Remove commas so they don't break the format
            ix = cellfun(@ischar,celltab(:,m));
            celltab(ix,m) = strrep(celltab(ix,m), ',', '');           
        end
    end


    fid = fopen(filename, 'w');
    fprintf(fid, fmt1, celltab{1,:});  % write header row
    for m = 2:Nr
        fprintf(fid, fmt, celltab{m,:});
    end
    fclose(fid);



end