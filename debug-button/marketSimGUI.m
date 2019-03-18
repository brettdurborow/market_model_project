function marketSimGUI()

%% Variables Global and Persistent in this GUI instance
   
    cMODEL = {};
    cASSET = {};
    cCHANGE = {};

    cDEBUG = {};
    cESTAT = {};
    simCount = 0;
    isOkInput = false;
    isOkOutput = false;
    numCores = feature('numcores');  % Number of physical cores on this machine
    numWorkers = numCores-1;
    numIterations = 100;
    resultsFolderPath = '';
    isCancel = false;
    tmpdir=strings(7,1);
    
%% Create and Size the GUI

    fw = 590;   % figure width
    fh = 600;   % figure height

    %  Create and then hide the Figure as it is being constructed.
    sc = get(0, 'ScreenSize');
    fp = get(0, 'DefaultFigurePosition');
    hF  = figure('Visible','off', ...
               'HandleVisibility', 'callback', ...
               'Position', [fp(1), fp(2)-fh+fp(4), fw, fh], ...
               'Name', 'Janssen Market-Share Monte Carlo Model', ...
               'MenuBar', 'none', ...
               'ToolBar', 'none', ...
               'DockControls', 'off', ...
               'IntegerHandle', 'off', ...
               'NumberTitle', 'off', ...
               'MenuBar', 'none', ...
               'Toolbar', 'figure', ...   %'ResizeFcn', @figResize, ...
               'CloseRequestFcn', @cb_Exit);



    th = 30; % title height
    tb = 10; % title border
    bw = 5;  % border width
    bh = 5;  % border height


   
%% Add controls to the GUI
   hTitleMain = uicontrol('Style', 'text', 'String', 'Janssen Market-Share Monte Carlo Model', ...
         'FontSize', 12, ...
         'FontName', 'Calibri', ...
         'FontWeight', 'bold', ...         
         'HorizontalAlignment', 'center', ...         
         'Position', [bw, 1+fh-th-bh, fw-2*bw, th], ...
         'Parent', hF);  
   
          
    hTextInputFile = uicontrol('Style', 'text', 'String', 'Input File:', ...
         'FontSize', 9, ...
         'HorizontalAlignment', 'right', ...         
         'Position', [15, fh-75, 90, 16], ...
         'Parent', hF);  
      
    hTextOutputFolder = uicontrol('Style', 'text', 'String', 'Output Folder:', ...
         'FontSize', 9, ...
         'HorizontalAlignment', 'right', ...         
         'Position', [15, fh-100, 90, 16], ...
         'Parent', hF);       

    hEditInputFile = uicontrol('Style', 'edit', 'String', ' ', ...
         'FontSize', 8, ...
         'HorizontalAlignment', 'right', ...
         'Position', [110, fh-75, 360, 20], ...
         'Parent', hF);     
     
    hEditOutputFolder = uicontrol('Style', 'edit', 'String', ' ', ...
         'FontSize', 8, ...
         'HorizontalAlignment', 'right', ...
         'Position', [110, fh-100, 360, 20], ...
         'Parent', hF);   
     
    hEditStatus = uicontrol('Style', 'edit', 'String', ' ', ...
         'FontSize', 8, ...
         'HorizontalAlignment', 'left', ...
         'Max', 100, ...
         'Min', 0, ...
         'Position', [15, fh-520, 555, 370], ...
         'Parent', hF);   
     
    hBtnBrowseInput = uicontrol('Style', 'pushbutton', 'String', 'Browse...', ...
         'Position', [480, fh-75, 90, 20], ...
         'Callback', {@cb_BrowseInput}, ...
         'Parent', hF);

    hBtnBrowseOutput = uicontrol('Style', 'pushbutton', 'String', 'Browse...', ...
         'Position', [480, fh-100, 90, 20], ...
         'Callback', {@cb_BrowseOutput}, ...
         'Parent', hF);
     
     
    hTextIterations = uicontrol('Style', 'text', 'String', 'Iterations:', ...
         'FontSize', 9, ...
         'HorizontalAlignment', 'right', ...         
         'Position', [15, fh-135, 90, 16], ...
         'Parent', hF);  
    
    hEditIterations = uicontrol('Style', 'edit', 'String', num2str(numIterations), ...
         'FontSize', 9, ...
         'HorizontalAlignment', 'right', ...
         'Position', [110, fh-135, 40, 20], ...
         'Callback', {@cb_NumIterations}, ...
         'Parent', hF);  
    
    hTextNumWorkers = uicontrol('Style', 'text', 'String', 'Number of Parallel Workers:', ...
         'FontSize', 9, ...
         'HorizontalAlignment', 'right', ...         
         'Position', [180, fh-135, 200, 16], ...
         'Parent', hF);  
    
    hEditNumWorkers = uicontrol('Style', 'edit', 'String', num2str(numWorkers), ...
         'FontSize', 9, ...
         'HorizontalAlignment', 'right', ...
         'Position', [385, fh-135, 25, 20], ...
         'Callback', {@cb_NumWorkers}, ...
         'Parent', hF);       
     
    hBtnRunSimulation = uicontrol('Style', 'pushbutton', 'String', 'Run Simulation', ...
         'Position', [380, fh-570, 90, 30], ...
         'Callback', {@cb_RunSim}, ...
         'Parent', hF);
    
    hBtnDebugSimulation = uicontrol('Style', 'pushbutton', 'String', 'Debug Simulation', ...
         'Position', [16, fh-570, 90, 30], ...
         'Callback', {@cb_DebugSim}, ...
         'Parent', hF);
     
    hBtnCancel = uicontrol('Style', 'pushbutton', 'String', 'Cancel', ...
         'Position', [480, fh-570, 90, 30], ...
         'Callback', {@cb_Cancel}, ...
         'Parent', hF);     
     
