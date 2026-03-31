classdef SimpleHisto_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                        matlab.ui.Figure
        DefaultDirectoryLabel           matlab.ui.control.Label
        SelectDefaultDirectoryButton    matlab.ui.control.Button
        TabGroup                        matlab.ui.container.TabGroup
        ImageProcessTab                 matlab.ui.container.Tab
        SaveFormatDropDown              matlab.ui.control.DropDown
        SaveFormatDropDownLabel         matlab.ui.control.Label
        TextArea                        matlab.ui.control.TextArea
        ProcessAndMergeButton           matlab.ui.control.Button
        SaveCompositeButton             matlab.ui.control.Button
        FluorescenceColorDropDown       matlab.ui.control.DropDown
        FluorescenceColorDropDownLabel  matlab.ui.control.Label
        FluorescenceGainSlider          matlab.ui.control.Slider
        FluoresenceIntensitySliderLabel  matlab.ui.control.Label
        FluorescentLowSlider            matlab.ui.control.RangeSlider
        FluorescentContrastSliderLabel  matlab.ui.control.Label
        StatusLabel                     matlab.ui.control.Label
        BrightfieldLowSlider            matlab.ui.control.RangeSlider
        BrightfieldContrastSliderLabel  matlab.ui.control.Label
        ImageSelectionPanel             matlab.ui.container.Panel
        FluorescentLabel                matlab.ui.control.Label
        SelectFluorescentButton         matlab.ui.control.Button
        BrightfieldLabel                matlab.ui.control.Label
        SelectBrightfieldButton         matlab.ui.control.Button
        UIAxesComposite                 matlab.ui.control.UIAxes
        UIAxesFluorescent               matlab.ui.control.UIAxes
        UIAxesBrightfield               matlab.ui.control.UIAxes
        AtlasBrowserTab                 matlab.ui.container.Tab
        SelectedCompositeLabel          matlab.ui.control.Label
        ShowCompositeCheckBox           matlab.ui.control.CheckBox
        SelectCompositeButton           matlab.ui.control.Button
        ResetAlignmentButton            matlab.ui.control.Button
        OverlayRotationSlider           matlab.ui.control.Slider
        OverlayRotationSliderLabel      matlab.ui.control.Label
        SaveOverlayButton               matlab.ui.control.Button
        NextPlateButton                 matlab.ui.control.Button
        PreviousPlateButton             matlab.ui.control.Button
        PlateSpinner                    matlab.ui.control.Spinner
        PlateSpinnerLabel               matlab.ui.control.Label
        OverlayYShiftSlider             matlab.ui.control.Slider
        OverlayYShiftSliderLabel        matlab.ui.control.Label
        OverlayXShiftSlider             matlab.ui.control.Slider
        OverlayXShiftSliderLabel        matlab.ui.control.Label
        OverlayScaleSlider              matlab.ui.control.Slider
        OverlayScaleSliderLabel         matlab.ui.control.Label
        OpacitySlider                   matlab.ui.control.Slider
        OpacitySliderLabel              matlab.ui.control.Label
        LoadAtlasFolderButton           matlab.ui.control.Button
        UIAxesAtlas                     matlab.ui.control.UIAxes
    end

    % Stored data
    properties (Access = private)
        BrightfieldPath   string = ""
        FluorescentPath   string = ""
        CompositeImage    = []
        DefaultDirectory  string = ""

        BrightfieldRaw    = []
        FluorescentRaw    = []
    
    AtlasFolder string = ""
    AtlasFiles struct = struct('name', {}, 'folder', {})
    AtlasImage = []
    AtlasGray = []

    OverlayScale double = 1.0
    OverlayXShift double = 0.0
    OverlayYShift double = 0.0
    OverlayRotation double = 0

SelectedCompositePath string = ""
SelectedCompositeImage = []
ShowComposite logical = true

    end

   

    methods (Access = private)


        % Runs when the app starts
        function startupFcn(app)
            app.DefaultDirectory = string(pwd);

            app.StatusLabel.Text = "Please select a default folder and then choose your images.";
            app.DefaultDirectoryLabel.Text = "Default folder: " + app.DefaultDirectory;
            app.BrightfieldLabel.Text = "Brightfield: (none)";
            app.FluorescentLabel.Text = "Fluorescent: (none)";

            app.ProcessAndMergeButton.Enable = "off";
            app.SaveCompositeButton.Enable = "off";
            cla(app.UIAxesComposite);

          app.SelectedCompositePath = "";
         app.SelectedCompositeImage = [];
         app.ShowComposite = true;
         app.ShowCompositeCheckBox.Value = true;
         app.SelectedCompositeLabel.Text = "Composite: (current image)";

        end
            
 % Enable the process button only when both images are selected
        function updateProcessButtonState(app)
            hasBrightfield = strlength(app.BrightfieldPath) > 0 && isfile(app.BrightfieldPath);
            hasFluorescent = strlength(app.FluorescentPath) > 0 && isfile(app.FluorescentPath);

            if hasBrightfield && hasFluorescent
                app.ProcessAndMergeButton.Enable = "on";
            else
                app.ProcessAndMergeButton.Enable = "off";
            end
        end

        % Open uigetfile in the default folder
        function filePath = selectImageFile(app, dialogTitle)
            if strlength(app.DefaultDirectory) == 0 || ~isfolder(app.DefaultDirectory)
                startFolder = pwd;
            else
                startFolder = char(app.DefaultDirectory);
            end

            [file, path] = uigetfile( ...
                {'*.tif;*.tiff;*.jpg;*.jpeg;*.png;*.bmp', 'Image Files (*.tif, *.tiff, *.jpg, *.jpeg, *.png, *.bmp)'; ...
                 '*.*', 'All Files (*.*)'}, ...
                char(dialogTitle), ...
                startFolder);

            if isequal(file, 0)
                filePath = "";
                return;
            end

            filePath = string(fullfile(path, file));
        end

 % Read image, convert to grayscale if needed, and convert to double
     function img = readAndPrepareImage(~, filePath)
    img = imread(filePath);
    img = squeeze(img);

    % If it is true RGB, convert to grayscale
    if ndims(img) == 3 && size(img, 3) == 3
        img = rgb2gray(img);
    elseif ndims(img) > 2
        % For multi-page / multi-channel TIFFs, keep the first plane
        img = img(:,:,1);
    end

    img = im2double(img);
