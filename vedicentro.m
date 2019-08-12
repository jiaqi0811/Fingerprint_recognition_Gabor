
a=imread('101_1.tif');
a=imrotate(a,-20);
img=double(a);
[out,xc,yc]=centralizing(img,0);
figure('Name','immagine');
imshow(a);
hold on;
plot(xc,yc,'O');
hold off;

