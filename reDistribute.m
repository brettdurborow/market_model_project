function newShare = reDistribute(initialShare, adjustment, errThresh)

    if nargin < 3
        errThresh = 1e-4;
    end

    if length(initialShare) ~= length(adjustment)
        error('Expected initialShare and adjustment to be vectors of equal length');
    end

    if abs(sum(initialShare)-1) > length(initialShare) * eps
        error('Expected oldShare to sum to 1');
    end
    
    
    Na = length(adjustment);
    A = zeros(Na);   
    for m = 1:Na
        for n = 1:Na
            if m ~= n
                A(m,n) =  initialShare(m) / (1-initialShare(n));
            end            
        end
    end
    
    cumShare = initialShare .* adjustment;  % patients that stay with their initial asset
    redistShare = initialShare .* (1-adjustment);  % patients that switch to another asset 
    
    Niter = 20;
    cumErr = nan(Niter, 1);
    for m = 1:Niter
        redistShare = A * redistShare;  % redistribute proportionally to the initial share of each asset
        cumShare = cumShare + redistShare .* adjustment;  % some of the redisributed patients will stay
        redistShare = redistShare .* (1-adjustment);  % some of the redistributed patients will switch again
        cumErr(m) = 1 - sum(cumShare);
        if cumErr(m) < errThresh
            break;
        end
    end

    % figure; semilogy(cumErr); grid on;  title('Error as a function of iteration');
    
    newShare = cumShare / sum(cumShare);

end
