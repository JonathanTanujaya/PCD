clear; clc;

load('trainedKNN_HOG.mat');

imagePath = 'angka8.png';
if ~isfile(imagePath)
    error('File gambar tidak ditemukan: %s', imagePath);
end

I = imread(imagePath);
I = imresize(I, [28 28]);
if size(I,3) == 3
    I = rgb2gray(I);
end

hogFeat = extractHOGFeatures(I);

predictedLabel = predict(mdl, hogFeat);

fprintf('Prediksi label gambar: %s\n', string(predictedLabel));

imshow(I);
title(['Prediksi: ', char(predictedLabel)]);
