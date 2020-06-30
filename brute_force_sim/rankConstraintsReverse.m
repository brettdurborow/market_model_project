% rankConstraintsReverse
%
% This script calculates the highest probable launch scenarios compatible
% with the list of fully constrained launch scenarios. It does this by
% sequentially removing constraints from 


%ptrs=[0.5850;0.4800;0.4000;0.25;0.1640;0.1638;0.1638;0.1638;0.1400;0.1400; 0.1392; 0.1392;0.12;0.1044;0.1044;0.1044;0.1];
ptrs=[0.12;0.585;0.164;0.164;0.164;0.164;0.25;0.1044225;0.1044225;0.1044225;0.13923;0.14;0.1638;0.1;0.1638;0.1638;0.48;0.4;0.139230];
follow_on_inds=[14;15;20;18;25;26;27;19;16;17];
followed_inds=[1;8;9;10;22;23;24;11;13;32];

%ptrs=[0.40;.59;0.1;0.24;0.9];

Nassets=length(ptrs);
Nscenarios=2^Nassets;
robustness=0.8;

fprintf('Assets: %d Scenarios %d robustness: %g\n',Nassets,Nscenarios,robustness);

% We need the matrix of sorted scenarios in order to enumerate all posible
% combinations of C constraints.
I=logical(bsxfun(@(a,b)bitget(a,b,'uint32'),uint32(0:Nscenarios-1).',1:Nassets));

% Get the asset rankings for the fully constrained case (note that the rows
% of II are sorted according to the cdf.
[II,p_orig,cdf,ind_s]=rankAssets(ptrs,[],[]);%followed_inds,follow_on_inds);

% Extract the indices already satisfying the robustness threshold
ind_r=cdf<=robustness;

% The minimum probability will allow us to 
[pmin,imin]=min(p_orig(ind_r));

Nrobust=sum(ind_r);
Nnot=Nscenarios-Nrobust;
fprintf('Of %d launch scenarios, %04.1f%% are robust %04.1f%% need constraints removed\n',Nscenarios,Nrobust/Nscenarios*100,Nnot/Nscenarios*100);

Isave=cell(Nassets,1);
Psave1=cell(Nassets,1);

% This will serve as the OFF mask
S=zeros(Nscenarios,Nassets,'logical');
R=zeros(Nscenarios,Nassets,'logical');

% We begin with all variables constrained.
P=II.*ptrs'+(~II).*(1-ptrs');

constraints=zeros(Nscenarios,1);
last_r=zeros(Nscenarios,1,'logical');
% One by one, we are going to remove the constraints until all scenarios
% have probability greater than pmin
for UC=Nassets:-1:1
    % First, compute all scenario probabilities
    p=prod(P,2);
    
    % Partition scenarios into A) p >= pmin; B) p < pmin
    ind_r= p>pmin;
    
    % We work only with part B (the remainder), removing constraints to
    % increase the probability of those scenarios until all have p>=pmin.
    Nremaining=sum(~ind_r);
    fprintf('Constrained assets: %d remaining (%d/%d): %g\n',UC,Nremaining,Nscenarios, Nremaining/Nscenarios*100);
    
    % Get the indices of those scenarios with probability less than p_min
    places=find(~ind_r);
    
    % Find the column indices of least probable assets for each scenario
    [~,s]=min(P(~ind_r,:),[],2);
    
    % Convert column indices to linear indices
    indS=sub2ind([Nscenarios,Nassets],places,s,ones(Nremaining,1,'logical'));
    
    % Indicate the places where the constraints have been turned off
    S(indS)=true;
    
    % The probability of an unconstrained asset is now 1.
    P(indS)=1;

    % Once all scenarios satisfy the minimum launch probabilty, stop.
    if all(ind_r)
        fprintf('Terminated early\n')
        break
    end
end
% Get the number of unconstrained assets per base scenario
s=Nassets-sum(S,2);

% From each base scenario, we need to enumerate all possibilities of the
% unconstrained asset

% Construct the on and off matrices for the base scenarios.
ON=II&~S;
OFF=(~II)&(~S);

twos=2.^(0:Nassets-1)';

ON2=uint64(ON*twos);
OFF2=uint64(OFF*twos);
I2=uint64(I*twos);
s2=sum(I,2);

T=cell(Nassets+1,1);

% From the base scenarios, we need to enumerate all possible launch
% scenarios made from removing the constraints from the launch scenarios.

% How do we loop through these? We have 2 different scenarios:
%
% 1) For the equality case: These are a fixed subset. They contain all
%    scenarios having exactly C constraints set that are compatible with
%    the robustness.
%
% 2) The scenarios where we have to loosen the constraint restriction. That
%    is, say we transition from 19 constraints to 18 constraints. The
%    subset having 19 constraints can have 1 constraint removed. 

for UC=Nassets:-1:0
    UCs=s>UC;
    for C=Nassets:-1:UC
        % Get the additional entries from
        ON3=reshape(bsxfun(@bitand,ON2(UCs),I2(s2==C)'),[],1);
        OFF3=reshape(bsxfun(@bitand,OFF2(UCs),I2(s2==C)'),[],1);
        % This is the set up to
    end    
    %T{UC+1}=unique(table([ON2(s==UC);ON3],[OFF2(s==UC);OFF3],'VariableNames',{'on','off'}),'rows');
end






% Get the number of constrained assets for each base scenario
% i.e. the complement of S
% b=sum(ON,2);
% ONsave1=cell(Nassets+1,1);
% OFFsave1=cell(Nassets+1,1);
% Psave1=cell(Nassets+1,1);
% Pmask=cell(Nassets+1,1);
% 
% count=0;
% for C=0:Nassets
%     M=ON(b==C,:)';
%     Ms=S(b==C,:)';
%     ncombs=size(M,2);
%     nchoice=2^C;
%     CC=zeros(size(M),'logical');
%     LC=I(1:nchoice,1:C);
%     ONC=zeros(nchoice*ncombs,Nassets,'logical');
%     OFFC=zeros(nchoice*ncombs,Nassets,'logical');
%     p=zeros(nchoice*ncombs,1);
% 
%     for c=1:nchoice
%         CC(M)=repmat(LC(c,:),1,ncombs);
%         on=(M&CC)';
%         off=(~CC&M)';
%         p((c-1)*ncombs+1:c*ncombs)=prod(ptrs'.*on+(1-ptrs').*off+~(M|Ms)',2);
%         ONC((c-1)*ncombs+1:c*ncombs,:)=on;
%         OFFC((c-1)*ncombs+1:c*ncombs,:)=off;
%     end
%     p_mask=p>=pmin; %robustness_threshold;
%     Pmask{C+1}=p_mask;
%     count=count+sum(p_mask);
%     ONsave1{C+1}=ONC(p_mask,:);
%     OFFsave1{C+1}=OFFC(p_mask,:);
%     fprintf('(%d/%d): p > p_min: %g\n',sum(p_mask),length(p_mask),sum(p_mask)./length(p_mask)*100);
%     
%     Psave1{C+1}=p(p_mask,1);
%     
%         
% end
% 
% 
% 
% 
% %fclose(fp);
% Ps=cell2mat(Psave1);
% % Nfull=length(P);
% % 
% ONs=cell2mat(ONsave1);
% OFFs=cell2mat(OFFsave1);
% 
% [Probability,sorter]=sort(P,'descend');
% 
% ON=ON(sorter,:);
% OFF=OFF(sorter,:);
% 
