function data=custom_reader(filename)
fp=fopen(filename,'r');
data=reshape(fread(fp,inf,'double'),[],2);
fclose(fp);