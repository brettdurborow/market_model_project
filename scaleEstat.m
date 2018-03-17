function ESTAT2 = scaleEstat(ESTAT1, factor)

    ESTAT2 = struct;
    ESTAT2.DateGrid = ESTAT1.DateGrid;
    
    fnames = fieldnames(ESTAT1.Branded);
    for m = 1:length(fnames)
        ESTAT2.Branded.(fnames{m}) = ESTAT1.Branded.(fnames{m}) * factor;
    end
    
    fnames = fieldnames(ESTAT1.Molecule);
    for m = 1:length(fnames)
        ESTAT2.Molecule.(fnames{m}) = ESTAT1.Molecule.(fnames{m}) * factor;
    end

end