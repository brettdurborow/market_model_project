function ESTAT = computeEnsembleStats(SimCubeBranded, SimCubeMolecule, dateGrid)
% SimCube is either Molecule, Branded, or Generic.  
% Compute outputs by first summarizing an ensemble (mean, 10th percentile, etc.)
% of Point Shares and then calculating the derived metrics (Units, Revenues, etc)
% from these summarized shares.

    N = size(SimCubeBranded, 1);

    ESTAT = struct;    
    ESTAT.DateGrid = dateGrid;
    
    prctile_list = [1,5,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80,85,90,95,99];   
    prctile_cube_b = prctile(SimCubeBranded, prctile_list, 1);
    prctile_cube_m = prctile(SimCubeMolecule, prctile_list, 1);
    
    ESTAT.Branded.Mean  = shiftdim(mean(SimCubeBranded, 1));
    ESTAT.Branded.StdErr = shiftdim(std(SimCubeBranded, 1)) / sqrt(N);
    ESTAT.Branded.Pct01 = shiftdim(prctile_cube_b(1,:,:));   
    ESTAT.Branded.Pct05 = shiftdim(prctile_cube_b(2,:,:));  
    ESTAT.Branded.Pct10 = shiftdim(prctile_cube_b(3,:,:)); 
    ESTAT.Branded.Pct15 = shiftdim(prctile_cube_b(4,:,:)); 
    ESTAT.Branded.Pct20 = shiftdim(prctile_cube_b(5,:,:)); 
    ESTAT.Branded.Pct25 = shiftdim(prctile_cube_b(6,:,:)); 
    ESTAT.Branded.Pct30 = shiftdim(prctile_cube_b(7,:,:)); 
    ESTAT.Branded.Pct35 = shiftdim(prctile_cube_b(8,:,:)); 
    ESTAT.Branded.Pct40 = shiftdim(prctile_cube_b(9,:,:)); 
    ESTAT.Branded.Pct45 = shiftdim(prctile_cube_b(10,:,:)); 
    ESTAT.Branded.Pct50 = shiftdim(prctile_cube_b(11,:,:)); 
    ESTAT.Branded.Pct55 = shiftdim(prctile_cube_b(12,:,:)); 
    ESTAT.Branded.Pct60 = shiftdim(prctile_cube_b(13,:,:)); 
    ESTAT.Branded.Pct65 = shiftdim(prctile_cube_b(14,:,:)); 
    ESTAT.Branded.Pct70 = shiftdim(prctile_cube_b(15,:,:)); 
    ESTAT.Branded.Pct75 = shiftdim(prctile_cube_b(16,:,:)); 
    ESTAT.Branded.Pct80 = shiftdim(prctile_cube_b(17,:,:)); 
    ESTAT.Branded.Pct85 = shiftdim(prctile_cube_b(18,:,:)); 
    ESTAT.Branded.Pct90 = shiftdim(prctile_cube_b(19,:,:)); 
    ESTAT.Branded.Pct95 = shiftdim(prctile_cube_b(20,:,:)); 
    ESTAT.Branded.Pct99 = shiftdim(prctile_cube_b(21,:,:)); 
        
    ESTAT.Molecule.Mean  = shiftdim(mean(SimCubeMolecule, 1));
    ESTAT.Molecule.StdErr = shiftdim(std(SimCubeMolecule, 1)) / sqrt(N);
    ESTAT.Molecule.Pct01 = shiftdim(prctile_cube_m(1,:,:));   
    ESTAT.Molecule.Pct05 = shiftdim(prctile_cube_m(2,:,:));   
    ESTAT.Molecule.Pct10 = shiftdim(prctile_cube_m(3,:,:));   
    ESTAT.Molecule.Pct15 = shiftdim(prctile_cube_m(4,:,:));   
    ESTAT.Molecule.Pct20 = shiftdim(prctile_cube_m(5,:,:));   
    ESTAT.Molecule.Pct25 = shiftdim(prctile_cube_m(6,:,:));   
    ESTAT.Molecule.Pct30 = shiftdim(prctile_cube_m(7,:,:));   
    ESTAT.Molecule.Pct35 = shiftdim(prctile_cube_m(8,:,:));   
    ESTAT.Molecule.Pct40 = shiftdim(prctile_cube_m(9,:,:));   
    ESTAT.Molecule.Pct45 = shiftdim(prctile_cube_m(10,:,:));   
    ESTAT.Molecule.Pct50 = shiftdim(prctile_cube_m(11,:,:));   
    ESTAT.Molecule.Pct55 = shiftdim(prctile_cube_m(12,:,:));   
    ESTAT.Molecule.Pct60 = shiftdim(prctile_cube_m(13,:,:));   
    ESTAT.Molecule.Pct65 = shiftdim(prctile_cube_m(14,:,:));   
    ESTAT.Molecule.Pct70 = shiftdim(prctile_cube_m(15,:,:));   
    ESTAT.Molecule.Pct75 = shiftdim(prctile_cube_m(16,:,:));   
    ESTAT.Molecule.Pct80 = shiftdim(prctile_cube_m(17,:,:));   
    ESTAT.Molecule.Pct85 = shiftdim(prctile_cube_m(18,:,:));   
    ESTAT.Molecule.Pct90 = shiftdim(prctile_cube_m(19,:,:));   
    ESTAT.Molecule.Pct95 = shiftdim(prctile_cube_m(20,:,:));   
    ESTAT.Molecule.Pct99 = shiftdim(prctile_cube_m(21,:,:));   

    
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
