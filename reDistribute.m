function newShare = reDistribute(initialShare, adjustment, errThresh)

    if nargin < 3
        errThresh = 1e-6;
    end

    if length(initialShare) ~= length(adjustment)
        error('Expected initialShare and adjustment to be vectors of equal length');
    end
    
    ixOk = ~isnan(initialShare);
    okShare = initialShare(ixOk);
    okAdjustment = adjustment(ixOk);

    if abs(sum(okShare)-1) > length(okShare) * eps
        error('Expected oldShare to sum to 1');
    end
        
    Na = length(okShare);
    A = zeros(Na);   
    for m = 1:Na
        for n = 1:Na
            if m ~= n
                A(m,n) =  okShare(m) / (1-okShare(n));
            end            
        end
    end
    
    cumShare = okShare .* okAdjustment;  % patients that stay with their initial asset
    redistShare = okShare .* (1-okAdjustment);  % patients that switch to another asset 
    
    Niter = 20;
    cumErr = nan(Niter, 1);
    for m = 1:Niter
        redistShare = A * redistShare;  % redistribute proportionally to the initial share of each asset
        cumShare = cumShare + redistShare .* okAdjustment;  % some of the redisributed patients will stay
        redistShare = redistShare .* (1-okAdjustment);  % some of the redistributed patients will switch again
        cumErr(m) = 1 - sum(cumShare);
        if cumErr(m) < errThresh
            break;
        end
    end

    % figure; semilogy(cumErr); grid on;  title('Error as a function of iteration');
    
    cumShare = cumShare / sum(cumShare);
    newShare = nan(size(initialShare));
    newShare(ixOk) = cumShare;

end
