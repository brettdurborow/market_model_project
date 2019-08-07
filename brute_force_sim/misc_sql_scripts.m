
%% Finally, construct the auxillary table
% MT=repmat(Model.MName,height(Ta)*Nt,1);
% CR=repmat(Ta.Country,1,Nt)';CR=CR(:);
% AR=repmat(Ta.Assets_Rated,1,Nt)';AR=AR(:);
% TP=repmat(dtDateGrid,height(Ta),1);
% launch_id=ones(height(Ta)*Nt,1,'uint32');
% aux_id=(int32(1):int32(length(launch_id)))';
% Taux=table(aux_id,MT,string(CR),string(AR),TP,'VariableNames',{'aux_id','model_name','Country_name','asset_name','date'});
% 
% taux=tic;
% writetable(Taux,output_folder+"Taux.csv",'QuoteStrings',true);
% taux=toc(taux);
% fprintf('[Timing] Table writing time %gs\n',taux);


% Check if DB connection has been made, open if necessary
if ~exist('conn','var')
    conn=connect_to_mysql('aMDD');
elseif ~isopen(conn)
    conn=connect_to_mysql('aMDD');
end

% Write the model name into the database
sqlwrite(conn,'Model',Model)

% Get the auto incrementing value from the database
allModels=sqlread(conn,'Model');
modelID=max(allModels.ID);

    tstartsql=tic;
    sqlwrite(conn,'scenarioOutput',Tout);
    tsql=toc(tstartsql);
    fprintf('[Timing] SQL big table write %gs\n',tsql);
    
    for i=1:find(launch_scenario<=launch_height)
       execute(conn,"delete from scenarioOutput where launch_code="+launchInfo{i}.launch_code(launch_scenario))
    end
    
    
    sql_statement=sprintf("load data local infile 'data/scenario_%d.dat' into table scenarioOutput fields terminated by ',' lines terminated by '\\n' ignore 1 rows",launch_scenario);
    twritestart=tic;
    execute(conn,sql_statement)
    twrite=toc(twritestart);
    fprintf('[Timing] SQL exec time %gs\n',twrite);

    
    if false
    % Big table with all variables.
TT=join(Taux,Tout);

tic
writetable(Tout,"data/Tout.dat");
toc

tic
writetable(TT,"data/TT.dat",'QuoteStrings',true);
toc

Q=table();%'VariableNames',{'launch_id','aux_id','Branded_Molecule','Molecule'});
datafile_counter=0;
for i=1:0
    Q=table(launch_id*i,aux_id,rand(length(launch_id),1),rand(length(launch_id),1),'VariableNames',{'launch_id','aux_id','Branded_Molecule','Molecule'});
    %if height(Q)>=height(T)*3 %2e6
    %    tic;
    %    K=join(Q,T);
    %writetable(K,"data/file_"+datafile_counter+".csv");
    %toc;
    %    %Q=table();%'VariableNames',{'launch_id','aux_id','Branded_Molecule','Molecule'});
    %   datafile_counter=datafile_counter+1;
    %  break
    %end
    tic;
    sqlwrite(conn,'Market_data',Q)
    %writetable(Q,"data/file_"+i+".dat");
    fp=fopen("data/file_"+i+".dat","w");
    fwrite(fp,[Q.Branded_Molecule;Q.Molecule],'double');
    fclose(fp);
    toc;
    
end
end


sql_statement="load data local infile 'data/Tout.dat' into table Market_data fields terminated by ',' lines terminated by '\n' ignore 1 rows";


