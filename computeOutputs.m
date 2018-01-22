function OUT = computeOutputs(MODEL, ASSET, dateGrid, sharePerAssetMonthlySeries)
    
    Nd = length(dateGrid);

    avgTherapyDays = repmat(cell2mat(ASSET.Avg_Therapy_Days), 1, Nd);
    launchPrice = repmat(cell2mat(ASSET.Launch_Price_DOT), 1, Nd);
    priceChange = repmat(cell2mat(ASSET.Price_Change),     1, Nd);
    priceCeilingOrFloor = repmat(cell2mat(ASSET.Price_Ceiling_Floor), 1, Nd);
    gtnChange = repmat(cell2mat(ASSET.GTN_Change), 1, Nd);
    gtnPct    = repmat(cell2mat(ASSET.GTN_Pct), 1, Nd);
    gtnCeilingOrFloor = repmat(cell2mat(ASSET.GTN_Ceiling_Floor), 1, Nd);

    dateMx = repmat(dateGrid, length(ASSET.Launch_Date), 1);
    launchDateMx = repmat(ASSET.Launch_Date, 1, Nd);
    yearsSinceLaunch = (dateMx - launchDateMx) / 365;


    OUT.BrandedPointShare = sharePerAssetMonthlySeries;
    OUT.BrandedPatientShare = sharePerAssetMonthlySeries .* MODEL.Tdays ./ avgTherapyDays;

    OUT.PricePerDayOfTherapy = launchPrice .* (1 + priceChange) .^ yearsSinceLaunch;
    OUT.PricePerDayOfTherapy(yearsSinceLaunch < 0) = 0;

    ixG = yearsSinceLaunch >= 0 & priceChange >= 0;  % if price is growing, set a ceiling
    ixL = yearsSinceLaunch >= 0 & priceChange < 0;   % if price is falling, set a floor
    OUT.PriceFloorOrCeiling = zeros(size(dateMx));
    OUT.PriceFloorOrCeiling(ixG) = min(OUT.PricePerDayOfTherapy(ixG), priceCeilingOrFloor(ixG));
    OUT.PriceFloorOrCeiling(ixL) = max(OUT.PricePerDayOfTherapy(ixL), priceCeilingOrFloor(ixL));

    OUT.GTN = gtnPct .* (1 + gtnChange) .^ yearsSinceLaunch;
    OUT.GTN(yearsSinceLaunch < 0) = 0;

    ixG = OUT.GTN > 0 & gtnChange >= 0;
    ixL = OUT.GTN > 0 & gtnChange < 0;
    OUT.GtnFloorOrCeiling = zeros(size(dateMx));
    OUT.GtnFloorOrCeiling(ixG) = min(OUT.GTN(ixG), gtnCeilingOrFloor(ixG));  % apply a ceiling
    OUT.GtnFloorOrCeiling(ixL) = max(OUT.GTN(ixL), gtnCeilingOrFloor(ixL));  % apply a floor

    OUT.Units = sharePerAssetMonthlySeries * MODEL.Pop * MODEL.SubPop * MODEL.PCP_Factor * MODEL.Tdays;
    OUT.NetRevenues = OUT.Units .* OUT.PriceFloorOrCeiling;
    
%     CumulativeSales
%     PeakSales
%     PeakPointShare
%     PeakPatientShare
%     CumulativeUnits
%     PeakUnits
    

%     tmp = repmat((1:Na)', 1, Nd);
%     figure; plot(dateGrid, launchPrice + tmp); datetick; grid on;
%             legend(ASSET.Assets_Rated, 'Location', 'EastOutside'); timeCursor(false);
    

end