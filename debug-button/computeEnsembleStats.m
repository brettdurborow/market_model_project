function ESTAT = computeEnsembleStats(SimCubeBranded, SimCubeMolecule, dateGrid)
% SimCube is either Molecule, Branded, or Generic.  
% Compute outputs by first summarizing an ensemble (mean, 10th percentile, etc.)
% of Point Shares and then calculating the derived metrics (Units, Revenues, etc)
% from these summarized shares.

    N = size(SimCubeBranded, 3);

    ESTAT = struct;    
    ESTAT.DateGrid = dateGrid;
    
    prctile_list = [1,5,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80,85,90,95,99];   
    prctile_cube_b = prctile(SimCubeBranded, prctile_list, 3);
    prctile_cube_m = prctile(SimCubeMolecule, prctile_list, 3);
    
    ESTAT.Branded.Mean  = mean(SimCubeBranded, 3);
    ESTAT.Branded.StdErr = std(SimCubeBranded, 0, 3) / sqrt(N);
    for k = 1:length(prctile_list)
        ESTAT.Branded.(sprintf('Pct%02d',prctile_list(k))) = prctile_cube_b(:,:,k);
    end
    
    ESTAT.Molecule.Mean  = mean(SimCubeMolecule, 3);
    ESTAT.Molecule.StdErr = std(SimCubeMolecule, 0, 3) / sqrt(N);
    for k = 1:length(prctile_list)
        ESTAT.Molecule.(sprintf('Pct%02d',prctile_list(k))) = prctile_cube_m(:,:,k);
    end
 
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
