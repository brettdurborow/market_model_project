function single_simulation(launch_scenario,Tm,Ta,Tc,eventTable,dateTable,Model,Country,launchInfo,ptrsTable,output_folder,output_type)

Na=Country.NAssets;

Nt=height(dateTable);

allEvents=datenum(eventTable.date);
dateGrid=datenum(dateTable.date);

% Use the left hand endpoints as the yearly date
dtDateGridYear=dateTable.date(1:12:end);

% Number of years to simulate for
Ny = size(dtDateGridYear,1);

launch_height=cellfun(@height,launchInfo)';

fprintf('Processing scenario %d/%d\n',launch_scenario,max(launch_height))
Tout=cell(size(Na));
Tmon=cell(size(Na));
Ttarget=cell(size(Na));
tscenario=tic;
for i=find(launch_scenario<=launch_height) %1:Nco
    country_selected=Country.CName(i);
    
    % define the index selector
    country_table_index=Ta.Country==country_selected;
    MODEL=Tm(Tm.CountrySelected==country_selected,:);
    ASSET=sortrows(Ta(country_table_index,:),'Unique_ID');
    
    % Get the launch vector over all assets
    isLaunchAll=launchInfo{i}.launch_logical(launch_scenario,:)';
    
    % Restrict to only those assets in the restricted asset table.
    isLaunch=isLaunchAll(ptrsTable.launch_mask(:,i));
    
    % Restrict number to only those assets actually launching. NB: We could restrict this by reducing the number of assets given to each model.
    Nlaunch=sum(isLaunch);
    
    % We disregard the Change even dates for now.
    CHANGE=Tc;%cCHANGE{Nco-i+1};
    isChange=false(Na(i),1);
    
    % Construct the event date vector
    eventDates = unique([ASSET.Launch_Date; ASSET.LOE_Date; ASSET.Starting_Share_Date]);% CHANGE.Launch_Date; CHANGE.LOE_Date]);
    nEvents=length(eventDates);
    CLASS = therapyClassRank(ASSET, isLaunch);
    %fprintf('Processing country %s, Length of assets %d\n',country_selected,length(ASSET.Assets_Rated));
    
    % Consider setting thes to -1 rather than NaN, since MySQL does not
    % support NaN...
    sharePerAssetOE=nan(Na(i),nEvents);
    sharePerAssetP=nan(Na(i),nEvents);
    sharePerAsset=nan(Na(i),nEvents);
    sharePerAssetEventSeries=nan(Na(i),nEvents);
    for m = 1:nEvents
        sharePerAssetOE(:,m) = orderOfEntryModel(MODEL, ASSET, CLASS, isLaunch, eventDates(m)); % NB: elastClass, elastAsset are contained in MODEL
        sharePerAssetP(:,m) = profileModel(MODEL, ASSET, CLASS, isLaunch, eventDates(m));
        
        sharePerAsset(:,m) = (sharePerAssetOE(:,m) * MODEL.OrderOfEntryWeight + sharePerAssetP(:,m) * MODEL.ProfileWeight) ...
            / (MODEL.OrderOfEntryWeight + MODEL.ProfileWeight);
        
        adjustmentFactor = applyFactors(MODEL, ASSET, CHANGE, isLaunch, isChange, eventDates(m));
        newSharePerAsset = reDistribute(sharePerAsset(:,m), adjustmentFactor);
        
        % NB: this is essentially the target share of the asset!
        sharePerAssetEventSeries(:, m) = newSharePerAsset;
        
    end
    [which_events,~]=find(allEvents==eventDates');
    
    Tlot=array2timetable(sharePerAssetOE(isLaunch,:)','RowTimes',eventTable.date(which_events),'VariableNames',ASSET.Assets_Rated(isLaunch));
    Tpmt=array2timetable(sharePerAssetP(isLaunch,:)','RowTimes',eventTable.date(which_events),'VariableNames',ASSET.Assets_Rated(isLaunch));
    Tcmb=array2timetable(sharePerAsset(isLaunch,:)','RowTimes',eventTable.date(which_events),'VariableNames',ASSET.Assets_Rated(isLaunch));
    Tadt=array2timetable(sharePerAssetEventSeries(isLaunch,:)','RowTimes',eventTable.date(which_events),'VariableNames',ASSET.Assets_Rated(isLaunch));
    
    % Here we can put together the launch target tables
    model_id=repmat(Model.ID,Nlaunch*nEvents,1);
    country_id=repmat(i,Nlaunch*nEvents,1);
    asset_id=kron(ASSET.Unique_ID(isLaunch),ones(nEvents,1));
    event_id=repmat(which_events,Nlaunch,1);
    
    Ttarget{i}=table(model_id,...
        repmat(launchInfo{i}.launch_code(launch_scenario),Nlaunch*nEvents,1),...
        country_id,asset_id,event_id,...
        reshape(Tlot.Variables,Nlaunch*nEvents,[]),...
        reshape(Tpmt.Variables,Nlaunch*nEvents,[]),...
        reshape(Tcmb.Variables,Nlaunch*nEvents,[]),...
        reshape(Tadt.Variables,Nlaunch*nEvents,[]),...
        'VariableNames',{'model_id','launch_code','country_id','asset_id','event_id','LOT','PMT','CMB','ADT'});
    
    % Filter out any rows where all of the target shares are NaN
    Ttarget{i}=Ttarget{i}(~all(ismissing(Ttarget{i}(:,{'LOT','PMT','CMB','ADT'})),2),:);
    
    % From the the target shares, run Bass diffusion.
    [sharePerAssetMonthlySeries, sharePerClassMonthlySeries, ~] =...
        bassDiffusionClass(dateGrid,ASSET, CLASS, isLaunch, eventDates, sharePerAssetEventSeries, false);
    
    %fprintf('||sumMonthlyShare||: %g\n',norm(sum(sharePerClassMonthlySeries)-1))
    % Finally split into Branded and Generic shares
    [brandedMonthlyShare, genericMonthlyShare] = bassBrandedShare(dateGrid, sharePerAssetMonthlySeries, ASSET);
    
    model_id=repmat(Model.ID,Ny*Nlaunch,1);
    country_id=repmat(i,Ny*Nlaunch,1);
    asset_id=kron(ASSET.Unique_ID(isLaunch),ones(Ny,1));
    date_id=repmat(dateTable.ID(1:12:end),Nlaunch,1);
    
    % indexable auxillary index. Rows cover the time dimension, columns
    % cover asset dimension
    %aux_ind_month=reshape(aux_bounds(i)+1:aux_bounds(i+1),Nt,[]);
    %aux_ind=aux_ind_month(1:12:end,:);
    
    Tbms=array2timetable(brandedMonthlyShare(isLaunch,:)','RowTimes',dateTable.date,'VariableNames',ASSET.Assets_Rated(isLaunch));
    %Tgms=array2timetable(genericMonthlyShare(isLaunch,:)','RowTimes',dateTable.date,'VariableNames',ASSET.Assets_Rated(isLaunch));
    % PL: This is really strange but follows how things work in the original code.
    Tgms=array2timetable(sharePerAssetMonthlySeries(isLaunch,:)','RowTimes',dateTable.date,'VariableNames',ASSET.Assets_Rated(isLaunch));
    
    % Compute the yearly averages
    %brandedYearlyShare=squeeze(mean(reshape(brandedMonthlyShare(isLaunch,:)',12,[],Nlaunch),1))';
    %genericYearlyShare=squeeze(mean(reshape(genericMonthlyShare(isLaunch,:)',12,[],Nlaunch),1))';
    brandedYearlyShare=retime(Tbms,'yearly','mean');
    genericYearlyShare=retime(Tgms,'yearly','mean');
    
    % Store the yearly share value in a table (option 1)
    % NB: The date_id year will correspond correctly, but will not be
    % aligned to the right month.
    Tout{i}=table(model_id,...
        repmat(launchInfo{i}.launch_code(launch_scenario),Ny*Nlaunch,1),...
        country_id,asset_id,date_id,...%reshape(aux_ind(:,isLaunch),Ny*Nlaunch,[]),
        reshape(brandedYearlyShare.Variables,Ny*Nlaunch,[]),...
        reshape(genericYearlyShare.Variables,Ny*Nlaunch,[]),...
        'VariableNames',{'model_id','launch_code','country_id','asset_id','date_id','Branded_Molecule','Molecule'});
    
    model_id=repmat(Model.ID,Nt*Nlaunch,1);
    country_id=repmat(i,Nt*Nlaunch,1);
    asset_id=kron(ASSET.Unique_ID(isLaunch),ones(Nt,1));
    date_id=repmat(dateTable.ID,Nlaunch,1);
    
    Tmon{i}=table(model_id,...
        repmat(launchInfo{i}.launch_code(launch_scenario),Nt*Nlaunch,1),...
        country_id,asset_id,date_id,...%reshape(aux_ind(:,isLaunch),Ny*Nlaunch,[]),
        reshape(brandedMonthlyShare(isLaunch,:)',Nt*Nlaunch,[]),...
        reshape(genericMonthlyShare(isLaunch,:)',Nt*Nlaunch,[]),...
        'VariableNames',{'model_id','launch_code','country_id','asset_id','date_id','Branded_Molecule','Molecule'});
    % Now do some timing on inserts with the smaller output table
    %tstartsql=tic;
    %sqlwrite(conn,'scenarioOutput',Tout{i});
    %writetable(Tout{i},sprintf("%sscenario_%d_country_%d.csv",output_folder,launch_scenario,i));
    %tsql=tsql+toc(tstartsql);
    %execute(conn,"delete from scenarioOutput where launch_code="+launchInfo{i}.launch_code(launch_scenario))
end

%fprintf('[Timing] Small table write time %gs\n',tsql);

% Concatenate all country level tables
Tout=vertcat(Tout{:});
Tmon=vertcat(Tmon{:});

% Same for the target shares
Ttarget=vertcat(Ttarget{:});

twritestart=tic;

% Always write target shares
writetable(Ttarget,sprintf("%starget_%04d.csv",output_folder,launch_scenario));

% Write all the other tables out

if output_type == "Yearly" || output_type == "Yearly+Monthly"
    writetable(Tout,sprintf("%sscenario_%04d.csv",output_folder,launch_scenario));
end

if output_type == "Monthly" || output_type == "Yearly+Monthly"
    writetable(Tmon,sprintf("%smonthly_%04d.csv",output_folder,launch_scenario));
end

twrite=toc(twritestart);
tscenario=toc(tscenario);
fprintf('[Timing] Single launch time %gs. Table writing time %gs\n',tscenario,twrite);
