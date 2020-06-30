        % [DEPRECIATED] Button pushed function: RunSimulationButton
        function RunQueueButtonPushed(app, event)
            % Check if input and output are set, then simulate
            if app.isOkInput && app.isOkOutput
                output_folder=app.Output_Folder.Value+app.Model.MName+filesep;
                % make a new sub-directory
                if ~exist(output_folder)
                    try
                        mkdir(output_folder)
                    catch
                        errordlg({'Could not create directory:',output_folder});
                    end
                end
                
                tstart=tic;
                writetable(app.Model,output_folder+"Model.csv");
                writetable(app.dateTable,output_folder+"dateGrid.csv");
                writetable(app.eventTable,output_folder+"dateEvent.csv");
                writetable(app.Country(:,{'ID','CName','Has_Model'}),output_folder+"Country.csv");
                writetable(app.Asset,output_folder+"Asset.csv");
                writetable(app.Company,output_folder+"Company.csv");
                writetable(app.Class,output_folder+"Class.csv");
                writetable(app.assetLaunchInfo,output_folder+"assetLaunchInfo.csv");
                writetable(app.launchCodes,output_folder+"launchCodes.csv");
                writetable(app.Ta,output_folder+"assumptions.csv");
                writetable(app.Tm,output_folder+"simulation.csv");
                twrite=toc(tstart);
                app.Status_text.Value=vertcat(sprintf('[Timing] Wrote all non-scenario tables to disk %gs',twrite),app.Status_text.Value);
                                
                fprintf('[Timing] Writing all non-output tables to disk %gs\n',twrite);

                %% Now we are in a position to do some of the actual calculations:
                %Firstly, we need a loop per country,
                tstart=tic;
                % Get the number of launchs in each country.
                launch_height=cellfun(@height,app.launchInfo)';
                
                % Update the status
                app.Status_text.Value=vertcat('Starting simulation.',app.Status_text.Value);
                
                % parallel loop for the launch scenarios
                WaitMessage = parfor_wait(max(launch_height),'Waitbar',true,'ReportInterval',1);
                cleanWait=onCleanup(@()delete(WaitMessage));
                % For parallel execution, apparently we can't access the
                % app variables directly, so we copy
                Tm=app.Tm; Ta=app.Ta; Tc=app.Tc; Td=app.Td; eventTable=app.eventTable;dateTable=app.dateTable;Model=app.Model;Country=app.Country;launchInfo=app.launchInfo;ptrsTable=app.ptrsTable;
                output_type=app.OutputType.Value;

                if app.ParallelWorkers.Value==1
                    % Run Serial code
                    for launch_scenario=1:max(launch_height)
                        single_simulation(launch_scenario,Tm,Ta,Tc,Td,eventTable,dateTable,Model,Country,launchInfo,ptrsTable,output_folder,output_type);
                        WaitMessage.Send;
                        if getappdata(WaitMessage.WaitbarHandle,'Cancelled')
                            % Write out that we have cancelled, all other
                            % variable should be cleaned up on exit.
                            app.Status_text.Value=vertcat('Simulation cancelled',app.Status_text.Value);
                            % Then exit the loop to stop fetching new jobs
                            break
                        end
                    end
                else
                    % Otherwise we run parallel version
                    for launch_scenario=1:max(launch_height)
                        % Asynchronously launch each scenario
                        future_launch(launch_scenario)=parfeval(@(launch) single_simulation(launch,Tm,Ta,Tc,Td,eventTable,dateTable,Model,Country,launchInfo,ptrsTable,output_folder,output_type),0,launch_scenario);
                    end
                    app.Status_text.Value=vertcat('Parallel queue initialized',app.Status_text.Value);
                    
                    cancelFutures = onCleanup(@() cancel(future_launch));
                    % Register progress bar to update after each excecution
                    updateWaitMessage=afterEach(future_launch,@()WaitMessage.Send(),0);
                    afterEach(future_launch,@(f) disp(f.Diary),0,'passFuture',true);
                    
                    numRead=0;timeout=10;
                    while numRead <= max(launch_height)
                        if ~all([future_launch.Read])
                            completedID=fetchNext(future_launch,timeout);
                        end
                        
                        if ~isempty(completedID)
                            numRead=numRead+1;
                            app.Status_text.Value=vertcat(future_launch(completedID).Diary,app.Status_text.Value);
                        end
                        
                        if getappdata(WaitMessage.WaitbarHandle,'Cancelled')
                            % Write out that we have cancelled, all other
                            % variable should be cleaned up on exit.
                            app.Status_text.Value=vertcat('Simulation cancelled',app.Status_text.Value);
                            % Then exit the loop to stop fetching new jobs
                            break
                        end
                    end
                end
                tsimulate=toc(tstart);
                fprintf('[Timing] Total simulation time: %gs\n',tsimulate);
                %if the launch wasnt cancelled, then we are done!
                app.Status_text.Value=vertcat('Simulation completed',app.Status_text.Value);

                app.Status_text.Value=vertcat(sprintf('[Timing] Total simulation time: %gs',tsimulate),app.Status_text.Value);
                
            else
                app.Status_text.Value=vertcat('[Warning]: Input and output paths must be specified',app.Status_text.Value);
            end
        end