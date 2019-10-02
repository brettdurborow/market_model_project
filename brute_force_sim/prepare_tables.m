load_data;
%fprintf('%s\n',msg)

[Tm,Ta,Tc,eventTable,dateTable,Country,Asset,Class,Company]=preprocess_data(modelID,cMODEL,cASSET,cCHANGE);

%fprintf('%s\n',msg)
[launchCodes,launchInfo,assetLaunchInfo,ptrsTable]=generate_launchCodes(Ta,Country,Asset,robustness);

Launch_Delay=(6:6:18)';
LOE_Delay=-(3:3:9)';
Tc=array2table([kron(ones(size(Launch_Delay)),Tc.Variables),kron(Launch_Delay,ones(height(Tc),1)),kron(LOE_Delay,ones(height(Tc),1))],'VariableNames',{'Country_ID','Asset_ID','Launch_Delay','LOE_Delay'});

write_tables;
%fprintf('%s\n',msg);

%% Now we are in a position to do some of the actual calculations:
%Firstly, we need a loop per country, 
tstart=tic;
% At this point, we have all information to construct the output table.
% We have a few distinct options for storing the outputs:
%  1) Cell array of tables
%  2) Insertation into a large table
%  3) Concatenating tables

%fprintf('[INFO] Robustness %3.0f\n[INFO] Total launch scenarios %d in parallel\n',robustness*100,max(launch_height));
launch_height=cellfun(@height,launchInfo)';
for launch_scenario=1:max(launch_height)
    single_simulation(launch_scenario,Tm,Ta,Tc,eventTable,dateTable,Model,Country,launchInfo,ptrsTable,output_folder,output_type);
end


% % parallel loop for the launch scenarios
% WaitMessage = parfor_wait(max(launch_height),'Waitbar',true,'ReportInterval',10);
% %cleanWait=onCleanup(@()waitCleanup(WaitMessage));
% for launch_scenario=1:max(launch_height)
%     future_launch(launch_scenario)=parfeval(@(launch) single_simulation(launch,Tm,Ta,Tc,eventTable,dateTable,Model,Country,launchInfo,ptrsTable,output_folder),0,launch_scenario);
% end
% updateWaitMessage=afterEach(future_launch,@()WaitMessage.Send(),0);
% 
% % Now collect together all the completed launches
% for launch_scenario=1:max(launch_height)
%     % Check if the process was cancelled
%     if getappdata(WaitMessage.WaitbarHandle,'Cancelled')
%         % First, cancel all of the future launch jobs
%         cancel(future_launch);
%         WaitMessage.Destroy;
%         % Then exit the loop to stop fetching new jobs
%         break
%     end
% 
%     % Fetch the next launch that completed
%     [completedIdx]=fetchNext(future_launch);
%     % Write out the message from the completed launch
%     fprintf('%s',future_launch(completedIdx).Diary);
% end

tsimulate=toc(tstart);
fprintf('[Timing] Total simulation time: %gs\n',tsimulate);
%WaitMessage.Destroy;
