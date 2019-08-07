
%datafile = 'aMDD Feb2019.xlsm';
datafile = 'Market_Model_Assumptions.xlsm';


%launch_data=readtable(datafile,'Sheet','Launch Scenarios','Range','D2:E26','TextType','string');
asset_data=readtable(datafile,'Sheet','Unique Asset List','Range','A3:CW75','TextType','string');
