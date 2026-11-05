
function out = loadDatacase( datacase )

  calDir = '/Users/nicholasdwork/Documents/Data/optData/20260318/checkerboard';
  illumFile = [];
  cropStartY = [];
  cropStopY = [];
  rotCenterX = [];
  dataFileIndxFor180 = 180;

  if datacase == 1
    dataDir = '/Users/nicholasdwork/Documents/Data/optData/20260405_cheaperSystem';
    airMargin = 200;
    cropStartY = 880;
    cropStopY = 2300;

  elseif datacase == 2
    dataDir = '/Users/nicholasdwork/Documents/Data/optData/20260411/zebrafish';
    illumFile = '/Users/nicholasdwork/Documents/Data/optData/20260411/1_justBackground.DNG';
    rotCenterX = 1991;
    cropStartY = 1000;
    cropStopY = 2500;

  elseif datacase == 3
    dataDir = '/Users/nicholasdwork/Documents/Data/optData/20260805/20260731_rigidTube_0_225_degree/zebrafish';
    illumFile = '/Users/nicholasdwork/Documents/Data/optData/20260805/20260731_rigidTube_0_225_degree/1_justBackground.DNG';
    airMargin = 500;
    rotCenterX = 1976;
    cropStartY = 866;
    cropStopY = 2242;
    rotAngle_deg = 0.225;

  elseif datacase == 4
    dataDir = '/Users/nicholasdwork/Documents/Data/optData/20260928/20260928_rigidTube_0_225_degree/zebrafish';
    illumFile = '/Users/nicholasdwork/Documents/Data/optData/20260928/20260928_rigidTube_0_225_degree/1_justBackground.DNG';
    airMargin = 900;
    rotCenterX = 2021;
    cropStartY = 1150;
    cropStopY = 2280;
    cropAmount = [ 800 800 ];
    cropCenter = [ 1400 1850 ];
    rotAngle_deg = 0.225;
    dataFileIndxFor180 = ceil( 180 / rotAngle_deg );
    sliceForRotCenter = 84;

  elseif datacase == 5
    dataDir = '/Users/nicholasdwork/Library/CloudStorage/Dropbox/Sharing/forGenna/OPT_Data/20261101_coloredTube_0_225_degree/coloredTube';
    illumFile = '/Users/nicholasdwork/Library/CloudStorage/Dropbox/Sharing/forGenna/OPT_Data/20261101_coloredTube_0_225_degree/1_justBackground.DNG';
    airMargin = 900;
    rotCenterX = 2021;
    cropStartY = 1150;
    cropStopY = 2280;
    rotAngle_deg = 0.225;
    dataFileIndxFor180 = ceil( 180 / rotAngle_deg );
    sliceForRotCenter = 84;
  end

  out.calDir = fixFileseps( calDir );
  out.dataDir = fixFileseps( dataDir );
  out.illumFile = fixFileseps( illumFile );
  out.airMargin = airMargin;
  out.rotCenterX = rotCenterX;
  out.cropStartY = cropStartY;
  out.cropStopY = cropStopY;
  out.cropAmount = cropAmount;
  out.cropCenter = cropCenter;
  out.rotAngle_deg = rotAngle_deg;  % rotation between projections
  out.dataFileIndxFor180 = dataFileIndxFor180;
  out.sliceForRotCenter = sliceForRotCenter;
end
