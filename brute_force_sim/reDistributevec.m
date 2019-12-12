function newShare = reDistributevec(initialShare, adjustment, errThresh)
% This new function redistributes the share based on the adjistment factor.
% This is done through an iterative process which is hard to vectorize
% efficiently. 


    if nargin < 3
        errThresh = 1e-6;
    end

    if size(initialShare,1) ~= length(adjustment)
        error('Expected initialShare and adjustment to be vectors of equal length');
    end
    
    % New share will be stored
    newShare=nan(size(initialShare));
    
    % Loop over all event dates
    for event=1:size(initialShare,2)
        
        ixOk = ~isnan(initialShare(:,event));
        if sum(ixOk) == 0
            newShare(:,event) = initialShare(:,event);
            continue
        end
        
        okShare = initialShare(ixOk,event);
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
        
        B=A*diag(1-okAdjustment);
        %rho=max(abs(eig(B)));
        %j=ceil(log(errThresh)/log(rho))+2;
        maxIter=20;
        
        cumShare=okShare;
        for m = 1:maxIter
            cumShare=okShare+B*cumShare;
            if abs(1-sum(okAdjustment.*cumShare))< errThresh
                %        fprintf('s: %g\n',1-sum(okAdjustment.*cumShare));
                break
            end
            %
        end
        cumShare=diag(okAdjustment)*cumShare;
        
        % NB: the above iteration could be done by evaluating the
        % polynomial, we can see what is faster
        %cumShare=diag(okAdjustment)*polyvalm(ones(1,m+1),B)*okShare;
        
        cumShare = cumShare / sum(cumShare);
        newShare(ixOk,event) = cumShare;
    end
end