%% Initialize the GUI
   
    set(hF, 'Visible', 'on'); % Make the GUI visible
    set(hF, 'MenuBar', 'none', ...
            'ToolBar', 'none');
    %jhEditStatus = findjobj(hEditStatus);   % Find underlying Java control peer for edit box
    %jEditStatus = jhEditStatus.getComponent(0).getComponent(0); % get the scroll-pane's internal edit control
    %jEditScroll = jhEditStatus.getVerticalScrollBar;
    %jEditStatus = get(get(jhEditStatus,'Viewport'),'View');% get the scroll-pane's internal edit control
    %jEditScroll = get(jhEditStatus,'VerticalScrollBar');
    
    
%% Helper Functions

    function addStatusMsg(msg)
        oldMsg = get(hEditStatus, 'String');
        if ischar(msg)
            msgFull = [{msg};oldMsg];
        else
            msgFull = [msg;oldMsg];
        end
        set(hEditStatus, 'String', msgFull);
        drawnow;
        %jEditStatus.setCaretPosition(jEditStatus.getDocument.getLength);  % set to last line in the box
        %jEditScroll.setValue(jEditScroll.getMaximum);
        %jhEditStatus.repaint;        
    end

    function [assetSheets, ceSheets, simuSheet] = checkInputSheets(fileName)
    % Build a list of Asset sheets in this workbook
        [~, sheets, ~] = xlsfinfo(fileName);
        
        simuSheet = sum(strcmpi(sheets, 'Simulation')) == 1;  % look for a sheet called "Simulation"

        assetSheets = {};
        %Needs Replacement
        for m = 1:length(sheets)
            ascii = double(sheets{m});
            if all(ascii >= 48 & ascii <= 57)
                assetSheets{end + 1} = sheets{m};
            end    
        end

        % Check for ChangeEvents for each Asset sheet
        ceSheets = cell(size(assetSheets));
        for m = 1:length(assetSheets)
            ceName = [assetSheets{m}, 'CE'];
            ix = find(strcmpi(sheets, ceName));
            if length(ix) == 1
                ceSheets{m} = sheets{m};
            end
        end        
        %end NR
    end


