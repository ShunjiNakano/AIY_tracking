%% Version 4: Use with DeepLabCut csv files. 
% this version uses the csv file of DeepLabCut for the prediction of AFD
% AIY cell body, AIY axon and ROI for background.

%% First, split the YCX image using metamorph, name them as 
  %FileName_CFP.tif and FileName_YFP.tif
FileName='FileName'; % input the file name of your image file
                     % ex) IK3212_20200101


%%

InitialFrame=1; %set initial frame number, You can change this
FinalFrame=79;  %set final frame number

IM_YFP_NORM_FACTOR=3; %set the intensity factor for displaying YFP image

Data=NaN(79,22);
Data(:,1)=1:79;% The first column for frame number
% frame_number, AFD_CFP, AFD_YFP, AIY_CFP, AIY_YFP, BC_CFP, BC_YFP,
% blank, AFD_CFP-BC_CFP,AFD_YFP-BC_YFP,AIY_CFP-BC_CFP,AIY_YFP-BC_YFP,
% blank, AFD_YFP/AFD_CFP, AIY_YFP/AIY_CFP,
% blank, X coordinate of AFD, Y of AFD, X of AIY cell body, Y of AIY cell
% body, X of AIY axon, Y of AIY axon

csv_file=dir('FileName_YFP*.csv');
CSV=readmatrix(csv_file(1).name,'NumHeaderLines',3);

AFD_Radius=5;
AIY_Radius=3;
BG_Radius=5;

%% Quick view of AFD and AIY trend

Quick_AFD_array=NaN(79,1);
Quick_AIY_array=NaN(79,1);

for K=InitialFrame:FinalFrame
    IM_CFP=imread('FileName_CFP.tif', K);
    IM_YFP=imread('FileName_YFP.tif', K);
    
    if round(CSV(K,2))<=AFD_Radius||round(CSV(K,3))<=AFD_Radius||round(CSV(K,8))<=AIY_Radius||....
            round(CSV(K,9))<=AIY_Radius||round(CSV(K,11))<=BG_Radius||round(CSV(K,12))<=BG_Radius
        Quick_AFD_array(K,1)=NaN;
        Quick_AIY_array(K,1)=NaN;
    else        
        Q_AFD_CFP=CircleIntensity(round(CSV(K,2)),round(CSV(K,3)),AFD_Radius,IM_CFP);
        Q_AFD_YFP=CircleIntensity(round(CSV(K,2)),round(CSV(K,3)),AFD_Radius,IM_YFP);
        Q_AIY_CFP=CircleIntensity(round(CSV(K,8)),round(CSV(K,9)),AIY_Radius,IM_CFP);
        Q_AIY_YFP=CircleIntensity(round(CSV(K,8)),round(CSV(K,9)),AIY_Radius,IM_YFP);

        Q_BG_CFP=CircleIntensity(round(CSV(K,11)),round(CSV(K,12)),BG_Radius,IM_CFP);
        Q_BG_YFP=CircleIntensity(round(CSV(K,11)),round(CSV(K,12)),BG_Radius,IM_YFP); 

        Q_AFD_minus_BG_CFP=Q_AFD_CFP-Q_BG_CFP;
        Q_AFD_minus_BG_YFP=Q_AFD_YFP-Q_BG_YFP;
        Q_AIY_minus_BG_CFP=Q_AIY_CFP-Q_BG_CFP;
        Q_AIY_minus_BG_YFP=Q_AIY_YFP-Q_BG_YFP;

        Quick_AFD_array(K,1)=Q_AFD_minus_BG_YFP./Q_AFD_minus_BG_CFP;
        Quick_AIY_array(K,1)=Q_AIY_minus_BG_YFP./Q_AIY_minus_BG_CFP;
    end
    
end

figure;
plotyy(1:79,Quick_AFD_array,1:79,Quick_AIY_array);
title('non-curated');


%% frame-by-frame analysis starts here


