function num = base2num(vec, base)
% like base2dec, but takes a numeric vector as input intead of a char

    if any(vec >= base)
        error('base2num input contained invalid values');
    end
    
    num = 0;
    for m = 1:length(vec)
        num = num + vec(end-m+1) * base ^ (m-1);        
    end
end