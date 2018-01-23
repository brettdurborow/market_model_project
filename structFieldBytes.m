function [bytes, bytesPct] = structFieldBytes(st)
    %% Compute the memory requirements of each field in struct

    if isa(st, 'struct')

        fnames = fieldnames(st);
        wMain = whos('st');

        bytes = struct;
        bytesPct = struct;
        bytes.Total = wMain.bytes;
        bytesPct.Total = 1;
        for fn = 1:length(fnames)
            tmp = st.(fnames{fn});
            wTmp = whos('tmp');
            bytes.(fnames{fn}) = wTmp.bytes;
            bytesPct.(fnames{fn}) = wTmp.bytes / bytes.Total;
        end
        
    else
        wMain = whos('st');
        bytes = wMain.bytes;
        bytesPct = 1;
    end
        
        
        

end