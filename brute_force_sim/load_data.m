%% Data loading:
%
% In the future, this wil be dealt with entirely by pulling data from the
% MySQL database. For the mement, we use a combination of the excel data reader
% and a cached .mat file.

% The modelID should be imported from the input data
modelID=1;

% the type of output for the simulation
output_type="Monthly";

%output_folder=string([uigetdir('','Select output folder'),filesep]);
output_folder="data"+filesep+"prepare_tables_output"+filesep;
target_folder=output_folder;%+"target"+filesep;
scenario_folder=output_folder;%+"scenario"+filesep;
monthly_folder=output_folder;%+"monthly"+filesep;

% If the directories need creating, then create, otherwise use existing
% directories
if ~exist(output_folder,'dir')
    mkdir(output_folder);
    %mkdir(scenario_folder);
    %mkdir(monthly_folder);
    %mkdir(target_folder);
end
%else
%     if ~exist(target_folder,'dir')
%         mkdir(target_folder);
%     end
%     if ~exist(scenario_folder,'dir')
%         mkdir(scenario_folder);
%     end
%     if ~exist(monthly_folder,'dir')
%         mkdir(monthly_folder);
%     end
% end

% Set the robustness value of the model run.
robustness=0.1;

%[dataFile,dataFolder] = uigetfile({'*.xls*','Excel files (.xls*)';'*.mat','Matlab Cache file (.mat)'},'Select Input file (Excel or MAT)');
dataFile='Market_Model_Assumptions.mat';
dataFolder='./';

% Put together full file name in case app is run in a different dir.
fullDataFile=fullfile(dataFolder,dataFile);

% Get file extension fro deciding which path to take0
[~,inputDataName,inputExtension]=fileparts(dataFile);


Model=table(modelID,output_folder,'VariableNames',{'ID','MName'});
% Global timing point
tbegin=tic;

%'Market_Model_Assumptions_1';

% Check first for a Cache .mat file
switch inputExtension
    case '.mat'
        load(dataFile);
    case {'.xls','.xlsx','.xlsm','.xlsb'}
        % First import assumptions and asset information from excel
        [cMODEL, cASSET, Tc,cDEBUG] = importAssumptions(dataFile);

        % Cache the output in a Matlab .Mat file
        if exist([inputDataName,'.mat'],'file')
            overWrite=questdlg('Overwrite existing Cache file?','Overwrite Cache','No');
            switch overWrite
                case 'Yes'
                    save([inputDataName,'.mat'], 'cMODEL','cASSET', 'Tc','cDEBUG');
            end
        else
            save([inputDataName,'.mat'], 'cMODEL','cASSET', 'Tc','cDEBUG');
        end
end

tdata_load=toc(tbegin);
fprintf('[Timing] Data loading: %gs\n',tdata_load);