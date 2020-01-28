function CLASS = therapyClassRank(ASSET,CLASS, isLaunch)
% In this function, we are will compute a table containing the class first
% launch date and the first launch rank (including duplicates).


% In the new model, classes already on the market will be given a ranking
% Based on the class starting share. New classes entering the market will
% be given a median launch order.

% We expand CLASS to have an in-class ranking and launch date
CLASS.First_Launch_Date = nan(height(CLASS),1);
CLASS.First_Launch_Rank = nan(height(CLASS),1);

for i=1:height(CLASS)
    className= CLASS.Therapy_Class(i);
    [firstLaunch,launchRank]=min(ASSET.Launch_Date((ASSET.Therapy_Class==className)&isLaunch));
    if firstLaunch
        CLASS.First_Launch_Date(i)=firstLaunch;
    end
end

% Remove those classes who don't have a launch date
CLASS(isnan(CLASS.First_Launch_Date),:)=[];

% First we specify that all classes that are already on the market be given
% a class rank based on their starting rank:
% The class with the largest starting share gets the largest class rank
CLASS=sortrows(CLASS,'Starting_Share');
classHasLaunched = CLASS.Starting_Share>0;
CLASS.First_Launch_Rank(classHasLaunched)=1:sum(classHasLaunched);

%[~,CLASS.First_Launch_Rank(classHasLaunched)]=sort(CLASS.Starting_Share(classHasLaunched),'descend');

% Get median launch rank
M=ceil(median(CLASS.First_Launch_Rank(classHasLaunched)));

% Find unlaunched classes with valid launch date
classUnlaunchedHasLaunchDate=~isnan(CLASS.First_Launch_Date)&~classHasLaunched;

% Shift the launched assets above the median so that we can give the
% unlaunched assets a launch rank closer to the median
classRankToShift=CLASS.First_Launch_Rank>M;
CLASS.First_Launch_Rank(classRankToShift)=CLASS.First_Launch_Rank(classRankToShift)+sum(classUnlaunchedHasLaunchDate);


% Rank unlaunched classes based on first class asset market entry date
CLASS(classUnlaunchedHasLaunchDate,:)=sortrows(CLASS(classUnlaunchedHasLaunchDate,:),'First_Launch_Date');
CLASS.First_Launch_Rank(classUnlaunchedHasLaunchDate)=M+(1:sum(classUnlaunchedHasLaunchDate));
%[~,classUnlaunchedRank]=sort(CLASS.First_Launch_Date(classUnlaunchedHasLaunchDate));


% Insert rank for unlaunched classes
%CLASS.First_Launch_Rank(classUnlaunchedHasLaunchDate)= M+classUnlaunchedRank;

end

%     [uClass,~,iC]= unique(ASSET.Therapy_Class, 'sorted');
% 
%     firstLaunch = nan(size(uClass));
%     for m = 1:length(uClass)
%         ix = (iC==m) & isLaunch;
%         if sum(ix) > 0
%             firstLaunch(m) = min(ASSET.Launch_Date(ix));
%         end    
%     end
%     
%     [~,~,launchRank]=unique(firstLaunch);
%     CLASS = table(uClass,firstLaunch,launchRank,...
%         'VariableNames',["Therapy_Class","First_Launch_Date","First_Launch_Rank"]);
