function celltab = formatTab_C(cMODEL, BENCH)
% format output for Tableau
% C = by Country
% runTime is of type DateTime so we can reference it to the Eastern timzeone

    colHead = {'Country', 'Secenario Run', 'Run Date', 'Assumption', 'Number Value'};
    
    mdNames = {'Pop', 'SubPop', 'Tdays', 'ProfileElasticity', 'ClassOeElasticity', ...
              'ProductOeElasticity', 'BarrierElasticity', ...
              'PCP_Factor', 'Rest_of_EMEA_Bump_Up_from_EU5', ...
              'Rest_of_AP_Bump_Up_from_EU5', 'CA_Bump_Up_from_EU5', 'LA_Bump_Up_from_EU5'};
    mdLabels = {'Population', 'Subpopulation', 'Therapy Days per Year', ... 
               'Profile Elasticity', 'Class Order of Entry Elasticity', ...
               'Product Order of Entry Elasticity', 'Barrier Elasticity', ...
               'PCP Factor', 'ROEMEA Bump-Up', 'ROAP Bump-Up', 'CA Bump-Up', 'LA Bump-Up'};
           
   bcNames  = {'NumIterations', 'NumWorkers', 'ExecutionTime'};
   bcLabels = {'Num Iterations', 'Num Workers', 'Execution Time'};

    nRows = length(mdNames) * length(cMODEL);
    celltab = cell(nRows, length(colHead));
    celltab(1,:) = colHead;
    
    rr = 1;
    for m = 1:length(cMODEL)
        MODEL = cMODEL{m};
        runTime = BENCH.RunTime(m);

        for n = 1:length(mdNames)  % Copy data from the MODEL struct
            rr = rr + 1;
            celltab{rr, 1} = MODEL.CountrySelected;
            celltab{rr, 2} = MODEL.ScenarioSelected;
            celltab{rr, 3} = datestr(runTime, 'yyyy-mm-dd HH:MM:SS');

            celltab{rr, 4} = mdLabels{n};
            celltab{rr, 5} = MODEL.(mdNames{n});        
        end        
        for n = 1:length(bcNames)  % Copy data from the BENCH struct
            rr = rr + 1;
            celltab{rr, 1} = MODEL.CountrySelected;
            celltab{rr, 2} = MODEL.ScenarioSelected;
            celltab{rr, 3} = datestr(runTime, 'yyyy-mm-dd HH:MM:SS');
            
            celltab{rr, 4} = bcLabels{n};
            celltab{rr, 5} = BENCH.(bcNames{n})(m);            
        end
    end
    
end