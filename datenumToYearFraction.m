function yf = datenumToYearFraction(dn)
% given a numeric matrix or cell array of datenums, convert to dates 
% in month-fraction format (eg. Nov 2018 represented as 2018.8333)
    
    isCellOut = false;
    if iscell(dn)
        dn = cell2mat(dn);
        isCellOut = true;
    end
    [yr, mo, ~] = datevec(dn);
    yf = yr + (mo - 1) / 12;
    
    if isCellOut
        yf = num2cell(yf);
    end

end