for K=InitialFrame:FinalFrame
    IM_CFP=imread('FileName_CFP.tif', K);
    IM_YFP=imread('FileName_YFP.tif', K);
    
    W1=figure('Position',[1 1 256 1024]);
    imshowpair(IM_CFP,IM_YFP);
    
    IM_YFP_DB=im2double(IM_YFP);
    IM_YFP_NORM=(IM_YFP_DB-min(IM_YFP_DB(:)))./(max(IM_YFP_DB(:))-min(IM_YFP_DB(:)));

    % adjust the brightness of displaying image of YFP
    IM_YFP_NORM=IM_YFP_NORM.*IM_YFP_NORM_FACTOR;
    
    % calculate centroid of AFD, AIY axon, BG
    polyin = polyshape([CSV(K,2),CSV(K,8),CSV(K,11)],[CSV(K,3),CSV(K,9),CSV(K,12)]);
    [centroid_x, centroid_y] = centroid(polyin);
    
    centroid_x=round(centroid_x);
    centroid_y=round(centroid_y);
    
   
    % determine the boundary for display image
    
    if centroid_x<150
        left=1;
    else
        left=centroid_x-150;
    end
    
    if centroid_x+150>size(IM_YFP_NORM,2)
        right=size(IM_YFP_NORM,2);
    else
        right=centroid_x+150;
    end
    
    if centroid_y<150
        top=1;
    else
        top=centroid_y-150;
    end
    
    if centroid_y+150>size(IM_YFP_NORM,1)
        bottom=size(IM_YFP_NORM,1);
    else
        bottom=centroid_y+150;
    end 
    
    W2=figure;
    figure(W2);
    imshow(IM_YFP_NORM);hold on
    title('move or delete ROIs and then hit return');
    h_AFD=images.roi.Circle(gca,'Center',[CSV(K,2),CSV(K,3)],'Radius',5,'Color','blue','Label','AFD');
    h_AIY=images.roi.Circle(gca,'Center',[CSV(K,8),CSV(K,9)],'Radius',5,'Color','red','Label','AIY');
    h_BG=images.roi.Circle(gca,'Center',[CSV(K,11),CSV(K,12)],'Radius',5,'Color','green','Label','BG');
    hold off
    set(W2.Children,'Xlim',[left, right]);
    set(W2.Children,'Ylim',[top, bottom]);
    set(W2,'Position',[500 1 900 900]);
    
    if right-left<300
        zoomfactor1=900./(right-left);
    else
        zoomfactor1=2;
    end
    
    if bottom-top<300
        zoomfactor2=900./(bottom-top);
    else
        zoomfactor2=2;
    end
    
    zoomfactor=min(zoomfactor1,zoomfactor2);
    
    zoom(zoomfactor)
    
    currkey=0;
    while currkey~=1
        pause; % wait for a keypress
        currkey=get(gcf,'CurrentKey'); 
        if strcmp(currkey, 'return') 
            currkey=1;
        else
            currkey=0; 
        end
    end
    
    
    % get position and intensity of each ROI
    
    if isvalid(h_AFD)==0
        AFD_x=NaN;
        AFD_y=NaN;
        AFD_YFP=NaN;
        AFD_CFP=NaN;
        
    else
        AFD_x=round(h_AFD.Center(1));
        AFD_y=round(h_AFD.Center(2));
        AFD_YFP=CircleIntensity(AFD_x,AFD_y,AFD_Radius,IM_YFP);
        AFD_CFP=CircleIntensity(AFD_x,AFD_y,AFD_Radius,IM_CFP);
    end
    
    
    if isvalid(h_AIY)==0
        AIY_x=NaN;
        AIY_y=NaN;
        AIY_YFP=NaN;
        AIY_CFP=NaN;
    else
        AIY_x=round(h_AIY.Center(1));
        AIY_y=round(h_AIY.Center(2));
        AIY_YFP=CircleIntensity(AIY_x,AIY_y,AIY_Radius,IM_YFP);
        AIY_CFP=CircleIntensity(AIY_x,AIY_y,AIY_Radius,IM_CFP);
    end
    
    if isvalid(h_BG)==0
        BG_x=NaN;
        BG_y=NaN;
        BG_YFP=NaN;
        BG_CFP=NaN;
    else
        BG_x=round(h_BG.Center(1));
        BG_y=round(h_BG.Center(2));
        BG_YFP=CircleIntensity(BG_x,BG_y,BG_Radius,IM_YFP);
        BG_CFP=CircleIntensity(BG_x,BG_y,BG_Radius,IM_CFP);
    end
    
    close all
    
    
    
    
    Data(K,2)=AFD_CFP;
    Data(K,3)=AFD_YFP;
    Data(K,4)=AIY_CFP;
    Data(K,5)=AIY_YFP;
    Data(K,6)=BG_CFP;
    Data(K,7)=BG_YFP;
    
    Data(K,9)=AFD_CFP-BG_CFP;
    Data(K,10)=AFD_YFP-BG_YFP;
    Data(K,11)=AIY_CFP-BG_CFP;
    Data(K,12)=AIY_YFP-BG_YFP;
    
    Data(K,14)=Data(K,10)./Data(K,9); % AFD ratio(Y/C) for the 14th coloumn
    Data(K,15)=Data(K,12)./Data(K,11); % AIY ratio(Y/C) for the 14th coloumn
    
    Data(K,17)=AFD_x;
    Data(K,18)=AFD_y;
    Data(K,19)=NaN; %for this version, put NaN for AIY cell body coordinate
    Data(K,20)=NaN; %for this version, put NaN for AIY cell body coordinate
    Data(K,21)=AIY_x;
    Data(K,22)=AIY_y;
    
end
figure;
plotyy(Data(:,1),Data(:,14),Data(:,1),Data(:,15));
title('curated');

figure;
plotyy(1:79,Quick_AFD_array,1:79,Quick_AIY_array);
title('non-curated');


%% write data

csvwrite('FileName_YCX.csv',Data);