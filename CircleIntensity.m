function MeanIntensity=CircleIntensity(Xcenter, Ycenter, radius, image)
    %CircleIntensity: Mean intensity of a circle region on image
    %pur radius an odd number
    
    if rem(radius, 2)==0
        radius=radius+1;
    end
    
    Xmin=Xcenter-radius;
    Xmax=Xcenter+radius;
    Ymin=Ycenter-radius;
    Ymax=Ycenter+radius;
    
    Array=image(Ymin:Ymax,Xmin:Xmax);
    
    ArrayCenter=radius+1;
    
    DistanceArrayX=NaN(2*radius+1,2*radius+1);
    DistanceArrayY=NaN(2*radius+1,2*radius+1);
    
    for K=1:size(DistanceArrayX,1)
        DistanceArrayX(:,K)=(K-ArrayCenter).^2;
    end
    
    for K=1:size(DistanceArrayY,1)
        DistanceArrayY(K,:)=(K-ArrayCenter).^2;
    end
    
    DistanceArray=DistanceArrayX+DistanceArrayY;
    DistanceArray=DistanceArray.^0.5;
    
    index=find(DistanceArray<=radius);
    MeanIntensity=mean(Array(index));
end

    