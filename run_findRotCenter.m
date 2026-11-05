function run_findRotCenter
  close all; rng(1);

  datacase = 5;

  showScale = 5;
  dSize = 1;
  %dSize = 2;  % um - with 12MP images, 2x2 pixels are combined into one
  distCam2RotCenter_mm = 13.1;  % mm
  focalLength_mm = 5.96;  % mm; true focal length of the bare iPhone camera lens
  epsVal = 1e-6;

  addpath( './dworkLib' );

  out = loadDatacase( datacase );
  calDir = out.calDir;
  dataDir = out.dataDir;
  illumFile = out.illumFile;
  cropStartY = out.cropStartY;
  cropStopY = out.cropStopY;
  rotAngle_deg = out.rotAngle_deg;
  dataFileIndxFor180 = out.dataFileIndxFor180;
  sliceForRotCenter = out.sliceForRotCenter;

  halfWidth = 1600;
  halfHeight = 1000;

  rotCentersDir = [ 'rotCenters_', num2str(datacase) ];
  mkdir( rotCentersDir );

  K_pixel = getKPixel( calDir, 'showScale', showScale );
  disp('K in pixel units:');
  disp( K_pixel );

  % The checkerboard calibration was performed without the additional magnification lens.
  % That means the principal point and radial distortion from the calibration are not valid
  % for the OPT data.  The magnification factor below is only a focal-length fix.
  % This works under the assumption that the principal point and ratio of focal lengths remain the same.
  % If this is not the case, the long-term fix is to calibrate the full optical train with the magnifier
  % attached and then remove this Mag block entirely.
  Mag = 1.8357;

  pixelPitch_mm = focalLength_mm / K_pixel(1,1);
  focalLengthX = K_pixel(1,1) * Mag;
  focalLengthY = K_pixel(2,2) * Mag; %#ok<NASGU>

  % These are the candidate rotation centers
  rotCenterXs = round( K_pixel(1,3) ) - 300 : 5 : round( K_pixel(1,3) ) + 300;

  dataFiles = dir( [ dataDir, filesep, '*.DNG' ] );
  dataFiles = sortFilesByNumericSuffix( dataFiles );
  dataFiles = dataFiles( 2 : dataFileIndxFor180 + 1 );

  img0 = readRawFrame( [ dataDir, filesep, dataFiles(1).name ] );
  sImg = size( img0 );

  illumRaw = readRawFrame( illumFile );
  if ~isequal( size( illumRaw ), sImg )
    error( 'Background image size does not match the projection image size.' );
  end
  illumRaw = max( illumRaw, epsVal );
  illumRows = illumRaw( cropStartY : cropStopY, : );

  centerIndxY = floor( sImg(1) / 2 ) + 1;
  centerIndxX = floor( sImg(2) / 2 ) + 1;

  cropStartX = centerIndxX - halfWidth;
  cropStopX  = centerIndxX + halfWidth;

  if numel( cropStartY ) == 0
    cropStartY = centerIndxY - halfHeight;
    cropStopY  = centerIndxY + halfHeight;
  end

  rotAngle_rad = rotAngle_deg * pi / 180;
  rotDist = distCam2RotCenter_mm / pixelPitch_mm;  % source-to-rotation-center distance in detector pixels

  detCenterX0 = halfWidth;
  principalPointX0 = detCenterX0;
    % The magnifier was NOT part of the calibration.  Until the full optical train is 
    % calibrated, force a self-consistent geometry by setting the principal point equal
    % to the detector element whose ray passes through the center of rotation.

  tmp = zeros( cropStopX - cropStartX + 1, 2 );
  sinoParaTmp = fan2Parallel( tmp, dSize, focalLengthX, rotDist, 'dProjAngle', rotAngle_rad, ...
    'detCenter', detCenterX0, 'principalPoint', principalPointX0 );
  sImgOut = [ size( sinoParaTmp, 1 ), size( sinoParaTmp, 1 ) ];

  parfor rotCenterX_indx = 1 : numel( rotCenterXs )
    rotCenterX = rotCenterXs( rotCenterX_indx );
    disp([ 'Working on rotCenterX = ', num2str(rotCenterX) ]);

    % Shift each image so that the detector element whose ray passes through
    % the center of rotation lands at the center of the crop.
    shiftX = centerIndxX - rotCenterX;

    muFlatPanel = getMuFlatPanel( dataDir, dataFiles, illumRows, shiftX, cropStartY, cropStopY, cropStartX, cropStopX, ...
      'slices2keep', sliceForRotCenter );

    recon = feldkampRecon( muFlatPanel, sImgOut, focalLengthX, rotDist, 'dProjAngle', rotAngle_rad, ...
      'dSizeX', dSize, 'detCenter', detCenterX0, 'principalPoint', principalPointX0, 'inputIsLineIntegrals', true );
    recon = squeeze( recon );
    recon = max( recon, 0 );
    recon = recon / max( recon(:) );

    reconFile = fixFileseps( [ './', rotCentersDir, '/rcx_', indx2str( rotCenterX, max(rotCenterXs) ), '.jpg' ] );
    imwrite( recon, reconFile );
  end

end

