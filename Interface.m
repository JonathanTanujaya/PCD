function Interface
    close all;

    modelPath = 'trainedKNN_HOG.mat';
    if ~isfile(modelPath)
        errordlg('Model tidak ditemukan. Harap latih model terlebih dahulu.', 'Model Error');
        return;
    end
    load(modelPath, 'mdl');

    guiData = struct();
    guiData.model = mdl;
    guiData.currentImage = [];

    mainFig = figure('Name', 'Digit Classification', ...
        'NumberTitle', 'off', 'MenuBar', 'none', ...
        'Units', 'normalized', 'Position', [0.15 0.15 0.7 0.7], ...
        'Color', [0.95 0.95 0.95], 'DeleteFcn', @(~,~) disp('GUI Closed'));

    guidata(mainFig, guiData);
    guiData = createUI(mainFig, guiData);
    guidata(mainFig, guiData);
end

function guiData = createUI(mainFig, guiData)
    
    ctrlPanel = uipanel('Parent', mainFig, 'Title', 'Controls', ...
        'Units', 'normalized', 'Position', [0.05 0.7 0.25 0.25], ...
        'FontSize', 12, 'FontWeight', 'bold', 'BackgroundColor', [0.9 0.9 0.9]);

    uicontrol(ctrlPanel, 'Style', 'pushbutton', 'String', 'Import Image', ...
        'Units', 'normalized', 'Position', [0.1 0.6 0.8 0.3], ...
        'BackgroundColor', [0.2 0.7 0.9], 'ForegroundColor', 'w', ...
        'FontSize', 14, 'FontWeight', 'bold', 'Callback', @importImageCallback);

    uicontrol(ctrlPanel, 'Style', 'pushbutton', 'String', 'Clear All', ...
        'Units', 'normalized', 'Position', [0.1 0.2 0.8 0.3], ...
        'BackgroundColor', [0.9 0.3 0.3], 'ForegroundColor', 'w', ...
        'FontSize', 14, 'FontWeight', 'bold', 'Callback', @clearAllCallback);

    resultPanel = uipanel('Parent', mainFig, 'Title', 'Results', ...
        'Units', 'normalized', 'Position', [0.05 0.25 0.25 0.4], ...
        'FontSize', 12, 'FontWeight', 'bold', 'BackgroundColor', [0.9 0.9 0.9]);

    guiData.predText = uicontrol(resultPanel, 'Style', 'text', ...
        'String', 'Prediction: -', 'FontSize', 16, 'FontWeight', 'bold', ...
        'Units', 'normalized', 'Position', [0.05 0.85 0.9 0.12], ...
        'BackgroundColor', [0.9 0.9 0.9]);

    guiData.detailText = uicontrol(resultPanel, 'Style', 'text', ...
        'String', 'Top 3 Results:', 'FontSize', 11, 'FontWeight', 'bold', ...
        'Units', 'normalized', 'Position', [0.05 0.75 0.9 0.08], ...
        'BackgroundColor', [0.9 0.9 0.9], 'HorizontalAlignment', 'left');

    guiData.resultsText = uicontrol(resultPanel, 'Style', 'text', ...
        'String', '-', 'FontSize', 10, ...
        'Units', 'normalized', 'Position', [0.05 0.25 0.9 0.5], ...
        'BackgroundColor', [0.9 0.9 0.9], 'HorizontalAlignment', 'left');

    guiData.toggleButton = uicontrol(resultPanel, 'Style', 'pushbutton', ...
        'String', 'Show All Results ▼', 'FontSize', 9, ...
        'Units', 'normalized', 'Position', [0.05 0.05 0.9 0.15], ...
        'BackgroundColor', [0.7 0.7 0.7], 'Callback', @toggleResultsCallback);

    guiData.showAll = false;

    imgPanel = uipanel('Parent', mainFig, 'Title', 'Image Processing', ...
        'Units', 'normalized', 'Position', [0.35 0.05 0.6 0.9], ...
        'FontSize', 12, 'FontWeight', 'bold', 'BackgroundColor', [0.9 0.9 0.9]);

    guiData.axesOriginal = axes('Parent', imgPanel, 'Position', [0.1 0.65 0.35 0.3]);
    title(guiData.axesOriginal, 'Original Image', 'FontSize', 11, 'FontWeight', 'bold');
    
    guiData.axesPreprocessed = axes('Parent', imgPanel, 'Position', [0.55 0.65 0.35 0.3]);
    title(guiData.axesPreprocessed, 'Grayscale', 'FontSize', 11, 'FontWeight', 'bold');
    
    guiData.axesFinal = axes('Parent', imgPanel, 'Position', [0.3 0.25 0.4 0.35]);
    title(guiData.axesFinal, 'Final (28x28)', 'FontSize', 11, 'FontWeight', 'bold');

