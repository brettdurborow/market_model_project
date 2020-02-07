function single_simulation(launch_scenario,Tm,Ta,Tc,Td,eventTable,dateTable,Model,Country,launchInfo,ptrsTable,output_folder,output_type)

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
Taoc=cell(size(Na));
tscenario=tic;
for i=find(launch_scenario<=launch_height) %1:Nco
    country_selected=Country.CName(i);
    
    % define the index selector
    country_table_index=Ta.Country==country_selected;
    MODEL=Tm(Tm.CountrySelected==country_selected,:);
    ASSET=sortrows(Ta(country_table_index,:),'Unique_ID'); % This sort can be omitted if the Ta table is presorted.
    CLASS=Tc(Tc.Country==country_selected,:);
    % Get the launch vector over all assets
    isLaunchAll=launchInfo{i}.launch_logical(launch_scenario,:)';
    
    % Restrict to only those assets in the restricted asset table.
    isLaunch=isLaunchAll(ptrsTable.launch_mask(:,i));
    
    % Restrict number to only those assets actually launching. NB: We could restrict this by reducing the number of assets given to each model.
    Nlaunch=sum(isLaunch);
    
    % Construct the event date vector
    eventDates = unique([ASSET.Launch_Date; ASSET.LOE_Date; ASSET.Starting_Share_Date]);
    nEvents=length(eventDates);
    [which_events,~]=find(allEvents==eventDates');
        
    % Call the nested function defining the model (this could be made external)
    [sharePerAssetOE,sharePerAssetP,sharePerAsset,sharePerAssetEventSeries,sharePerAssetMonthlySeries,brandedMonthlyShare,AOC]=model_and_diffuse(MODEL,ASSET,CLASS,isLaunch,eventDates,dateGrid);

    % Now do things with the output
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
    
    % Filter out rows before the starting share date
    start_date_id=eventTable.ID(dateGrid(1)==allEvents);
    Ttarget{i}=Ttarget{i}(Ttarget{i}.event_id>=start_date_id,:);

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
    moleculeYearlyShare=retime(Tgms,'yearly','mean');
    
    % Store the yearly share value in a table (option 1)
    % NB: The date_id year will correspond correctly, but will not be
    % aligned to the right month.
    Tout{i}=table(model_id,...
        repmat(launchInfo{i}.launch_code(launch_scenario),Ny*Nlaunch,1),...
        country_id,asset_id,date_id,...%reshape(aux_ind(:,isLaunch),Ny*Nlaunch,[]),
        reshape(brandedYearlyShare.Variables,Ny*Nlaunch,[]),...
        reshape(moleculeYearlyShare.Variables,Ny*Nlaunch,[]),...
        'VariableNames',{'model_id','launch_code','country_id','asset_id','date_id','Branded_Molecule','Molecule'});
    
    % Filter out the NaN entries in the table.
    Tout{i}=Tout{i}(~all(ismissing(Tout{i}(:,{'Branded_Molecule','Molecule'})),2),:);
    
    model_id=repmat(Model.ID,Nt*Nlaunch,1);
    country_id=repmat(i,Nt*Nlaunch,1);
    asset_id=kron(ASSET.Unique_ID(isLaunch),ones(Nt,1));
    date_id=repmat(dateTable.ID,Nlaunch,1);
    
    Tmon{i}=table(model_id,...
        repmat(launchInfo{i}.launch_code(launch_scenario),Nt*Nlaunch,1),...
        country_id,asset_id,date_id,...%reshape(aux_ind(:,isLaunch),Ny*Nlaunch,[]),
        reshape(brandedMonthlyShare(isLaunch,:)',Nt*Nlaunch,[]),...
        reshape(sharePerAssetMonthlySeries(isLaunch,:)',Nt*Nlaunch,[]),...
        'VariableNames',{'model_id','launch_code','country_id','asset_id','date_id','Branded_Molecule','Molecule'});

    % Now we can investigate the delays on the AOC output
    if ~isempty(Td)
        % Get the delay table
        DELAY=Td(Td.Country_ID==Country.ID(i),:);
        Te=cell(height(DELAY),1);
  
        for j = 1:height(DELAY)
            asset_delay_selector=ASSET.Unique_ID==DELAY.Asset_ID(j);
            original_launch_date=ASSET.Launch_Date(asset_delay_selector);
            original_LOE_date=ASSET.LOE_Date(asset_delay_selector);
            ASSET.Launch_Date(asset_delay_selector)=datenum(datetime(original_launch_date,'ConvertFrom','datenum')+calmonths(DELAY.Launch_Delay(j)));
            ASSET.LOE_Date(asset_delay_selector)=datenum(datetime(original_LOE_date,'ConvertFrom','datenum')+calmonths(DELAY.LOE_Delay(j)));
            % Construct the event date vector
            original_eventDates=eventDates;
            eventDates = unique([ASSET.Launch_Date(isLaunch); ASSET.LOE_Date(isLaunch); ASSET.Starting_Share_Date(isLaunch)]);

            [~,~,~,~,~,brandedMonthlyShare_delayed,AOC_delay]=model_and_diffuse(MODEL,ASSET,CLASS,isLaunch,eventDates,dateGrid);
            
            AOCpct_change=AOC_delay./AOC;
            nanMask=~isnan(AOCpct_change);
            Nvalid=nnz(nanMask);
           
            model_id=repmat(Model.ID,Nvalid,1);
            country_id=repmat(i,Nvalid,1);
            asset_id=ASSET.Unique_ID(isLaunch);
            delayed_asset_id=repmat(DELAY.Asset_ID(j),Nvalid,1);
            launch_delay_time=repmat(DELAY.Launch_Delay(j),Nvalid,1);
            loe_delay_time=repmat(DELAY.LOE_Delay(j),Nvalid,1);
            Te{j} = table(model_id,repmat(launchInfo{i}.launch_code(launch_scenario),Nvalid,1),...
                country_id,delayed_asset_id,launch_delay_time,loe_delay_time,asset_id(nanMask),AOCpct_change(nanMask),'VariableNames',{'model_id','launch_code','country_id','delayed_asset_id','launch_delay_time','loe_delay_time','asset_id','AOC_ratio'});

            % Reset the dates back to what they were originally
            eventDates=original_eventDates;
            ASSET.Launch_Date(asset_delay_selector)=original_launch_date;
            ASSET.LOE_Date(asset_delay_selector)=original_LOE_date;
        end
        Taoc{i}=vertcat(Te{:});
        %launchMask=isLaunch&(ASSET.Launch_Date<=dateGrid'); % not sure where this was used.
        
    else
        Taoc{i}=table([],[],[],[],[],[],[],'VariableNames',{'model_id','launch_code','country_id','delayed_asset_id','delay_time','asset_id','AOC_ratio'});
    end
end

%fprintf('[Timing] Small table write time %gs\n',tsql);

% Concatenate all country level tables
Tout=vertcat(Tout{:});
Tmon=vertcat(Tmon{:});
Taoc=vertcat(Taoc{:});

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

writetable(Taoc,sprintf("%sdelay_%04d.csv",output_folder,launch_scenario));

twrite=toc(twritestart);
tscenario=toc(tscenario);
fprintf('[Timing] Single launch time %gs. Table writing time %gs\n',tscenario,twrite);
end

function [sharePerAssetOE,sharePerAssetP,sharePerAsset,sharePerAssetEventSeries,sharePerAssetMonthlySeries,brandedMonthlyShare,AOC]=model_and_diffuse(MODEL,ASSET,CLASS,isLaunch,eventDates,dateGrid)
nEvents=length(eventDates);
Na=length(isLaunch);

% Set up output matrices
sharePerAssetOE=nan(Na,nEvents);
sharePerAssetP=nan(Na,nEvents);
sharePerAsset=nan(Na,nEvents);
sharePerAssetEventSeries=nan(Na,nEvents);
CLASS = therapyClassRank(ASSET, CLASS, isLaunch);

sharePerAssetOE = orderOfEntryModelvec(MODEL, ASSET, CLASS, isLaunch, eventDates);
sharePerAssetP = profile_Modelvec(MODEL,ASSET,CLASS,isLaunch,eventDates);
sharePerAsset=(sharePerAssetOE*MODEL.OrderOfEntryWeight+sharePerAssetP*MODEL.ProfileWeight)/(MODEL.OrderOfEntryWeight + MODEL.ProfileWeight);
adjustmentFactor = applyFactors(MODEL, ASSET,  isLaunch);
sharePerAssetEventSeries = reDistributevec(sharePerAsset, adjustmentFactor);

% for m=1:nEvents
%     sharePerAssetEventSeries(:,m) = reDistribute(sharePerAsset(:,m), adjustmentFactor);
% end
%
% adjustmentFactor = applyFactors(MODEL, ASSET,  isLaunch);
% for m = 1:nEvents
%     sharePerAssetOE(:,m) = orderOfEntryModel(MODEL, ASSET, CLASS, isLaunch, eventDates(m)); % NB: elastClass, elastAsset are contained in MODEL
%     sharePerAssetP(:,m) = profileModel(MODEL, ASSET, CLASS, isLaunch, eventDates(m));
%     
%     sharePerAsset(:,m) = (sharePerAssetOE(:,m) * MODEL.OrderOfEntryWeight + sharePerAssetP(:,m) * MODEL.ProfileWeight) ...
%         / (MODEL.OrderOfEntryWeight + MODEL.ProfileWeight);
%     
%     newSharePerAsset= reDistribute(sharePerAsset(:,m), adjustmentFactor);
%     %
%     % NB: this is essentially the target share of the asset!
%     sharePerAssetEventSeries(:, m) = newSharePerAsset;
%     
% end

%ma=@(x)max(max(abs(x)));
%fprintf('vectorized speedup: %g ||OE|| %g ||P|| %g ||COM|| %g ||SERIES|| %g \n',tt_scalar/tt_vec,ma(sharePerAssetOE-sharePerAssetOEvec),ma(sharePerAssetP-sharePerAssetPvec),ma(sharePerAsset-sharePerAssetvec),ma(sharePerAssetEventSeries-sharePerAssetEventSeriesvec));
% From the the target shares, run Bass diffusion.

[sharePerAssetMonthlySeries, sharePerClassMonthlySeries, ~] =...
    bassDiffusionClass(dateGrid,ASSET, CLASS, isLaunch, eventDates, sharePerAssetEventSeries, false);

%fprintf('||sumMonthlyShare||: %g\n',norm(sum(sharePerClassMonthlySeries)-1))
% Finally split into Branded and Generic shares
[brandedMonthlyShare, genericMonthlyShare] = bassBrandedShare(dateGrid, sharePerAssetMonthlySeries, ASSET);

% Set up integration mask to evaluate area under curve of Share
Lmask = max(ASSET.Launch_Date(isLaunch),ASSET.Starting_Share_Date(isLaunch)) <= dateGrid';
LOEmask = ASSET.LOE_Date(isLaunch) >= dateGrid';
Imask= Lmask & LOEmask;

% Perform the actual integration (with unit spacing == months)
AOC = sum(brandedMonthlyShare(isLaunch,:).*Imask,2,'omitnan');
end