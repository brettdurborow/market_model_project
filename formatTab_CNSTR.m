function [celltab, fmt] = formatTab_CNSTR(cCNSTR)
% format output for writing to file
% CNSTR = constraint lookup table

    NONE = 0;  ON = 1;  OFF = 2;  % possible constraint values
    CNSTR_0 = cCNSTR{1}; % first one is 'None' constraint set
    
    celltab = cell(length(cCNSTR), 1+length(CNSTR_0.ConstraintValues));
    
    for m = 1:length(cCNSTR)
        CNSTR = cCNSTR{m};
        if ~isequaln(CNSTR_0.ConstraintAssets, CNSTR.ConstraintAssets)
            error('Inconsistent arrays in Constraints cellarray');
        end
        celltab{m,1} = CNSTR.ConstraintName;
        celltab{m,2} = CNSTR.Probability;
        ixON  = 2+find(CNSTR.ConstraintValues == ON);
        ixOFF = 2+find(CNSTR.ConstraintValues == OFF);
        celltab(m, ixON) = {'ON'};
        celltab(m, ixOFF) = {'OFF'};       
    end    
        
    colHead = [{'Constraint Name', 'Constraint Probability'}, CNSTR_0.ConstraintAssets'];
    celltab = [colHead; celltab];
    celltab(:, 3:end) = celltab(:, end:-1:3);  % Reverse column order for Assets

    fmt = repmat('%s,', [1, length(colHead)]);
    fmt = [fmt(1:end-1), '\n'];  % for writing to CSV

    
end