end

function importImageCallback(~, ~)
    [file, path] = uigetfile({'*.png;*.jpg;*.jpeg;*.bmp;*.tiff'}, 'Select an Image');
    if isequal(file, 0), return; end

    I = imread(fullfile(path, file));
    guiData = guidata(gcf);
    guiData.currentImage = I;
    guidata(gcf, guiData);

    processAndDisplayImage(I);
end

function clearAllCallback(~, ~)
    guiData = guidata(gcf);
    cla(guiData.axesOriginal);
    cla(guiData.axesPreprocessed);
    cla(guiData.axesFinal);
    
    title(guiData.axesOriginal, 'Original Image', 'FontSize', 11, 'FontWeight', 'bold');
    title(guiData.axesPreprocessed, 'Grayscale', 'FontSize', 11, 'FontWeight', 'bold');
    title(guiData.axesFinal, 'Final (28x28)', 'FontSize', 11, 'FontWeight', 'bold');

    set(guiData.predText, 'String', 'Prediction: -');
    set(guiData.detailText, 'String', 'Top 3 Results:');
    set(guiData.resultsText, 'String', '-');
    set(guiData.toggleButton, 'String', 'Show All Results ▼');
    
    guiData.currentImage = [];
    guiData.showAll = false;
    guidata(gcf, guiData);
end

function toggleResultsCallback(~, ~)
    guiData = guidata(gcf);
    guiData.showAll = ~guiData.showAll;
    
    if guiData.showAll
        set(guiData.detailText, 'String', 'All Results:');
        set(guiData.toggleButton, 'String', 'Show Less ▲');
    else
        set(guiData.detailText, 'String', 'Top 3 Results:');
        set(guiData.toggleButton, 'String', 'Show All Results ▼');
    end
    
    guidata(gcf, guiData);
    
    if ~isempty(guiData.currentImage)
        processAndDisplayImage(guiData.currentImage);
    end
end

function processAndDisplayImage(I)
    guiData = guidata(gcf);
    
    if size(I,3) == 3
        I_gray = rgb2gray(I);
    else
        I_gray = I;
    end
    
    I_gray = im2double(I_gray);
    I_final = imresize(I_gray, [28 28]);
    
    imshow(guiData.currentImage, 'Parent', guiData.axesOriginal);
    imshow(I_gray, 'Parent', guiData.axesPreprocessed);
    imshow(I_final, 'Parent', guiData.axesFinal);

    hog = extractHOGFeatures(I_final);
    hog = single(hog);
    
    [label, scores] = predict(guiData.model, hog);
    
    [sortedScores, sortedIndices] = sort(scores, 'descend');
    classLabels = guiData.model.ClassNames;
    
    set(guiData.predText, 'String', sprintf('Prediction: %s', string(label)));
    
    resultsStr = '';
    if guiData.showAll
        validResults = sortedScores >= 0.1;
        numResults = sum(validResults);
    else
        numResults = min(3, length(sortedScores));
    end
    
    for i = 1:numResults
        if guiData.showAll && sortedScores(i) < 0.1
            break;
        end
        confidence = sortedScores(i) * 100;
        digit = classLabels(sortedIndices(i));
        resultsStr = sprintf('%sDigit %s: %.1f%%\n', resultsStr, string(digit), confidence);
    end
    
    set(guiData.resultsText, 'String', resultsStr);
end