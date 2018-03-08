function ym = datenumToYyyymm(dn)
% given a numeric matrix or cell array of datenums, convert to dates 
% in yyyymm format (eg. Nov 2018 represented as 201811)
    
    isCellOut = false;
    if iscell(dn)
        dn = cell2mat(dn);
        isCellOut = true;
    end
    [yr, mo, ~] = datevec(dn);
    ym = yr * 100 + mo;
    
    if isCellOut
        ym = num2cell(ym);
    end

end