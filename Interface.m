function Interface
    close all;

    % Load Model
    modelPath = 'trainedKNN_HOG.mat';
    if ~isfile(modelPath)
        errordlg('Model tidak ditemukan. Harap latih model terlebih dahulu.', 'Model Error');
        return;
    end
    load(modelPath, 'mdl');

    % Data struktur awal
    guiData = struct();
    guiData.model = mdl;
    guiData.currentImage = [];
    guiData.hogFeatures = [];

    % === Main Figure ===
    mainFig = figure('Name', 'Digit Classification (HOG + KNN)', ...
        'NumberTitle', 'off', 'MenuBar', 'none', ...
        'Units', 'normalized', 'Position', [0.1 0.1 0.8 0.8], ...
        'Color', [1 1 1], 'DeleteFcn', @(~,~) disp('GUI Closed'));

    % Simpan guiData
    guidata(mainFig, guiData);

    % === UI PANEL ===
    guiData = createUI(mainFig, guiData);

    % Simpan ulang
    guidata(mainFig, guiData);
end

function guiData = createUI(mainFig, guiData)
    %% Panel Kiri - Control Panel
    ctrlPanel = uipanel('Parent', mainFig, 'Title', 'Control Panel', ...
        'Units', 'normalized', 'Position', [0.02 0.6 0.25 0.35], ...
        'FontSize', 10, 'FontWeight', 'bold');

    uicontrol(ctrlPanel, 'Style', 'pushbutton', 'String', 'Import Image', ...
        'Units', 'normalized', 'Position', [0.1 0.7 0.8 0.2], ...
        'BackgroundColor', [0.2 0.6 0.8], 'ForegroundColor', 'w', ...
        'FontSize', 12, 'Callback', @importImageCallback);

    uicontrol(ctrlPanel, 'Style', 'pushbutton', 'String', 'Clear All', ...
        'Units', 'normalized', 'Position', [0.1 0.4 0.8 0.2], ...
        'BackgroundColor', [0.8 0.2 0.2], 'ForegroundColor', 'w', ...
        'FontSize', 12, 'Callback', @clearAllCallback);

    %% Panel Preprocessing
    prePanel = uipanel('Parent', mainFig, 'Title', 'Preprocessing Options', ...
        'Units', 'normalized', 'Position', [0.02 0.2 0.25 0.38]);

    uicontrol(prePanel, 'Style', 'text', 'String', 'Resize to:', ...
        'Units', 'normalized', 'Position', [0.1 0.85 0.8 0.1], ...
        'HorizontalAlignment', 'left');

    guiData.sizePopup = uicontrol(prePanel, 'Style', 'popupmenu', ...
        'String', {'28x28', '32x32', '64x64', '128x128'}, ...
        'Units', 'normalized', 'Position', [0.1 0.75 0.8 0.08]);

    guiData.contrastCheck = uicontrol(prePanel, 'Style', 'checkbox', ...
        'String', 'Enhance Contrast', 'Units', 'normalized', ...
        'Position', [0.1 0.6 0.8 0.1]);

    guiData.noiseCheck = uicontrol(prePanel, 'Style', 'checkbox', ...
        'String', 'Noise Reduction', 'Units', 'normalized', ...
        'Position', [0.1 0.48 0.8 0.1]);

    guiData.edgeCheck = uicontrol(prePanel, 'Style', 'checkbox', ...
        'String', 'Edge Enhancement', 'Units', 'normalized', ...
        'Position', [0.1 0.36 0.8 0.1]);

    uicontrol(prePanel, 'Style', 'pushbutton', ...
        'String', 'Apply Preprocessing', 'FontSize', 11, ...
        'Units', 'normalized', 'Position', [0.1 0.1 0.8 0.15], ...
        'BackgroundColor', [0.6 0.8 0.2], ...
        'Callback', @reprocessCurrentImage);

    %% Panel Tampilan Gambar
    imgPanel = uipanel('Parent', mainFig, 'Title', 'Image View & Prediction', ...
        'Units', 'normalized', 'Position', [0.3 0.05 0.68 0.9]);

    guiData.axesOriginal     = axes('Parent', imgPanel, 'Position', [0.05 0.7 0.25 0.25]);
    guiData.axesPreprocessed = axes('Parent', imgPanel, 'Position', [0.35 0.7 0.25 0.25]);
    guiData.axesGrayscale    = axes('Parent', imgPanel, 'Position', [0.65 0.7 0.25 0.25]);
    guiData.axesHOG          = axes('Parent', imgPanel, 'Position', [0.05 0.35 0.25 0.25]);

    guiData.predText = uicontrol(imgPanel, 'Style', 'text', ...
        'String', 'Prediction: -', 'FontSize', 18, 'FontWeight', 'bold', ...
        'Units', 'normalized', 'Position', [0.4 0.45 0.4 0.1]);

    guiData.confText = uicontrol(imgPanel, 'Style', 'text', ...
        'String', 'Confidence: -', 'FontSize', 14, ...
        'Units', 'normalized', 'Position', [0.4 0.4 0.4 0.08]);

    guiData.featureStats = uicontrol(imgPanel, 'Style', 'text', ...
        'String', 'Feature Stats will appear here...', ...
        'HorizontalAlignment', 'left', ...
        'Units', 'normalized', 'Position', [0.05 0.02 0.9 0.3]);