%%  Callbacks for GUI. 
   %  These callbacks automatically have access to component handles
   %  and initialized data because they are nested at a lower level

   
    function cb_Exit(source, eventdata)
        strAnswer = questdlg('Are you sure you want to exit?', 'Exit the application?', 'OK', 'Cancel', 'OK');

        cb_Cancel(source, eventdata);
        if strcmp(strAnswer, 'OK')
            delete(hF);
            clear;
        end
    end

    function cb_BrowseOutput(source, eventdata)
        foldername = uigetdir(); 
        set(hEditOutputFolder, 'String', foldername);
        outStr = get(hEditOutputFolder, 'String');
        if exist(outStr, 'dir') == 7
            isOkOutput = true;
            msg = sprintf('Selected valid output folder:\n%s', foldername);
            resultsFolderPath = foldername;
        else
            isOkOutput = false;
            msg = 'WARNING: invalid Output Folder!';
            resultsFolderPath = '';
        end
        addStatusMsg(msg)        
    end

    function cb_BrowseInput(source, eventdata)
        filterSpec = {'*.xls*'};
        dialogTitle = 'Select an Excel File';
        [fileName, folderName, filterIndex] = uigetfile(filterSpec, dialogTitle);
        if folderName == 0  % user hit cancel in uigetfile dialog 
            isOkInput = false;
        else
            fullFileName = fullfile(folderName, fileName);
            set(hEditInputFile, 'String', fullFileName);
            try
                [assetSheets, ceSheets, simuSheet] = checkInputSheets(fullFileName);
            catch
                addStatusMsg('Unable to open Input file!  Please check file location and Excel installation.');
                isOkInput = false;
            end
            if isempty(assetSheets)
                msgbox('Found no "Asset" sheet in this file named "1", "2", etc.  Unable to continue.');
                isOkInput = false;
            else 
                tStart = tic;
                [cMODEL, cASSET, cCHANGE, cDEBUG] = importAssumptions(fullFileName);
                % Verify that all sheets contain run the same Scenario
                scenario_selected=cMODEL{1}.ScenarioSelected;
                for i=1:length(cMODEL)
                    if scenario_selected~=cMODEL{i}.ScenarioSelected
                        msg=sprintf('Scenario selected in Sheet %s does not match other sheets\n',assetSheets{i});
                        addStatusMsg(msg);
                        error(msg);
                    end
                end
                msg=sprintf('Scenario selected: %s\n',scenario_selected);
                addStatusMsg(msg);
                msg = sprintf('Imported Data, elapsed time = %1.1f sec\n', toc(tStart));
                addStatusMsg(msg);
                isOkInput = true;
            end
        end
    end

    function cb_NumIterations(source, eventdata)
        num = str2double(get(source, 'String'));
        if ~isempty(num) && num > 0
            numIterations = num;
            set(source, 'String', num2str(num));
        else
            set(source, 'String', num2str(numIterations)); 
        end
    end

    function cb_NumWorkers(source, eventdata)
        num = str2double(get(source, 'String'));
        if ~isempty(num) && num > 0
            numWorkers = num;
            set(source, 'String', num2str(num));
        else
            set(source, 'String', num2str(numWorkers)); 
        end
    end

    function myRMdir
        for jj=1:7
            if exist(tmpdir(jj))
                fprintf('Removing temporary dir: %s\n',tmpdir(jj));
                rmdir(tmpdir(jj),'s');
            end
        end
    end

    function cb_RunSim(source, eventdata)
        isCancel = false;        
        if ~isOkInput || ~isOkOutput
            addStatusMsg('Unable to Run Simulation!  Please check Input and Output paths');
            return;
        end
        
        % Cleanup function to remove temporary files
        cup=onCleanup(@()myRMdir);
              
        tStart = tic;
        cCNSTR = getConstraints(cASSET);
        fnames = {'NumIterations', 'NumWorkers', 'ExecutionTime', 'RunTime'};
        BENCH = struct;  % intialize the benchmark struct
        for m = 1:length(fnames)
            BENCH.(fnames{m}) = nan(size(cMODEL));
        end
        
        warning('off', 'MATLAB:xlswrite:AddSheet'); % Suppress the annoying warnings
        runTime = datetime('now', 'TimeZone', 'America/New_York');  % Entire run has same RunTime       
        outFolder = fullfile(resultsFolderPath, sprintf('ModelOut_%s_%s',cMODEL{1}.ScenarioSelected, datestr(runTime, 'yyyy-mm-dd_HHMMSS')));
        if ~exist(outFolder, 'dir')
            mkdir(outFolder)
        end
        
        for m = 1:length(cMODEL)
            % Quick return if cancel button is pressed
            if isCancel
                isCancel = false;
                return;
            end
            
            MODEL = cMODEL{m};
            ASSET = cASSET{m};
            CHANGE = cCHANGE{m};
            addStatusMsg(sprintf('Starting to process country: %s on sheet: %s', MODEL.CountrySelected, MODEL.AssetSheet));
            
            % This is where the magic happens, and we generate the
            % simulation cubes. Inside this function we do parallel
            % excecution.
            [dateGrid, SimCubeBranded, SimCubeMolecule, tExec] = marketModelMonteCarlo(MODEL, ASSET, CHANGE, numIterations, numWorkers);
            
            % ParamapplyConstraints(cCNSTR{n}, MODEL, ASSET, SimCubeBranded, SimCubeMolecule, dateGrid,tmpdir(m));eters of the overall simulation for performance benchmarking
            BENCH.NumIterations(m) = numIterations;
            BENCH.NumWorkers(m) = numWorkers;
            BENCH.ExecutionTime(m) = tExec;  % Tries to exclude time to setup worker pool on first call
            
            tCnstrExec=tic;
            tmpdir(m)=tempname();
            mkdir(tmpdir(m))
                        
            if  numWorkers>1       % Run parallel code on already initialized parallel pool                
                % This part could be run in parallel. However, we need to
                % avoid a function call so that the SimCubes are not
                % recreated
                
                % Now apply constraints
                for n=1:length(cCNSTR)
                    applyConstraints(cCNSTR{n}, MODEL, ASSET, SimCubeBranded, SimCubeMolecule, dateGrid,tmpdir(m));
                end
 
            else % Otherwise sequential code
                for n=1:length(cCNSTR)
                    applyConstraints(cCNSTR{n}, MODEL, ASSET, SimCubeBranded, SimCubeMolecule, dateGrid,tmpdir(m));
                end
            end
            tCnstrExec=toc(tCnstrExec);
            
            % By this point, we have written all constraints to disk and
            % later we will have to reread them (but this should be 7 at a
            % time, so in the long run, should be more efficient.
            msg = sprintf('Country:%s, Ran %d iterations, Monte Carlo = %1.1f sec, Constraint Writing: %1.1f sec, Cume time = %1.1f\n', ...
                    MODEL.CountrySelected, numIterations, tExec,tCnstrExec, toc(tStart));
            addStatusMsg(msg);
        end
        
        BENCH.RunTime = repmat(runTime, size(BENCH.NumIterations));
              
        %% Now we will re-read the previous data written to file, 
        % looping over each constraint (in parallel)
        msg=sprintf('Writing outputs for constraints in parallel\nSee console for timing output\n');
        addStatusMsg(msg);

        
%         parfor n=1:length(cCNSTR)
%             msg = sprintf('Writing outputs for Constraints: %s , Cume time = %1.1f sec', cCNSTR{n}.ConstraintName, toc(tStart));
%             fprintf(msg);
%             %addStatusMsg(msg);
%             read_constraint_write_csv(tmpdir,cCNSTR{n},cCNSTR,outFolder,BENCH)         
%         end
        
        % Break into smaller for loops, again to reduce IPC
        startVec =  1:numWorkers:length(cCNSTR);
        endVec = startVec + numWorkers - 1;
        endVec(end) = length(cCNSTR);
        for m = 1:length(startVec)
            cname1 = cCNSTR{startVec(m)}.ConstraintName;
            cname2 = cCNSTR{endVec(m)}.ConstraintName;
            msg = sprintf('Writing outputs for Constraints: %s to %s, Cume time = %1.1f sec', cname1, cname2, toc(tStart));
            addStatusMsg(msg);            
            parfor n = startVec(m):endVec(m)  
                cname = cCNSTR{n}.ConstraintName;
                outFolderSub = fullfile(outFolder, cname);
                read_constraint_write_csv(tmpdir,cCNSTR{n},cCNSTR,outFolder,BENCH);
                %[~, cFileNames] = writeTablesCsv(outFolderSub, cMODELc{n}, cASSETc{n}, cESTATc{n}, cCNSTR, BENCH);
            end
        end


        %% Produce various outputs for a single realization

        doPlots = false;
        
        if doPlots            
            figure; semilogy(dateGrid, OUT_Molecule.M.PointShare); datetick; grid on; 
                    title('Share Per Asset - Monthly');
                    legend(ASSET.Assets_Rated, 'Location', 'EastOutside'); timeCursor(false);

            figure; hA = area(dateGrid, OUT_Molecule.M.PointShare'); datetick; grid on; axis tight;
                    title('Share Per Asset - Molecule Mean Monthly'); 
                    legend(hA(end:-1:1), ASSET.Assets_Rated(end:-1:1), 'Location', 'EastOutside'); timeCursor(false);

            figure; hA = area(dateGrid, OUT_Branded.M.PointShare'); datetick; grid on; axis tight;
                    title('Share Per Asset - Branded Mean Monthly'); 
                    legend(hA(end:-1:1), ASSET.Assets_Rated(end:-1:1), 'Location', 'EastOutside'); timeCursor(false);

            figure; hA = area(OUT_Branded.Y.YearVec, OUT_Branded.Y.PointShare'); grid on; axis tight;
                    title('Share Per Asset - Branded Mean Annually'); 
                    legend(hA(end:-1:1), ASSET.Assets_Rated(end:-1:1), 'Location', 'EastOutside'); timeCursor(false);
        end



        tElapsed = toc(tStart);
        msg = sprintf('\nRun complete, elapsed time = %1.2f sec\n', tElapsed);
        addStatusMsg(msg);
        
    end

    function cb_DebugSim(source,eventdata)
        isCancel = false;
        if ~isOkInput || ~isOkOutput
            addStatusMsg('Unable to Run Simulation!  Please check Input and Output paths');
            return;
        else
            addStatusMsg('Running Debug simultation');
        end
        
        tStart = tic;
        cCNSTR = getConstraints(cASSET);
        fnames = {'NumIterations', 'NumWorkers', 'ExecutionTime', 'RunTime'};
        BENCH = struct;  % intialize the benchmark struct
        for m = 1:length(fnames)
            BENCH.(fnames{m}) = nan(size(cMODEL));
        end
        
        warning('off', 'MATLAB:xlswrite:AddSheet'); % Suppress the annoying warnings
        
        % Set up output folder
        runTime = datetime('now', 'TimeZone', 'America/New_York');  % Entire run has same RunTime       
        outFolder = string(fullfile(resultsFolderPath, sprintf('DebugOut_%s', datestr(runTime, 'yyyy-mm-dd_HHMMSS'))));
        if ~exist(outFolder, 'dir')
            mkdir(outFolder)
        end
        tExec=toc(tStart);
        dASSET=cell(size(cASSET));
        dMODEL=cell(size(cMODEL));
        dESTAT=cell(size(cESTAT));
        
        doDebug=true;
        
        isChange=[];
  
        % Initializations
        tableVarNames=["Country","Scenario_Run","Run_Date","Class","Asset","Time",...
            "Profile_Model_Target_Share","OE_Target_Share",...
            "Unadj_Combined_Target_Share","Adjustment_Factor","Adjusted_Target_Share"];
        
        debugFilename=outFolder+filesep+"Debug_output"+datestr(runTime, '_yyyy-mm-dd_HHMMSS')+".csv";
        T=table;
        
        % Extract Scenario names from debug cell
        Scenarios=cDEBUG{1}.Scenario_names;
        tic;
        % For a fixed scenario, we run all countries
        for k=1:length(Scenarios)
            % Quick return if cancel is pressed
            if isCancel
                isCancel = false;
                return;
            end
            
            msg=sprintf('Debug processing scenario: %s',Scenarios(k));
            addStatusMsg(msg);
            
            Tc=cell(length(cMODEL),1);
            % Loop all countries and simulate 
            parfor m = 1:length(cMODEL)
                MODEL = cMODEL{m};
                ASSET = cDEBUG{m}.asset;
                CHANGE = cCHANGE{m};
                DEBUG = cDEBUG{m};

                % Set fixed launch probabilities
                isLaunch=DEBUG.Scenario_PTRS(:,k);

                dASSET{m}=ASSET;
                dMODEL{m}=MODEL;
                dMODEL{m}.ConstraintRealizationCount=1;
                dMODEL{m}.ConstraintProbability=1;
                dMODEL{m}.ConstraintName='CNSTR_0';
                dMODEL{m}.ScenarioSelected=Scenarios(k);
                
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
                
                Nc=size(SIM.DBG.ClassProfile,1);
                Therapy_class=categorical(SIM.DBG.ClassNames);
                Country=categorical(repmat(string(MODEL.CountrySelected),Nc,1));
                Asset_Names=categorical(strings(Nc,1));
                % Data for the classes
                TClass=table(repmat(Country,nEvents,1),... % Country
                    repmat(categorical(Scenarios(k)),nEvents*Nc,1),... % Scenario
                    repmat(categorical(runTime),nEvents*Nc,1),... % Run Time
                    repmat(Therapy_class,nEvents,1),... %Class
                    repmat(Asset_Names,nEvents,1),... %Asset
                    reshape(repmat(SIM.DBG.EventDates,Nc,1),[],1),... %Time
                    SIM.DBG.ClassProfile(:),... % Profile_model_Target_Share
                    SIM.DBG.ClassOrderOfEntry(:),... % OE_Target_Share
                    SIM.DBG.ClassUnadjTargetShare(:),... % Unadjusted_Combined_Target_share
                    SIM.DBG.ClassAdjFactor(:),... % Adjustment_Factor
                    SIM.DBG.ClassTargetShare(:),... % Adjusted_Target_Share
                    'VariableNames',tableVarNames);
                Tc{m}=[TAsset;TClass];
                
            end
            BENCH.ExecutionTime(m) = -1; % Not used
            
            % Concatenate table just computed for all countries
            T=vertcat(T,Tc{:});
            BENCH.RunTime = repmat(runTime,length(dMODEL),1);
            % Here, all countries are prepared for this specific scenario
            % Thus we write them to file
            msg=sprintf('Writing csv output for Scenario %s',Scenarios(k));
            addStatusMsg(msg);
            tic;
            
            % Testing a new strategy,: Asynchronous execution of the write
            % table.
            %parfeval(@writeTablesCsv,0,outFolder+filesep+Scenarios(k),dMODEL, dASSET, dESTAT, cCNSTR, BENCH);
            writeTablesCsv(outFolder+filesep+Scenarios(k)+datestr(runTime, '_yyyy-mm-dd_HHMMSS'),dMODEL, dASSET, dESTAT, cCNSTR, BENCH);
            tWrite=toc;
            addStatusMsg(sprintf('\nTime for writing csv output files: %g',tWrite));
        end
       
        toc;

        tic;
        writetable(T,debugFilename);
        % Apparently the fastest way to get rid of the NaN and <missing>
        % values is to re-read the file and using string replacement.
        f=fopen(debugFilename);
        raw=char(fread(f)');
        fclose(f);
        raw=strrep(raw,'NaN','');
        raw=strrep(raw,'<undefined>','');
        f=fopen(debugFilename,'w');
        fwrite(f,raw);
        fclose(f);
        tWrite=toc;
        
        addStatusMsg(sprintf('Time for writing table %g\n',tWrite))
        
    end % cb_DebugSim

    function cb_Cancel(source, eventdata)
        msg = sprintf('User manually canceled operation by pressing the "Cancel" button.\n');
        addStatusMsg(msg);
        isCancel = true;
        myPool = gcp('nocreate');
        try
            delete(myPool);
        catch
        end
    end


end
