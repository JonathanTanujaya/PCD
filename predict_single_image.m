clear; clc;

modelPath = 'trainedKNN_HOG.mat';
if ~isfile(modelPath)
    error('Model KNN tidak ditemukan: %s', modelPath);
end
load(modelPath, 'mdl');

imagePath = 'angka5.png';
if ~isfile(imagePath)
    error('File gambar tidak ditemukan: %s', imagePath);
end

Iorig = imread(imagePath);
Iproc = preprocessImage(Iorig);

hogFeat = extractHOGFeatures(Iproc);
predictedLabel = predict(mdl, hogFeat);
fprintf('%s\n', string(predictedLabel));

function Iout = preprocessImage(I)
    I = imresize(I, [28 28]);
    if size(I, 3) == 3
        I = rgb2gray(I);
    end
    I = im2double(I);
    Iout = I;
end
