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
    isCancel = false;
    
    
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
    jhEditStatus = findjobj(hEditStatus);   % Find underlying Java control peer for edit box
    jEditStatus = jhEditStatus.getComponent(0).getComponent(0); % get the scroll-pane's internal edit control
    jEditScroll = jhEditStatus.getVerticalScrollBar;
    
%% Helper Functions

    function addStatusMsg(msg)
        oldMsg = get(hEditStatus, 'String');
        if ischar(msg)
            msgFull = [oldMsg; {msg}];
        else
            msgFull = [oldMsg; msg];
        end
        set(hEditStatus, 'String', msgFull);
        drawnow;
        jEditStatus.setCaretPosition(jEditStatus.getDocument.getLength);  % set to last line in the box
        jEditScroll.setValue(jEditScroll.getMaximum);
        jhEditStatus.repaint;        
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
        isCancel = false;        
        if ~isOkInput || ~isOkOutput
            addStatusMsg('Unable to Run Simulation!  Please check Input and Output paths');
            return;
        end
        
        tStart = tic;
        cCNSTR = getConstraints(cASSET);
        fnames = {'NumIterations', 'NumWorkers', 'ExecutionTime', 'RunTime'};
        BENCH = struct;  % intialize the benchmark struct
        for m = 1:length(fnames)
            BENCH.(fnames{m}) = nan(size(cMODEL));
        end
        
        warning('off', 'MATLAB:xlswrite:AddSheet'); % Suppress the annoying warnings
        runTime = datetime('now', 'TimeZone', 'America/New_York');  % Entire run has same RunTime       
        outFolder = fullfile(resultsFolderPath, sprintf('ModelOut_%s', datestr(runTime, 'yyyy-mm-dd_HHMMSS')));
        if ~exist(outFolder, 'dir')
            mkdir(outFolder)
        end
%         outFileName = fullfile(outFolder, sprintf('ModelOutputs_%s.xlsx', datestr(runTime, 'yyyy-mm-dd_HHMMSS')));
        
        ccMODEL = cell(length(cMODEL), length(cCNSTR));
        ccASSET = cell(length(cMODEL), length(cCNSTR));
        ccESTAT = cell(length(cMODEL), length(cCNSTR));
        for m = 1:length(cMODEL)
            if isCancel
                isCancel = false;
                return;
            end
            MODEL = cMODEL{m};
            ASSET = cASSET{m};
            CHANGE = cCHANGE{m};
            addStatusMsg(sprintf('Starting to process country: %s on sheet: %s', MODEL.CountrySelected, MODEL.AssetSheet));

            [dateGrid, SimCubeBranded, SimCubeMolecule, tExec] = marketModelMonteCarlo(MODEL, ASSET, CHANGE, numIterations, numWorkers);

            % Parameters of the overall simulation for performance benchmarking
            BENCH.NumIterations(m) = numIterations;
            BENCH.NumWorkers(m) = numWorkers;
            BENCH.ExecutionTime(m) = tExec;  % Tries to exclude time to setup worker pool on first call

            parfor n = 1:length(cCNSTR)
                [a, b, c] = applyConstraints(cCNSTR{n}, MODEL, ASSET, SimCubeBranded, SimCubeMolecule, dateGrid);
                ccMODEL{m,n} = a;
                ccASSET{m,n} = b;
                ccESTAT{m,n} = c;
            end
            
%             MODEL = ccMODEL{m,1};  % First column is the simulation without constraints
%             ASSET = ccASSET{m,1};
%             ESTAT = ccESTAT{m,1};            
%             OUT_Branded  = writeEnsembleOutputs(outFileName, [MODEL.CountrySelected, '_Branded_Mean'], ESTAT.Branded.Mean, ESTAT.DateGrid, MODEL, ASSET);
%             OUT_BrStdEr  = writeEnsembleOutputs(outFileName, [MODEL.CountrySelected, '_Branded_StdErr'], ESTAT.Branded.StdErr, ESTAT.DateGrid, MODEL, ASSET);
%             OUT_Molecule = writeEnsembleOutputs(outFileName, [MODEL.CountrySelected, '_Molecule_Mean'], ESTAT.Molecule.Mean, ESTAT.DateGrid, MODEL, ASSET);
%             addStatusMsg(sprintf('Wrote to file: %s', outFileName));
            
            msg = sprintf('Country:%s, Ran %d iterations, Elapsed time = %1.1f sec, Cume time = %1.1f\n', ...
                    MODEL.CountrySelected, numIterations, tExec, toc(tStart));
            addStatusMsg(msg);
        end
        BENCH.RunTime = repmat(runTime, size(BENCH.NumIterations));
              
%         cMODEL = ccMODEL(:,1);  % First column is the unconstrained simulation
%         cASSET = ccASSET(:,1);
%         cESTAT = ccESTAT(:,1);
%         xlsFileName = fullfile(resultsFolderPath, sprintf('TableauData_%s.xlsx', datestr(runTime, 'yyyy-mm-dd_HHMMSS')));
%         [cTableau, cSheetNames] = writeTableauXls(xlsFileName, cMODEL, cASSET, cESTAT, BENCH);
%         addStatusMsg(sprintf('Wrote to file: %s\n', xlsFileName));

        
%         for n = 1:length(cCNSTR)
%             if isCancel
%                 isCancel = false;
%                 return;
%             end
%             cMODEL = ccMODEL(:,n);
%             cASSET = ccASSET(:,n);
%             cESTAT = ccESTAT(:,n);
%             cname = cCNSTR{n}.ConstraintName;
%             outFolderSub = fullfile(outFolder, cname);
%             
%             msg = sprintf('Writing outputs for Constraints: %s, Cume time = %1.1f sec', cname, toc(tStart));
%             addStatusMsg(msg);
%             [cTables, cFileNames] = writeTablesCsv(outFolderSub, cMODEL, cASSET, cESTAT, cCNSTR, BENCH);
%         end
        
        
        clear cESTAT SimCubeBranded SimCubeMolecule

        % Reorganize the memory to reduce interprocess communication
        cESTATc = cell(size(cCNSTR));
        cMODELc = cell(size(cCNSTR));
        cASSETc = cell(size(cCNSTR));
        for n = 1:length(cESTATc)
           cESTATc{n} = ccESTAT(:,n); 
           cMODELc{n} = ccMODEL(:,n);
           cASSETc{n} = ccASSET(:,n);
        end

        % Break into smaller parfor loops, again to reduce IPC
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

                [cTables, cFileNames] = writeTablesCsv(outFolderSub, cMODELc{n}, cASSETc{n}, cESTATc{n}, cCNSTR, BENCH);
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