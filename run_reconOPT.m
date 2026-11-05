function run_reconOPT
  close all; rng(1);

  datacase = 4;

  showScale = 5;
  dSize = 1;
  %dSize = 2;  % um - with 12MP images, 2x2 pixels are combined into one
  distCam2RotCenter_mm = 13.1;  % mm
  focalLength_mm = 5.96;  % mm; true focal length of the bare iPhone camera lens
  epsVal = 1e-6;
  reconDir = [ './slices_', num2str(datacase) ];

  addpath( './dworkLib' );

  out = loadDatacase( datacase );
  calDir = out.calDir;
  dataDir = out.dataDir;
  illumFile = out.illumFile;
  cropStartY = out.cropStartY;
  cropStopY = out.cropStopY;
  cropAmount = out.cropAmount;
  cropCenter = out.cropCenter;
  rotAngle_deg = out.rotAngle_deg;
  dataFileIndxFor180 = out.dataFileIndxFor180;
  rotCenterX = out.rotCenterX;

  halfWidth = 1400;
  halfHeight = 1000;

  K_pixel = getKPixel( calDir, 'showScale', showScale );
  disp('K in pixel units:');
  disp( K_pixel );

  % The checkerboard calibration was performed without the additional magnification lens.
  % That means the principal point and radial distortion from the calibration are not valid
  % for the OPT data.  The magnification factor below is only a focal-length fix.
  % The correct long-term fix is to calibrate the full optical train with the magnifier attached
  % and then remove this Mag block entirely.
  Mag = 1.8357;

  pixelPitch_mm = focalLength_mm / K_pixel(1,1);
  focalLengthX = K_pixel(1,1) * Mag;
  focalLengthY = K_pixel(2,2) * Mag; %#ok<NASGU>

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
  if numel( cropStartY ) == 0
    cropStartY = centerIndxY - halfHeight;
    cropStopY  = centerIndxY + halfHeight;
  end
  cropStartX = centerIndxX - halfWidth;
  cropStopX  = centerIndxX + halfWidth;

  % Shift each image so that the detector element whose ray passes through
  % the center of rotation lands at the center of the crop.
  shiftX = centerIndxX - rotCenterX;

  detCenterX0 = halfWidth;
  principalPointX0 = detCenterX0;
    % The magnifier was NOT part of the calibration.  Until the full optical train is 
    % calibrated, force a self-consistent geometry by setting the principal point equal
    % to the detector element whose ray passes through the center of rotation.

  muFlatPanel = getMuFlatPanel( dataDir, dataFiles, illumRows, shiftX, cropStartY, cropStopY, cropStartX, cropStopX );
  muFlatPanel = single( muFlatPanel );

  rotAngle_rad = rotAngle_deg * pi / 180;
  rotDist = distCam2RotCenter_mm / pixelPitch_mm;  % source-to-rotation-center distance in detector pixels

  tmp = zeros( cropStopX - cropStartX + 1, 2 );
  sinoParaTmp = fan2Parallel( tmp, dSize, focalLengthX, rotDist, 'dProjAngle', rotAngle_rad, ...
    'detCenter', detCenterX0, 'principalPoint', principalPointX0 );
  sImgOut = [ size( sinoParaTmp, 1 ), size( sinoParaTmp, 1 ) ];
  clear tmp sinoParaTmp

  mkdir( reconDir );
  recon3D = feldkampRecon( muFlatPanel, sImgOut, focalLengthX, rotDist, 'dProjAngle', rotAngle_rad, ...
    'dSizeX', dSize, 'detCenter', detCenterX0, 'principalPoint', principalPointX0, 'inputIsLineIntegrals', true, ...
    'cropAmount', cropAmount, 'cropCenter', cropCenter, 'outDir', reconDir, 'printEvery', 1, 'verbose', true );

  recon3D = max( recon3D, 0 );
  recon3D = recon3D / max( recon3D(:) );
  
  nSlices = size( recon3D, 3 );
  for slice = 1 : nSlices
    imwrite( squeeze( recon3D(slice,:,:) ), [ './slices/slice_', indx2str( slice, nSlices ), '.jpg' ] );
  end

end

