function pyrs = makeTexturePyramid(pyrsIntensity)
 %pyrs = makeTexturePyramid(pyrsIntensity);
      pyrs.label = 'Texture';
      pyrs.type = 'dyadic';
      pyrs.origImage = pyrsIntensity.origImage;
for levelnum = 1:length(pyrsIntensity.level);
      levelimg = pyrsIntensity.level(levelnum).data;
      [imageRow,imageCol]=size(levelimg);
      levelimg = [levelimg(1,:);levelimg(1,:);levelimg(1,:);levelimg;levelimg(imageRow,:);levelimg(imageRow,:);levelimg(imageRow,:)];%ͼ���������չ
      levelimg = [levelimg(:,1),levelimg(:,1),levelimg(:,1),levelimg,levelimg(:,imageCol),levelimg(:,imageCol),levelimg(:,imageCol)];%ͼ���������չ
      [imageRowExpand,imageColExpand]=size(levelimg);

%------�Թ�����������������ء����Ծء��ֲ��ȶ��ԡ����5����������-------
    ASM = zeros(imageRow,imageCol);ENT = zeros(imageRow,imageCol);INT = zeros(imageRow,imageCol);
    IDM = zeros(imageRow,imageCol);CON = zeros(imageRow,imageCol);
    for n = 1:4  
    for i=4:imageRowExpand-3
        for j=4:imageColExpand-3 
            glcm = zeros(imageRow,imageCol);
            switch n
                case 1 
                    glcm= graycomatrix(A(i-3:i+3,j-3:j+3),'NumLevels',16,'G',[],'Offset',[0,1]);
                case 2 
                    glcm = graycomatrix(A(i-3:i+3,j-3:j+3),'NumLevels',16,'G',[],'Offset',[-1,1]);
                case 3 
                    glcm = graycomatrix(A(i-3:i+3,j-3:j+3),'NumLevels',16,'G',[],'Offset',[-1,0]);
                case 4 
                    glcm = graycomatrix(A(i-3:i+3,j-3:j+3),'NumLevels',16,'G',[],'Offset',[-1,-1]);
                otherwise
            end
            glcm = glcm/sum(sum(glcm));%��һ��
            ASM(i-3,j-3,n) = sum(sum(glcm^2));%����

            ENTtmp = 0;INTtmp = 0; IDMtmp  =0; 
            CONtmpUX = 0; CONtmpUY = 0;
            for k = 1:16
                for l = 1:16
                    if glcm(k,l)~=0
                    ENTtmp = -glcm(k,l)*log(glcm(k,l))+ENTtmp;
                    end
                    INTtmp = glcm(k,l)*(k-l)^2 + INTtmp;%%%��ʽ�Ƿ���ȷ������
                    IDMtmp = glcm(k,l)/(1+(k-l)^2) + IDMtmp;
                    CONtmpUX = glcm(k,l)*k + CONtmpUX;%������е�ux
                    CONtmpUY = glcm(k,l)*l + CONtmpUY;%������е�uy
                end 
            end
            CONtmpSX = 0; CONtmpSY = 0;CONtmpKLP = 0;
            for k = 1:16
                for l = 1:16
                    CONtmpSX = glcm(k,l)*(k-CONtmpUX)^2 + CONtmpSX;%������е�x���򷽲�
                    CONtmpSY = glcm(k,l)*(l-CONtmpUY)^2 + CONtmpSY;%������е�y���򷽲�
                    CONtmpKLP = k*l*glcm(k,l) + CONtmpKLP;
                end
            end
            ENT(i-3,j-3,n) = ENTtmp;%��
            INT(i-3,j-3,n) = INTtmp;%���Ծ�
            IDM(i-3,j-3,n) = IDMtmp;%�ֲ��ȶ���
            CON(i-3,j-3,n) = (CONtmpKLP-CONtmpUX*CONtmpUY)/(CONtmpSX*CONtmpSY);
        end
    end
    end
%------���ĸ�����������ľ�ֵΪ����������������յ�ֵ------
    ASMmean = zeros(imageRow,imageCol);
    ENTmean = zeros(imageRow,imageCol);
    INTmean = zeros(imageRow,imageCol);
    IDMmean = zeros(imageRow,imageCol);
    CONmean = zeros(imageRow,imageCol);
    ASMtmp = 0; ENTtmp = 0;INTtmp = 0; IDMtmp  =0; CONtmp = 0;
    for i=1:imageRow
        for j=1:imageCol
            for n = 1:4
                ASMtmp = ASM(i,j,n) + ASMtmp;
                ENTtmp = ENT(i,j,n) + ENTtmp;
                INTtmp = INT(i,j,n) + INTtmp;
                IDMtmp = IDM(i,j,n) + IDMtmp;
                CONtmp = CON(i,j,n) + CONtmp;
            end
            ASMmean(i,j) = ASMtmp/4;
            ENTmean(i,j) = ENTtmp/4;
            INTmean(i,j) = INTtmp/4;
            IDMmean(i,j) = IDMtmp/4;
            CONmean(i,j) = CONtmp/4;
        end
    end
    PCAImage = [reshape(ASMmean,imageRow*imageCol,1),reshape(ENTmean,imageRow*imageCol,1),...
        reshape(INTmean,imageRow*imageCol,1),reshape(IDMmean,imageRow*imageCol,1),...
        reshape(CONmean,imageRow*imageCol,1)];
    %������ʽ������ôдPCAImage =
    %[ASMmean(:),ENTmean(:),INTmean(:),IDMmean(:),CONmean(:)];
    [COEFF,SCORE,LATENT] = princomp(double(PCAImage));
    SCORE = SCORE(:,1:3);%ȡ5������������ǰ3������------��һ���Ƿ����ʡ��
    
 %------PCA����и�ֵ���֣����Զ�ÿһ�м�ÿһ���������� �ֱ��һ����0-255��Χ
 %Ҫ��һ����0-255�����������
    %ÿ�м�ȥ�Լ�������Сֵ
    minM =[ min(SCORE(:,1),1),min(SCORE(:,2),1),min(SCORE(:,3),1)];
    maxM = [max(SCORE(:,1),1),max(SCORE(:,2),1), max(SCORE(:,3),1)];

    SCORE(:,1) = bsxfun(@minus,SCORE(:,1),minM(1));
    SCORE(:,2) = bsxfun(@minus,SCORE(:,2),minM(2));
    SCORE(:,3) = bsxfun(@minus,SCORE(:,3),minM(3));
    %���������ۺ�Ϊ��SCORE = bsxfun(@minus,SCORE,minM);
    %��һ������
    SCORE(:,1) = 255*bsxfun(@rdivide,SCORE(:,1), maxM(1)-minM(1));
    SCORE(:,2) = 255*bsxfun(@rdivide,SCORE(:,2), maxM(2)-minM(2));
    SCORE(:,3) = 255*bsxfun(@rdivide,SCORE(:,3), maxM(3)-minM(3));
    
 %----------��3�����������ϳ�Ϊһ����������ͼ-------
    TextureMap = mean(SCORE,2);%��3�����������ľ�ֵ���ϳ�һ������ͼ��
    map.data = reshape(TextureMap,iamgeRow,imageCol);
    map.date = clock;
    map.label = sprintf('Texture-%d',levelnum);%pyrs�Ľṹ
    map.origImage = pyrsIntensity.origImage;
    map.parameters.type = 'dyadic';
    pyrs.level(levelnum) = map;
end     
      pyrs.date = clock;
      