function new_asset=convert_asset(asset)
% convert_asset is a basic function to try to cut down the size of the
% asset structure. The idea is to keep cell usage to a minimum. Thus, we
% use the string array class to store strings, and all other numeric values
% will be kept as vectors. 

% <25-Jan-2018> Piers Lawrence

fn=fieldnames(asset)';
new_asset=struct;
for f=fn
    thing=asset.(f{:});
    if iscell(thing) && (iscellstr(thing) || any(cellisstr(thing)))
        sthing=string(thing);
        sthing(ismissing(sthing))=""; % we get some downstream effects of missing values, so we avoid these
        new_asset.(f{:})=sthing;
    elseif iscell(thing)
        new_asset.(f{:})=cell2mat(thing);
    else
        new_asset.(f{:})=thing;
    end
end
        
