%Image classifier for solving simple "captcha" images involving the
%printed digits 0, 2 and 1.
%
%Made for lab 5 of image analysis
%
%Date:22.12.2017
%Authors: Mattias Eriksson, Suraj Murali

function S = myclassifier(im)

%base return value
S = floor(rand(1,3)*3);

%Thresholding
gray = graythresh(im);
bwim = imbinarize(im, gray);

%Morphological transformation to limit noise
SE = strel('square', 3);
afterOpen = imclose(bwim, SE);

%Filtering noise
filtered = bwareaopen(~afterOpen, 20);  

%Segmentation
components = bwconncomp(filtered);

%acuiering the boundry box
boundingbox = regionprops(components,'BoundingBox');


%if 3 objects detected clasify as 3 digits, else solve combined digits
if(components.NumObjects > 2)
    
    intersections = findIntersects(boundingbox,filtered);
    S = estimateNumbers(intersections);    

elseif(components.NumObjects == 2)
    
    %find the bigest region
    width = 0;
    regionIndex = 0;
    for i = 1:2
        box = boundingbox(i).BoundingBox;
        tempwidth = box(3);
        if(tempwidth > width)
            width = tempwidth;
            regionIndex = i;
        end
    end
    
    %finding the convex hull
    convexHulls = regionprops(components,'ConvexImage');
    convexRegion = convexHulls(regionIndex).ConvexImage;
    
    %extracting the subregion matching the convex hull
    box = boundingbox(regionIndex).BoundingBox;   
    x = ceil(box(2));
    y = ceil(box(1));
    height = box(4);
 
    subimage = filtered(x:(x + height-1), y:(y+width-1));
    
    %aquiering the convex portions 
    concaveImage = convexRegion - subimage;
    
    %Filtering regions smaller than 5
    concaveImage = bwareaopen(concaveImage, 5);
    
    %segmenting the concae regions
    concaveRegions = bwconncomp(concaveImage);
    
    %finding the boundry boxes and centroids for the convex regions
    subRegionBoundries = regionprops(concaveRegions,'BoundingBox','Centroid');
    
    %finding the top moste region
    minY = 10000;
    topIndex = 0;
    for i= 1:size(subRegionBoundries)
        box = subRegionBoundries(i).BoundingBox;
        y = box(2);
        if(minY > y)
            minY = y;
            topIndex = i;
        end
    end
    
    %finding the x value of the centroid for that region for use as a
    %dividing line
    arr = subRegionBoundries(topIndex).Centroid;
    cutingX = arr(1);
    
    %translation to super image coordinates
    box = boundingbox(regionIndex).BoundingBox;
    x = ceil(box(1));
    cutingX = round(cutingX + x);
    
    %finding the intersections count for the other digit
    intersections = zeros(1, 3); 
    indexOffset = 1;
    if(regionIndex == 1)
        otherBox = boundingbox(2).BoundingBox;
        width = otherBox(3);
        centerX = ceil(otherBox(1)) + ceil(width/2) + 2;
        intersections(3) = findIntersectsAtline(otherBox, centerX, filtered);
        indexOffset = 0;
    end
    otherBox = boundingbox(1).BoundingBox;
    width = otherBox(3);
    centerX = ceil(otherBox(1)) + ceil(width/2) + 2;
    intersections(1) = findIntersectsAtline(otherBox, centerX, filtered);
    
    %finding the centers of the combined digits
    width = box(3);
    center1 = round((x + cutingX)/2) + 2;
    center2 = round((x + width + cutingX)/2) + 2;  

    %calculating the intersections
    intersections(1+indexOffset) = findIntersectsAtline(box, center1, filtered);
    intersections(2+indexOffset) = findIntersectsAtline(box, center2, filtered);
    
    %estimate the numbeers based on intersection count
    S = estimateNumbers(intersections);
end
end

%function for counting lines of arbitrary thickness intersecting a spesific line across the x axis bounded along the
%y axis by a boundry box
%
%box: the boundry box
%center: the position of the line along the x axis
%data: the data to check 
%
%returns the number of intersection
function Inumber = findIntersectsAtline(box,center, data);

    x = ceil(box(2));
    count = 0;
    lastpixel = 0;
    for y = x:(x + box(4))
        if(lastpixel == 0 & data(y,center) == 1)
            count = count + 1; 
        end
        lastpixel = data(y,center);
    end
    Inumber = count;
end

%function for counting lines of arbitrary thickness intersecting 3 spesific line across the center of 3 boundry boxes bounded along the
%y axis by the same box.
%
%box: the boundry box
%data: the data to check 
%
%returns the number of intersection for the 3 lines as an array
function Inumber = findIntersects(boundingbox, data);

Inumber = zeros(1, 3);
for i = 1:3
    box = boundingbox(i).BoundingBox;
    
    %calculate the center
    width = box(3);
    x = ceil(box(2));
    center = ceil(box(1)) + ceil(width/2) + 2   ;
    
    %scan across the data
    count = 0;
    lastpixel = 0;
    for y = x:(x + box(4))
        if(lastpixel == 0 & data(y,center) == 1)
            count = count + 1; 
        end
        lastpixel = data(y,center);
    end
    Inumber(i) = count;
end
end

%function that estimates number of the digits based on how many times they intersect a line acros ther center from top 
%to bottom
function S = estimateNumbers(intersections);
    numbers = zeros(1, 3);    
    for i = 1:3
        num = intersections(i);
        if(num < 2)
             numbers(i) = 1;
        elseif(num == 2)
             numbers(i) = 0;
        else
             numbers(i) = 2;
        end            
    end
    S = numbers;
end
