% Script to generate some random blocks of data and insert them into the
% MySQL database as a blob of data
Nassets=50;
Ncountries=7;
Nmonths=240;

% We will select only portion of the possible scenarios
Nscenarios=8521;%17535;%81066;%225600;
tic;
% From the sorted probabilites and incies, we read in the binary data
fp=fopen('probabilities.dat','rb');
scenarioProbability=fread(fp,Nscenarios,'double');
fclose(fp);

fp=fopen('indices.dat','rb');
scenarioIndex=fread(fp,Nscenarios,'uint32');
fclose(fp);

% Make a temporary directory to store the files
tmpdir=[tempname,'/'];
mkdir(tmpdir)
cleanup=onCleanup(@()rmdir(tmpdir,'s'));
toc;
%conn=connect_to_mysql;

%% Option 1: Big table, SQL write. Result: not efficient. Not scalable (exceeds memory for inserting into DB)
% construct a table of random data, converted to binary for insertion
% T=table(scenarioIndex(1:Nscenarios),reshape(typecast(rand(Nscenarios*Nmonths*Nassets*Ncountries,1),'uint8'),Nscenarios,[]),'VariableNames',{'launch_id','cube'});
% tic;
% sqlwrite(conn,'MyBlob',T);
% toc;

%% Option 2: Big buffer, write binary data to file. Similar scalability issues.
% buffer=rand(Nscenarios*Nmonths*Nassets*Ncountries,1);
% tic;
% fp=fopen([tmpdir,'buffer.dat'],'wb');
% fwrite(fp,buffer,'double');
% fclose(fp);
% toc

%% Option 3: Write each cube to file
dt=0;
dt1=0;
tic;
%h = waitbar(0,'Please wait...');


%outfile=[tmpdir,'big_block.dat'];
%fp=fopen(outfile,'wb');
for i=1:Nscenarios
    %waitbar(i/Nscenarios,h);
    tt1=cputime;
    data=rand(Nmonths*Nassets*Ncountries,2);
    dt1=dt1+(cputime-tt1);
    
    tt=cputime;
    outfile=sprintf('%s%08d_%08d.dat',tmpdir,i,scenarioIndex(i));
    fp=fopen(outfile,'wb');
    fwrite(fp,data,'double');
    fclose(fp);
    dt=dt+(cputime-tt);
end


fprintf('Generating data: %fs Writing data to file: %fs for %d scenarios\n',dt1,dt,Nscenarios);
toc;
%close(h)
%% Option 4: Write each cube to SQL database
% dt=0;
% 
% z=zeros(Nscenarios,1);
% for i=1:Nscenarios
%     id=mod(i,8)+1;
%     data=typecast(rand(1,Nmonths*Nassets*Ncountries),'uint8');
%     tt=cputime;
%     T=table(scenarioIndex(i),scenarioProbability(i),data,'VariableNames',{'launch_id','probability','cube'});
%     conn=database('JnJ?useSSL=false','pirenzi','S7mMLy9v','Vendor','MySQL','Server','localhost');
%     sqlwrite(conn,'MyBlob',T);
%     dt=dt+(cputime-tt);
% end
% fprintf('Writing blobs to MySQL: %fs for %d scenarios\n',dt,Nscenarios);
