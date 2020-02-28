function rankConstraintsNew(output_folder,ptrsTable,Model,Country,Asset,robustness,followed_inds,follow_on_inds)
% rankConstraintsNew generates a file of constraints given the ptrs table
% for all countries. Parts are based directly on the rankAssets function to
% generate the initial 2^Nassets list of launch scenarios.

unlaunched_id=Asset.ID<=64;
fp=fopen(output_folder+"Constraints.csv",'w');
% Write header
fprintf(fp,['Country_id,Probability,Model,Launch_ON,Launch_OFF,Constraints_total,Constraints_ON,Constraints_OFF,',repmat('A%d,',1,64),'Description\n'],1:64);
fmt=['%d,%.15f,%d,%u,%u,%d,%d,%d,',repmat('%d,',1,64),'D\n'];
h=waitbar(0,'Constraint processing');
waitObject=onCleanup(@()delete(h));

%WaitMessage = parfor_wait(max(launch_height),'Waitbar',true,'ReportInterval',1);
T=table(zeros(0,1,'uint64'),zeros(0,1),zeros(0,1),zeros(0,1,'uint64'),zeros(0,1,'uint64'),...
    zeros(0,1),zeros(0,1),zeros(0,1),zeros(0,64,'logical'),strings(0,1),'VariableNames',...
    {'Country_id','Probability','Model','Launch_ON','Launch_OFF','Constraints_total','Constraints_ON','Constraints_OFF','A','Description'});
