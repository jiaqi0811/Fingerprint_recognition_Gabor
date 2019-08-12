function [Outputprint,XofCenter,YofCenter] = centralizing(fingerprint,ctrl)
%中心化，滤波器需要
global immagine n_bands h_bands n_arcs h_radius h_lato n_sectors matrice filterpic

x=[-16:1:16];
y=[-16:1:16];
dimx=size(x,2);%33
dimy=size(y,2);%33
% 滤波器参数
varianza=sqrt(55);
ordine=1;
gamma=2;
filtro_core=zeros(dimx,dimy);
filtro_delta=zeros(dimx,dimy);
for ii=1:dimx
    for jj=1:dimy
        esponente=exp(-(x(ii)^2+y(jj)^2)/(2*varianza^2));
        fattore=x(ii)+i*y(jj);
        filtro_core(ii,jj)=esponente*fattore^ordine;           
        fattore=x(ii)-i*y(jj);
        filtro_delta(ii,jj)=esponente*fattore^ordine;
    end
end
%------------------------------------
%------------高斯低通滤波器-----------
%------------------------------------
x=[-16:1:16];
y=[-16:1:16];
dimx=size(x,2);
dimy=size(y,2);
varianza=sqrt(1.2);
filtro=zeros(dimx,dimy);
for ii=1:dimx
    for jj=1:dimy
        esponente=exp(-(x(ii)^2+y(jj)^2)/(2*varianza^2));
        filtro(ii,jj)=esponente;
    end
end
% 归一化
filtro=filtro/sum(sum(filtro)); 
%------------------------------------
img=fingerprint;
img=double(img);
%------------------------------------
[gx,gy]=gradient(img); %差分图
num=(gx+i*gy).^2;
den=abs((gx+i*gy).^2);
pos=find(den);
num(pos)=num(pos)./den(pos);
z=zeros(size(img,1),size(img,2));
z(pos)=num(pos);
pos=find(den==0);
z(pos)=1;%找点

filterpic=z;
%imshow(z)
angle=0;        
bxv=8;       
byv=8;
bxc=64;        
byc=64;
soglia_var=20;  
dimseclose=10;  % 闭运算
dimseerode=44;  % 腐蚀
maxcore=200;    % 扫描中的最大特征点数
[dimx,dimy]=size(fingerprint);%dimx dimy分别为图像的宽度和高度
%---------------------------
temp=z;%找点
[temp,dimxt,dimyt]=mirror(temp);
z_f=conv2fft(temp,filtro_core,'same');
z_f=recrop(z_f,dimxt,dimyt);
z_f=abs(z_f);


%---------------------------
%----------------------------
% resize-------------------- 
imgd=double(fingerprint);
dimxr=dimx-mod(dimx,bxv);
dimyr=dimy-mod(dimy,byv);
imgr=imgd(1:dimxr,1:dimyr);
%---------------------------
nbx=dimxr/bxv;
nby=dimyr/byv;
mat_var=zeros(dimxr,dimyr);
for ii=1:nbx
    for jj=1:nby
        blocco=imgr((ii-1)*bxv+1:ii*bxv,(jj-1)*byv+1:jj*byv);
        media=sum(sum(blocco))/(bxv*byv);
        varianza=1/(bxv*byv)*sum(sum(abs(media.^2-blocco.^2)));
        mat_var((ii-1)*bxv+1:ii*bxv,(jj-1)*byv+1:jj*byv)=sqrt(varianza);
    end
end
mat_ok=zeros(dimxr,dimyr);
pos=find(mat_var>soglia_var);
mat_ok(pos)=1;
mat_ok(dimx,dimy)=0;
mat_ok=imclose(mat_ok,ones(dimseclose));
mat_ok=imerode(mat_ok,ones(dimseerode));

%--------------------------------------------------------------------------
dimxr=dimx-mod(dimx,bxc);
dimyr=dimy-mod(dimy,byc);
imgr=imgd(1:dimxr,1:dimyr);
matrice_finale=z_f.*mat_ok;
%--------------------------------------------------------------------------
[massimo_vettore,posizione_vettore]=max(matrice_finale);
[massimo,posizione]=max(massimo_vettore);
y_max=posizione;
x_max=posizione_vettore(posizione);

XofCenter=y_max;
YofCenter=x_max;
Outputprint=zeros(50);
