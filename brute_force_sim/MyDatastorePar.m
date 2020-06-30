%% STEP 1: INHERIT FROM DATASTORE CLASSES
classdef MyDatastorePar < matlab.io.Datastore & ...
        matlab.io.datastore.Partitionable
   
    properties(Access = private)
        CurrentFileIndex double
        FileSet matlab.io.datastore.DsFileSet
    end
    
    % Property to support saving, loading, and processing of
    % datastore on different file system machines or clusters.
    % In addition, define the methods get.AlternateFileSystemRoots()
    % and set.AlternateFileSystemRoots() in the methods section. 
    properties(Dependent)
        AlternateFileSystemRoots
    end
    
%% STEP 2: DEFINE THE CONSTRUCTOR AND THE REQUIRED METHODS
    methods
        % Define your datastore constructor
        function myds = MyDatastorePar(location,altRoots)
            myds.FileSet = matlab.io.datastore.DsFileSet(location,...
                'FileExtensions','.bin', ...
                'FileSplitSize',3*8*1024*100);
            myds.CurrentFileIndex = 1;
             
            if nargin == 2
                 myds.AlternateFileSystemRoots = altRoots;
            end
            
            reset(myds);
        end
        
        % Define the hasdata method
        function tf = hasdata(myds)
            % Return true if more data is available
            tf = hasfile(myds.FileSet);
        end
        
        % Define the read method
        function [data,info] = read(myds)
            % Read data and information about the extracted data
            % See also: MyFileReader()
            if ~hasdata(myds)
                msgII = ['Use the reset method to reset the datastore ',... 
                         'to the start of the data.']; 
                msgIII = ['Before calling the read method, ',...
                          'check if data is available to read ',...
                          'by using the hasdata method.'];
                error('No more data to read.\n%s\n%s',msgII,msgIII);
            end
            
            fileInfoTbl = nextfile(myds.FileSet);
            data = MyFileReader(fileInfoTbl);
            info.Size = size(data);
            info.FileName = fileInfoTbl.FileName;
            info.Offset = fileInfoTbl.Offset;
            
            % Update CurrentFileIndex for tracking progress
            if fileInfoTbl.Offset + fileInfoTbl.SplitSize >= ...
                    fileInfoTbl.FileSize
                myds.CurrentFileIndex = myds.CurrentFileIndex + 1 ;
            end
        end
        
        % Define the reset method
        function reset(myds)
            % Reset to the start of the data
            reset(myds.FileSet);
            myds.CurrentFileIndex = 1;
        end

        % Define the partition method
        function subds = partition(myds,n,ii)
            subds = copy(myds);
            subds.FileSet = partition(myds.FileSet,n,ii);
            reset(subds);
        end
        
        % Getter for AlternateFileSystemRoots property
        function altRoots = get.AlternateFileSystemRoots(myds)
            altRoots = myds.FileSet.AlternateFileSystemRoots;
        end

        % Setter for AlternateFileSystemRoots property
        function set.AlternateFileSystemRoots(myds,altRoots)
            try
              % The DsFileSet object manages AlternateFileSystemRoots
              % for your datastore
              myds.FileSet.AlternateFileSystemRoots = altRoots;

              % Reset the datastore
              reset(myds);  
            catch ME
              throw(ME);
            end
        end
      
    end
    
    methods (Hidden = true)          
        % Define the progress method
        function frac = progress(myds)
            % Determine percentage of data read from datastore
            if hasdata(myds) 
               frac = (myds.CurrentFileIndex-1)/...
                             myds.FileSet.NumFiles; 
            else 
               frac = 1;  
            end 
        end
    end
    
    methods(Access = protected)
        % If you use the  FileSet property in the datastore,
        % then you must define the copyElement method. The
        % copyElement method allows methods such as readall
        % and preview to remain stateless 
        function dscopy = copyElement(ds)
            dscopy = copyElement@matlab.mixin.Copyable(ds);
            dscopy.FileSet = copy(ds.FileSet);
        end
        
        % Define the maxpartitions method
        function n = maxpartitions(myds)
            n = maxpartitions(myds.FileSet);
        end
    end
end

%% STEP 3: IMPLEMENT YOUR CUSTOM FILE READING FUNCTION
function data = MyFileReader(fileInfoTbl)
% create a reader object using FileName
reader = matlab.io.datastore.DsFileReader(fileInfoTbl.FileName);

% seek to the offset
seek(reader,fileInfoTbl.Offset,'Origin','start-of-file');

% read fileInfoTbl.SplitSize amount of data
data = read(reader,fileInfoTbl.SplitSize,'OutputType','uint64');

% Notes: uint64(7) masks the first 3 bits that are the least significant in
% the Probability colum (this allows us to hide the country code in the probability).
% The number uint64(18446744073709551608) masks the other values.
% Step 1: Throw away the first 32 bits
C=reshape(typecast(uint32(data(1:4:end)),'uint8'),4,[])';
data = table(C(:,4),typecast(data(2:4:end),'double'),data(3:4:end),data(4:4:end),C(:,3),C(:,2),C(:,1),'VariableNames',{'Country_id','Probability','Launch_ON','Launch_OFF','Con','Coff','Ctotal'});

end
