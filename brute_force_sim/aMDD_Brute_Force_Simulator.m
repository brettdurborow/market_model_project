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
        NumberofUnlaunchedAssetsEditFieldLabel matlab.ui.control.Label
        NumberofUnlaunchedAssetsEditField matlab.ui.control.NumericEditField
        NumberofLaunchedAssetsEditFieldLabel matlab.ui.control.Label
        NumberofLaunchedAssetsEditField matlab.ui.control.NumericEditField
        EstFileSizeLabel            matlab.ui.control.Label
        EstFileSizeEditField        matlab.ui.control.EditField
        RunSimulationButton         matlab.ui.control.Button
        RunQueueButton              matlab.ui.control.Button
        ptrsTab                     matlab.ui.container.Tab
        ptrsAxes                    matlab.ui.control.UIAxes
        checkBox                    matlab.ui.control.CheckBox
        PreviousSelectionButton     matlab.ui.control.Button
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
        Nunlaunched % Number of unlaunched assets
        Nlaunched % Number of launched assets
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
        end
            
        % Button pushed function: BrowseFile
        function BrowseFileButtonPushed(app, event)
            % Specify file filters for excel or mat
            filterSpec = {'*.xls*;*.mat','Excel (.xls*) or Matlab Cache file (.mat)'};
            
            % Dialogue text for input
            dialogTitle = 'Select Input file (Excel or MAT)';
          
            switch event.Source.Text 
                case 'Browse'
                    app.Status_text.Value = vertcat('Browsing for input file',app.Status_text.Value);
                    % Prompt user for file input
                    [dataFile,dataFolder] = uigetfile(filterSpec, dialogTitle);

                case 'Previous Selection'
                    try
                        load('previous_selection.mat','dataFile','dataFolder','Output_Folder');
                        app.Output_Folder.Value = Output_Folder;
                        app.Status_text.Value = vertcat(sprintf('Loading previously selected file: %s',dataFile),app.Status_text.Value);
                        app.isOkInput = true;
                        app.isOkOutput = true;
                    catch ME
                        app.Status_text.Value = vertcat(['[ERRORMSG]: ',ME.message],'[WARNING]: Previous File Selection failed',app.Status_text.Value);
                        return
                    end
                    
                otherwise
                    app.Status_text.Value = vertcat('Unknown event source',app.Status_text.Value);
                    return
            end
                        
            
            if dataFolder == 0  % user hit cancel in uigetfile dialog
                app.isOkInput = false;
                app.Input_File.Value = '';
                app.Status_text.Value=vertcat('[WARNING]: No input file selected!',app.Status_text.Value);
                
            else % User selected something
                
                % Put together full file name in case app is run in a different dir.
                fullDataFile=fullfile(dataFolder,dataFile);
                
                % Get file extension fro deciding which path to take
                [~,inputDataName,inputExtension]=fileparts(dataFile);
                
                
                % Check first for a Cache .mat file
                switch inputExtension
                    case '.mat'
                        try
                            load(fullDataFile, 'cMODEL','cASSET', 'cCHANGE','cDEBUG');
                            app.isOkInput = true;
                        catch ME
                            app.Status_text.Value=vertcat(['[ERRORMSG]: ',ME.message],'[WARNING]: Error reading cache file. Try loading Excel file instead');
                            app.isOKInput=false;
                        end
                    case {'.xls','.xlsx','.xlsm','.xlsb'}
                        % Check input file for asset, change event, and simulation sheets
                        assetSheets=[];
                        try
                            [assetSheets, ~ , simuSheet] = checkInputSheets(fullDataFile);%ceSheets
                        catch ME
                            app.Status_text.Value=vertcat(['[ERRORMSG]: ',ME.message],'[WARNING]: Unable to open Input file!  Please check file location and Excel installation.',app.Status_text.Value);
                            app.isOkInput = false;
                        end
                        % Input check passes now check if there are asset sheets to import
                        if all(assetSheets==0) || simuSheet==0
                            warndlg('Found no "Asset" sheet in this file named "1", "2", etc.  Unable to continue.');
                            app.isOkInput = false;
                        else
                            tStart = tic;
                            % First import assumptions and asset information from excel
                            try
                                [cMODEL, cASSET, cCHANGE,cDEBUG] = importAssumptions(fullDataFile);
                                app.Status_text.Value = vertcat(sprintf('[Timing] Import Data: %gs',toc(tStart)),app.Status_text.Value);
                                app.isOkInput = true;
                            catch ME
                                app.Status_text.Value=vertcat(['[ERRORMSG]: ',ME.message],'[WARNING]: Importing assumptions failed. Check input data', app.Status_text.Value);
                                app.isOkInput=false;
                            end
                                                            
                            % Cache the output in a Matlab .Mat file
                            if app.isOkInput && exist([inputDataName,'.mat'],'file')
                                app.Status_text.Value=vertcat('[INFO]: Overwriting existing Cache file',app.Status_text.Value);
                                save([inputDataName,'.mat'], 'cMODEL','cASSET', 'cCHANGE','cDEBUG');
                            end
                        end
                end
                if ~app.isOkInput
                    % Update input text (probably not necessary).
                    app.Input_File.Value='';
                    app.Status_text.Value = vertcat('[WARNING]: Input file not correctly loaded', app.Status_text.Value);
                    return
                else
                    % Update input text
                    app.Input_File.Value=fullDataFile;  %[inputDataName,inputExtension];
                    app.Status_text.Value=vertcat('Success: Input data loaded.',app.Status_text.Value);
                end
                
                
                app.Status_text.Value=vertcat('Starting data pre-processing:',app.Status_text.Value);
                % We preprocess the data to get the tables out
                try
                    tstart=tic;
                    [app.Tm,app.Ta,app.Tc,app.eventTable,app.dateTable,app.Country,app.Asset,app.Class,app.Company]...
                        = preprocess_data(app.modelID,cMODEL,cASSET,cCHANGE);
                    tdata_proc=toc(tstart);
                    % Output some status messages
                    app.Status_text.Value=vertcat(sprintf('[Timing] Data pre-processing: %gs',tdata_proc),app.Status_text.Value);
                catch ME
                    app.Status_text.Value=vertcat(['[ERRORMSG]: ',ME.message],'[WARNING]: Data pre-processing failed',app.Status_text.Value);
                    app.Input_File.Value='';
                    app.isOkInput=false;
                    return
                end
                
                
                app.Status_text.Value=vertcat('Generating launch Scenarios',app.Status_text.Value);
                try
                    % Since we have the data available, we generate the launch codes
                    tstart=tic;
                    [app.launchCodes,app.launchInfo,app.assetLaunchInfo,app.ptrsTable,app.Nunlaunched,app.Nlaunched]=generate_launchCodes(app.Ta,app.Country,app.Asset,app.RobustnessSlider.Value/100);
                    tlaunch_scenarios=toc(tstart);
                    app.Status_text.Value=vertcat(sprintf('[Timing] Generating launch scenarios: %gs',tlaunch_scenarios),app.Status_text.Value);
                    app.NumberofScenariosEditField.Value=height(app.launchCodes);
                    app.NumberofUnlaunchedAssetsEditField.Value=app.Nunlaunched;
                    app.NumberofLaunchedAssetsEditField.Value=app.Nlaunched;
                catch ME
                    app.Status_text.Value=vertcat(['[ERRORMSG]: ',ME.message],'[WARNING]: Generating launch scenarios failed',app.Status_text.Value);
                    app.Input_File.Value='';
                    app.isOkInput=false;
                    return
                end
                
                
                try
                    cla(app.ptrsAxes)
                    app.ptrsAxes.XScale='log';
                    hold(app.ptrsAxes,'on')
                    for i=1:length(app.launchInfo)
                        semilogx(app.ptrsAxes,app.launchInfo{i}.cdf);
                    end
                    legend(app.ptrsAxes,app.Country.CName,'Location','SouthEast')
                    hold(app.ptrsAxes,'off');
                catch ME
                    app.Status_text.Value=vertcat(['[ERRORMSG]: ',ME.message],'[WARNING]: Plotting Cumulative PTRS failed',app.Status_text.Value);
                end
                
                UpdateFileSize(app);
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

        function UpdateFileSize(app,event)
            Ny=size(app.dateTable.date(1:12:end),1);
            Nt=height(app.dateTable);
            Nevents=app.Country.Nevents;
            total_individual_asset_launches=sum(cellfun(@(a)sum(sum(a.launch_logical)),app.launchInfo));
            total_event_asset_launches=sum(cellfun(@(a)sum(sum(a.launch_logical)),app.launchInfo).*Nevents);
            
            % The following approximate file sizes are based on empirically
            % measuring the average number of characters per line of output
            target_filesize = total_event_asset_launches*77;
            yearly_filesize = total_individual_asset_launches*54*Ny;
            monthly_filesize = total_individual_asset_launches*51*Nt;
            
            if app.OutputType.Value =="Yearly"
                total_filesize = target_filesize + yearly_filesize;
            elseif app.OutputType.Value == "Monthly"
                total_filesize=target_filesize + monthly_filesize;
            else
                total_filesize=target_filesize + yearly_filesize + monthly_filesize;
            end
            
            unit_ind=min(max(1,floor(log2(total_filesize)/10)),4);
            units={'KB','MB','GB','TB'};
            
            fprintf('Total file size: %6.2f %s\n',total_filesize/2^(unit_ind*10),units{unit_ind});
            app.EstFileSizeEditField.Value=sprintf('%6.2f %s',total_filesize/2^(unit_ind*10),units{unit_ind});
            app.EstFileSizeEditField.UserData=total_filesize;
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
                msg = '[WARNING]: invalid Output Folder!';
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

                UpdateFileSize(app);

            end
            % Otherwise, we don't need to do anything
        end

        % Button pushed function: RunSimulationButton
        function RunSimulationButtonPushed(app, event)
            % Check if input and output are set, then simulate
            if app.isOkInput && app.isOkOutput
                [~,FileName,~]=fileparts(app.Tm.FileName(1));
                app.Model=table(app.modelID,FileName+"_"+string(datetime(app.Tm.FileDate(1),'Format','dd-MMM-yyyy-HH_mm'))+...
                    "_RUN_"+string(datetime('now','Format','dd-MMM-yyyy-HH_mm')),'VariableNames',{'ID','MName'});

                
                output_folder=app.Output_Folder.Value+app.Model.MName+filesep;
                % make a new sub-directory
                if ~exist(output_folder)
                    try
                        mkdir(output_folder)
                    catch
                        errordlg({'Could not create directory:',output_folder});
                    end
                end
                
                % By here we should have everything needed to save the
                % cache file for the previous input
                Output_Folder = app.Output_Folder.Value;
                [dataFolder,dataFile,dataExt]=fileparts(app.Input_File.Value);
                dataFile=[dataFile,dataExt];
                save('previous_selection.mat','dataFile','dataFolder','Output_Folder');
                
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
                app.Status_text.Value=vertcat('[Warning]: Input and output paths must be specified',app.Status_text.Value);
            end
        end

        function PreviousSelectionButtonPushed(app,event)
            BrowseFileButtonPushed(app, event)
        end
        
        
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
                app.Status_text.Value=vertcat('[Warning]: Input and output paths must be specified',app.Status_text.Value);
            end
        end

        function OutputTypeValueChanged(app, event)
            value = app.OutputType.Value;
            app.Status_text.Value=vertcat(sprintf('Output type change to: %s',value),app.Status_text.Value);
            UpdateFileSize(app);
        end

        
        % Value changed function: ParallelWorkers
        function ParallelWorkersValueChanged(app, event)
            value = app.ParallelWorkers.Value;
            app.Status_text.Value=vertcat(sprintf('Number of processors changed to: %d',value),app.Status_text.Value);
        end
        
