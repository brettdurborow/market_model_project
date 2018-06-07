function [celltab, fmt] = formatTab_CNSTR(cCNSTR)
% format output for writing to file
% CNSTR = constraint lookup table

    NONE = 0;  ON = 1;  OFF = 2;  % possible constraint values
    CNSTR_0 = cCNSTR{1}; % first one is 'None' constraint set
    
    celltab = cell(length(cCNSTR), 1+length(CNSTR_0.ConstraintValues));
    
    for m = 2:length(cCNSTR)
        CNSTR = cCNSTR{m};
        if ~isequaln(CNSTR_0.ConstraintAssets, CNSTR.ConstraintAssets)
            error('Inconsistent arrays in Constraints cellarray');
        end
        celltab{m,1} = CNSTR.ConstraintName;
        ixON  = 1+find(CNSTR.ConstraintValues == ON);
        ixOFF = 1+find(CNSTR.ConstraintValues == OFF);
        celltab(m, ixON) = {'ON'};
        celltab(m, ixOFF) = {'OFF'};       
    end    
        
    colHead = [{'ConstraintName'}, CNSTR_0.ConstraintAssets'];
    celltab(1,:) = colHead;
    celltab(:, 2:end) = celltab(:, end:-1:2);

    fmt = repmat('%s,', [1, length(colHead)]);
    fmt = [fmt(1:end-1), '\n'];  % for writing to CSV

    
end