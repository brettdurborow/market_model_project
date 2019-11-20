function [II,p,cdf]=rankAssets(ptrs,followed_inds,follow_on_inds)
% rankAssets enumerates and ranks all possible launch combinations of
% assets given their PTRS value.



% Mask only those assets needing to be exhaustively tested:
% 1) having value between 0 and 1;
% 2) not a follow on asset
not_follow_on=true(size(ptrs));
not_follow_on(follow_on_inds)=false;
ptrs_mask=(0<ptrs)&(ptrs<1)& not_follow_on;
ptrs_inds=find(ptrs_mask);

% Mask for guaranteed launches
will_launch = ptrs==1;

% Get the total number of assets
Ntotal=length(ptrs);

% Get the number of assets to rank
Nassets=sum(ptrs_mask);
%fprintf('Number of assets: %d\n',Nassets)
% Make sure we don't have too many scenarios (we will hit a problem well
% before this value, infact, we will not be able to generate a vector this big)
assert(Nassets<=32,'Maximum number of assets to exhaustively test exceeded')

% The total number of combinations:
Nscenarios=2^Nassets;

% Initialize the probabilities to output
p=zeros(Nscenarios,1);

% Indexing variable
%I=uint32(0:Nscenarios-1)';
II=false(Nscenarios,Ntotal);
II(:,will_launch)=true;
for i=1:Nscenarios
    I=i+1;
    launch=logical(bitget(I,1:Nassets,'uint32'));
    p(i)=prod(ptrs(ptrs_inds(launch)))*prod(1-ptrs(ptrs_inds(~launch)));
    II(i,ptrs_mask)=launch;
    II(i,follow_on_inds)=II(i,followed_inds);
end

% II2=false(Nscenarios,Ntotal);
% II2(:,will_launch)=true;
% I2=(uint32(1):uint32(Nscenarios))';
% p=ones(Nscenarios,1);
% for i=1:Nassets
%     launch=logical(bitget(I2,i,'uint32'));
%     p=p.*(launch*ptrs(ptrs_inds(i))).*(1-(~launch*ptrs(ptrs_inds(i))));
%     II2(launch,ptrs_mask)=launch;
%     II2(launch,follow_on_inds)=II(launch,followed_inds);
% end


% Sort the launch scenarios 
[p,ind]=sort(p,'descend');

% Sort the launch sequence
%I1=I(ind);

% Sort the logical array representing the sequence
II=II(ind,:);

% now convert logical bits in II to an index (This seems to be a silly way of doing things)
%I=uint64(bin2dec(char('0'+ II(:,end:-1:1))));
%I=uint64(II*(2.^(0:Ntotal-1)'));

% Compute the cumulative launch probability
cdf=cumsum(p);

%semilogx(cdf)
%xlabel('Launch number')
%ylabel('Cumulative probability')
