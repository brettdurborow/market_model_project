function marketSimGUI()

%% Variables Global and Persistent in this GUI instance
   
    cMODEL = {};
    cASSET = {};
    cCHANGE = {};
    cESTAT = {};
    simCount = 0;
    isOkInput = false;
    isOkOutput = false;
    numCores = feature('numcores');  % Number of physical cores on this machine
    numWorkers = numCores-1;
    numIterations = 1000;
    resultsFolderPath = '';
    
    
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
     
    hBtnCancel = uicontrol('Style', 'pushbutton', 'String', 'Cancel', ...
         'Position', [480, fh-570, 90, 30], ...
         'Callback', {@cb_Cancel}, ...
         'Parent', hF);     
     
%% Initialize the GUI
   
    set(hF, 'Visible', 'on'); % Make the GUI visible
    set(hF, 'MenuBar', 'none', ...
            'ToolBar', 'none');
        
%% Helper Functions

    function addStatusMsg(msg)
        oldMsg = get(hEditStatus, 'String');
        if ischar(msg)
            msgFull = [oldMsg; {msg}];
        else
            msgFull = [oldMsg; msg];
        end
        set(hEditStatus, 'String', msgFull);
    end

    function [assetSheets, ceSheets, simuSheet] = checkInputSheets(fileName)
    % Build a list of Asset sheets in this workbook
        [~, sheets, ~] = xlsfinfo(fileName);
        
        simuSheet = sum(strcmpi(sheets, 'Simulation')) == 1;  % look for a sheet called "Simulation"

        assetSheets = {};
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
    end


%%  Callbacks for GUI. 
   %  These callbacks automatically have access to component handles
   %  and initialized data because they are nested at a lower level

   
    function cb_Exit(source, eventdata)
        strAnswer = questdlg('Are you sure you want to exit?', 'Exit the application?', 'OK', 'Cancel', 'OK');

        if strcmp(strAnswer, 'OK')
            delete(hF);
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
                [cMODEL, cASSET, cCHANGE] = importAssumptions(fullFileName);
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

    function cb_RunSim(source, eventdata)
        
        if ~isOkInput || ~isOkOutput
            addStatusMsg('Unable to Run Simulation!  Please check Input and Output paths');
            return;
        end
        
        tStart = tic;
        fnames = {'NumIterations', 'NumWorkers', 'ExecutionTime', 'RunTime'};
        BENCH = struct;  % intialize the benchmark struct
        for m = 1:length(fnames)
            BENCH.(fnames{m}) = nan(size(cMODEL));
        end
        outFileName = fullfile(resultsFolderPath, sprintf('ModelOutputs_%s.xlsx', datestr(now, 'yyyy-mm-dd_HHMMSS')));
        
        cESTAT = cell(size(cMODEL));
        for m = 1:length(cMODEL)
            MODEL = cMODEL{m};
            ASSET = cASSET{m};
            CHANGE = cCHANGE{m};
            addStatusMsg(sprintf('Starting to process country: %s on sheet: %s', MODEL.CountrySelected, MODEL.AssetSheet));

            [dateGrid, SimCubeBranded, SimCubeMolecule, tExec] = marketModelMonteCarlo(MODEL, ASSET, CHANGE, numIterations, numWorkers);

            % Parameters of the overall simulation for performance benchmarking
            BENCH.NumIterations(m) = numIterations;
            BENCH.NumWorkers(m) = numWorkers;
            BENCH.ExecutionTime(m) = tExec;  % Tries to exclude time to setup worker pool on first call

            ESTAT = computeEnsembleStats(SimCubeBranded, SimCubeMolecule, dateGrid);
            cESTAT{m} = ESTAT;
            
            OUT_Branded  = writeEnsembleOutputs(outFileName, [MODEL.CountrySelected, '_Branded_Mean'], ESTAT.Branded.Mean, ESTAT.DateGrid, MODEL, ASSET);
            OUT_BrStdEr  = writeEnsembleOutputs(outFileName, [MODEL.CountrySelected, '_Branded_StdErr'], ESTAT.Branded.StdErr, ESTAT.DateGrid, MODEL, ASSET);
            OUT_Molecule = writeEnsembleOutputs(outFileName, [MODEL.CountrySelected, '_Molecule_Mean'], ESTAT.Molecule.Mean, ESTAT.DateGrid, MODEL, ASSET);
            addStatusMsg(sprintf('Wrote to file: %s', outFileName));
            
            msg = sprintf('Country:%s, Ran %d iterations, Elapsed time = %1.1f sec, Cume time = %1.1f\n', ...
                    MODEL.CountrySelected, numIterations, tExec, toc(tStart));
            addStatusMsg(msg);
        end
        endTime = datetime('now', 'TimeZone', 'America/New_York');  % Entire run has same RunTime
        BENCH.RunTime = repmat(endTime, size(BENCH.NumIterations));
               
        xlsFileName = fullfile(resultsFolderPath, sprintf('TableauData_%s.xlsx', datestr(endTime, 'yyyy-mm-dd_HHMMSS')));
        [cTableau, cSheetNames] = writeTableauXls(xlsFileName, cMODEL, cASSET, cESTAT, BENCH);
        addStatusMsg(sprintf('Wrote to file: %s\n', xlsFileName));



        %% Produce various outputs for a single realization

        doPlots = true;
        
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
        msg = sprintf('Run complete, elapsed time = %1.2f sec\n', tElapsed);
        addStatusMsg(msg);
        
    end

    function cb_Cancel(source, eventdata)
        msg = 'User manually canceled operation by pressing the "Cancel" button.';
        addStatusMsg(msg);
        myPool = gcp('nocreate');
        try
            delete(myPool);
        catch
        end
    end


end