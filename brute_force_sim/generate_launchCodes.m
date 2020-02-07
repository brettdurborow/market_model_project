function [launchCodes,launchInfo,assetLaunchInfo,ptrsTable,Nunlaunched,Nlaunched]=generate_launchCodes(Ta,Country,Asset,robustness)
%% Now we generate the launch scenrios for each country
%
% This is really the entry point to the main algorithm, and the one that
% should be batch processed and parallelized over the countries.
tstart=tic;

Nco=height(Country);
Na_total=height(Asset);

% Here we will populate the PTRS values for all assets over all countries
%PTRS=zeros(Na_total,Nco);
launch_mask=false(Na_total,Nco);
launchInfo=cell(Nco,1);
assetLaunchInfo=cell(Nco,1);
launchCodes=cell(Nco,1);
fullLaunch=cell(Nco,1);

PTRS=array2table(zeros(Na_total,Nco),'VariableNames',Country.CName,'RowNames',Asset.AName);

% For follow-on assets we need a mask note that empty ones will be ""
[unique_follow_on,ind_unique_follow_on,ind_follow_on]=unique(Ta.Follow_On);

% We know that "" will be the first so we find the mapping between the
% unique asset list and the follow on assets. 
[followed_inds,~]=find(Asset.AName==unique_follow_on(2:end,:)');
[follow_on_inds,~]=find(Asset.AName==Ta.Assets_Rated(ind_unique_follow_on(2:end,:))');

% Specify a vector for the potentially unlaunched assets
unlaunched_id=Asset.ID<=64;
Nunlaunched=sum(unlaunched_id);
launched_id=Asset.ID>64;
Nlaunched=sum(launched_id);

for i=1:Nco
    % Select country rows
    country_selected=Country.CName(i);
    country_table_index=Ta.Country==country_selected;
   
    % Select PTRS
    PTRS(Ta.Assets_Rated(country_table_index),country_selected)=table(Ta.Scenario_PTRS(country_table_index));
    
    % Rank the assets to produce their launch indices
    [II,p,cdf]=rankAssets(PTRS(:,i).Variables,followed_inds,follow_on_inds);
    
    % Now we are going to truncate based on the robustness factor
    ind_r = cdf<=robustness;
    
    %I_r=uint64(II(ind_r,unlaunched_id)*(2.^(0:Nunlaunched-1)'));
    % New launch codes indicating up to 64 unlaunched assets
    I_r=uint64(II(ind_r,unlaunched_id)*(2.^(Asset.ID(unlaunched_id)-1)));
    % Here we replicate the asset indices
    K=repmat(Asset.ID,1,sum(ind_r));
    
    % Select those assets who launch
    indK=K(II(ind_r,:)');
  
    % Replicate the launch code
    K1=repmat(I_r,1,Na_total)';
    
    % Select only those who launch
    indK1=K1(II(ind_r,:)');
    
    assetLaunchInfo{i}=table(indK1,indK,i*ones(size(indK)),'VariableNames',{'launch_code','asset_launched','country_id'});
    
    launchCodes{i}=table(I_r,i*ones(sum(ind_r),1),p(ind_r),'VariableNames',{'launch_code','country_id','probability'});
    
    % Put everything into a table
    launchInfo{i}=table(I_r,II(ind_r,:),p(ind_r),cdf(ind_r),'VariableNames',{'launch_code','launch_logical','probability','cdf'});   
    %fullLaunch{i}=table(I,II,p,cdf,'VariableNames',{'launch_code','launch_logical','probability','cdf'});
end
% Concatenate all launch info and launch codes together
assetLaunchInfo=vertcat(assetLaunchInfo{:});
launchCodes=sortrows(vertcat(launchCodes{:}),'probability','descend');

launch_mask=PTRS.Variables>0; % these assets launch
ptrsTable=table(PTRS.Variables,launch_mask,'VariableNames',{'PTRS','launch_mask'});
tlaunch_scenarios=toc(tstart);
fprintf('[Timing] Generate launch scenario ranking: %gs\n',tlaunch_scenarios);