for i=1:size(ptrsTable.PTRS,2)
    % Extract the PTRS for the i-th country
    ptrs=ptrsTable.PTRS(:,i);
    
    % Deal with the follow on assets
    not_follow_on=true(size(ptrs));
    not_follow_on(follow_on_inds)=false;
    
    % The mask of active unlaunched assets requires 0<ptrs<1 and that it is
    % not a follow on asset
    ptrs_mask=(0<ptrs)&(ptrs<1)& not_follow_on;
    
    % For some reason we might need the explicit indices rather than the
    % logical mask
    ptrs_inds=find(ptrs_mask);
    
    % Mask for guaranteed launches
    will_launch = ptrs==1;
    wont_launch = ptrs==0;
    
    % Get the total number of assets
    Ntotal=length(ptrs);
    
    % Get the number of assets to rank
    Nassets=sum(ptrs_mask);

    twos=2.^(Asset.ID(ptrs_mask)-1);%0:Nassets-1)';

    % The total number of combinations:
    Nscenarios=2^Nassets;
    
    % Initialize the probabilities to output
    p=zeros(Nscenarios,1);
    
    % This is the way to vectorize the bitget computation
    I=uint32(0:Nscenarios-1)'; % The integer version of the logical array
    
    % We recreate the array for the total number of assets.
    II=false(Nscenarios,Ntotal);
    
    % Those that will launch (of the unlaunched assets) are marked by true always
    II(:,will_launch)=true;
    II(:,ptrs_mask)=bsxfun(@(a,b)logical(bitget(a,b,'uint32')),I,uint32(1):Nassets);
    II(:,follow_on_inds)=II(:,followed_inds);
    p(:)=prod(ptrs(ptrs_mask)'.*II(:,ptrs_mask)+(1-ptrs(ptrs_mask)').*(~II(:,ptrs_mask)),2);

    % Sort the launch scenarios
    [p,ind]=sort(p,'descend');

    % Sort the logical array representing the sequence
    II=II(ind,:);

    % Compute the cumulative launch probability
    cdf=cumsum(p);
    
    % Locate the minimum probability scenario for this level of robustness
    pmin=min(p(cdf<=robustness));
        
    %=========     Begin constraint calculations ========
    % For this we need a cut down list of scenarios by the PTRS values
    IIp=II(:,ptrs_mask); %-> only assets 0<ptrs<1 and not follow on
        
    % We also need the matrix of sorted scenarios in order to enumerate all posible
    % combinations of C constraints.
    I=bsxfun(@(a,b)bitget(a,b,'uint32'),I,1:Nassets);

    % Find the number of ON constraints in each row of the base 2^Nassets 
    s=sum(IIp,2);
    count=0;
    Cmax=min(4,Nassets);%min(max(ceil(Nassets/4),4),Nassets);
    for  C=0:Cmax%,floor(Nassets*3/4):Nassets]
        waitbar(C/(Cmax+1),h,sprintf('Processing country %s; Constraint %d/%d\n',Country.CName(i),C,Cmax))
        % Construct the mask where there are exactly C constraints
        M=IIp(s==C,:)';
    
        % This is the number of distinct rows with C constraints
        ncombs=size(M,2);
        
        % Since the Mask is fixed we just fill in the different choices
        CC=zeros(size(M),'logical');
        nchoice=2^C;
        fprintf('Constraints: %d combinations: %d choices: %d\n',C,ncombs,nchoice);
        
        %Set up full ON and OFF matrices to output
        ON=zeros(size(M,2),64,'logical');
        %ON(:,Asset.ID(will_launch&unlaunched_id))=true;
        OFF=zeros(size(M,2),64,'logical');
        %OFF(:,Asset.ID(wont_launch&unlaunched_id))=true;
        
        % The launch combinations for C constraints are given by this submatrix
        LC=I(1:nchoice,1:C);
        % These are the choices that will fill the set bits
        for c=1:nchoice
            % We fill in the choice into the mask matrix
            CC(M)=repmat(LC(c,:),1,ncombs);
            on=(M&CC)';

            ON(:,Asset.ID(ptrs_mask))=on;
            ON(:,Asset.ID(follow_on_inds))=ON(:,Asset.ID(followed_inds));
            
            off=(~CC&M)';
            OFF(:,Asset.ID(ptrs_mask))=off;
            OFF(:,Asset.ID(follow_on_inds))=OFF(:,Asset.ID(followed_inds));
   
            p=prod(ptrs(ptrs_mask)'.*on+(1-ptrs(ptrs_mask)').*off+~M',2);
            p_mask=p>=pmin;
            Nvalid=sum(p_mask);
            count=count+sum(p_mask);
            on2=on(p_mask,:)*twos;
            off2=off(p_mask,:)*twos;
            Con=sum(on(p_mask,:),2);
            Coff=sum(off(p_mask,:),2);
            D=strings(Nvalid,1);
            if ~isempty(on2) && ~isempty(off2)
                out=[repmat(Country.ID(i),Nvalid,1),p(p_mask),repmat(Model.ID,Nvalid,1),...
                    on2,off2,Con,Coff,Con+Coff,ON(p_mask,:)-~(ON(p_mask,:)|OFF(p_mask,:))];
                sout=sprintf(fmt,out');
                %sout=regexprep(sout,{'-1','D'},{'\\\\N','%s'}); % To put null values in sql database.
                sout=regexprep(sout,{'-1','D'},{'','%s'});
                
                for k=1:size(out,1)
                    A=Asset.AName(ptrs_mask);
                    A(on(k,:))=A(on(k,:))+"=ON;";
                    A(off(k,:))=A(off(k,:))+"=OFF;";
                    D(k)=join(A(on(k,:)|off(k,:)),'');
                    if ismissing(D)
                        D(k)="Risk Adjusted Model";
                    end
                end
                sout=sprintf(sout,D);
                T=vertcat(T,table(repmat(Country.ID(i),Nvalid,1),p(p_mask),...
                    repmat(Model.ID,Nvalid,1),on2,off2,Con,Coff,Con+Coff,ON(p_mask,:)-~(ON(p_mask,:)|OFF(p_mask,:)),D,...
                    'VariableNames',{'Country_id','Probability','Model','Launch_ON','Launch_OFF','Constraints_total','Constraints_ON','Constraints_OFF','A','Description'}));
                fprintf(fp,'%s',sout);
            end
        
        end
        
    end
end
fclose(fp);
close(h);
T=sortrows(T,{'Country_id','Probability'},{'ascend','descend'});
US=T(T.Country_id==Country.ID(Country.CName=="US"),:);

UStoCmask=uint64(ptrsTable.launch_mask(unlaunched_id,:)'*2.^(Asset.ID(unlaunched_id)-1));
Tmask=UStoCmask(T.Country_id);
Ncountry=height(Country);

T100=addvars(T([],:),[],'NewVariableNames','setid','Before','Country_id');
fmt1=['%d,',regexprep(fmt,'D','%s')];

fp=fopen(output_folder+"Top100constraints.csv",'w');
fprintf(fp,['setid,Country_id,Probability,Model,Launch_ON,Launch_OFF,Constraints_total,Constraints_ON,Constraints_OFF,',repmat('A%d,',1,64),'Description\n'],1:64);
setid_epoch=uint64((now-datenum(2020,1,1))*1e5);
for setid=1:100
    select=(bitand(US.Launch_ON(setid),Tmask)==T.Launch_ON)&(bitand(US.Launch_OFF(setid),Tmask)==T.Launch_OFF);
    Tsel=addvars(T(select,:),repmat(setid_epoch+setid,Ncountry,1),'NewVariableNames','setid','Before','Country_id');
    T100=vertcat(T100,Tsel);
    Tselc=table2cell(Tsel)';
    sout=sprintf(fmt1,Tselc{:});
    sout=regexprep(sout,'-1','');
    fprintf(fp,'%s',sout);
end
fclose(fp);




end

