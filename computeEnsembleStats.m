function ESTAT = computeEnsembleStats(SimCubeBranded, SimCubeMolecule, dateGrid)
% SimCube is either Molecule, Branded, or Generic.  
% Compute outputs by first summarizing an ensemble (mean, 10th percentile, etc.)
% of Point Shares and then calculating the derived metrics (Units, Revenues, etc)
% from these summarized shares.

    N = size(SimCubeBranded, 1);

    ESTAT = struct;    
    ESTAT.DateGrid = dateGrid;
    
    ESTAT.Branded.Mean  = squeeze(mean(SimCubeBranded, 1));
    ESTAT.Branded.StdErr = squeeze(std(SimCubeBranded, 1)) / sqrt(N);
    ESTAT.Branded.Pct01 = squeeze(prctile(SimCubeBranded, 1, 1));   
    ESTAT.Branded.Pct05 = squeeze(prctile(SimCubeBranded, 5, 1));   
    ESTAT.Branded.Pct10 = squeeze(prctile(SimCubeBranded, 10, 1));        
    ESTAT.Branded.Pct15 = squeeze(prctile(SimCubeBranded, 15, 1));    
    ESTAT.Branded.Pct20 = squeeze(prctile(SimCubeBranded, 20, 1));    
    ESTAT.Branded.Pct25 = squeeze(prctile(SimCubeBranded, 25, 1));  
    ESTAT.Branded.Pct30 = squeeze(prctile(SimCubeBranded, 30, 1)); 
    ESTAT.Branded.Pct35 = squeeze(prctile(SimCubeBranded, 35, 1));
    ESTAT.Branded.Pct40 = squeeze(prctile(SimCubeBranded, 40, 1));
    ESTAT.Branded.Pct45 = squeeze(prctile(SimCubeBranded, 45, 1));
    ESTAT.Branded.Pct50 = squeeze(prctile(SimCubeBranded, 50, 1));
    ESTAT.Branded.Pct55 = squeeze(prctile(SimCubeBranded, 55, 1));
    ESTAT.Branded.Pct60 = squeeze(prctile(SimCubeBranded, 60, 1));
    ESTAT.Branded.Pct65 = squeeze(prctile(SimCubeBranded, 65, 1));
    ESTAT.Branded.Pct70 = squeeze(prctile(SimCubeBranded, 70, 1));
    ESTAT.Branded.Pct75 = squeeze(prctile(SimCubeBranded, 75, 1));
    ESTAT.Branded.Pct80 = squeeze(prctile(SimCubeBranded, 80, 1));
    ESTAT.Branded.Pct85 = squeeze(prctile(SimCubeBranded, 85, 1));
    ESTAT.Branded.Pct90 = squeeze(prctile(SimCubeBranded, 90, 1));
    ESTAT.Branded.Pct95 = squeeze(prctile(SimCubeBranded, 95, 1));
    ESTAT.Branded.Pct99 = squeeze(prctile(SimCubeBranded, 99, 1));
    

    ESTAT.Molecule.Mean  = squeeze(mean(SimCubeMolecule, 1));
    ESTAT.Molecule.StdErr = squeeze(std(SimCubeMolecule, 1)) / sqrt(N);    
    ESTAT.Molecule.Pct10 = squeeze(prctile(SimCubeMolecule, 10, 1));        
    ESTAT.Molecule.Pct25 = squeeze(prctile(SimCubeMolecule, 25, 1));    
    ESTAT.Molecule.Pct50 = squeeze(prctile(SimCubeMolecule, 50, 1));        
    ESTAT.Molecule.Pct75 = squeeze(prctile(SimCubeMolecule, 75, 1));        
    ESTAT.Molecule.Pct90 = squeeze(prctile(SimCubeMolecule, 90, 1));   
    
    % Variables:  
        % Mean Net Revenues
        % Mean Branded Point Share
        % Mean Branded Patient Share
        % Mean Branded Units        
    % Statistics: Mean, 10, 25, 50 75, 90
    % Annual averages
    % Across years: Cumulative and Peak
    % the revenue table has the PTRS and the company 
    

%     tmp = squeeze(mean(SimCube, 1));
%     tmp = squeeze(median(SimCube, 1));
%     tmp = squeeze(prctile(SimCube, 95, 1));
%     tmp = squeeze(prctile(SimCube, 65, 1));
%     tmp = squeeze(prctile(SimCube, 5, 1));
%         
%     figure; hA = area(dateGrid, tmp'); datetick; grid on; axis tight;
%             title('Share Per Asset'); 
%             legend(hA(end:-1:1), ASSET.Assets_Rated(end:-1:1), 'Location', 'EastOutside'); timeCursor(false);   
    
end
