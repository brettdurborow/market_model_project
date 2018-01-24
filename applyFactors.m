function adjustmentFactor = applyFactors(MODEL, ASSET, CHANGE, isLaunch, isChange, eventDate)
%
%
% Assumes the ChangeEvents in the CHANGE structure are sorted in ascending 
% order of Launch_Date

    loeDate = ASSET.LOE_Date;

    patientBarriers = zeros(size(isLaunch));
    patientBarriers(isLaunch) = cell2mat(ASSET.Patient_Barriers(isLaunch));
    
    brandedAccessBarriers = zeros(size(isLaunch));
    brandedAccessBarriers(isLaunch) = cell2mat(ASSET.Branded_Access_Barriers(isLaunch));
    
    %% Handle ChangeEvents if there are any
    
    for m = 1:length(CHANGE.Asset)
        if isChange(m) && CHANGE.Launch_Date(m) <= eventDate  % if this change is active
            ix = find(strcmp(CHANGE.Asset{m}, ASSET.Assets_Rated) & strcmp(MODEL.CountrySelected, ASSET.Country));
            if isempty(ix)
                error('ChangeEvents sheet contains unrecognized asset: "%s"', CHANGE.Asset{m});
            elseif length(ix) > 1
                error('Asset name: "%s" in ChangeEvents sheet matches multiple rows in "Assets" sheet', CHANGE.Asset{m});
            end
            if isLaunch(ix)  % only apply the change if the product was launched in the first place
                patientBarriers(ix) = CHANGE.Patient_Barriers{m};
                loeDate(ix) = CHANGE.LOE_Date(m);
            end
        end
    end
    
    %% Compute factors
    
    ixLOE = loeDate <= eventDate;
    
%     marketAccessFilter = repmat(MODEL.WillingToPayForTreatment, size(isLaunch));
%     marketAccessFilter(~ixLOE) = cell2mat(ASSET.Branded_Access_Barriers(~ixLOE));
    
    adjustmentFactor = patientBarriers .* brandedAccessBarriers;
    adjustmentFactor = adjustmentFactor / max(adjustmentFactor);
    
end