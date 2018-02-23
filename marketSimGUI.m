function marketSimGUI()

%% Variables Global and Persistent in this GUI instance
   
    MODEL = [];
    ASSET = [];
    CHANGE = [];
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
                [status, sheets, xlFormat] = xlsfinfo(fullFileName);
            catch
                addStatusMsg('Unable to open Input file!  Please check file location and Excel installation.');
                isOkInput = false;
            end
            if ~ismember('Assets', sheets)
                msgbox('Found no sheet in this file named "Assets".  Unable to continue.');
                isOkInput = false;
            else 
                if ~ismember('ChangeEvents', sheets)
                    % ChangeEvents sheet is now optional
                    msgbox('Found no sheet in this file named "ChangeEvents".  Are you sure?');
                end
                tStart = tic;
                [MODEL, ASSET, CHANGE] = importAssumptions(fullFileName);
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
        [dateGrid, SimCube, SimCubeMolecule] = marketModelMonteCarlo(MODEL, ASSET, CHANGE, numIterations, numWorkers);

        Nsim = size(SimCube, 1);
        msg = sprintf('Ran %d simulations, elapsed time = %1.1f sec\n', Nsim, toc(tStart));
        addStatusMsg(msg);
        
%         STAT = computeSimStats(SimCube);

        outFileName = fullfile(resultsFolderPath, sprintf('ModelOutputs_%s.xlsx', datestr(now, 'yyyy-mm-dd_HHMMSS')));
        EOUT_Branded = writeEnsembleOutputs(outFileName, 'Branded', SimCube, dateGrid, MODEL, ASSET);
        EOUT_Molecule = writeEnsembleOutputs(outFileName, 'Molecule', SimCubeMolecule, dateGrid, MODEL, ASSET);

        msg = sprintf('Wrote Ensemble Statistics, elapsed time = %1.1f sec\n', toc(tStart));
        addStatusMsg(msg);


        %% Produce various outputs for a single realization

        doPlots = true;
        
        if doPlots
            [annualDates, annualBrandedShare] = annualizeMx(dateGrid, EOUT_Branded.Mean.PointShare, 'mean');
            
            figure; semilogy(dateGrid, EOUT_Molecule.Mean.PointShare); datetick; grid on; 
                    title('Share Per Asset - Monthly');
                    legend(ASSET.Assets_Rated, 'Location', 'EastOutside'); timeCursor(false);

            figure; hA = area(dateGrid, EOUT_Molecule.Mean.PointShare'); datetick; grid on; axis tight;
                    title('Share Per Asset - Molecule Mean Monthly'); 
                    legend(hA(end:-1:1), ASSET.Assets_Rated(end:-1:1), 'Location', 'EastOutside'); timeCursor(false);

            figure; hA = area(dateGrid, EOUT_Branded.Mean.PointShare'); datetick; grid on; axis tight;
                    title('Share Per Asset - Branded Mean Monthly'); 
                    legend(hA(end:-1:1), ASSET.Assets_Rated(end:-1:1), 'Location', 'EastOutside'); timeCursor(false);

            figure; hA = area(annualDates, annualBrandedShare'); grid on; axis tight;
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