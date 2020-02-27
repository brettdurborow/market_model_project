%function [P,ON,OFF,iON,iOFF]=rankConstraints(ptrs,robustness_threshold)
% rank constraints
%
% This script will setup a toy problem for ranking constraints, we need to
% be able to enumerate all 3^Nassets launch conditions in order to be able
% to exhaustively explore all launch conditions.
% Asset=["axs05";"sage217";"other_ox2";"seltorexant";"kor_jnj679";"other_kor";...
%     "esketamine_otf";"pimavanserin";"rel1017";"s47445";"mglunam";...
%     "orexin1";"other_ox1";"mij821";];
%AID=[5, 38, 23, 39, 11, 20, 9, 26, 36, 37, 13, 17]';
Aname="As"+(1:64)';
AID=[3;5;9;11;12;13;14;15;16;17;18;20;22;23;26;33;36;37;38;39;41];

Asset=[ "ampar";"axs05";"esketamine_otf";"kor_jnj679";"m1_5";"mglunam";...
    "nr2a";"nr2b";"mij821";"orexin1";"other_ampa";"other_kor";"other_ox1";...
    "other_ox2";"pimavanserin";"sunflower";"rel1017";"s47445";"sage217";"seltorexant";"tak653"];
ptrs=[0.1200;0.5850;0.1640;0.2500;0.1044;0.1400;0.1044;0.1044;0.1392;0.1400;0.1200;0.2500;0.1400;0.4000;0.1638;0.1000;0.1638;0.1638;0.4800;0.4000;0.1392];
ptrs=[0.12,0.585,0.164,0.25,0.10442,0.14,0.10442,0.10442,0.13923,0.14,0.12,0.25,0.14,0.14,0.4,0.10442,0.10442,0.10442,0.1638,0.1,0.1638,0.1638,0.48,0.4,0.13923]';
%ptrs=[0.12,0.585,0.164,0.25,0.10442,0.14,0.10442,0.10442,0.13923,0.14,0.12,0.25,0.14,0.4,0.1638,0.1,0.1638,0.1638,0.48,0.4,0.13923]';
ptrs=[0.5850;0.4800;0.4000;0.25;0.1640;0.1638;0.1638;0.1638;0.1400;0.1400; 0.1392; 0.1392;0.12;0.1044;0.1044;0.1044;0.1];

%ptrs=[0.40;.59;0.1;0.24;0.9];

Nassets=length(ptrs)
Nscenarios=2^Nassets;

robustness=0.8;

[II,p,cdf]=rankAssets(ptrs,[],[]);

ind_r=cdf<=robustness;

pmin=min(p(ind_r));


robustness_threshold=0.04588;
% This is the column index vector
%v=1:Nassets;

