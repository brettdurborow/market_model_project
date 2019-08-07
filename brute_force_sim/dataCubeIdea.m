% Convert dates to datetime ( Turns out that datetime is really quite slow)
% Ta.Launch_Date=datetime(Ta.Launch_Date,'ConvertFrom','datenum');
% Ta.Launch_Date.Format='defaultdate';
% Ta.LOE_Date=datetime(Ta.LOE_Date,'ConvertFrom','datenum');
% Ta.LOE_Date.Format='defaultdate';
% Ta.Starting_Share_Date=datetime(Ta.Starting_Share_Date,'ConvertFrom','datenum');
% Ta.Starting_Share_Date.Format='defaultdate';

% Now set up the index mappings between asset_number and Asset name
% and country_number and country name
[unique_assets,ind_unique_assets,ind_assets]=unique(Ta.Assets_Rated);
%[unique_country,ind_unique_country,ind_country]=unique(Ta.Country);
[unique_classes,ind_unique_classes,ind_class]=unique(Ta.Therapy_Class);

% From these, we can now write the asset, country, and class tables in the
% MySQL database
%Asset_table=table(ind_unique_assets,string(unique_assets),'VariableNames',{'asset_id','asset_name'});
%Country_table=table(ind_unique_country,string(unique_country),'VariableNames',{'country_id','country_name'});
%Class_table=table(ind_unique_classes,string(unique_classes),'VariableNames',{'class_id','class_name'});

% These are the 
% Asset_table=table(string(unique_assets),'VariableNames',{'asset_name'});
% Country_table=table(string(unique_country),'VariableNames',{'country_name'});
% Class_table=table(string(unique_classes),'VariableNames',{'class_name'});


if false

Launch_date=repmat(Ta.Launch_Date,1,Ncl);



if ~exist('conn','var') 
    conn=connect_to_mysql('JnJ');
end

if ~isopen(conn)
    conn=connect_to_mysql('JnJ');
end

%sqlwrite(conn,'Model',Model);


%% The data cube idea (it may actually be more trouble than it is worth.)
%Define the linear indexes into the 3 dimensional cube for assets and
% country.
ind_map_asset_country=sub2ind([1,Na,Nco],ones(size(ind_assets)),ind_assets,ind_country);
ind_map_class_country=sub2ind([1,Ncl,Nco],ones(size(ind_class)),ind_class,ind_country);
ind_map_asset_class_country=sub2ind([Na,Ncl,Nco],ind_assets,ind_class,ind_country);
ind_map_time_asset_country=sub2ind([Nt,Na,Nco],ind_assets,ind_class,ind_country);

% Set up the data cube for the asset names
Smap=strings(1,Na,Nco);
Smap(ind_map_asset_country)=Ta.Assets_Rated;

% Set up the data cube for classes
Cmap=strings(1,Na,Nco);
Cmap(ind_map_asset_country)=Ta.Therapy_Class;

% Extract the asset launches by asset, class, and country
Asset_launch=NaT(Na,Ncl,Nco);
Asset_launch.Format='defaultdate';
Asset_launch(ind_map_asset_class_country)=Ta.Launch_Date;

% Compute minimum time over to find the first class launch in that country
% NB: min over first index implies we are finding the minimum w.r.t. all
% assets in that class in that country. We save the indices to index the
% asset names also)
[Class_launch,class_inds]=min(Asset_launch,[],1); 

% For classes, we can do the same conversion
Cmap_p=nan(1,Ncl,Nco);
Cmap_p(ind_map_class_country)=Ta.Class_p;

%% The following code is essentiall what needs replicating in the new data cube format
if false
    % Run simulation based on a fixed launch vector (No Monte Carlo)
    SIM = marketModelOneRealization(MODEL, ASSET, CHANGE, isLaunch, isChange, doDebug);
    
    % Compute statistics from the simulation
    dESTAT{m} = computeEnsembleStats( SIM.BrandedMonthlyShare, SIM.SharePerAssetMonthlySeries, SIM.DateGrid);
    
    % Shapes to use
    Na=length(ASSET.Assets_Rated);
    nEvents=length(SIM.DBG.EventDates);
    
    Therapy_class=categorical(ASSET.Therapy_Class);
    Asset_Names=categorical(ASSET.Assets_Rated);
    Country=categorical(ASSET.Country);
    
    % Data for the Assets
    TAsset=table(repmat(Country,nEvents,1),... % Country
        repmat(categorical(Scenarios(k)),nEvents*Na,1),... % Scenario Run
        repmat(categorical(runTime),nEvents*Na,1),... % Run Time
        repmat(Therapy_class,nEvents,1),... %Class
        repmat(Asset_Names,nEvents,1),... %Asset
        reshape(repmat(SIM.DBG.EventDates,Na,1),[],1),... %Time
        SIM.DBG.AssetProfile(:),... % Profile_model_Target_Share
        SIM.DBG.AssetOrderOfEntry(:),... % OE_Target_Share
        SIM.DBG.AssetUnadjTargetShare(:),... % Unadjusted_Combined_Target_share
        SIM.DBG.AssetAdjFactor(:),... % Adjustment_Factor
        SIM.DBG.AssetTargetShare(:),... % Adjusted_Target_Share
        'VariableNames',tableVarNames);
end
