classdef aMDD_Brute_Force_Simulator < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        aMDDBruteForceSimulatorUIFigure  matlab.ui.Figure
        RobustnessSliderLabel       matlab.ui.control.Label
        RobustnessSlider            matlab.ui.control.Slider
        InputFileEditFieldLabel     matlab.ui.control.Label
        Input_File                  matlab.ui.control.EditField
        OutputEditFieldLabel        matlab.ui.control.Label
        Output_Folder               matlab.ui.control.EditField
        TabGroup                    matlab.ui.container.TabGroup
        StatusTab                   matlab.ui.container.Tab
        Status_text                 matlab.ui.control.TextArea
        ConsoleTab                  matlab.ui.container.Tab
        Console_text                matlab.ui.control.TextArea
        NumberofParallelWorkersDropDownLabel  matlab.ui.control.Label
        ParallelWorkers             matlab.ui.control.DropDown
        NumberofOutputTypeDropDownLabel matlab.ui.control.Label
        OutputType                  matlab.ui.control.DropDown        
        BrowseFile                  matlab.ui.control.Button
        BrowseFolder                matlab.ui.control.Button
        NumberofScenariosEditFieldLabel  matlab.ui.control.Label
        NumberofScenariosEditField  matlab.ui.control.NumericEditField
        NumberofParallelWorkersEditFieldLabel  matlab.ui.control.Label
        NumberofParallelWorkersEditField  matlab.ui.control.NumericEditField
        RunSimulationButton         matlab.ui.control.Button
        %RunQueueButton              matlab.ui.control.Button
        ptrsTab                     matlab.ui.container.Tab
        ptrsAxes                    matlab.ui.control.UIAxes
    end

    
    properties (Access = private)
        Ta % Asset table
        Tm % Model table
        Tc % Change table (future)
        modelID = 1 % Model
        isOkInput = false % Input file is read and OK.
        isOkOutput = false % Output folder is valid
        numCores = feature('numcores')
        ParallelPool % Parallel pool
    end
    
    properties (Access = public)
        eventTable
        dateTable
        Model
        Country
        Asset
        Class
        Company
        launchCodes
        launchInfo
        ptrsTable
        assetLaunchInfo
    end
    

    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            % Set the number of entries in the dropdown for the number of parallel workers.
            app.ParallelWorkers.Items=["Serial","Parallel"];
            app.ParallelWorkers.ItemsData=[1,app.numCores];
            app.ParallelWorkers.Value=app.numCores;
            app.NumberofParallelWorkersEditField.Value = app.numCores;
            %app.ParallelPool=parpool(app.numCores);
        end
            
        % Button pushed function: BrowseFile
        function BrowseFileButtonPushed(app, event)
            % Specify file filters for excel or mat
            filterSpec = {'*.xls*;*.mat','Excel (.xls*) or Matlab Cache file (.mat)'};
            
            % Dialogue text for input
            dialogTitle = 'Select Input file (Excel or MAT)';
            
            % Prompt user for file input
            [dataFile,dataFolder] = uigetfile(filterSpec, dialogTitle);
            
            if dataFolder == 0  % user hit cancel in uigetfile dialog
                app.isOkInput = false;
                app.Input_File.Value = '';
                app.Status_text.Value=vertcat('WARNING: no input file set!',app.Status_text.Value);
                
            else % User selected something
                
                % Put together full file name in case app is run in a different dir.
                fullDataFile=fullfile(dataFolder,dataFile);
                
                % Get file extension fro deciding which path to take
                [~,inputDataName,inputExtension]=fileparts(dataFile);
                
                % Update input text
                app.Input_File.Value=fullDataFile;
                
                % Check first for a Cache .mat file
                switch inputExtension
                    case '.mat'
                        load(fullDataFile);
                        app.isOkInput = true;
                    case {'.xls','.xlsx','.xlsm','.xlsb'}
                        % Check input file for asset, change event, and simulation sheets
                        assetSheets=[];
                        try
                            [assetSheets, ~ , simuSheet] = checkInputSheets(fullDataFile);%ceSheets
                        catch
                            app.Status_text.Value=vertcat({'Unable to open Input file!  Please check file location and Excel installation.'},app.Status_text.Value);
                            app.isOkInput = false;
                        end
                        % Input check passes now check if there are asset sheets to import
                        if all(assetSheets==0) || simuSheet==0
                            msgbox('Found no "Asset" sheet in this file named "1", "2", etc.  Unable to continue.');
                            app.isOkInput = false;
                        else
                            tStart = tic;
                            % First import assumptions and asset information from excel
                            [cMODEL, cASSET, cCHANGE,cDEBUG] = importAssumptions(fullDataFile);
                            app.Status_text.Value = vertcat(sprintf('Imported Data, elapsed time = %1.1f sec',toc(tStart)),app.Status_text.Value);
                            
                            app.isOkInput = true;
                            
                            % Cache the output in a Matlab .Mat file
                            if exist([inputDataName,'.mat'],'file')
                                overWrite=questdlg('Overwrite existing Cache file?','Overwrite Cache','No');
                                switch overWrite
                                    case 'Yes'
                                        save([inputDataName,'.mat'], 'cMODEL','cASSET', 'cCHANGE','cDEBUG');
                                end
                            end
                        end
                end
                app.Status_text.Value=vertcat('Starting data pre-processing:',app.Status_text.Value);
                % We preprocess the data to get the tables out
                tstart=tic;
                [app.Tm,app.Ta,app.Tc,app.Model,app.eventTable,app.dateTable,app.Country,app.Asset,app.Class,app.Company]...
                    = preprocess_data(app.modelID,cMODEL,cASSET,cCHANGE);
                tdata_proc=toc(tstart);
                
                % Output some status messages
                app.Status_text.Value=vertcat(sprintf('[Timing] Data pre-processing: %gs',tdata_proc),app.Status_text.Value);
                
                app.Status_text.Value=vertcat('Generating launch Scenarios',app.Status_text.Value);
                % Since we have the data available, we generate the launch codes
                tstart=tic;
                [app.launchCodes,app.launchInfo,app.assetLaunchInfo,app.ptrsTable]=generate_launchCodes(app.Ta,app.Country,app.Asset,app.RobustnessSlider.Value/100);
                tlaunch_scenarios=toc(tstart);
                app.NumberofScenariosEditField.Value=height(app.launchCodes);
                app.Status_text.Value=vertcat(sprintf('[Timing] Generating launch scenarios: %gs',tlaunch_scenarios),app.Status_text.Value);
                cla(app.ptrsAxes)
                app.ptrsAxes.XScale='log';
                hold(app.ptrsAxes,'on')
                for i=1:length(app.launchInfo)
                    semilogx(app.ptrsAxes,app.launchInfo{i}.cdf);
                end
                legend(app.ptrsAxes,app.Country.CName,'Location','SouthEast')
                hold(app.ptrsAxes,'off');
                
            end
            
            function [assetSheets, ceSheets, simuSheet] = checkInputSheets(fileName)
                % Build a list of Asset sheets in this workbook
                [~, sheets, ~] = xlsfinfo(fileName);
                %Find simulation sheet
                simuSheet = sum(strcmpi(sheets, 'Simulation')) == 1;  % look for a sheet called "Simulation"
                
                % Find asset sheets
                assetSheets=cellfun(@(s) ~isempty(s) && length(s)==1 ,regexp(sheets,'^[1-7]$'));
                ceSheets=cellfun(@(s) ~isempty(s) && length(s)==3,regexp(sheets,'^[1-7]CE$'));
            end
            
        end

        % Button pushed function: BrowseFolder
        function BrowseFolderButtonPushed(app, event)
            foldername = uigetdir();
            % If there is no input, then we need to check that the type is numeric
            if ischar(foldername) && exist(foldername,'dir') == 7
                app.isOkOutput = true;
                app.Output_Folder.Value=[foldername,filesep];
                msg = {'Selected valid output folder:';app.Output_Folder.Value};
            else
                app.isOkOutput = false;
                msg = 'WARNING: invalid Output Folder!';
                app.Output_Folder.Value = '';
            end
            app.Status_text.Value=vertcat(msg,app.Status_text.Value);
            
        end

        % Value changed function: RobustnessSlider
        function RobustnessSliderValueChanged(app, event)
            app.Status_text.Value=vertcat(sprintf('Robustness value changed to: %.1f', app.RobustnessSlider.Value),app.Status_text.Value);
            % If input was already read, then we need to (re)calculate the launch Codes
            if app.isOkInput
                tstart=tic;
                [app.launchCodes,app.launchInfo,app.assetLaunchInfo,app.ptrsTable]=generate_launchCodes(app.Ta,app.Country,app.Asset,app.RobustnessSlider.Value/100);
                app.NumberofScenariosEditField.Value=height(app.launchCodes);
                tlaunch_scenarios=toc(tstart);
                cla(app.ptrsAxes)
                app.ptrsAxes.XScale='log';
                hold(app.ptrsAxes,'on')
                for i=1:length(app.launchInfo)
                    semilogx(app.ptrsAxes,app.launchInfo{i}.cdf);
                end
                legend(app.ptrsAxes,app.Country.CName)
                hold(app.ptrsAxes,'off');

                app.Status_text.Value=vertcat(sprintf('[Timing] Generating launch scenarios: %gs',tlaunch_scenarios),...
                    app.Status_text.Value);
            end
            % Otherwise, we don't need to do anything
        end

        % Button pushed function: RunSimulationButton
        function RunSimulationButtonPushed(app, event)
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

                % Extract static variables 
                Tm=app.Tm; Ta=app.Ta; Tc=app.Tc; eventTable=app.eventTable;dateTable=app.dateTable;Model=app.Model;Country=app.Country;launchInfo=app.launchInfo;ptrsTable=app.ptrsTable;
                output_type=app.OutputType.Value;
                % Set up a progress bar (apparently works in serial code, too)
                WaitMessage = parfor_wait(max(launch_height),'Waitbar',true,'ReportInterval',1);
                cleanWait=onCleanup(@()delete(WaitMessage));

                % Check if we are running the serial code or not
                if app.ParallelWorkers.Value == 1 
                    % Run Serial code
                    for launch_scenario=1:max(launch_height)
                        single_simulation(launch_scenario,Tm,Ta,Tc,eventTable,dateTable,Model,Country,launchInfo,ptrsTable,output_folder,output_type);
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
                    % parallel loop for the launch scenarios
                    app.Status_text.Value=vertcat('[WARNING]: Cancel button does not function for parfor loops',app.Status_text.Value);
                    
                    parfor launch_scenario=1:max(launch_height)
                        single_simulation(launch_scenario,Tm,Ta,Tc,eventTable,dateTable,Model,Country,launchInfo,ptrsTable,output_folder,output_type);
                        WaitMessage.Send;
                   end
                end
                
                tsimulate=toc(tstart);
                fprintf('[Timing] Total simulation time: %gs\n',tsimulate);
                %if the launch wasnt cancelled, then we are done!
                app.Status_text.Value=vertcat('Simulation completed',app.Status_text.Value);

                app.Status_text.Value=vertcat(sprintf('[Timing] Total simulation time: %gs\n',tsimulate),app.Status_text.Value);
                
            else
                app.Status_text.Value=vertcat('Warning Input and output paths must be specified',app.Status_text.Value);
            end
        end

                % Button pushed function: RunSimulationButton
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
                Tm=app.Tm; Ta=app.Ta; Tc=app.Tc; eventTable=app.eventTable;dateTable=app.dateTable;Model=app.Model;Country=app.Country;launchInfo=app.launchInfo;ptrsTable=app.ptrsTable;
                output_type=app.OutputType.Value;

                if app.ParallelWorkers.Value==1
                    % Run Serial code
                    for launch_scenario=1:max(launch_height)
                        single_simulation(launch_scenario,Tm,Ta,Tc,eventTable,dateTable,Model,Country,launchInfo,ptrsTable,output_folder,output_type);
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
                        future_launch(launch_scenario)=parfeval(@(launch) single_simulation(launch,Tm,Ta,Tc,eventTable,dateTable,Model,Country,launchInfo,ptrsTable,output_folder,output_type),0,launch_scenario);
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
                app.Status_text.Value=vertcat('Warning Input and output paths must be specified',app.Status_text.Value);
            end
        end

        function OutputTypeValueChanged(app, event)
            value = app.OutputType.Value;
            app.Status_text.Value=vertcat(sprintf('Output type change to: %s',value),app.Status_text.Value);
        end

        
        % Value changed function: ParallelWorkers
        function ParallelWorkersValueChanged(app, event)
            value = app.ParallelWorkers.Value;
            app.Status_text.Value=vertcat(sprintf('Number of processors changed to: %d',value),app.Status_text.Value);
        end
    end

    % App initialization and construction
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create aMDDBruteForceSimulatorUIFigure
            app.aMDDBruteForceSimulatorUIFigure = uifigure;
            app.aMDDBruteForceSimulatorUIFigure.Position = [100 100 640 694];
            app.aMDDBruteForceSimulatorUIFigure.Name = 'aMDD Brute Force Simulator';

            % Create RobustnessSliderLabel
            app.RobustnessSliderLabel = uilabel(app.aMDDBruteForceSimulatorUIFigure);
            app.RobustnessSliderLabel.HorizontalAlignment = 'right';
            app.RobustnessSliderLabel.Position = [59 551 69 22];
            app.RobustnessSliderLabel.Text = 'Robustness';

            % Create RobustnessSlider
            app.RobustnessSlider = uislider(app.aMDDBruteForceSimulatorUIFigure);
            app.RobustnessSlider.ValueChangedFcn = createCallbackFcn(app, @RobustnessSliderValueChanged, true);
            app.RobustnessSlider.Tooltip = {'Set robustness percentage'};
            app.RobustnessSlider.Position = [149 560 419 3];
            app.RobustnessSlider.Value = 80;

            % Create InputFileEditFieldLabel
            app.InputFileEditFieldLabel = uilabel(app.aMDDBruteForceSimulatorUIFigure);
            app.InputFileEditFieldLabel.HorizontalAlignment = 'right';
            app.InputFileEditFieldLabel.Position = [61 637 55 22];
            app.InputFileEditFieldLabel.Text = 'Input File';

            % Create Input_File
            app.Input_File = uieditfield(app.aMDDBruteForceSimulatorUIFigure, 'text');
            app.Input_File.Editable = 'off';
            app.Input_File.Position = [131 637 319 22];

            % Create OutputEditFieldLabel
            app.OutputEditFieldLabel = uilabel(app.aMDDBruteForceSimulatorUIFigure);
            app.OutputEditFieldLabel.HorizontalAlignment = 'right';
            app.OutputEditFieldLabel.Position = [74 594 42 22];
            app.OutputEditFieldLabel.Text = 'Output';

            % Create Output_Folder
            app.Output_Folder = uieditfield(app.aMDDBruteForceSimulatorUIFigure, 'text');
            app.Output_Folder.Editable = 'off';
            app.Output_Folder.Position = [131 594 319 22];

            % Create TabGroup
            app.TabGroup = uitabgroup(app.aMDDBruteForceSimulatorUIFigure);
            app.TabGroup.Position = [59 57 521 414];

            % Create StatusTab
            app.StatusTab = uitab(app.TabGroup);
            app.StatusTab.Title = 'Status';
            app.StatusTab.Scrollable = 'on';

            % Create Status_text
            app.Status_text = uitextarea(app.StatusTab);
            app.Status_text.Editable = 'on';
            app.Status_text.Position = [15 10 487 373];

            % Create NumberofParallelWorkersDropDownLabel
            app.NumberofParallelWorkersDropDownLabel = uilabel(app.aMDDBruteForceSimulatorUIFigure);
            app.NumberofParallelWorkersDropDownLabel.HorizontalAlignment = 'left';
            app.NumberofParallelWorkersDropDownLabel.Position = [180 500 153 22];
            app.NumberofParallelWorkersDropDownLabel.Text = 'Mode:';

            % Create ParallelWorkers
            app.ParallelWorkers = uidropdown(app.aMDDBruteForceSimulatorUIFigure);
            app.ParallelWorkers.Items = {};
            app.ParallelWorkers.ValueChangedFcn = createCallbackFcn(app, @ParallelWorkersValueChanged, true);
            app.ParallelWorkers.Position = [180 480 75 22];
            app.ParallelWorkers.Value = {};

            % Create NumberofOutputTypeDropDownLabel
            app.NumberofOutputTypeDropDownLabel = uilabel(app.aMDDBruteForceSimulatorUIFigure);
            app.NumberofOutputTypeDropDownLabel.HorizontalAlignment = 'left';
            app.NumberofOutputTypeDropDownLabel.Position = [275 500 153 22];
            app.NumberofOutputTypeDropDownLabel.Text = 'Output Type:';

            % Create OutputType
            app.OutputType = uidropdown(app.aMDDBruteForceSimulatorUIFigure);
            app.OutputType.Items = {'Yearly','Monthly','Yearly+Monthly'};
            app.OutputType.ValueChangedFcn = createCallbackFcn(app, @OutputTypeValueChanged, true);
            app.OutputType.Position = [275 480 110 22];
            app.OutputType.Value = 'Yearly';
            
            % Create BrowseFile
            app.BrowseFile = uibutton(app.aMDDBruteForceSimulatorUIFigure, 'push');
            app.BrowseFile.ButtonPushedFcn = createCallbackFcn(app, @BrowseFileButtonPushed, true);
            app.BrowseFile.Position = [468 637 100 22];
            app.BrowseFile.Text = 'Browse';

            % Create BrowseFolder
            app.BrowseFolder = uibutton(app.aMDDBruteForceSimulatorUIFigure, 'push');
            app.BrowseFolder.ButtonPushedFcn = createCallbackFcn(app, @BrowseFolderButtonPushed, true);
            app.BrowseFolder.Position = [468 594 100 22];
            app.BrowseFolder.Text = 'Browse';

            % Create NumberofScenariosEditFieldLabel
            app.NumberofScenariosEditFieldLabel = uilabel(app.aMDDBruteForceSimulatorUIFigure);
            app.NumberofScenariosEditFieldLabel.HorizontalAlignment = 'right';
            app.NumberofScenariosEditFieldLabel.Position = [391 487 62 28];
            app.NumberofScenariosEditFieldLabel.Text = {'Number of'; 'Scenarios'};

            % Create NumberofParallelWorkersEditFieldLabel
            app.NumberofParallelWorkersEditFieldLabel = uilabel(app.aMDDBruteForceSimulatorUIFigure);
            app.NumberofParallelWorkersEditFieldLabel.HorizontalAlignment = 'right';
            app.NumberofParallelWorkersEditFieldLabel.Position = [59 487 62 42];
            app.NumberofParallelWorkersEditFieldLabel.Text = {'Number of';'Parallel'; 'Workers'};

            
            % Create NumberofScenariosEditField
            app.NumberofScenariosEditField = uieditfield(app.aMDDBruteForceSimulatorUIFigure, 'numeric');
            app.NumberofScenariosEditField.Limits = [0 Inf];
            app.NumberofScenariosEditField.ValueDisplayFormat = '%d';
            app.NumberofScenariosEditField.Editable = 'off';
            app.NumberofScenariosEditField.Position = [468 487 100 28];

            % Create NumberofScenariosEditField
            app.NumberofParallelWorkersEditField = uieditfield(app.aMDDBruteForceSimulatorUIFigure, 'numeric');
            app.NumberofParallelWorkersEditField.Limits = [0 Inf];
            app.NumberofParallelWorkersEditField.ValueDisplayFormat = '%d';
            app.NumberofParallelWorkersEditField.Editable = 'off';
            app.NumberofParallelWorkersEditField.Position = [131 487 28 28];

            
            % Create RunSimulationButton
            app.RunSimulationButton = uibutton(app.aMDDBruteForceSimulatorUIFigure, 'push');
            app.RunSimulationButton.ButtonPushedFcn = createCallbackFcn(app, @RunSimulationButtonPushed, true);
            app.RunSimulationButton.Position = [480 20 100 22];
            app.RunSimulationButton.Text = 'Run Simulation';
            
            % Create RunSimulationButton2
            %             app.RunQueueButton = uibutton(app.aMDDBruteForceSimulatorUIFigure, 'push');
            %             app.RunQueueButton.ButtonPushedFcn = createCallbackFcn(app, @RunQueueButtonPushed, true);
            %             app.RunQueueButton.Position = [59 20 100 22];
            %             app.RunQueueButton.Text = 'Run Queue';
            %
            % Create ConsoleTab
            app.ptrsTab = uitab(app.TabGroup);
            app.ptrsTab.Title = 'Cumulative PTRS';
            
            % Create UIAxes
            app.ptrsAxes = uiaxes(app.ptrsTab);
            title(app.ptrsAxes, 'Cumulative PTRS')
            xlabel(app.ptrsAxes, 'Number of Launches')
            ylabel(app.ptrsAxes, 'Probability')
            app.ptrsAxes.Position = [7 7 508 377];

        end
    end

    methods (Access = public)

        % Construct app
        function app = aMDD_Brute_Force_Simulator

            % Create and configure components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.aMDDBruteForceSimulatorUIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)
            %delete(app.ParallelPool);
            % Delete UIFigure when app is deleted
            delete(app.aMDDBruteForceSimulatorUIFigure)
        end
    end
end