function data=custom_reader(filename)
fp=fopen(filename,'r');
d=reshape(fread(fp,'*uint64'),3,[])';
data=table(typecast(d(:,1),'double'),d(:,2),d(:,3),'VariableNames',{'p','on','off'});
fclose(fp);