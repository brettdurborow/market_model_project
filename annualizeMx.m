function [annualDates, annualMx] = annualizeMx(monthlyDates, monthlyMx, method)
% Given a monthly time series matrix, computes yearly Sum or Average, as desired.
%

    yr = year(monthlyDates);
    annualDates = unique(yr, 'sorted');
    annualMx = nan(size(monthlyMx,1), length(annualDates));
    if strcmpi(method, 'mean')
        for m = 1:length(annualDates)
            ix = yr == annualDates(m);
            annualMx(:,m) = mean(monthlyMx(:,ix), 2);
        end
    elseif strcmpi(method, 'sum')
        for m = 1:length(annualDates)
            ix = yr == annualDates(m);
            annualMx(:,m) = sum(monthlyMx(:,ix), 2) * 12 / sum(ix);
        end
    else
        error('Unrecognized Method');
    end
end