function adjustmentFactor = applyFactors(MODEL, ASSET, isLaunch)
%   applyFactors computes and adjustment factor based on the barriers and
%   calibration columns of the input data.
%
    loeDate = ASSET.LOE_Date;

    barriers = zeros(size(isLaunch));
    barriers(isLaunch) = ASSET.Barriers(isLaunch);
    
    calibration = zeros(size(isLaunch));
    calibration(isLaunch) = ASSET.Calibration(isLaunch);
    
    %% Compute factors
    adjustmentFactor = barriers .* calibration;
    adjustmentFactor = adjustmentFactor / max(adjustmentFactor);
    
end