function wasCancelled=rankConstraintsNew(output_folder,ptrsTable,Model,Country,Asset,robustness,followed_inds,follow_on_inds,doBinary)
% rankConstraintsNew generates a file of constraints given the ptrs table
% for all countries. Parts are based directly on the rankAssets function to
% generate the initial 2^Nassets list of launch scenarios.
wasCancelled=false;
% Get how many countries we are dealing with
Ncountries=height(Country);

% This gives the column indices of the unlaunched assets.
unlaunched_id=Asset.ID<=64;

% This is the mask for the assets which are explored
ptrs=ptrsTable.PTRS;
ptrs_mask=(0<ptrs)&(ptrs<1);

% This masks the assets to each specific country
cMask=uint64(ptrs_mask(unlaunched_id,:)'*2.^(Asset.ID(unlaunched_id)-1));

% Deal with the follow on assets
not_follow_on=true(size(ptrs,1),1);
not_follow_on(follow_on_inds)=false;

% This is the mask for the actual valid ptrs values
ptrsv_mask=ptrs_mask&not_follow_on;

% Mask for guaranteed launches
will_launch = ptrs==1;
   
% Get the total number of assets
Ntotal=size(ptrs,1);

% Get the number of assets to rank
Nassets=sum(ptrs_mask&not_follow_on);

tstart=tic;
% We loop over all countries and generate the scenarios
for i=1:Ncountries
    tic

    % Get the powers according to the Asset ID
    twos=2.^(Asset.ID(ptrs_mask(:,i))-1);

    % Only deal with the valid ptrs values
    ptrsmt=ptrs(ptrsv_mask(:,i),i)';

    % The total number of combinations:
    Nscenarios=2^Nassets(i);
    
    % Initialize the probabilities to output
    p=zeros(Nscenarios,1);
    
    % This is the way to vectorize the bitget computation
    I=uint32(0:Nscenarios-1)'; % The integer version of the logical array
    
    % We recreate the array for the total number of assets.
    II=false(Nscenarios,Ntotal);
    
    % Those that will launch (of the unlaunched assets) are marked by true always
    II(:,will_launch(:,i))=true;
    II(:,ptrsv_mask(:,i))=bsxfun(@(a,b)logical(bitget(a,b,'uint32')),I,uint32(1):Nassets(i));
    %     II(:,follow_on_inds)=II(:,followed_inds);
    p(:)=prod(ptrsmt.*II(:,ptrsv_mask(:,i))+(1-ptrsmt).*(~II(:,ptrsv_mask(:,i))),2);

    % Sort the launch scenarios
    [p,ind]=sort(p,'descend');

    % Sort the logical array representing the sequence
    II=II(ind,:);

    % Compute the cumulative launch probability
    cdf=cumsum(p);
    
    % Locate the minimum probability scenario for this level of robustness
    [pmin,imin]=min(p(cdf<=robustness));
    
    %=========     Begin constraint calculations ========
    % For this we need a cut down list of scenarios by the PTRS values
    IIp=II(:,ptrsv_mask(:,i)); %-> only assets 0<ptrs<1 and not follow on
    
    % We also need the matrix of sorted scenarios in order to enumerate all posible
    % combinations of C constraints.
    I=logical(bsxfun(@(a,b)bitget(a,b,'uint32'),I,1:Nassets(i)));

    % Find the number of ON constraints in each row of the base 2^Nassets 
    s=sum(IIp(:,not_follow_on(ptrsv_mask(:,i))),2);
    
    Cmax=Nassets(i);

    WaitMessage = parfor_wait(Cmax,'Waitbar',true,'ReportInterval',1);
    cleanWait=onCleanup(@()delete(WaitMessage));
    
    for  C=Cmax:-1:Cmax-1%0:Cmax
        % Decide between text and binary
        if doBinary
            % Open output file
            fp=fopen(output_folder+"Constraints"+C+".bin",'Wb');
        else
            % Open output file
            fp=fopen(output_folder+"Constraints_"+C+".csv",'W');
    
            % Write header
            fprintf(fp,'Country_id,Launch_ON,Launch_OFF,Probability\n');
        end
        
        % Construct the mask where there are exactly C constraints
        M=IIp(s==C,:)';
    
        % This is the number of distinct rows with C constraints
        ncombs=size(M,2);
        
        % Since the Mask is fixed we just fill in the different choices
        CC=zeros(size(M),'logical');

        % We have to repeat the number of choices for each number of
        % constraints
        nchoice=2^C;
        
        % Give some output
        fprintf('Constraints: %d combinations: %d choices: %d\n',C,ncombs,nchoice);
        
        % These arrays contain the mapping to the proper set of asset indices
        ON=zeros(ncombs,64,'logical');
        OFF=zeros(ncombs,64,'logical');
        
        % The launch combinations for C constraints are given by this submatrix
        LC=I(1:nchoice,1:C);

        % These are the choices that will fill the set bits
        for c=1:nchoice
            % We fill in the choice into the mask matrix
            CC(M)=repmat(LC(c,:),1,ncombs);
            on=(M&CC)';
            off=(~CC&M)';
   
            % Generate the probability of the scenario
            p=prod(ptrsmt.*on+(1-ptrsmt).*off+~M',2);

            % Expand the on/off to the full matrix
            ON(:,ptrsv_mask(unlaunched_id,i))=on;
            OFF(:,ptrsv_mask(unlaunched_id,i))=off;
            
            % Set the follow on assets to their followed value
%            ON(:,follow_on_inds)=ON(:,followed_inds);
%            OFF(:,follow_on_inds)=OFF(:,followed_inds);
            
            % Mask off those not compatible with the robustness
            p_mask=p>=pmin;

            % Calculate the number of valid rows
            Nvalid=sum(p_mask);

            % these are the output vectors
            p=p(p_mask);
            on2=(ON(p_mask,ptrs_mask(:,i))*twos);
            off2=(OFF(p_mask,ptrs_mask(:,i))*twos);
            
            %Con=sum(on(p_mask,:),2);
            %Coff=sum(off(p_mask,:),2);
            if ~isempty(on2) && ~isempty(off2)
                if doBinary
                    % This packs together the Constraint numbers as well as
                    % the Country_id into a uint64 of which the first 32
                    % bits are free, if needed later.
                    %inpack=uint64(typecast(reshape([uint8(Con+Coff),uint8(Coff),uint8(Con),uint8(repmat(Country.ID(i),Nvalid,1))]',[],1),'uint32'));
                    %inpack=typecast(reshape([uint32(count+1:count+Nvalid);uint32(repmat(Country.ID(i),1,Nvalid))],[],1),'uint64');
                    inpack=repmat(uint64(Country.ID(i)),Nvalid,1);
                    % Pack everything together and write out to file
                    out=[inpack,on2,off2,typecast(p,'uint64')]';
                    fwrite(fp,out,'uint64');
                else
                    %out=[(count+1:count+Nvalid)',repmat(Country.ID(i),Nvalid,1),on2,off2,p]';
                    out=[repmat(Country.ID(i),Nvalid,1),on2,off2,p]';
                    fprintf(fp,'%d,%d,%d,%.16f\n',out);
                end
            end
        end
        fclose(fp);
        % Update the number of valid scenarios and count
        WaitMessage.Send;
        if getappdata(WaitMessage.WaitbarHandle,'Cancelled')
            wasCancelled=true;
            WaitMessage.Destroy;
            fclose(fp);
            tstop=toc(tstart);
            fprintf('\nCancelled by user after: %fs\n',tstop)
            return;
        end
    end
    toc
end
% Close waitbar
WaitMessage.Destroy;
% Close all written files
fclose(fp);

tstop=toc(tstart);
fprintf('\nConstraint generation complete. Took: %fs\n',tstop)

end

