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
        else
            isOkOutput = false;
            msg = 'WARNING: invalid Output Folder!';
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
            resultsFolderPath = folderName;
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
            elseif ~ismember('ChangeEvents', sheets)
                msgbox('Found no sheet in this file named "ChangeEvents".  Unable to continue.');
                isOkInput = false;
            else 
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
        [SimCube, dateGrid] = marketModelMonteCarlo(MODEL, ASSET, CHANGE, numIterations, numWorkers);

        Nsim = size(SimCube, 1);
        msg = sprintf('Ran %d simulations, elapsed time = %1.1f sec\n', Nsim, toc(tStart));
        addStatusMsg(msg);
        
        STAT = computeSimStats(SimCube);

        fprintf('Computed Percentile Statistics, elapsed time = %1.1f sec\n', toc(tStart));


        %% Produce various outputs for a single realization

        simNum = 1;

        sharePerAssetMonthlySeries = squeeze(SimCube(simNum, :, :));

        uClass = unique(ASSET.Therapy_Class);
        Nc = length(uClass);
        Nt = size(sharePerAssetMonthlySeries, 2);
        sharePerClassMonthlySeries = zeros(Nc, Nt);

        for m = 1:Nc
            ix = find(strcmpi(uClass(m), ASSET.Therapy_Class));
            sharePerClassMonthlySeries(m,:) = nansum(sharePerAssetMonthlySeries(ix, :), 1);    
        end

        OUT = computeOutputs(MODEL, ASSET, dateGrid, sharePerAssetMonthlySeries);
        
        doPlots = true;  %ToDo: remove this

        if doPlots
            figure; plot(dateGrid, 1-nansum(sharePerAssetMonthlySeries)); datetick; grid on; timeCursor(false);
                    title('Sum-To-One Error');

            figure; semilogy(dateGrid, sharePerAssetMonthlySeries); datetick; grid on; title('Share Per Asset');
                    legend(ASSET.Assets_Rated, 'Location', 'EastOutside'); timeCursor(false);

            figure; hA = area(dateGrid, sharePerAssetMonthlySeries'); datetick; grid on; axis tight;
                    title('Share Per Asset'); 
                    legend(hA(end:-1:1), ASSET.Assets_Rated(end:-1:1), 'Location', 'EastOutside'); timeCursor(false);

            figure; hA = area(dateGrid, sharePerClassMonthlySeries'); datetick; grid on; axis tight;
                    title('Share Per Class'); 
                    legend(hA(end:-1:1), uClass(end:-1:1), 'Location', 'EastOutside'); timeCursor(false);            

            figure; semilogy(dateGrid, OUT.Units); datetick; grid on; title('Units');
                    legend(ASSET.Assets_Rated, 'Location', 'EastOutside'); timeCursor(false);

            figure; semilogy(dateGrid, OUT.NetRevenues); datetick; grid on; title('Net Revenues');
                    legend(ASSET.Assets_Rated, 'Location', 'EastOutside'); timeCursor(false);

        end


        %% Plot one Asset


        if doPlots
            aNum = 10;  % asset number to plot
            figure; 
            plot(dateGrid, STAT.Percentile90(aNum,:), dateGrid, STAT.Percentile50(aNum,:), dateGrid, STAT.Percentile10(aNum,:));
            legend({'90th %ile', '50th %ile', '10th %ile'});
            title(sprintf('Monthly Share Percentiles: %s', ASSET.Assets_Rated{aNum}));
            datetick; grid on; timeCursor(false);

            figure; cdfplot(SimCube(:, aNum, Nt)); 
            title(sprintf('CDF of final share over %d sims for Asset %d.  PTRS=%1.1f%%', Nsim, aNum, ASSET.Scenario_PTRS{aNum} * 100));

        end


        tElapsed = toc(tStart);
        fprintf('Run complete, elapsed time = %1.2f sec\n', tElapsed);        
        
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