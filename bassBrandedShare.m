function [brandedMonthlyShare, genericMonthlyShare] = bassBrandedShare(dateGrid, sharePerAssetMonthlySeries, ASSET)

    brandedMonthlyShare = zeros(size(sharePerAssetMonthlySeries));
    daysPerYear = 365.25;

    for m = 1:length(ASSET.Assets_Rated)
        p_LOE = ASSET.LOE_p{m};
        q_LOE = ASSET.LOE_q{m};
        ixLOE = find(dateGrid >= ASSET.LOE_Date(m));
        moleculeShare = sharePerAssetMonthlySeries(m, ixLOE(1));
        brandedShareTarget = (1 - ASSET.LOE_Pct{m}) * moleculeShare;
        if ASSET.LOE_Date(m) < dateGrid(1)  % if asset LOE date was before our simulation
            tt = [0, dateGrid(1) - ASSET.LOE_Date(m)] / daysPerYear;
            share = bassDiffusion(tt, p_LOE, q_LOE, moleculeShare, brandedShareTarget, false);
            startingShare = share(end);
        else
            startingShare = moleculeShare;
        end
        tt = (dateGrid(ixLOE) - dateGrid(ixLOE(1))) / daysPerYear;
        share = bassDiffusion(tt, p_LOE, q_LOE, startingShare, brandedShareTarget, false);
        brandedMonthlyShare(m, 1:ixLOE(1)) = sharePerAssetMonthlySeries(m, 1:ixLOE(1));
        brandedMonthlyShare(m, ixLOE) = share;        
    end

    genericMonthlyShare = sharePerAssetMonthlySeries - brandedMonthlyShare;

end