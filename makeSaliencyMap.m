% makeSaliencyMap - creates a saliency map for an image.
%
% [salmap, saliencyData] = makeSaliencyMap(img, salParams, varargin)
%    Creates a saliency map for img according to salParams.
%       img: Image structure for the input image.
%       salParams: the saliency parameters structure
%       varargin: additional data needed by individual channels.
%          Currently, varargin may hold a vector of auxiliary pyramids
%          used for TopDown attention.
%
%       salmap: a map structure containing the saliency map
%       saliencyData: a vector of structures for each feature with 
%                     additional information with the fields:
%          origImage: Image structure of the input image.
%          label: the feature name.
%          pyr: a vector of pyramids for this feature.
%          FM: a vector of feature maps.
%          csLevels: the center and surround levels used to
%                    compute the feature maps.
%          CM: the conspicuity map for this feature.
%          date: the time and date when this structure was created.
%
% See also runSaliency, batchSaliency, estimateShape, defaultSaliencyParams, 
%          initializeImage, dataStructures.

% This file is part of the SaliencyToolbox - Copyright (C) 2006-2013
% by Dirk B. Walther and the California Institute of Technology.
% See the enclosed LICENSE.TXT document for the license agreement. 
% More information about this project is available at: 
% http://www.saliencytoolbox.net

function [salmap, saliencyData] = makeSaliencyMap(img, salParams, varargin)

% ensure that salParams.features is a cell array
if ischar(salParams.features)
  salParams.features = {salParam.features};
end
numFeat = length(salParams.features);

% loop over all requested features
for f = 1:numFeat
  saliencyData(f).origImage = img;
  saliencyData(f).label = salParams.features{f};
  
  if (strcmp('Orientation',salParams.features{f}))   
     
    % for orientation computation, see if we already have an 
    % intensity pyramid that we can borrow to make things faster
    idx = strmatch('Intensity',{saliencyData(1:f-1).label});
    if isempty(idx)
      % found no intensity pyramid
      saliencyData(f).pyr = makeFeaturePyramids(img,salParams.features{f},...
                              salParams)
    else
      % found an intensity pyramid - hand it over to be used for orientation filtering
      saliencyData(f).pyr = makeFeaturePyramids(img,salParams.features{f},...
                              salParams,saliencyData(idx(1)).pyr(1));
    end
  else

    % for all other features: call with the auxiliary data in varargin
    saliencyData(f).pyr = makeFeaturePyramids(img,salParams.features{f},salParams,varargin{:});
  end
  
  combFM = [];
  numPyr = length(saliencyData(f).pyr);
  
  % center-surround contrasts for all pyramids
  for p = 1:numPyr
    if (strcmp('TopDown',salParams.features{f}))
      
      % special version of centerSurround for TopDown
      [FM,csLevels] = centerSurroundTopDown(saliencyData(f).pyr(p),salParams);
    else
      
      % Plain vanilla version for everything else
      [FM,csLevels] = centerSurround(saliencyData(f).pyr(p),salParams);
    end
    
    saliencyData(f).FM(p,:) = maxNormalize(FM,salParams,[0,10]);%归一化第p个pyr中的所有中央周边差图
    saliencyData(f).csLevels(p,:) = csLevels;
    
    % combine the feature maps over all scales
    combFM = [combFM combineMaps(saliencyData(f).FM(p,:),...
                                 [salParams.features{f} 'CM'])];
    %将第p个pyr里面的中央周边差图合并到combFM中，即方向特征的一个子方向的中央周边差合成图
    %日后循环的效果是：若一个Feat只有一个pyr，像灰度，那么这句是将6个不同scale的中央周边差图放在一个变量里面，即combFM
    %日后循环的效果是：若一个Faet有多个pyr，像方向（颜色）有4个pyr，那么combFM是一个4个元素的行向量，
    %每个元素是一个pyr，即一个子特征的中央周边差合成图
  end
  
  % normalize the combined feature maps 
  combFM = maxNormalize(combFM,salParams,[0,0]);
  %归一化一个Feat的所有pyr，即所有子特征的 中央周边差合成图
  
  % compute conspicuity maps over all sub-features
  if (numPyr == 1)
    saliencyData(f).CM = combFM;
  else
    % more than 1 sub-feature: additional normalization step
    saliencyData(f).CM = maxNormalize(combineMaps(combFM,[salParams.features{f} 'CM']),...
                                      salParams,[0,0]);
     %将一个Feat的所有子特征的特征图合并。
  end
    
  % weigh the conspicuity map appropriately
  saliencyData(f).CM.data = salParams.weights(f) * saliencyData(f).CM.data / numPyr / numFeat;  
  saliencyData(f).date = clock;
end % end loop over features

% compute the saliency map by combining all the conspicuity maps
salmap = combineMaps([saliencyData.CM],'SaliencyMap');
salmap = maxNormalize(salmap,salParams,[0,2]);
salmap.parameters = salParams;