% We need the matrix of sorted scenarios in order to enumerate all posible
% combinations of C constraints.
I=bsxfun(@(a,b)bitget(a,b,'uint32'),uint32(0:Nscenarios-1).',1:Nassets);

% Expand this to a logical matrix of indices
%II=bsxfun(@(a,b)logical(bitget(a,b,'uint32')),I,uint32(1):Nassets);

% Get the number of non-zeros in each row
s=sum(II,2);

tmpfile=[tempname,'.csv'];


twos=2.^(0:Nassets-1)';

ON=[];%zeros(3^Nassets,Nassets);
OFF=[];%zeros(3^Nassets,Nassets);
P=[];
ONsave=cell(Nassets+1,1);
OFFsave=cell(Nassets+1,1);
Psave=cell(Nassets+1,1);

fp=fopen(tmpfile,'w');
format=[repmat('%d,',1,2*Nassets),'%.16f\n'];

fprintf(fp,'ON,OFF,p\n');

count=0;
% We start with no constraints and increase to Na constraints
for  C=0:Nassets;%min(7,Nassets)
    
    % Construct the mask where there are exactly C constraints
    M=II(s==C,:)';
    
    % This is the number of distinct rows with C constraints
    ncombs=size(M,2);
    
    % Since the Mask is fixed we just fill in the different choices 
    CC=zeros(size(M),'logical');
    nchoice=2^C;
    fprintf('Constraints: %d combinations: %d choices: %d\n',C,ncombs,nchoice);

    % The launch combinations for C constraints are given by this submatrix
    LC=I(1:nchoice,1:C);
    ON=zeros(nchoice*ncombs,Nassets,'logical');
    OFF=zeros(nchoice*ncombs,Nassets,'logical');
    P=zeros(nchoice*ncombs,1);
    % These are the choices that will fill the set bits
    for c=1:nchoice
        % We fill in the choice into the mask matrix 
        CC(M)=repmat(LC(c,:),1,ncombs);
        on=(M&CC)';
        off=(~CC&M)';
        
        p=prod(ptrs'.*on+(1-ptrs').*off+~M',2);
%         p_mask=p>=pmin;
%         out=[on(p_mask,:),off(p_mask,:),p(p_mask)];
%         if ~isempty(out)
%             fprintf(fp,format,out');
%         end
        
        % If we collect the vectors
        P((c-1)*ncombs+1:c*ncombs)=prod(ptrs'.*on+(1-ptrs').*off+~M',2);
        ON((c-1)*ncombs+1:c*ncombs,:)=on;
        OFF((c-1)*ncombs+1:c*ncombs,:)=off;
    end
    p_mask=P>=pmin; %robustness_threshold;
    count=count+sum(p_mask);
    ONsave{C+1}=ON(p_mask,:);
    OFFsave{C+1}=OFF(p_mask,:);
    fprintf('(%d/%d): p > p_min: %g\n',sum(p_mask),length(p_mask),sum(p_mask)./length(p_mask)*100);
    %
    Psave{C+1}=P(p_mask,1);
end
P=vertcat(Psave{:});
fprintf('Total scenarios generated: %d\n',count);
fclose(fp);
% P=cell2mat(Psave);
% Nfull=length(P);
% % 
% ON=cell2mat(ONsave);
% OFF=cell2mat(OFFsave);
% 
% [Probability,sorter]=sort(P,'descend');
% 
% ON=ON(sorter,:);
% OFF=OFF(sorter,:);
% 
% ONfull=zeros(Nfull,64,'logical');
% OFFfull=zeros(Nfull,64,'logical');
% ONfull(:,AID)=ON(sorter,:);
% OFFfull(:,AID)=OFF(sorter,:);
% Unconstrained=~(ONfull|OFFfull);
% Launch_ON=uint64(ONfull(:,AID)*(2.^(AID-1)));
% Launch_OFF=uint64(OFFfull(:,AID)*(2.^(AID-1)));
% Constraints_ON=sum(ONfull,2);
% Constraints_OFF=sum(OFFfull,2);
% Constraints_total=Constraints_ON+Constraints_OFF;
% 
% As=double(ONfull);
% As(Unconstrained)=nan;
% As=array2table(As,'VariableNames',Aname');
% 
% Country_id=ones(size(Probability));
% Model=ones(size(Probability));
% 
% 
% Description=strings(Nfull,1);
% 
% 
% for k=1:Nfull
%     A=Asset;
%     A(ONfull(k,AID))=A(ONfull(k,AID))+"=ON;";
%     A(OFFfull(k,AID))=A(OFFfull(k,AID))+"=OFF;";
%     Description(k)=join(A(ONfull(k,AID)|OFFfull(k,AID)));
%     
% end
% Description(ismissing(Description))="Risk Adjusted Model";
% 
% fmt = ['%d,%.15f,%d,%u,%u,%d,%d,%d',repmat('%.15f,',1,64)];
% 
% 
% T=horzcat(table(Country_id,Probability,Model,Launch_ON,Launch_OFF,Constraints_total,Constraints_ON,Constraints_OFF),As,table(Description));
% T=readtable(tmpfile);
% delete(tmpfile)

% Sort the resulting scenarios by probability
% [P,inds]=sort(P,'descend');
% ON=ON(inds,:);
% OFF=OFF(inds,:);
% iON=uint64(ON*(2.^(0:Nassets-1)'));
% iOFF=uint64(OFF*(2.^(0:Nassets-1)'));
% iMASK=bitor(iON,iOFF);


% Apparently, this is the implementation for the combinations
% k=2;
% n=Nassets;
% v=1:Nassets;
% tmp = uint16(2^n-1):-1:2;
% x = bsxfun(@bitget,tmp.',n:-1:1);
% 
% idx = x(sum(x,2) == k,:);
% nrows = size(idx,1);
% [rows,~] = find(idx');
% c = reshape(v(rows),k,nrows).';
