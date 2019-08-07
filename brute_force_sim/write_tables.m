%% Disk operations: 
% Write all tables out out to disk
tstart=tic;
writetable(Model,output_folder+"Model.csv");
writetable(dateTable,output_folder+"dateGrid.csv");
writetable(eventTable,output_folder+"dateEvent.csv");
writetable(Country(:,{'ID','CName','Has_Model'}),output_folder+"Country.csv");
writetable(Asset,output_folder+"Asset.csv");
writetable(Company,output_folder+"Company.csv");
writetable(Class,output_folder+"Class.csv");
writetable(assetLaunchInfo,output_folder+"assetLaunchInfo.csv");
writetable(launchCodes,output_folder+"launchCodes.csv");
writetable(Ta,output_folder+"assumptions.csv");
writetable(Tm,output_folder+"simulation.csv");
twrite=toc(tstart);
fprintf('[Timing] Writing all non-output tables to disk %gs\n',twrite);


