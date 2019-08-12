 % 输入为 256 x 256 image 8-bit grayscale
clear;
clc;
close all;
global immagine n_bands h_bands n_arcs h_radius h_lato n_sectors matrice num_disk filterpic 


n_bands=4;
h_bands=20;
n_arcs=16;
h_radius=12;
h_lato=h_radius+(n_bands*h_bands*2)+16;
if mod(h_lato,2)==0
    h_lato=h_lato-1;
end
n_sectors=n_bands*n_arcs;
matrice=zeros(h_lato);
for ii=1:(h_lato*h_lato)
    matrice(ii)=whichsector(ii);
end
num_disk=8;
% 1--> 添加数据库
% 0--> 识别
%ok=0;
chos=0;
possibility=5;

%messaggio='Insert the number of set: each set determins a class. This set should include a number of images for each person, with some variations in expression and in the lighting.';
while chos~=possibility,
    chos=menu('指纹识别系统','选择图片添加至数据库','选择图片进行指纹识别','删除数据库',...
       'Garbor滤波器','退出'); %'指纹图片显示'
    %--------------------------------------------------------------------------
    %--------------------------------------------------------------------------
    %--------------------------------------------------------------------------
    % 计算指纹特征值并添加至数据库
    if chos==1
        clc;
        close all;
        selezionato=0;
        while selezionato==0
            [namefile,pathname]=uigetfile({'*.bmp;*.tif;*.tiff;*.jpg;*.jpeg;*.gif','IMAGE Files (*.bmp,*.tif,*.tiff,*.jpg,*.jpeg,*.gif)'},'Chose GrayScale Image');
            if namefile~=0
                [img,map]=imread(strcat(pathname,namefile));
                selezionato=1;
            else
              disp('请选择灰度图像');
            end
        end
        
        immagine=double(img);%图片加载
        
        if isa(img,'uint8') %判断灰度图像的位数
            graylevmax=2^8-1;
        end
        if isa(img,'uint16') %判断灰度图像的位数
            graylevmax=2^16-1;
        end
        if isa(img,'uint32') %判断灰度图像的位数
            graylevmax=2^32-1;
        end
        
        
        fingerprint = immagine;%指纹图像 
        
        N=h_lato;
        
        [BinarizedPrint,XofCenter,YofCenter]=centralizing(fingerprint,0);
        [CroppedPrint]=cropping(XofCenter,YofCenter,fingerprint);%裁剪
        
        figure('name','加载图像信息');
        subplot(131)
        imshow(img);
        title('原始指纹图片')
        subplot(132)
        imshow(CroppedPrint);
        title('二值指纹裁剪图片')
        subplot(133)
        imshow(filterpic);
        title('滤波后图片')
        [NormalizedPrint,vector]=sector_norm(CroppedPrint,0);%归一化
        
        for (angle=0:1:num_disk-1)  %num_dist 8  
            gabor=gabor2d_sub(angle,num_disk);
            ComponentPrint=conv2fft(NormalizedPrint,gabor,'same');%garbor滤波
            [disk,vector]=sector_norm(ComponentPrint,1);    
            finger_code1{angle+1}=vector(1:n_sectors);%提取特征
        end
        
        img=imrotate(img,180/(num_disk*2));%旋转
        fingerprint=double(img);
        
        [BinarizedPrint,XofCenter,YofCenter]=centralizing(fingerprint,0);
        [CroppedPrint]=cropping(XofCenter,YofCenter,fingerprint);
        [NormalizedPrint,vector]=sector_norm(CroppedPrint,0);
        
        for (angle=0:1:num_disk-1)    
            gabor=gabor2d_sub(angle,num_disk);
            ComponentPrint=conv2fft(NormalizedPrint,gabor,'same');%garbor滤波
            [disk,vector]=sector_norm(ComponentPrint,1);    
            finger_code2{angle+1}=vector(1:n_sectors);%提取特征
        end
        % 加载指纹数据至数据库
        if (exist('fp_database.dat')==2)%已存在
            load('fp_database.dat','-mat');
            fp_number=fp_number+1;
            data{fp_number,1}=finger_code1;%保存新数据
            data{fp_number,2}=finger_code2;%保存新数据
            save('fp_database.dat','data','fp_number','-append');
        else
            fp_number=1;
            data{fp_number,1}=finger_code1;
            data{fp_number,2}=finger_code2;
            save('fp_database.dat','data','fp_number');
        end
        
        message=strcat('指纹数据加载，编号为',num2str(fp_number));
        msgbox(message,'指纹数据库');
    end
    %--------------------------------------------------------------------------
    %--------------------------------------------------------------------------
    %--------------------------------------------------------------------------
    % 指纹识别
    if chos==2
        clc;
        close all;
        selezionato=0;
        while selezionato==0 %读取文件
            [namefile,pathname]=uigetfile({'*.bmp;*.tif;*.tiff;*.jpg;*.jpeg;*.gif','IMAGE Files (*.bmp,*.tif,*.tiff,*.jpg,*.jpeg,*.gif)'},'Chose GrayScale Image');
            if namefile~=0
                [img,map]=imread(strcat(pathname,namefile));
                selezionato=1;
            else
                disp('选择灰度图片');
            end
        end
        
        immagine=double(img);
        
        if isa(img,'uint8')
            graylevmax=2^8-1;
        end
        if isa(img,'uint16')
            graylevmax=2^16-1;
        end
        if isa(img,'uint32')
            graylevmax=2^32-1;
        end
        
        fingerprint = immagine;
        
        N=h_lato;
        
        [BinarizedPrint,XofCenter,YofCenter]=centralizing(fingerprint,0);%中心化
        [CroppedPrint]=cropping(XofCenter,YofCenter,fingerprint);%裁剪
        [NormalizedPrint,vector]=sector_norm(CroppedPrint,0);%归一化
        
        figure('Name','匹配图像信息');
        subplot(131)
        imshow(img);
        title('匹配指纹图片')
        subplot(132)
        imshow(CroppedPrint);
        title('二值指纹裁剪图片')
        subplot(133)
        imshow(filterpic);
        title('滤波后图片')
        
        vettore_in=zeros(num_disk*n_sectors,1);
        for (angle=0:1:num_disk-1)    
            gabor=gabor2d_sub(angle,num_disk);
            ComponentPrint=conv2fft(NormalizedPrint,gabor,'same');
            [disk,vector]=sector_norm(ComponentPrint,1);    
            finger_code{angle+1}=vector(1:n_sectors);
            vettore_in(angle*n_sectors+1:(angle+1)*n_sectors)=finger_code{angle+1};
        end
        
        if (exist('fp_database.dat')==2)
            load('fp_database.dat','-mat');
    %--------------------------------------------------------------------------
    %--------------------------------------------------------------------------
    %--------------------------------------------------------------------------
    % 开始匹配
            vettore_a=zeros(num_disk*n_sectors,1);
            vettore_b=zeros(num_disk*n_sectors,1);
            best_matching=zeros(fp_number,1);
            valori_rotazione=zeros(n_arcs,1);
            for scanning=1:fp_number
                fcode1=data{scanning,1};
                fcode2=data{scanning,2};
                for rotazione=0:(n_arcs-1)
                    p1=fcode1;
                    p2=fcode2;

                    for conta_disco=1:num_disk
                        disco1=p1{conta_disco};
                        disco2=p2{conta_disco};
                        for old_pos=1:n_arcs
                            new_pos=mod(old_pos+rotazione,n_arcs);
                            if new_pos==0
                                new_pos=n_arcs;
                            end
                            for conta_bande=0:1:(n_bands-1)
                                disco1r(new_pos+conta_bande*n_arcs)=disco1(old_pos+conta_bande*n_arcs);
                                disco2r(new_pos+conta_bande*n_arcs)=disco2(old_pos+conta_bande*n_arcs);
                            end
                        end
                        p1{conta_disco}=disco1r;
                        p2{conta_disco}=disco2r;
                    end
     
                    for old_disk=1:num_disk
                        new_disk=mod(old_disk+rotazione,num_disk);
                        if new_disk==0
                            new_disk=num_disk;
                        end
                        pos=old_disk-1;
                        vettore_a(pos*n_sectors+1:(pos+1)*n_sectors)=p1{new_disk};
                        vettore_b(pos*n_sectors+1:(pos+1)*n_sectors)=p2{new_disk};                    
                    end
                    d1=norm(vettore_a-vettore_in);
                    d2=norm(vettore_b-vettore_in);
                    if d1<d2
                        val_minimo=d1;
                    else
                        val_minimo=d2;
                    end
                    valori_rotazione(rotazione+1)=val_minimo;
                end
                [minimo,posizione_minimo]=min(valori_rotazione);
                best_matching(scanning)=minimo;
            end
            [distanza_minima,posizione_minimo]=min(best_matching);
            beep;
            message=strcat('数据库中匹配度最高的指纹数据为:',num2str(posizione_minimo),...
                ' 欧氏距离为: ',num2str(distanza_minima));
            msgbox(message,'匹配数据结果');%,'help
            
        else
            message='数据库为空，无法查询.';
            msgbox(message,'指纹数据库出现错误');    
        end
        
    end 
    
    if chos==3
        clc;
        close all;
        if (exist('fp_database.dat')==2)
            button = questdlg('是否要移除指纹数据库?');
            if strcmp(button,'是')
                delete('fp_database.dat');
                msgbox('指纹数据已被移除.','Database removed','help');
            end
        else
            warndlg('指纹数据为空.',' 警告 ')
        end
    end % fine caso 4

    if chos==4
        clc;
        close all;
        figure('name','Gabor滤波器');
        mesh(gabor2d_sub(0,num_disk));
    end % fine caso 6
end % fine while