
T=readtable('Scenario_185819579029920_2019-08-02_074336/Outputs.csv');
T1=T(T.Country=="US"&T.OutputMetric=="Mean"&T.PeriodType=="Year",:);%{'Country','Asset','Period','BrandedPointShare','MoleculePointShare'});
Time=datetime(unique(T1.Period),1,1);
debug_asset_names=lower(regexprep(unique(T1.Asset,'stable'),{'[^a-zA-Z_0-9 ]','\s'},{'','_'}));
BrandedPointShare=array2timetable(reshape(T1.BrandedPointShare,length(Time),[]),'RowTimes',Time,'VariableNames',debug_asset_names);
MoleculePointShare=array2timetable(reshape(T1.MoleculePointShare,length(Time),[]),'RowTimes',Time,'VariableNames',debug_asset_names);

for i=brandedYearlyShare.Properties.VariableNames
    fprintf('%s branded error: %g  generic error: %g\n',i{1},...
        norm(brandedYearlyShare(1:length(Time),i).Variables-BrandedPointShare(:,i).Variables,'inf'),...
        norm(genericYearlyShare(1:length(Time),i).Variables-MoleculePointShare(:,i).Variables,'inf'))
end