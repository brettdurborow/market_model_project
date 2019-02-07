function [brandedMonthlyShare, genericMonthlyShare] = bassBrandedShare(dateGrid, sharePerAssetMonthlySeries, ASSET)

    brandedMonthlyShare = sharePerAssetMonthlySeries;
    daysPerYear = 365.25;
    
    for m = 1:length(ASSET.Assets_Rated)
        p_LOE = ASSET.LOE_p(m);
        q_LOE = ASSET.LOE_q(m);
        ixLOE = find(dateGrid >= ASSET.LOE_Date(m));
        moleculeShareMonthly = sharePerAssetMonthlySeries(m, ixLOE);
        
        % Find "LOE Factor" to multiply against molecule share, to compute branded/generic split
        loeFactorTarget = (1 - ASSET.LOE_Pct(m));        
        if ASSET.LOE_Date(m) < dateGrid(1)  % if asset LOE date was before our simulation
            tt = [0, dateGrid(1) - ASSET.LOE_Date(m)] / daysPerYear;
            loeFactorStart = 1;
            loeFactorPre = bassDiffusion(tt, p_LOE, q_LOE, loeFactorStart, loeFactorTarget, false);
            loeFactorStart = loeFactorPre(end);
        else
            loeFactorStart = 1;
        end
        tt = (dateGrid(ixLOE) - dateGrid(ixLOE(1))) / daysPerYear;
        loeFactor = bassDiffusion(tt, p_LOE, q_LOE, loeFactorStart, loeFactorTarget, false);

        brandedMonthlyShare(m, ixLOE) = loeFactor .* sharePerAssetMonthlySeries(m, ixLOE);        
    end

    genericMonthlyShare = sharePerAssetMonthlySeries - brandedMonthlyShare;
    
%     % Uncomment for debugging
%     figure; hA = area(dateGrid, sharePerAssetMonthlySeries'); datetick; grid on; axis tight;
%     title('Share Per Asset - Molecule Monthly'); 
%     legend(hA(end:-1:1), ASSET.Assets_Rated(end:-1:1), 'Location', 'EastOutside'); timeCursor(false);
%     
%     figure; hA = area(dateGrid, brandedMonthlyShare'); datetick; grid on; axis tight;
%     title('Share Per Asset - Branded Monthly'); 
%     legend(hA(end:-1:1), ASSET.Assets_Rated(end:-1:1), 'Location', 'EastOutside'); timeCursor(false);
%     
%     figure; hA = area(dateGrid, genericMonthlyShare'); datetick; grid on; axis tight;
%     title('Share Per Asset - Generic Monthly'); 
%     legend(hA(end:-1:1), ASSET.Assets_Rated(end:-1:1), 'Location', 'EastOutside'); timeCursor(false);

end