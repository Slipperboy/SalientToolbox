% makeIntensityPyramid - creates an intensity pyramid.
%
% intPyr = makeIntensityPyramid(image,type)
%    Creates an intensity pyramid from image.
%       image: an Image structure for the input image.
%       type: 'dyadic' or 'sqrt2'
%
% See also makeFeaturePyramids, makeGaussianPyramid, dataStructures.

% This file is part of the SaliencyToolbox - Copyright (C) 2006-2013
% by Dirk B. Walther and the California Institute of Technology.
% See the enclosed LICENSE.TXT document for the license agreement. 
% More information about this project is available at: 
% http://www.saliencytoolbox.net

function intPyr = makeIntensityPyramid(image,type)

declareGlobal;

im = loadImage(image);

map.origImage = image;
map.label = 'Intensity';
if(size(im,3)~=3)
    map.data = im;
else
    map.data = rgb2gray(im);
end
map.date = clock;

intPyr = makeGaussianPyramid(map,type);