end

%% === Callback & Helper ===
function importImageCallback(~, ~)
    [file, path] = uigetfile({'*.png;*.jpg;*.bmp'}, 'Select an Image');
    if isequal(file, 0), return; end

    I = imread(fullfile(path, file));
    guiData = guidata(gcf);
    guiData.currentImage = I;
    guidata(gcf, guiData);

    processAndDisplayImage(I, 'User Image');
end

function clearAllCallback(~, ~)
    guiData = guidata(gcf);
    cla(guiData.axesOriginal);     title(guiData.axesOriginal, 'Original');
    cla(guiData.axesPreprocessed); title(guiData.axesPreprocessed, 'Preprocessed');
    cla(guiData.axesGrayscale);    title(guiData.axesGrayscale, '28x28');
    cla(guiData.axesHOG);          title(guiData.axesHOG, 'HOG');

    set(guiData.predText, 'String', 'Prediction: -');
    set(guiData.confText, 'String', 'Confidence: -');
    set(guiData.featureStats, 'String', 'Feature Stats will appear here...');
end

function reprocessCurrentImage(~, ~)
    guiData = guidata(gcf);
    if ~isempty(guiData.currentImage)
        processAndDisplayImage(guiData.currentImage, 'Updated Image');
    end
end

function processAndDisplayImage(I, ~)
    guiData = guidata(gcf);
    
    % Resize size
    sizes = [28, 32, 64, 128];
    resizeVal = sizes(get(guiData.sizePopup, 'Value'));

    % Grayscale
    if size(I,3) == 3
        I = rgb2gray(I);
    end
    I = im2double(imresize(I, [resizeVal resizeVal]));

    if get(guiData.contrastCheck, 'Value')
        I = adapthisteq(I);
    end
    if get(guiData.noiseCheck, 'Value')
        I = wiener2(I, [3 3]);
    end
    if get(guiData.edgeCheck, 'Value')
        I = imfilter(I, fspecial('unsharp'));
    end

    % Resize ke 28x28 untuk HOG
    I28 = imresize(I, [28 28]);
    hog = extractHOGFeatures(I28);

    % Tampilkan gambar
    imshow(guiData.currentImage, 'Parent', guiData.axesOriginal);
    title(guiData.axesOriginal, 'Original');

    imshow(I, 'Parent', guiData.axesPreprocessed);
    title(guiData.axesPreprocessed, 'Preprocessed');

    imshow(I28, 'Parent', guiData.axesGrayscale);
    title(guiData.axesGrayscale, 'Final (28x28)');

    try
        [~, vis] = extractHOGFeatures(I28);
        imshow(vis, 'Parent', guiData.axesHOG);
    catch
        imagesc(hog, 'Parent', guiData.axesHOG); title(guiData.axesHOG, 'HOG (raw)');
    end

    % Prediksi
    hog = single(hog);  % MENGHILANGKAN warning pdist2
    [label, score] = predict(guiData.model, hog);

    % Update teks
    set(guiData.predText, 'String', sprintf('Prediction: %s', string(label)));
    set(guiData.confText, 'String', sprintf('Confidence: %.2f%%', max(score) * 100));

    % Statistik fitur
    featTxt = sprintf('HOG dim: %d | mean: %.4f | std: %.4f | max: %.4f', ...
        length(hog), mean(hog), std(hog), max(hog));
    set(guiData.featureStats, 'String', featTxt);
end
