
function outDir = adjustMaxBrightness(inDir, xPercent, outDir)
%ADJUSTMAXBRIGHTNESS Copy an image directory and scale maximum brightness.
%
% outDir = adjustMaxBrightness(inDir, xPercent)
% outDir = adjustMaxBrightness(inDir, xPercent, outDir)
%
% Copies inDir and writes a sibling directory of the same images. Each image
% is multiplied by (1 + xPercent/100), so the maximum changes by xPercent.
% Positive xPercent brightens, negative darkens. Results are clipped to the
% numeric range of the input class. The source directory is not modified.
%
% Example:
%   adjustMaxBrightness('/data/slices', 50)

    if nargin < 2
        error('adjustMaxBrightness:args', 'inDir and xPercent are required.');
    end
    if ~isfolder(inDir)
        error('adjustMaxBrightness:dir', 'Directory not found: %s', inDir);
    end

    inDir = char(inDir);
    if nargin < 3 || isempty(outDir)
        [parent, name] = fileparts(inDir);
        outDir = fullfile(parent, sprintf('%s_bright%+g', name, xPercent));
    end
    if isfolder(outDir)
        error('adjustMaxBrightness:exists', 'Output directory already exists: %s', outDir);
    end

    copyfile(inDir, outDir);
    scale = 1 + xPercent / 100;
    exts = {'.tif', '.tiff', '.png', '.jpg', '.jpeg', '.bmp'};
    files = dir(outDir);
    files = files(~[files.isdir]);

    n = 0;
    for k = 1:numel(files)
        [~, ~, ext] = fileparts(files(k).name);
        if ~any(strcmpi(ext, exts))
            continue
        end
        path = fullfile(outDir, files(k).name);
        img = imread(path);
        imwrite(scaleAndClip(img, scale), path);
        n = n + 1;
    end
    fprintf('Wrote %d images to %s\n', n, outDir);
end

function out = scaleAndClip(img, scale)
    cls = class(img);
    adj = double(img) * scale;
    adj = max(adj, 0);
    if isinteger(img)
        adj = min(adj, double(intmax(cls)));
    end
    out = cast(adj, cls);
end
