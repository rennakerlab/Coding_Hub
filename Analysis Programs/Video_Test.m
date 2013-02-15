function Video_Test

disp(imaqhwinfo);                                                           %Display the video adapters installed on this computer.

%Assuming 'winvideo' is one of the adapters installed...
vid = videoinput('winvideo',1,'RGB24_320x240');                             %Create a video input object.
preview(vid);
figure;                                                                     %Create another figure to show processed frames from the video feed.
tic;                                                                        %Start a timer.
while toc < 30                                                              %Loop for 30 seconds.
    frame = getsnapshot(vid);                                               %Grab a single frame from the video feed.
    im = sum(frame,3);                                                      %Collapse the RGB frame into a grayscale/monoscale 2-D matrix by summing the RGB values.
    
%     subplot(2,2,1);                                                         %In the top left plot...
%     imagesc(im);                                                            %Show the monochrome image.
%     title('Monochrome');                                                    %Show a title for the image.
%     colormap(gray);
    
%     subplot(2,2,2);                                                         %In the top right plot...
%     imagesc(1./im);                                                         %Show the reciprocal monochrome image.
%     title('Reciprocal');                                                    %Show a title for the image.
%     colormap(hsv);
    
    im = boxsmooth(im,[5,5]);                                               %Smooth the image with a 5-by-5 boxsmooth.
%     subplot(2,2,3);                                                         %In the bottom left plot...
%     imagesc(im);                                                            %Show the smoothed image.
%     title('Smoothed 5-by-5 pixels');                                        %Show a title for the image.
%     colormap(jet);
    
    contrast_threshold = 765/2;                                             %Set a threshold for applying maximum contrast.
    im(im < contrast_threshold) = 0;                                        %Set all pixels below the threshold to zero.
    im(im > contrast_threshold) = 1;                                        %Set all pixels below the threshold to one.
%     subplot(2,2,4);                                                         %In the bottom right plot...
    imagesc(im);                                                            %Show the maximum-contrast image.
%     title('Smoothed, Maximum Contrast');                                    %Show a title for the image.
    colormap(gray);                                                         %Set the colormap to "gray" or whichever you like (i.e. "jet", "summer", "hsv", etc.).
    drawnow;                                                                %Make the figure display the image before executing the next loop.
end

closepreview(vid);                                                          %Close the video preview figure.
delete(vid);                                                                %Delete the video input object.