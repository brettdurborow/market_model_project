function [Tm,Ta,Td,eventTable,dateTable,Country,Asset,Class,Company]=preprocess_data(modelID,cMODEL,cASSET)
%% Data pre-processing.
% 
% From the input data structures, we do some pre-processing to get the data
% into a more easily usable form.
%
% NB: We reverse the ordering in all of the structures below.
tstart=tic;
% utility function to sanitize incoming strings
sanitize=@(name)lower(regexprep(name,{'[^a-zA-Z_0-9 ]','\s'},{'','_'}));

% Get country names in reverse ordering
unique_country=string(cellfun(@(A)A.CountrySelected,cMODEL(end:-1:1),'UniformOutput',false));
ind_unique_country=(1:length(unique_country))';

% Convert model array to table type 
Tm=cellfun(@(C)struct2table(C,'AsArray',true),cMODEL,'UniformOutput',false);
Tm=vertcat(Tm{end:-1:1});

% Ensure that the file name and modification dates are identical
Tm.FileName=string(Tm.FileName);
Tm.FileDate=datetime(Tm.FileDate);
assert(all(Tm.FileName==Tm.FileName(1))& all(Tm.FileDate==Tm.FileDate(1)),...
    "Model file name and date must be identcal")


% Convert all char to string type
Tm.CountrySelected=string(Tm.CountrySelected);


% Convert the assets to the asset table and reverse the ordering
Ta=cellfun(@(A)struct2table(A),cASSET,'UniformOutput',false);
Ta=Ta(end:-1:1);

% We need to validate the assets based on their PTRS value, as none of the
% assets having PTRS==0 will launch, then we remove them from consideration
% Thus, the number of assets is given as the number of nonzero PTRS values
Na=cellfun(@(A)sum(A.Scenario_PTRS>0),Ta); % Get asset sizes
% Generate number of unique events in each country
Nevents=cellfun(@(A)length(unique([A.Launch_Date; A.LOE_Date; A.Starting_Share_Date])),cASSET(end:-1:1));
% Concatenate into a single table.
Ta=vertcat(Ta{:});
% Then remove any values with a zero PTRS value
Ta(Ta.Scenario_PTRS==0,:)=[];

% Process the asset names to only contain only alphanumeric plus underscore and hyphens
Ta.Assets_Rated=sanitize(Ta.Assets_Rated);
Ta.Follow_On=sanitize(Ta.Follow_On);

% Now add the time dimension
[launchDate,~,ind_launch] = unique(Ta.Launch_Date);
[loeDate,~,ind_loe]=unique(Ta.LOE_Date);
[startDate,iA,ind_start]=unique(Ta.Starting_Share_Date);

% We are going to ensure that Starting share date is consistent accross all
% countries, issuing a warning if not all the same.
if length(startDate)>1
    warning('Starting share date is not unique over all countries. Replacing date with minimum');
    Ta.Starting_Share_Date(Ta.Starting_Share_Date~=min(startDate))=min(startDate);
end

% Convert the starting date to datetime
dtStartDate=datetime(startDate,'ConvertFrom','datenum');

% Set the number of years past the start date to simulate
dateHorizon=calyears(30);

dtStartYear=datetime(min(year(dtStartDate)),1,1);
% Construct a datetime grid for the table construction
dtDateGrid=(min(dtStartDate):calmonths(1):min(dtStartDate)+dateHorizon)';
%dtDateGrid=(dtStartYear:calmonths(1):dtStartYear+dateHorizon)';

dtDateGrid.Format='uuuu-MM-dd HH:mm:ss';

% Use the left hand endpoints as the yearly date
dtDateGridYear=dtDateGrid(1:12:end);

% Number of years to simulate for
Ny = size(dtDateGridYear,1);

% Since datetime is much slower for simulation, we convert to datenum (seconds)
dateGrid=datenum(dtDateGrid);

% Create a unique event date vector for all assets
[allEvents,~,~]=unique([Ta.Launch_Date;Ta.LOE_Date;Ta.Starting_Share_Date]);
dtAllEvents=datetime(allEvents,'ConvertFrom','datenum');
dtAllEvents.Format='uuuu-MM-dd HH:mm:ss';

% Extract the number of unique Countries and Dates
Nco=length(ind_unique_country);
Nt=length(dateGrid);

% Give the bounds for the size of each block for one country in the
% Auxilary table
aux_bounds=[0;cumsum(Na*Nt)];

% We need to generate indices for the unique set of assets over all countries
% The ordering is done via the unique IDs of the input table
[unique_asset_id,ind_unique_assets,ind_assets]=unique(Ta.Unique_ID);

% Extract the actual asset names for our asset table.
unique_assets=Ta.Assets_Rated(ind_unique_assets);

% Calculate the total number of assets
Na_total=length(unique_assets);

% Same for the classes
[unique_classes,ind_unique_classes,ind_classes]=unique(Ta.Therapy_Class);%(ind_unique_assets));

% And for company1 + company2 
[unique_company,ind_unique_company,ind_company]=unique([Ta.Company1,Ta.Company2]);%(ind_unique_assets)
ind_company=reshape(ind_company,[],2);

[~,~,ind_country]=unique(Ta.Country,'stable');

% Update the Ta table to include the IDs
Ta=addvars(Ta,ind_company(:,1),ind_company(:,2),ind_classes,ind_country,'NewVariableNames',{'Company1_ID','Company2_ID','Class_ID','Country_ID'});
Ta=sortrows(Ta,{'Country_ID','Unique_ID'});

Tm=addvars(Tm,repmat(modelID,Nco,1),ind_unique_country,'NewVariableNames',{'Model_ID','Country_ID'});
% Construct all of the processed input tables and write out to csv (or
% database)
eventTable=table((1:length(allEvents))',dtAllEvents,'VariableNames',{'ID','date'});
dateTable=table((1:length(dtDateGrid))',dtDateGrid,'VariableNames',{'ID','date'});
Country=table(ind_unique_country,unique_country,Na,true(size(unique_country)),Nevents,'VariableNames',{'ID','CName','NAssets','Has_Model','Nevents'});% 'Description'=>NULL
Asset=table(unique_asset_id,unique_assets,ind_company(ind_unique_assets,1),ind_company(ind_unique_assets,2),ind_classes(ind_unique_assets),'VariableNames',{'ID','AName','Company1','Company2','Class'}); %'UID',
Class=table((1:length(unique_classes))',unique_classes,'VariableNames',{'ID','CName'}); % CDescription
Company=table((1:length(unique_company))',unique_company,'VariableNames',{'ID','CName'});

% Construct the delay table
Td=Ta(sanitize(Ta.Company1)=="janssen",{'Country_ID','Unique_ID'});

% Timing statistics
tdata_proc=toc(tstart);
fprintf('[Timing] Data processing: %gs\n',tdata_proc);

