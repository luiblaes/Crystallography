close all;
clear all;

pxtomm=1; %Default set to 1
plot_figure=0;
Pic_name={};
%Select image
[file,path]=uigetfile('.jpg','Select the .jpg file');

%Load image
I = imread([path file]);

%Plot "stop selection" button and image
%figure
figure;
ButtonHandle = uicontrol('Style', 'PushButton', ...
                         'String', 'Stop selection', ...
                         'Callback', 'delete(gcbf)');

%ef = uieditfield("numeric");
imshow(I);
i=0;
[m,n,~]=size(I);
    try
for k = 1:1e6
    %Get the coordinades of the rectangles drawn with the mouse
  rect(k,:) = getrect;

  %If the any boundary of the rectangle lies outside image push it to the
  %boundary
  if rect(k,1)<1
      rect(k,3)=rect(k,3)-(abs(rect(k,1)));
      rect(k,1)=1;
  elseif rect(k,2)<1
      rect(k,4)=rect(k,4)-(abs(rect(k,2)));
      rect(k,2)=1;
  elseif rect(k,1)+rect(k,3)>n
        rect(k,3)=n-rect(k,1);
  elseif rect(k,2)+rect(k,4)>m
        rect(k,4)=m-rect(k,2);
  end
  %Plot rectangles
hold on
rectangle('Position',rect(k,:))

%Line in console where the user stops selection 
  if ~ishandle(ButtonHandle)
    disp('Selection stopped by user');
    break;
  end
  
end
  catch
    end
    
%% Section developed in October 2023

%Predefine arrays
MajorAxis_a=[];
MinorAxis_a=[];

%Max and Min area limit (in pixels) of the particles to be detected
Amax=1e10;
Amin=500;

%Loop for the number of rectangles drawn
for j= 1:k-1
try


Icrop=imcrop(I(:,:,1), rect(j,:));
Icropv2=Icrop;
if plot_figure==1
figure
imshow(Icrop)
else 
end
[~, threshold] = edge(Icrop, 'sobel');
fudgeFactor = .75;
BWs = edge(Icrop,'sobel', threshold * fudgeFactor);
if plot_figure==1
figure, imshow(BWs), title('binary gradient mask');
else
end
se90 = strel('line', 3, 90);
se0 = strel('line', 3, 0);

BWsdil = imdilate(BWs, [se90 se0]);
if plot_figure==1
figure, imshow(BWsdil), title('dilated gradient mask');
else
end
BWdfill = imfill(BWsdil, 'holes');

if plot_figure==1
figure, imshow(BWdfill);
title('binary image with filled holes');
else
end
BWnobord = imclearborder(BWdfill, 4);

if plot_figure==1
figure, imshow(BWnobord), title('cleared border image');
else
end

seD = strel('diamond',1);
BWfinal = imerode(BWnobord,seD);
BWfinal = imerode(BWfinal,seD);

if plot_figure==1
figure, imshow(BWfinal), title('segmented image');
else
end
% %These lines to define the elements to later obtain the proporties
CC = bwconncomp(BWfinal,4); %These lines to remove small particles (not needed but doesn´t harm)
S = regionprops(CC,'Area','Eccentricity','centroid');
L = labelmatrix(CC);
% %After the first "complete" analysis here we define Area and eccentricity
% %thresholds
BWNew = ismember(L, find([S.Area] <= Amax & [S.Area] >= Amin  & [S.Eccentricity] <= 0.95));%;AxisLength','Eccentricity','Area');
sv2 = regionprops(BWNew,'centroid','MajorAxisLength','MinorAxisLength','Eccentricity','Area', 'Orientation');

% % Parameterize the ellipse equation to be fitted to the detected particle
% 

co=-cosd(sv2.Orientation);
si=sind(sv2.Orientation);
the=linspace(0,2*pi,200);

% 
% %Figure showing the image filtered and filled and the ellipse fitted
if plot_figure==1

figure
imshow(Icrop)
sv2.MajorAxisLength=sv2.MajorAxisLength-sv2.MajorAxisLength/15;
sv2.MinorAxisLength=sv2.MinorAxisLength-sv2.MinorAxisLength/10;
p=line(sv2.MajorAxisLength/2*cos(the)*co-si*sv2.MinorAxisLength/2*sin(the)+sv2.Centroid(1),sv2.MajorAxisLength/2*cos(the)*si+co*sv2.MinorAxisLength/2*sin(the)+sv2.Centroid(2));
p.Color = 'red';
p.LineWidth = 1.5;

else
end

BWoutline = bwperim(BWfinal);
Segout = Icrop;
Segout(BWoutline) = 255;

if plot_figure==1
figure, imshow(Segout), title('outlined original image');
else
end
%Convert image to bw image using matlab function

%Save the major axis and the minor axis of the fitted ellipse
MajorAxis_a=[MajorAxis_a; sv2.MajorAxisLength/pxtomm];
MinorAxis_a=[MinorAxis_a; sv2.MinorAxisLength/pxtomm];


catch
    
end
end
Pic_name(1:length(MajorAxis_a),1)={file};
%Save data in Excel file (same path as the original image)
T = table(MajorAxis_a,MinorAxis_a,Pic_name)
filename= 'jack.xls';

if exist([path filename], 'file') == 2.
% File exists.
writetable(T,[path 'jack.xls'],'WriteMode','append','WriteVariableNames',false)  
else
% File does not exist.
writetable(T,[path 'jack.xls'])
end
