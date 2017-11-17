function oeVec = oeShare(rankVec, elasticity)
% Compute market share based on order of market entry, using an exponential model.
% if elasticity is 0, share is divided equally among the entrants.  
% if elasticity is >0, later entrants receive more share than earlier ones
% if elasticity is <0, earlier entrants receive more share than later ones
%
% rankVec: length N vector of order-of-entry ranks.  
%          Expects each element to be an integer from 1 to N
%          If elements of rankVec are repeated (eg. if two are ranked 3rd)
%          the share weight for the tied entrants will be made equal
%


    ix = ~isnan(rankVec);
    
    N = sum(ix);  % number of competitors that launched
    
    order = 1:N;
    a_solve = log(1.0 / sum(order .^ elasticity));  % share weights must add to 1.0
    share = exp(a_solve) * order .^ elasticity;
    
    oeVec = nan(size(rankVec));
    uRank = unique(rankVec);
    p = 1;
    for m = 1:length(uRank)
        ix = find(rankVec == uRank(m));
        q = p + length(ix) - 1;
        aveShare = sum(share(p:q)) / (q-p+1);
        oeVec(ix) = aveShare;
        p = q + 1;
    end
    
    
end