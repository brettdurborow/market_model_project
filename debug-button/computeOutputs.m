function OUT = computeOutputs(MODEL, ASSET, dateGrid, monthlyShareMx, doAnnual)
% Calculate derived metrics (Units, Revenues, etc.) from PointShares.  
% Return both monthly and annualized results.

    if nargin < 5
        doAnnual = true;
    end
    
    Nd = length(dateGrid);

    avgTherapyDays = repmat(ASSET.Avg_Therapy_Days, 1, Nd);
    unitsPerDot = repmat(ASSET.Units_per_DOT, 1, Nd);

    OUT = struct;
    OUT.M.DateGrid = dateGrid;
    OUT.M.PointShare = monthlyShareMx;
    OUT.M.PatientShare = monthlyShareMx .* MODEL.Tdays ./ avgTherapyDays;
    
    OUT.M.PricePerDot = zeros(size(monthlyShareMx));
    OUT.M.GTN = zeros(size(monthlyShareMx));
    [dateGridYear, ~, ~] = datevec(dateGrid);
    for m = 1:length(ASSET.Assets_Rated)
        OUT.M.PricePerDot(m,:) = cappedGrowth(dateGridYear, ASSET.Launch_Year(m), ASSET.Launch_Price_DOT(m), ...
                                            ASSET.Price_Change(m), ASSET.Price_Ceiling_Floor(m));       
        OUT.M.GTN(m,:) = cappedGrowth(dateGridYear, ASSET.Launch_Year(m), ASSET.GTN_Pct(m), ...
                                    ASSET.GTN_Change(m), ASSET.GTN_Ceiling_Floor(m));       
    end
    OUT.M.Units = monthlyShareMx .* unitsPerDot * MODEL.Pop * MODEL.SubPop * ...
        MODEL.PCP_Factor * MODEL.Tdays / 12;
    
    %New outputs: patient volume and gross revenues
    OUT.M.PatientVolume =  OUT.M.PatientShare * MODEL.Pop * MODEL.SubPop;
    OUT.M.GrossRevenues = OUT.M.Units .* OUT.M.PricePerDot./ unitsPerDot;
    
    OUT.M.NetRevenues = OUT.M.Units .* OUT.M.PricePerDot .* OUT.M.GTN ./ unitsPerDot;
   
    %% Also produce Annualized outputs
    
    if doAnnual    
        [OUT.Y.YearVec, OUT.Y.PointShare] = annualizeMx(dateGrid, OUT.M.PointShare, 'mean');
        [~, OUT.Y.PatientShare] = annualizeMx(dateGrid, OUT.M.PatientShare, 'mean');
        [~, OUT.Y.PricePerDot]  = annualizeMx(dateGrid, OUT.M.PricePerDot, 'mean');
        [~, OUT.Y.GTN]          = annualizeMx(dateGrid, OUT.M.GTN, 'mean');
        [~, OUT.Y.Units]        = annualizeMx(dateGrid, OUT.M.Units, 'sum');
        [~, OUT.Y.NetRevenues]  = annualizeMx(dateGrid, OUT.M.NetRevenues, 'sum');
        [~, OUT.Y.GrossRevenues]  = annualizeMx(dateGrid, OUT.M.NetRevenues, 'sum');
        [~, OUT.Y.PatientVolume]  = annualizeMx(dateGrid, OUT.M.PatientVolume, 'mean');
    end

end