%         function startParrallelPool(app,event)
%             if event.PreviousValue == 0 
%                 pool = gcp('nocreate');
%                 % Initialize a pool if not created already.
%                 if isempty(pool)
%                     app.ParallelPool=parpool(app.numCores);
%                     fprintf('Initialized parallel pool');
%                     app.checkBox.Value = true;
%                 end
%             else % Turning off parallel pool
%                 delete(gcp('nocreate'));
%                 app.checkBox.Value=0;
%             end
%         end
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
            app.RobustnessSliderLabel.Position = [49 581 69 22];
            app.RobustnessSliderLabel.Text = 'Robustness';

            % Create RobustnessSlider
            app.RobustnessSlider = uislider(app.aMDDBruteForceSimulatorUIFigure);
            app.RobustnessSlider.ValueChangedFcn = createCallbackFcn(app, @RobustnessSliderValueChanged, true);
            app.RobustnessSlider.Tooltip = {'Set robustness percentage'};
            app.RobustnessSlider.Position = [131 590 437 3];
            app.RobustnessSlider.Value = 80;

            % Create InputFileEditFieldLabel
            app.InputFileEditFieldLabel = uilabel(app.aMDDBruteForceSimulatorUIFigure);
            app.InputFileEditFieldLabel.HorizontalAlignment = 'right';
            app.InputFileEditFieldLabel.Position = [61 660 55 22];
            app.InputFileEditFieldLabel.Text = 'Input File';

            % Create Input_File
            app.Input_File = uieditfield(app.aMDDBruteForceSimulatorUIFigure, 'text');
            app.Input_File.Editable = 'off';
            app.Input_File.Position = [131 660 319 22];

            % Create OutputEditFieldLabel
            app.OutputEditFieldLabel = uilabel(app.aMDDBruteForceSimulatorUIFigure);
            app.OutputEditFieldLabel.HorizontalAlignment = 'right';
            app.OutputEditFieldLabel.Position = [74 617 42 22];
            app.OutputEditFieldLabel.Text = 'Output';

            % Create Output_Folder
            app.Output_Folder = uieditfield(app.aMDDBruteForceSimulatorUIFigure, 'text');
            app.Output_Folder.Editable = 'off';
            app.Output_Folder.Position = [131 617 319 22];

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
            app.NumberofParallelWorkersDropDownLabel.Position = [59 480 40 22];
            app.NumberofParallelWorkersDropDownLabel.Text = 'Mode:';

            % Create ParallelWorkers
            app.ParallelWorkers = uidropdown(app.aMDDBruteForceSimulatorUIFigure);
            app.ParallelWorkers.Items = {};
            app.ParallelWorkers.ValueChangedFcn = createCallbackFcn(app, @ParallelWorkersValueChanged, true);
            app.ParallelWorkers.Position = [104 480 75 22];
            app.ParallelWorkers.Value = {};

            % Create NumberofOutputTypeDropDownLabel
            app.NumberofOutputTypeDropDownLabel = uilabel(app.aMDDBruteForceSimulatorUIFigure);
            app.NumberofOutputTypeDropDownLabel.HorizontalAlignment = 'left';
            app.NumberofOutputTypeDropDownLabel.Position = [200 480 153 22];
            app.NumberofOutputTypeDropDownLabel.Text = 'Output Type:';

            % Create estimated file size
            app.EstFileSizeLabel = uilabel(app.aMDDBruteForceSimulatorUIFigure);
            app.EstFileSizeLabel.HorizontalAlignment = 'left';
            app.EstFileSizeLabel.Position = [400 480 153 22];
            app.EstFileSizeLabel.Text = 'Output Size:';

             % Create EstFileSizeLabelEditField
            app.EstFileSizeEditField = uieditfield(app.aMDDBruteForceSimulatorUIFigure, 'text');
            %app.EstFileSizeEditField.Limits = [0 Inf];
            app.EstFileSizeEditField.HorizontalAlignment = 'right';
            app.EstFileSizeEditField.Editable = 'off';
            app.EstFileSizeEditField.Position = [468 521-45 100 28];

            
            % Create OutputType
            app.OutputType = uidropdown(app.aMDDBruteForceSimulatorUIFigure);
            app.OutputType.Items = {'Yearly','Monthly','Yearly+Monthly'};
            app.OutputType.ValueChangedFcn = createCallbackFcn(app, @OutputTypeValueChanged, true);
            app.OutputType.Position = [280 480 110 22];
            app.OutputType.Value = 'Yearly';
            
            % Create BrowseFile
            app.BrowseFile = uibutton(app.aMDDBruteForceSimulatorUIFigure, 'push');
            app.BrowseFile.ButtonPushedFcn = createCallbackFcn(app, @BrowseFileButtonPushed, true);
            app.BrowseFile.Position = [468 660 100 22];
            app.BrowseFile.Text = 'Browse';

            % Create BrowseFolder
            app.BrowseFolder = uibutton(app.aMDDBruteForceSimulatorUIFigure, 'push');
            app.BrowseFolder.ButtonPushedFcn = createCallbackFcn(app, @BrowseFolderButtonPushed, true);
            app.BrowseFolder.Position = [468 617 100 22];
            app.BrowseFolder.Text = 'Browse';

            % Create PreviousSelectionButton
            app.PreviousSelectionButton = uibutton(app.aMDDBruteForceSimulatorUIFigure, 'push');
            app.PreviousSelectionButton.ButtonPushedFcn = createCallbackFcn(app, @PreviousSelectionButtonPushed, true);
            app.PreviousSelectionButton.Position = [59 20 110 22];
            app.PreviousSelectionButton.Text = 'Previous Selection';

            
            % Create NumberofScenariosEditFieldLabel
            app.NumberofScenariosEditFieldLabel = uilabel(app.aMDDBruteForceSimulatorUIFigure);
            app.NumberofScenariosEditFieldLabel.HorizontalAlignment = 'right';
            app.NumberofScenariosEditFieldLabel.Position = [391 521 62 28];
            app.NumberofScenariosEditFieldLabel.Text = {'Number of'; 'Scenarios'};

            % Create NumberofParallelWorkersEditFieldLabel
            app.NumberofParallelWorkersEditFieldLabel = uilabel(app.aMDDBruteForceSimulatorUIFigure);
            app.NumberofParallelWorkersEditFieldLabel.HorizontalAlignment = 'right';
            app.NumberofParallelWorkersEditFieldLabel.Position = [29 521 92 28];
            app.NumberofParallelWorkersEditFieldLabel.Text = {'Number of';'Parallel Workers'};

            % Create NumberofParallelWorkersEditFieldLabel
            app.NumberofUnlaunchedAssetsEditFieldLabel = uilabel(app.aMDDBruteForceSimulatorUIFigure);
            app.NumberofUnlaunchedAssetsEditFieldLabel.HorizontalAlignment = 'right';
            app.NumberofUnlaunchedAssetsEditFieldLabel.Position = [139 511 92 42];
            app.NumberofUnlaunchedAssetsEditFieldLabel.Text = {'Number of';'Unlaunched';'Assets'};

            % Create NumberofUnlaunchedAssetsEditField
            app.NumberofUnlaunchedAssetsEditField = uieditfield(app.aMDDBruteForceSimulatorUIFigure, 'numeric');
            app.NumberofUnlaunchedAssetsEditField.Limits = [0 Inf];
            app.NumberofUnlaunchedAssetsEditField.ValueDisplayFormat = '%d';
            app.NumberofUnlaunchedAssetsEditField.Editable = 'off';
            app.NumberofUnlaunchedAssetsEditField.Position = [241 521 28 28];

            % Create NumberofLaunchedAssetsEditFieldLabel
            app.NumberofLaunchedAssetsEditFieldLabel = uilabel(app.aMDDBruteForceSimulatorUIFigure);
            app.NumberofLaunchedAssetsEditFieldLabel.HorizontalAlignment = 'right';
            app.NumberofLaunchedAssetsEditFieldLabel.Position = [139+110 511 92 42];
            app.NumberofLaunchedAssetsEditFieldLabel.Text = {'Number of';'Launched';'Assets'};

            % Create NumberofLaunchedAssetsEditField
            app.NumberofLaunchedAssetsEditField = uieditfield(app.aMDDBruteForceSimulatorUIFigure, 'numeric');
            app.NumberofLaunchedAssetsEditField.Limits = [0 Inf];
            app.NumberofLaunchedAssetsEditField.ValueDisplayFormat = '%d';
            app.NumberofLaunchedAssetsEditField.Editable = 'off';
            app.NumberofLaunchedAssetsEditField.Position = [241+110 521 28 28];

            
            % Create NumberofScenariosEditField
            app.NumberofScenariosEditField = uieditfield(app.aMDDBruteForceSimulatorUIFigure, 'numeric');
            app.NumberofScenariosEditField.Limits = [0 Inf];
            app.NumberofScenariosEditField.ValueDisplayFormat = '%d';
            app.NumberofScenariosEditField.Editable = 'off';
            app.NumberofScenariosEditField.Position = [468 521 100 28];

            % Create NumberofParallelWorkersEditField
            app.NumberofParallelWorkersEditField = uieditfield(app.aMDDBruteForceSimulatorUIFigure, 'numeric');
            app.NumberofParallelWorkersEditField.Limits = [0 Inf];
            app.NumberofParallelWorkersEditField.ValueDisplayFormat = '%d';
            app.NumberofParallelWorkersEditField.Editable = 'off';
            app.NumberofParallelWorkersEditField.Position = [131 521 28 28];

            
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
            app.ptrsTab= uitab(app.TabGroup);
            app.ptrsTab.Title = 'Cumulative PTRS';
            
            % Create UIAxes
            app.ptrsAxes = uiaxes(app.ptrsTab);
            title(app.ptrsAxes, 'Cumulative PTRS')
            xlabel(app.ptrsAxes, 'Number of Launches')
            ylabel(app.ptrsAxes, 'Probability')
            app.ptrsAxes.Position = [7 7 508 377];

            % ['Depreciated'] Create parallel pool checkbox
            %             app.checkBox = uicheckbox(app.aMDDBruteForceSimulatorUIFigure);
            %             app.checkBox.Position =  [56 8 100 58];
            %             app.checkBox.Enable = 'on';
            %             app.checkBox.Text = {'Parallel Pool';'Connected'};
            %             app.checkBox.ValueChangedFcn = createCallbackFcn(app,@startParrallelPool,true);
            %             app.checkBox.Visible = false;
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