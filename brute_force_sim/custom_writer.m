function custom_writer(info,data,country,ptrs,asset)
m=(size(data,2)-1)/2;
T=table(repmat(data(:,1),m,1),kron(country,ones(size(data,1),1,'like',country)),reshape(data(:,2:m+1)',[],1),reshape(data(:,m+2:end)',[],1),'VariableNames',{'SetID','Country_id','Launch_ON','Launch_OFF'});

fName=info.SuggestedFilename+".csv";
disp(fName);
disp(info);
writetable(T,fName);