end

    function imgOut = adjustWithSliderRange(~, imgIn, limits)
    imgIn = im2double(squeeze(imgIn));

    limits = double(limits(:).');
    if numel(limits) ~= 2
        error("Slider limits must be a 2-element vector.");
    end

    lowVal = min(limits(1), limits(2));
    highVal = max(limits(1), limits(2));

    if highVal <= lowVal
        highVal = min(lowVal + 0.01, 1);
    end

    imgOut = (imgIn - lowVal) ./ (highVal - lowVal);
    imgOut = max(0, min(1, imgOut));
end



function refreshDisplays(app)
  if isempty(app.BrightfieldRaw) || isempty(app.FluorescentRaw)
        return;
    end

    % Read contrast ranges from range sliders
    bfLimits = app.BrightfieldLowSlider.Value;
    flLimits = app.FluorescentLowSlider.Value;

    % Adjust each image separately
    brightfieldAdj = app.adjustWithSliderRange(app.BrightfieldRaw, bfLimits);
    fluorescentAdj = app.adjustWithSliderRange(app.FluorescentRaw, flLimits);

    % Match sizes
    if ~isequal(size(brightfieldAdj), size(fluorescentAdj))
        fluorescentAdj = imresize(fluorescentAdj, size(brightfieldAdj));
    end

    % Display brightfield
    cla(app.UIAxesBrightfield);
    imshow(brightfieldAdj, 'Parent', app.UIAxesBrightfield, 'InitialMagnification', 'fit');
    title(app.UIAxesBrightfield, 'Brightfield Image');
    axis(app.UIAxesBrightfield, 'image');

    % Display fluorescent
    cla(app.UIAxesFluorescent);
    imshow(fluorescentAdj, 'Parent', app.UIAxesFluorescent, 'InitialMagnification', 'fit');
    title(app.UIAxesFluorescent, 'Fluorescent Image');
    axis(app.UIAxesFluorescent, 'image');

    % Build composite
    grayBase = brightfieldAdj;
    fluorGain = app.FluorescenceGainSlider.Value;
    fluor = min(1, fluorGain * fluorescentAdj);

    % Start with grayscale background
    R = grayBase;
    G = grayBase;
    B = grayBase;

    switch string(app.FluorescenceColorDropDown.Value)
        case "Green"
            G = min(1, grayBase + fluor);

        case "Yellow"
            R = min(1, grayBase + fluor);
            G = min(1, grayBase + fluor);

        case "Red"
            R = min(1, grayBase + fluor);

        otherwise
            G = min(1, grayBase + fluor);
    end

    app.CompositeImage = cat(3, R, G, B);

    % Display composite
    cla(app.UIAxesComposite);
    imshow(app.CompositeImage, 'Parent', app.UIAxesComposite, 'InitialMagnification', 'fit');
    title(app.UIAxesComposite, 'Composite Image');
    axis(app.UIAxesComposite, 'image');

    app.SaveCompositeButton.Enable = "on";

    if ~isempty(app.AtlasFiles)
    app.renderAtlasOverlay();
end

end


function cropped = trimAtlasPage(~, img)
    if ndims(img) == 3
        imgGray = rgb2gray(img);
    else
        imgGray = img;
    end

    imgGray = im2double(imgGray);

    % Find all non-white pixels
    mask = imgGray < 0.98;

    if ~any(mask(:))
        cropped = img;
        return;
    end

    [r, c] = find(mask);
    r1 = max(min(r) - 20, 1);
    r2 = min(max(r) + 20, size(img,1));
    c1 = max(min(c) - 20, 1);
    c2 = min(max(c) + 20, size(img,2));

    cropped = img(r1:r2, c1:c2, :);
end


function loadAtlasPlate(app, idx)
    if isempty(app.AtlasFiles)
        return;
    end

    idx = round(idx);
    idx = max(1, min(numel(app.AtlasFiles), idx));

    filePath = fullfile(app.AtlasFiles(idx).folder, app.AtlasFiles(idx).name);
    atlasImg = imread(filePath);

    % Optional crop helper
    atlasImg = app.trimAtlasPage(atlasImg);

    app.AtlasImage = atlasImg;

    % Cache grayscale version for fast redraws
    if ndims(atlasImg) == 3 && size(atlasImg, 3) == 3
        app.AtlasGray = im2double(rgb2gray(atlasImg));
    else
        app.AtlasGray = im2double(squeeze(atlasImg));
        if ndims(app.AtlasGray) > 2
            app.AtlasGray = app.AtlasGray(:,:,1);
        end
    end
   
    app.renderAtlasOverlay();
end

function renderAtlasOverlay(app)
    if isempty(app.AtlasGray)
        return;
    end

    atlasGray = app.AtlasGray;

    cla(app.UIAxesAtlas);
    imshow(atlasGray, [], 'Parent', app.UIAxesAtlas, 'InitialMagnification', 'fit');
    hold(app.UIAxesAtlas, 'on');

    % Decide which composite to use
    overlay = [];
    if app.ShowComposite
        if ~isempty(app.SelectedCompositeImage)
            overlay = app.SelectedCompositeImage;
        elseif ~isempty(app.CompositeImage)
            overlay = app.CompositeImage;
        end
    end

    % Draw overlay if available
    if ~isempty(overlay)
        overlay = im2double(overlay);

        % Build alpha mask from fluorescence signal only
        fluorMask = overlay(:,:,2) > 0.08;
        fluorMask = imgaussfilt(double(fluorMask), 1) > 0.2;

        % Alignment controls
        s = app.OverlayScale;
        xShift = app.OverlayXShift;
        yShift = app.OverlayYShift;
        theta = deg2rad(app.OverlayRotation);

        % Composite size
        [hO, wO, ~] = size(overlay);
        cx = (wO + 1) / 2;
        cy = (hO + 1) / 2;

        % Rotate + scale about center, then shift
        a =  s * cos(theta);
        b =  s * sin(theta);
        c = -s * sin(theta);
        d =  s * cos(theta);

        tx = cx - cx * a - cy * c + xShift;
        ty = cy - cx * b - cy * d + yShift;

        tform = affine2d([a b 0; c d 0; tx ty 1]);

        % Output canvas matches atlas plate
        Rout = imref2d(size(atlasGray));

        % Warp overlay and mask onto atlas canvas
        overlay = imwarp(overlay, tform, 'OutputView', Rout, 'FillValues', 0);
        fluorMask = imwarp(double(fluorMask), tform, 'OutputView', Rout, 'FillValues', 0);
        fluorMask = fluorMask > 0.5;

        % Draw overlay
        h = imshow(overlay, 'Parent', app.UIAxesAtlas, 'InitialMagnification', 'fit');
        h.AlphaData = double(fluorMask) * app.OpacitySlider.Value;
    end

    hold(app.UIAxesAtlas, 'off');
    axis(app.UIAxesAtlas, 'image');
    title(app.UIAxesAtlas, sprintf("Atlas Plate %d/%d", app.PlateSpinner.Value, numel(app.AtlasFiles)));
end


%function showAtlasPlate(app, idx)
   % if isempty(app.AtlasFiles)
      %  return;
    %end

    %idx = round(idx);
    %idx = max(1, min(numel(app.AtlasFiles), idx));

    % Load atlas plate
    %filePath = fullfile(app.AtlasFiles(idx).folder, app.AtlasFiles(idx).name);
    %atlasImg = imread(filePath);

    % Optional crop helper if you already added it
    %atlasImg = app.trimAtlasPage(atlasImg);

    % Convert atlas to grayscale for display
   % if ndims(atlasImg) == 3 && size(atlasImg, 3) == 3
      %  atlasGray = im2double(rgb2gray(atlasImg));
   % else
      %  atlasGray = im2double(squeeze(atlasImg));
        %if ndims(atlasGray) > 2
            %atlasGray = atlasGray(:,:,1);
        %end
    %end

    %cla(app.UIAxesAtlas);
    %imshow(atlasGray, [], 'Parent', app.UIAxesAtlas, 'InitialMagnification', 'fit');
    %hold(app.UIAxesAtlas, 'on');

    % Overlay composite if available
%if ~isempty(app.CompositeImage)
   % overlay = im2double(app.CompositeImage);

    % Build an alpha mask that keeps only fluorescent signal visible
    % (works for Green / Yellow / Red composites)
   % dRG = abs(overlay(:,:,1) - overlay(:,:,2));
   % dGB = abs(overlay(:,:,2) - overlay(:,:,3));
   % dRB = abs(overlay(:,:,1) - overlay(:,:,3));
   % alphaMask = max(cat(3, dRG, dGB, dRB), [], 3) > 0.03;

    % Read alignment controls
    %s = app.OverlayScale;
    %xShift = app.OverlayXShift;
    %yShift = app.OverlayYShift;

    % Scale around the center of the overlay image
    %[hO, wO, ~] = size(overlay);
    %cx = (wO + 1) / 2;
    %cy = (hO + 1) / 2;

    % Affine transform: scale about center + translation
    %tform = affine2d([ ...
       % s  0  0; ...
       % 0  s  0; ...
        %(1 - s) * cx + xShift, (1 - s) * cy + yShift, 1]);

    % Output canvas matches atlas plate
   % Rout = imref2d(size(atlasGray));

    % Warp overlay and alpha mask onto atlas canvas
    %overlay = imwarp(overlay, tform, 'OutputView', Rout, 'FillValues', 0);
    %alphaMask = imwarp(double(alphaMask), tform, 'OutputView', Rout, 'FillValues', 0);
    %alphaMask = alphaMask > 0.5;

    % Draw overlay
    %h = imshow(overlay, 'Parent', app.UIAxesAtlas, 'InitialMagnification', 'fit');
    %h.AlphaData = double(alphaMask) * app.OpacitySlider.Value;
    %hold(app.UIAxesAtlas, 'off');
%end
    
   
   % axis(app.UIAxesAtlas, 'image');
   % title(app.UIAxesAtlas, sprintf("Atlas Plate %d/%d", idx, numel(app.AtlasFiles)));
    %app.PlateSlider.Value = idx;
%end



        end
    
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn2(app)
    app.DefaultDirectory = string(pwd);
    app.StatusLabel.Text = "Please select a default folder and then choose your images.";
    app.DefaultDirectoryLabel.Text = "Default folder: " + app.DefaultDirectory;
    app.BrightfieldLabel.Text = "Brightfield: (none)";
    app.FluorescentLabel.Text = "Fluorescent: (none)";
    app.ProcessAndMergeButton.Enable = "off";
    app.SaveCompositeButton.Enable = "off";
    cla(app.UIAxesComposite);

    if nargout == 0
        clear app
    end

        end

        % Button pushed function: SelectDefaultDirectoryButton
        function SelectDefaultDirectoryButtonPushed(app, event)
             if strlength(app.DefaultDirectory) == 0 || ~isfolder(app.DefaultDirectory)
                startFolder = pwd;
            else
                startFolder = char(app.DefaultDirectory);
            end

            folder = uigetdir(startFolder, "Select Default Image Folder");

            if isequal(folder, 0)
                app.StatusLabel.Text = "Default folder selection cancelled.";
                return;
            end

            app.DefaultDirectory = string(folder);
            app.DefaultDirectoryLabel.Text = "Default folder: " + app.DefaultDirectory;
            app.StatusLabel.Text = "Default folder updated.";
        end

        % Button pushed function: SelectBrightfieldButton
        function SelectBrightfieldButtonPushed(app, event)
           filePath = app.selectImageFile("Select Brightfield Image");

    if strlength(filePath) == 0
        app.StatusLabel.Text = "No brightfield image selected.";
        return;
    end

    app.BrightfieldPath = filePath;
    app.BrightfieldRaw = app.readAndPrepareImage(filePath);

    [~, name, ext] = fileparts(filePath);
    app.BrightfieldLabel.Text = sprintf('Brightfield: %s%s', name, ext);
    app.StatusLabel.Text = "Brightfield image loaded.";

    app.updateProcessButtonState();
    if ~isempty(app.FluorescentRaw)
        app.refreshDisplays();
    end
        end

        % Button pushed function: SelectFluorescentButton
        function SelectFluorescentButtonPushed(app, event)
         filePath = app.selectImageFile("Select Fluorescent Image");

    if strlength(filePath) == 0
        app.StatusLabel.Text = "No fluorescent image selected.";
        return;
    end

    app.FluorescentPath = filePath;
    app.FluorescentRaw = app.readAndPrepareImage(filePath);

    [~, name, ext] = fileparts(filePath);
    app.FluorescentLabel.Text = sprintf('Fluorescent: %s%s', name, ext);
    app.StatusLabel.Text = "Fluorescent image loaded.";

    app.updateProcessButtonState();
    if ~isempty(app.BrightfieldRaw)
        app.refreshDisplays();
    end
        end

        % Button pushed function: ProcessAndMergeButton
        function ProcessAndMergeButtonPushed(app, event)
          if isempty(app.BrightfieldRaw) || isempty(app.FluorescentRaw)
        app.StatusLabel.Text = "Please select both images first.";
        return;
    end

    app.StatusLabel.Text = "Processing...";
    drawnow;

    try
        % Just refresh the displays and build the composite
        app.refreshDisplays();
        app.StatusLabel.Text = "Processing complete. Image is ready to be saved.";
        app.SaveCompositeButton.Enable = "on";

    catch ME
        app.CompositeImage = [];
        app.SaveCompositeButton.Enable = "off";
        app.StatusLabel.Text = "Error: " + string(ME.message);
    end
        end

        % Button pushed function: SaveCompositeButton
        function SaveCompositeButtonPushed(app, event)
          if isempty(app.CompositeImage)
        app.StatusLabel.Text = "No composite image available to save.";
        return;
    end

    % Ensure Composites subfolder exists
    saveFolder = fullfile(app.DefaultDirectory, "Composites");
    if ~isfolder(saveFolder)
        mkdir(saveFolder);
    end

    % Default output name
    defaultName = "composite.tif";
    if strlength(app.BrightfieldPath) > 0
        [~, baseName, ~] = fileparts(app.BrightfieldPath);
        defaultName = baseName + "_composite.tif";
    end

    % Decide file type based on dropdown selection
    formatChoice = string(app.SaveFormatDropDown.Value);

    switch formatChoice
        case "Full Resolution TIFF"
            filterSpec = {'*.tif;*.tiff', 'TIFF Image (*.tif, *.tiff)'};
            defaultExt = ".tif";

        case {"Downsampled PNG (50%)", "Downsampled PNG (25%)"}
            filterSpec = {'*.png', 'PNG Image (*.png)'};
            defaultExt = ".png";

        otherwise
            filterSpec = {'*.*', 'All Files (*.*)'};
            defaultExt = ".tif";
    end

    % Make the suggested filename match the chosen format
    [~, baseName, ~] = fileparts(char(defaultName));
    suggestedName = fullfile(saveFolder, baseName + defaultExt);

    % Save dialog
    [file, path] = uiputfile( ...
        filterSpec, ...
        'Save Composite Image As', ...
        suggestedName);

    if isequal(file, 0)
        app.StatusLabel.Text = "Save cancelled.";
        return;
    end

    % Force correct extension even if user types something else
    [~, chosenName, ~] = fileparts(file);
    fullFileName = fullfile(path, chosenName + defaultExt);

    try
        img = app.CompositeImage;

        switch formatChoice
            case "Full Resolution TIFF"
                imwrite(im2uint16(img), fullFileName);

            case "Downsampled PNG (50%)"
                imgSmall = imresize(img, 0.5);
                imwrite(im2uint8(imgSmall), fullFileName);

            case "Downsampled PNG (25%)"
                imgSmall = imresize(img, 0.25);
                imwrite(im2uint8(imgSmall), fullFileName);

            otherwise
                error("Unknown save format: %s", formatChoice);
        end

        [~, savedName, savedExt] = fileparts(fullFileName);
        app.StatusLabel.Text = sprintf("Image saved to %s%s", savedName, savedExt);

    catch ME
        app.StatusLabel.Text = "Save failed: " + string(ME.message);
    end
        end

        % Value changed function: BrightfieldLowSlider
        function BrightfieldLowSliderValueChanged(app, event)
            value = app.BrightfieldLowSlider.Value;
             if ~isempty(app.BrightfieldRaw) && ~isempty(app.FluorescentRaw)
        app.refreshDisplays();
    end
        end

        % Value changed function: FluorescentLowSlider
        function FluorescentLowSliderValueChanged(app, event)
            value = app.FluorescentLowSlider.Value;
            if ~isempty(app.BrightfieldRaw) && ~isempty(app.FluorescentRaw)
       app.refreshDisplays();
    end
        end

        % Value changed function: FluorescenceGainSlider
        function FluorescenceGainSliderValueChanged(app, event)
            value = app.FluorescenceGainSlider.Value;
            if ~isempty(app.BrightfieldRaw) && ~isempty(app.FluorescentRaw)
        app.refreshDisplays();
    end

        end

        % Value changed function: FluorescenceColorDropDown
        function FluorescenceColorDropDownValueChanged(app, event)
            value = app.FluorescenceColorDropDown.Value;
            if ~isempty(app.BrightfieldRaw) && ~isempty(app.FluorescentRaw)
        app.refreshDisplays();
            end
        end

        % Button pushed function: LoadAtlasFolderButton
        function LoadAtlasFolderButtonPushed(app, event)
            startFolder = char(app.DefaultDirectory);
    if strlength(app.DefaultDirectory) == 0 || ~isfolder(app.DefaultDirectory)
        startFolder = pwd;
    end

    folder = uigetdir(startFolder, 'Select Atlas Folder');

    if isequal(folder, 0)
        app.StatusLabel.Text = "Atlas folder selection cancelled.";
        return;
    end

    app.AtlasFolder = string(folder);

    % Collect atlas images
    files = [ ...
        dir(fullfile(folder, '*.tif')); ...
        dir(fullfile(folder, '*.tiff')); ...
        dir(fullfile(folder, '*.png')); ...
        dir(fullfile(folder, '*.jpg')); ...
        dir(fullfile(folder, '*.jpeg')) ];

    if isempty(files)
        app.StatusLabel.Text = "No atlas image files found in the selected folder.";
        cla(app.UIAxesAtlas);
        app.PlateSpinner.Enable = "off";
        return;
    end

    % Natural sort by the first number in the filename
names = {files.name};
plateNums = nan(size(names));

for k = 1:numel(names)
    tok = regexp(names{k}, '\d+', 'match');
    if ~isempty(tok)
        plateNums(k) = str2double(tok{end});
    else
        plateNums(k) = inf; % files without numbers go to the end
    end
end

[~, order] = sortrows([plateNums(:), (1:numel(files)).']);
files = files(order);



app.AtlasFiles = files;
nFiles = numel(app.AtlasFiles);
    % Configure spinner
   app.PlateSpinner.Limits = [1 nFiles];
    app.PlateSpinner.Value = 1;
    app.PlateSpinner.Step = 1;
    app.PlateSpinner.Enable = "on";

    % Show first plate
   app.loadAtlasPlate(1);

    app.StatusLabel.Text = sprintf("Loaded %d atlas plates.", nFiles);
        end

        % Value changed function: OpacitySlider
        function OpacitySliderValueChanged(app, event)
            if isempty(app.AtlasFiles)
        return;
    end

    app.renderAtlasOverlay();
        end

        % Value changed function: OverlayScaleSlider
        function OverlayScaleSliderValueChanged(app, event)
           app.OverlayScale = app.OverlayScaleSlider.Value;
    if ~isempty(app.AtlasFiles)
        app.renderAtlasOverlay();
    end
   
        end

        % Value changed function: OverlayXShiftSlider
        function OverlayXShiftSliderValueChanged(app, event)
            app.OverlayXShift = app.OverlayXShiftSlider.Value;
            if ~isempty(app.AtlasFiles)
         app.renderAtlasOverlay();
    end
        end

        % Value changed function: OverlayYShiftSlider
        function OverlayYShiftSliderValueChanged(app, event)
            app.OverlayYShift = app.OverlayYShiftSlider.Value;
             if ~isempty(app.AtlasFiles)
        app.renderAtlasOverlay();
    end
        end

        % Value changed function: PlateSpinner
        function PlateSpinnerValueChanged(app, event)
           if isempty(app.AtlasFiles)
        return;
    end

    app.loadAtlasPlate(app.PlateSpinner.Value);
            
        end

        % Button pushed function: PreviousPlateButton
        function PreviousPlateButtonPushed(app, event)
            if isempty(app.AtlasFiles)
        return;
    end

    newIdx = max(1, round(app.PlateSpinner.Value) - 1);
    app.PlateSpinner.Value = newIdx;
    app.loadAtlasPlate(newIdx);
        end

        % Button pushed function: NextPlateButton
        function NextPlateButtonPushed(app, event)
            if isempty(app.AtlasFiles)
        return;
    end

    newIdx = min(numel(app.AtlasFiles), round(app.PlateSpinner.Value) + 1);
    app.PlateSpinner.Value = newIdx;
    app.loadAtlasPlate(newIdx);
        end

        % Button pushed function: SaveOverlayButton
        function SaveOverlayButtonPushed(app, event)
            if isempty(app.AtlasFiles) || isempty(app.AtlasGray)
        app.StatusLabel.Text = "No atlas overlay to save.";
        return;
    end

    [file, path] = uiputfile( ...
        {'*.png','PNG Image (*.png)'; '*.tif','TIFF Image (*.tif)'; '*.jpg','JPEG Image (*.jpg)'}, ...
        'Save Atlas Overlay As');

    if isequal(file, 0)
        app.StatusLabel.Text = "Save cancelled.";
        return;
    end

    fullFileName = fullfile(path, file);

    try
        exportgraphics(app.UIAxesAtlas, fullFileName, 'Resolution', 300);
        app.StatusLabel.Text = "Overlay saved.";
    catch ME
        app.StatusLabel.Text = "Save failed: " + string(ME.message);
    end
        end

        % Value changed function: OverlayRotationSlider
        function OverlayRotationSliderValueChanged(app, event)
            app.OverlayRotation = app.OverlayRotationSlider.Value;
    if ~isempty(app.AtlasFiles)
        app.renderAtlasOverlay();
    end
            
        end

        % Button pushed function: ResetAlignmentButton
        function ResetAlignmentButtonPushed(app, event)
             app.OverlayScale = 1.0;
    app.OverlayXShift = 0;
    app.OverlayYShift = 0;
    app.OverlayRotation = 0;

    app.OverlayScaleSlider.Value = 1.0;
    app.OverlayXShiftSlider.Value = 0;
    app.OverlayYShiftSlider.Value = 0;
    app.OverlayRotationSlider.Value = 0;
    app.OpacitySlider.Value = 0.5;

    if ~isempty(app.AtlasFiles)
        app.renderAtlasOverlay();
    end
        end

        % Button pushed function: SelectCompositeButton
        function SelectCompositeButtonPushed(app, event)
            startFolder = fullfile(app.DefaultDirectory, "Composites");
    if ~isfolder(startFolder)
        startFolder = app.DefaultDirectory;
    end

    [file, path] = uigetfile( ...
        {'*.tif;*.tiff;*.png;*.jpg;*.jpeg', 'Composite Images (*.tif, *.tiff, *.png, *.jpg, *.jpeg)'; ...
         '*.*', 'All Files (*.*)'}, ...
        'Select Composite Image', ...
        startFolder);

    if isequal(file, 0)
        app.StatusLabel.Text = "Composite selection cancelled.";
        return;
    end

    fullFileName = fullfile(path, file);

    % Always reload from disk
    img = imread(fullFileName);

    % Convert to RGB if needed
    if ndims(img) == 2
        img = repmat(img, [1 1 3]);
    elseif ndims(img) == 3 && size(img, 3) > 3
        img = img(:,:,1:3);
    end

    app.SelectedCompositePath = string(fullFileName);
    app.SelectedCompositeImage = im2double(img);

    [~, name, ext] = fileparts(file);
    app.SelectedCompositeLabel.Text = sprintf("Composite: %s%s", name, ext);
    app.StatusLabel.Text = "Composite loaded for atlas overlay.";

    % Helpful debug while testing:
    % disp(app.SelectedCompositePath)

    if ~isempty(app.AtlasFiles)
        app.renderAtlasOverlay();
    end
        end

        % Value changed function: ShowCompositeCheckBox
        function ShowCompositeCheckBoxValueChanged(app, event)
            app.ShowComposite = app.ShowCompositeCheckBox.Value;

    if ~isempty(app.AtlasFiles)
        app.renderAtlasOverlay();
    end
            
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 1239 848];
            app.UIFigure.Name = 'MATLAB App';

            % Create TabGroup
            app.TabGroup = uitabgroup(app.UIFigure);
            app.TabGroup.Position = [29 24 1197 777];

            % Create ImageProcessTab
            app.ImageProcessTab = uitab(app.TabGroup);
            app.ImageProcessTab.Title = 'Image Process';

            % Create UIAxesBrightfield
            app.UIAxesBrightfield = uiaxes(app.ImageProcessTab);
            title(app.UIAxesBrightfield, 'Brightfield Image')
            app.UIAxesBrightfield.TickDir = 'none';
            app.UIAxesBrightfield.Position = [255 409 418 275];

            % Create UIAxesFluorescent
            app.UIAxesFluorescent = uiaxes(app.ImageProcessTab);
            title(app.UIAxesFluorescent, 'Fluorescent Image')
            app.UIAxesFluorescent.TickDir = 'none';
            app.UIAxesFluorescent.Position = [708 405 428 283];

            % Create UIAxesComposite
            app.UIAxesComposite = uiaxes(app.ImageProcessTab);
            title(app.UIAxesComposite, 'COMPOSITE IMAGE')
            app.UIAxesComposite.TickDir = 'none';
            app.UIAxesComposite.Position = [702 20 434 318];

            % Create ImageSelectionPanel
            app.ImageSelectionPanel = uipanel(app.ImageProcessTab);
            app.ImageSelectionPanel.Title = 'Image Selection';
            app.ImageSelectionPanel.Position = [13 463 231 221];

            % Create SelectBrightfieldButton
            app.SelectBrightfieldButton = uibutton(app.ImageSelectionPanel, 'push');
            app.SelectBrightfieldButton.ButtonPushedFcn = createCallbackFcn(app, @SelectBrightfieldButtonPushed, true);
            app.SelectBrightfieldButton.FontWeight = 'bold';
            app.SelectBrightfieldButton.Position = [9 162 113 22];
            app.SelectBrightfieldButton.Text = 'Select Brightfield';

            % Create BrightfieldLabel
            app.BrightfieldLabel = uilabel(app.ImageSelectionPanel);
            app.BrightfieldLabel.WordWrap = 'on';
            app.BrightfieldLabel.FontAngle = 'italic';
            app.BrightfieldLabel.Position = [13 107 205 44];
            app.BrightfieldLabel.Text = 'Brightfield';

            % Create SelectFluorescentButton
            app.SelectFluorescentButton = uibutton(app.ImageSelectionPanel, 'push');
            app.SelectFluorescentButton.ButtonPushedFcn = createCallbackFcn(app, @SelectFluorescentButtonPushed, true);
            app.SelectFluorescentButton.FontWeight = 'bold';
            app.SelectFluorescentButton.Position = [6 74 121 22];
            app.SelectFluorescentButton.Text = 'Select Fluorescent';

            % Create FluorescentLabel
            app.FluorescentLabel = uilabel(app.ImageSelectionPanel);
            app.FluorescentLabel.WordWrap = 'on';
            app.FluorescentLabel.FontAngle = 'italic';
            app.FluorescentLabel.Position = [13 10 205 38];
            app.FluorescentLabel.Text = 'Fluorescent';

            % Create BrightfieldContrastSliderLabel
            app.BrightfieldContrastSliderLabel = uilabel(app.ImageProcessTab);
            app.BrightfieldContrastSliderLabel.HorizontalAlignment = 'right';
            app.BrightfieldContrastSliderLabel.Position = [293 716 107 22];
            app.BrightfieldContrastSliderLabel.Text = 'Brightfield Contrast';

            % Create BrightfieldLowSlider
            app.BrightfieldLowSlider = uislider(app.ImageProcessTab, 'range');
            app.BrightfieldLowSlider.Limits = [0 1];
            app.BrightfieldLowSlider.ValueChangedFcn = createCallbackFcn(app, @BrightfieldLowSliderValueChanged, true);
            app.BrightfieldLowSlider.Position = [458 726 150 3];
            app.BrightfieldLowSlider.Value = [0 1];

            % Create StatusLabel
            app.StatusLabel = uilabel(app.ImageProcessTab);
            app.StatusLabel.WordWrap = 'on';
            app.StatusLabel.FontSize = 14;
            app.StatusLabel.FontAngle = 'italic';
            app.StatusLabel.Position = [13 354 520 42];
            app.StatusLabel.Text = 'Status';

            % Create FluorescentContrastSliderLabel
            app.FluorescentContrastSliderLabel = uilabel(app.ImageProcessTab);
            app.FluorescentContrastSliderLabel.HorizontalAlignment = 'right';
            app.FluorescentContrastSliderLabel.Position = [760 717 116 22];
            app.FluorescentContrastSliderLabel.Text = 'Fluorescent Contrast';

            % Create FluorescentLowSlider
            app.FluorescentLowSlider = uislider(app.ImageProcessTab, 'range');
            app.FluorescentLowSlider.Limits = [0 1];
            app.FluorescentLowSlider.ValueChangedFcn = createCallbackFcn(app, @FluorescentLowSliderValueChanged, true);
            app.FluorescentLowSlider.Position = [903 726 150 3];
            app.FluorescentLowSlider.Value = [0 1];

            % Create FluoresenceIntensitySliderLabel
            app.FluoresenceIntensitySliderLabel = uilabel(app.ImageProcessTab);
            app.FluoresenceIntensitySliderLabel.HorizontalAlignment = 'right';
            app.FluoresenceIntensitySliderLabel.Position = [377 266 119 22];
            app.FluoresenceIntensitySliderLabel.Text = 'Fluoresence Intensity';

            % Create FluorescenceGainSlider
            app.FluorescenceGainSlider = uislider(app.ImageProcessTab);
            app.FluorescenceGainSlider.Limits = [0 3];
            app.FluorescenceGainSlider.ValueChangedFcn = createCallbackFcn(app, @FluorescenceGainSliderValueChanged, true);
            app.FluorescenceGainSlider.Position = [532 275 150 3];
            app.FluorescenceGainSlider.Value = 1;

            % Create FluorescenceColorDropDownLabel
            app.FluorescenceColorDropDownLabel = uilabel(app.ImageProcessTab);
            app.FluorescenceColorDropDownLabel.HorizontalAlignment = 'right';
            app.FluorescenceColorDropDownLabel.Position = [378 201 109 22];
            app.FluorescenceColorDropDownLabel.Text = 'Fluorescence Color';

            % Create FluorescenceColorDropDown
            app.FluorescenceColorDropDown = uidropdown(app.ImageProcessTab);
            app.FluorescenceColorDropDown.Items = {'Green', 'Yellow', 'Red'};
            app.FluorescenceColorDropDown.ValueChangedFcn = createCallbackFcn(app, @FluorescenceColorDropDownValueChanged, true);
            app.FluorescenceColorDropDown.Position = [508 201 100 22];
            app.FluorescenceColorDropDown.Value = 'Green';

            % Create SaveCompositeButton
            app.SaveCompositeButton = uibutton(app.ImageProcessTab, 'push');
            app.SaveCompositeButton.ButtonPushedFcn = createCallbackFcn(app, @SaveCompositeButtonPushed, true);
            app.SaveCompositeButton.BackgroundColor = [0 1 0];
            app.SaveCompositeButton.FontSize = 18;
            app.SaveCompositeButton.FontWeight = 'bold';
            app.SaveCompositeButton.Position = [458 74 155 30];
            app.SaveCompositeButton.Text = 'Save Composite';

            % Create ProcessAndMergeButton
            app.ProcessAndMergeButton = uibutton(app.ImageProcessTab, 'push');
            app.ProcessAndMergeButton.ButtonPushedFcn = createCallbackFcn(app, @ProcessAndMergeButtonPushed, true);
            app.ProcessAndMergeButton.BackgroundColor = [0 1 1];
            app.ProcessAndMergeButton.FontSize = 18;
            app.ProcessAndMergeButton.FontWeight = 'bold';
            app.ProcessAndMergeButton.Position = [597 366 180 30];
            app.ProcessAndMergeButton.Text = 'Process and Merge';

            % Create TextArea
            app.TextArea = uitextarea(app.ImageProcessTab);
            app.TextArea.FontSize = 14;
            app.TextArea.FontColor = [0.0667 0.4431 0.7451];
            app.TextArea.BackgroundColor = [0.9412 0.9412 0.9412];
            app.TextArea.Position = [26 39 249 299];
            app.TextArea.Value = {'(1) Select the Brightfield image, followed by the corresponding fluorescent image.'; ''; '(2) Use the contrast sliders to adjust '; ''; '(3) Select ''Process and Merge'' to create the final composite.'; ''; '(4) Fluorescence intensity and color (Green/Yellow/Red) can be adjusted'; ''; '(5) Save composite at desired resolution (note: a ''Composites'' folder will be created within the default directory)'};

            % Create SaveFormatDropDownLabel
            app.SaveFormatDropDownLabel = uilabel(app.ImageProcessTab);
            app.SaveFormatDropDownLabel.HorizontalAlignment = 'right';
            app.SaveFormatDropDownLabel.Position = [378 148 74 22];
            app.SaveFormatDropDownLabel.Text = 'Save Format';

            % Create SaveFormatDropDown
            app.SaveFormatDropDown = uidropdown(app.ImageProcessTab);
            app.SaveFormatDropDown.Items = {'Full Resolution TIFF', 'Downsampled PNG (50%)', 'Downsampled PNG (25%)'};
            app.SaveFormatDropDown.Position = [467 148 215 22];
            app.SaveFormatDropDown.Value = 'Full Resolution TIFF';

            % Create AtlasBrowserTab
            app.AtlasBrowserTab = uitab(app.TabGroup);
            app.AtlasBrowserTab.Title = 'Atlas Browser';

            % Create UIAxesAtlas
            app.UIAxesAtlas = uiaxes(app.AtlasBrowserTab);
            title(app.UIAxesAtlas, 'Title')
            app.UIAxesAtlas.Position = [343 20 845 677];

            % Create LoadAtlasFolderButton
            app.LoadAtlasFolderButton = uibutton(app.AtlasBrowserTab, 'push');
            app.LoadAtlasFolderButton.ButtonPushedFcn = createCallbackFcn(app, @LoadAtlasFolderButtonPushed, true);
            app.LoadAtlasFolderButton.Position = [31 707 108 22];
            app.LoadAtlasFolderButton.Text = 'Load Atlas Folder';

            % Create OpacitySliderLabel
            app.OpacitySliderLabel = uilabel(app.AtlasBrowserTab);
            app.OpacitySliderLabel.HorizontalAlignment = 'right';
            app.OpacitySliderLabel.Position = [13 426 46 22];
            app.OpacitySliderLabel.Text = 'Opacity';

            % Create OpacitySlider
            app.OpacitySlider = uislider(app.AtlasBrowserTab);
            app.OpacitySlider.Limits = [0 1];
            app.OpacitySlider.ValueChangedFcn = createCallbackFcn(app, @OpacitySliderValueChanged, true);
            app.OpacitySlider.Position = [81 435 150 3];
            app.OpacitySlider.Value = 0.35;

            % Create OverlayScaleSliderLabel
            app.OverlayScaleSliderLabel = uilabel(app.AtlasBrowserTab);
            app.OverlayScaleSliderLabel.HorizontalAlignment = 'right';
            app.OverlayScaleSliderLabel.Position = [12 345 80 22];
            app.OverlayScaleSliderLabel.Text = 'Overlay Scale';

            % Create OverlayScaleSlider
            app.OverlayScaleSlider = uislider(app.AtlasBrowserTab);
            app.OverlayScaleSlider.Limits = [0.25 4];
            app.OverlayScaleSlider.ValueChangedFcn = createCallbackFcn(app, @OverlayScaleSliderValueChanged, true);
            app.OverlayScaleSlider.Position = [114 354 150 3];
            app.OverlayScaleSlider.Value = 1;

            % Create OverlayXShiftSliderLabel
            app.OverlayXShiftSliderLabel = uilabel(app.AtlasBrowserTab);
            app.OverlayXShiftSliderLabel.HorizontalAlignment = 'right';
            app.OverlayXShiftSliderLabel.Position = [10 266 82 22];
            app.OverlayXShiftSliderLabel.Text = 'Overlay XShift';

            % Create OverlayXShiftSlider
            app.OverlayXShiftSlider = uislider(app.AtlasBrowserTab);
            app.OverlayXShiftSlider.Limits = [-2000 2000];
            app.OverlayXShiftSlider.ValueChangedFcn = createCallbackFcn(app, @OverlayXShiftSliderValueChanged, true);
            app.OverlayXShiftSlider.Position = [114 275 150 3];

            % Create OverlayYShiftSliderLabel
            app.OverlayYShiftSliderLabel = uilabel(app.AtlasBrowserTab);
            app.OverlayYShiftSliderLabel.HorizontalAlignment = 'right';
            app.OverlayYShiftSliderLabel.Position = [12 190 81 22];
            app.OverlayYShiftSliderLabel.Text = 'Overlay YShift';

            % Create OverlayYShiftSlider
            app.OverlayYShiftSlider = uislider(app.AtlasBrowserTab);
            app.OverlayYShiftSlider.Limits = [-2000 2000];
            app.OverlayYShiftSlider.ValueChangedFcn = createCallbackFcn(app, @OverlayYShiftSliderValueChanged, true);
            app.OverlayYShiftSlider.Position = [115 199 150 3];

            % Create PlateSpinnerLabel
            app.PlateSpinnerLabel = uilabel(app.AtlasBrowserTab);
            app.PlateSpinnerLabel.HorizontalAlignment = 'right';
            app.PlateSpinnerLabel.Position = [75 601 32 22];
            app.PlateSpinnerLabel.Text = 'Plate';

            % Create PlateSpinner
            app.PlateSpinner = uispinner(app.AtlasBrowserTab);
            app.PlateSpinner.ValueChangedFcn = createCallbackFcn(app, @PlateSpinnerValueChanged, true);
            app.PlateSpinner.Enable = 'off';
            app.PlateSpinner.Position = [122 601 100 22];
            app.PlateSpinner.Value = 1;

            % Create PreviousPlateButton
            app.PreviousPlateButton = uibutton(app.AtlasBrowserTab, 'push');
            app.PreviousPlateButton.ButtonPushedFcn = createCallbackFcn(app, @PreviousPlateButtonPushed, true);
            app.PreviousPlateButton.Position = [42 559 100 22];
            app.PreviousPlateButton.Text = 'Previous Plate';

            % Create NextPlateButton
            app.NextPlateButton = uibutton(app.AtlasBrowserTab, 'push');
            app.NextPlateButton.ButtonPushedFcn = createCallbackFcn(app, @NextPlateButtonPushed, true);
            app.NextPlateButton.Position = [178 559 100 22];
            app.NextPlateButton.Text = 'Next Plate';

            % Create SaveOverlayButton
            app.SaveOverlayButton = uibutton(app.AtlasBrowserTab, 'push');
            app.SaveOverlayButton.ButtonPushedFcn = createCallbackFcn(app, @SaveOverlayButtonPushed, true);
            app.SaveOverlayButton.BackgroundColor = [0 1 0];
            app.SaveOverlayButton.FontSize = 18;
            app.SaveOverlayButton.FontWeight = 'bold';
            app.SaveOverlayButton.FontColor = [0 0 0];
            app.SaveOverlayButton.Position = [1039 708 128 30];
            app.SaveOverlayButton.Text = 'Save Overlay';

            % Create OverlayRotationSliderLabel
            app.OverlayRotationSliderLabel = uilabel(app.AtlasBrowserTab);
            app.OverlayRotationSliderLabel.HorizontalAlignment = 'right';
            app.OverlayRotationSliderLabel.Position = [7 129 94 22];
            app.OverlayRotationSliderLabel.Text = 'Overlay Rotation';

            % Create OverlayRotationSlider
            app.OverlayRotationSlider = uislider(app.AtlasBrowserTab);
            app.OverlayRotationSlider.Limits = [-30 30];
            app.OverlayRotationSlider.ValueChangedFcn = createCallbackFcn(app, @OverlayRotationSliderValueChanged, true);
            app.OverlayRotationSlider.Step = 1;
            app.OverlayRotationSlider.Position = [123 138 150 3];

            % Create ResetAlignmentButton
            app.ResetAlignmentButton = uibutton(app.AtlasBrowserTab, 'push');
            app.ResetAlignmentButton.ButtonPushedFcn = createCallbackFcn(app, @ResetAlignmentButtonPushed, true);
            app.ResetAlignmentButton.Position = [100 53 102 22];
            app.ResetAlignmentButton.Text = 'Reset Alignment';

            % Create SelectCompositeButton
            app.SelectCompositeButton = uibutton(app.AtlasBrowserTab, 'push');
            app.SelectCompositeButton.ButtonPushedFcn = createCallbackFcn(app, @SelectCompositeButtonPushed, true);
            app.SelectCompositeButton.Position = [160 707 109 22];
            app.SelectCompositeButton.Text = 'Select Composite';

            % Create ShowCompositeCheckBox
            app.ShowCompositeCheckBox = uicheckbox(app.AtlasBrowserTab);
            app.ShowCompositeCheckBox.ValueChangedFcn = createCallbackFcn(app, @ShowCompositeCheckBoxValueChanged, true);
            app.ShowCompositeCheckBox.Text = 'Show Composite ';
            app.ShowCompositeCheckBox.Position = [293 707 116 22];

            % Create SelectedCompositeLabel
            app.SelectedCompositeLabel = uilabel(app.AtlasBrowserTab);
            app.SelectedCompositeLabel.WordWrap = 'on';
            app.SelectedCompositeLabel.FontAngle = 'italic';
            app.SelectedCompositeLabel.Position = [13 647 331 50];
            app.SelectedCompositeLabel.Text = 'Selected Composite';

            % Create SelectDefaultDirectoryButton
            app.SelectDefaultDirectoryButton = uibutton(app.UIFigure, 'push');
            app.SelectDefaultDirectoryButton.ButtonPushedFcn = createCallbackFcn(app, @SelectDefaultDirectoryButtonPushed, true);
            app.SelectDefaultDirectoryButton.FontWeight = 'bold';
            app.SelectDefaultDirectoryButton.Position = [48 811 153 22];
            app.SelectDefaultDirectoryButton.Text = 'Select Default Directory ';

            % Create DefaultDirectoryLabel
            app.DefaultDirectoryLabel = uilabel(app.UIFigure);
            app.DefaultDirectoryLabel.WordWrap = 'on';
            app.DefaultDirectoryLabel.FontAngle = 'italic';
            app.DefaultDirectoryLabel.Position = [229 800 873 45];
            app.DefaultDirectoryLabel.Text = 'Default Directory';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = SimpleHisto_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn2)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end