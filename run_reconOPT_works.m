function run_reconOPT
  close all; rng(1);

  showScale = 5;
  rotAngle_deg = 1;  % rotation between projections
  dSize = 1;
  %dSize = 2;  % um - with 12MP images, 2x2 pixels are combined into one
  distCam2RotCenter_mm = 13.1;  % mm
  focalLength_mm = 5.96;  % mm; true focal length of the bare iPhone camera lens
  epsVal = 1e-6;
  datacase = 4;

  calDir = fixFileseps( '/Users/nicholasdwork/Documents/Data/optData/20260318/checkerboard' );
  illumFile = [];
  cropStartY = [];
  rotCenterXs = [];
  dataFileIndxFor180 = 180;

  if datacase == 1
    dataDir = fixFileseps( '/Users/nicholasdwork/Documents/Data/optData/20260405_cheaperSystem' );
    airMargin = 200;
    cropStartY = 880;
    cropStopY = 2300;

  elseif datacase == 2
    dataDir = fixFileseps( '/Users/nicholasdwork/Documents/Data/optData/20260411/zebrafish' );
    illumFile = '/Users/nicholasdwork/Documents/Data/optData/20260411/1_justBackground.DNG';
    rotCenterXs = 1991;
    cropStartY = 1000;
    cropStopY = 2500;

  elseif datacase == 3
    dataDir = fixFileseps( '/Users/nicholasdwork/Documents/Data/optData/20260805/20260731_rigidTube_0_225_degree/zebrafish' );
    illumFile = '/Users/nicholasdwork/Documents/Data/optData/20260805/20260731_rigidTube_0_225_degree/1_justBackground.DNG';
    airMargin = 500;
    rotCenterXs = 1976;
    cropStartY = 866;
    cropStopY = 2242;
    rotAngle_deg = 0.225;  % rotation between projections

  elseif datacase == 4
    dataDir = fixFileseps( '/Users/nicholasdwork/Documents/Data/optData/20260928/20260928_rigidTube_0_225_degree/zebrafish' );
    illumFile = '/Users/nicholasdwork/Documents/Data/optData/20260928/20260928_rigidTube_0_225_degree/1_justBackground.DNG';
    airMargin = 900;
    rotCenterXs = 2021;
    cropStartY = 1150;
    cropStopY = 2280;
    rotAngle_deg = 0.225;  % rotation between projections
    dataFileIndxFor180 = ceil( 180 / rotAngle_deg );

  elseif datacase == 5
    dataDir = fixFileseps( '/Users/nicholasdwork/Library/CloudStorage/Dropbox/Sharing/forGenna/OPT_Data/20261101_coloredTube_0_225_degree/coloredTube' );
    illumFile = '/Users/nicholasdwork/Library/CloudStorage/Dropbox/Sharing/forGenna/OPT_Data/20261101_coloredTube_0_225_degree/1_justBackground.DNG' );
    airMargin = 900;
    rotCenterXs = 2021;
    cropStartY = 1150;
    cropStopY = 2280;
    rotAngle_deg = 0.225;  % rotation between projections
    dataFileIndxFor180 = ceil( 180 / rotAngle_deg );
  end

  halfWidth = 1000;
  halfHeight = 1000;

  [ squares, sImgCal ] = getSquareCorners( calDir, 'showScale', showScale );

  midIndxsRC = size2midIndxs( sImgCal );   % [ row, column ]
  midIndxsXY = [ midIndxsRC(2); midIndxsRC(1) ];       % [x; y]

  nSquares = numel( squares );
  [ newPts, T ] = normalizePts2D( cell2mat( squares' ), 't', midIndxsXY );
  normSquares = cell( 1, 1, nSquares );
  for squareIndx = 1 : numel( squares )
    normSquares{ 1, 1, squareIndx } = newPts( 4*(squareIndx-1)+1 : 4*squareIndx, : );
  end

  K = calibrateCamFromSquares( cell2mat( normSquares ) );
  disp( 'K:' );
  disp( K );

  K_pixel = T \ K;
  K_pixel = K_pixel / K_pixel(3,3);
  disp('K in pixel units:');
  disp( K_pixel );

  if ~exist( 'rotCenterXs', 'var' ) || numel( rotCenterXs ) == 0
    rotCenterXs = round( K_pixel(1,3) ) - 250 : 5 : round( K_pixel(1,3) ) + 250;
  end

  disp('image center [x;y]:');
  disp(midIndxsXY);

  disp('principal point [x;y] from the bare camera calibration:');
  disp(K_pixel(1:2,3));


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
  nDataFiles = numel( dataFiles );

  img0 = readRawFrame( [ dataDir, filesep, dataFiles(1).name ] );
  sImg = size( img0 );
  epsVal = 1e-6;

  illumRaw = [];
  if exist( 'illumFile', 'var' ) && numel( illumFile ) > 0
    illumRaw = readRawFrame( illumFile );
    if ~isequal( size( illumRaw ), sImg )
      error( 'Background image size does not match the projection image size.' );
    end
    illumRaw = max( illumRaw, epsVal );
  end

  leftAirColsRaw  = 1 : airMargin - 1;
  rightAirColsRaw = sImg(2)-airMargin : sImg(2);
  airColsRaw = [ leftAirColsRaw, rightAirColsRaw ];

  centerIndxY = floor( sImg(1) / 2 ) + 1;
  centerIndxX = floor( sImg(2) / 2 ) + 1;
  centerRow = centerIndxY - cropStartY + 1;

  if numel( cropStartY ) == 0
    cropStartY = centerIndxY - halfHeight;
    cropStopY  = centerIndxY + halfHeight;
  end

  %parfor rotCenterX_indx = 1 : numel( rotCenterXs )
for rotCenterX_indx = 1 : numel( rotCenterXs )
    rotCenterX = rotCenterXs( rotCenterX_indx );
    disp([ 'Working on rotCenterX = ', num2str(rotCenterX) ]);
  
    % Shift each image so that the detector element whose ray passes through
    % the center of rotation lands at the center of the crop.
    shiftX = centerIndxX - rotCenterX;

    cropStartX = centerIndxX - halfWidth;
    cropStopX  = centerIndxX + halfWidth;
  
    % 1-based detector coordinates inside the cropped, shifted sinogram.
    detCenterX = halfWidth + 1;
  
    % The magnifier was NOT part of the calibration, so the calibrated principal point is not
    % reliable for the OPT data.  Until the full optical train is calibrated, force a
    % self-consistent geometry by setting the principal point equal to the detector element
    % whose ray passes through the center of rotation.
    principalPointX = detCenterX;
  
    % fan2Parallel uses zero-based detector coordinates.
    detCenterX0 = detCenterX - 1;
    principalPointX0 = principalPointX - 1;

    if numel( illumFile ) > 0
      % Use the blank-field image directly as the 2D flat field.
      illumRows = illumRaw( cropStartY : cropStopY, : );   %#ok<PFBNS>
    end

    % Allocate the CROPPED line-integral stack directly.
    %muFlatPanel = zeros( cropStopY - cropStartY + 1, 2 * halfWidth + 1, nDataFiles );
    muFlatPanel = cell( 1, 1, nDataFiles );

    for fileIndx = nDataFiles : -1 : 1
    %parfor fileIndx = 1 : nDataFiles
      projRaw = readRawFrame( [ dataDir, filesep, dataFiles( fileIndx ).name ] );
      projRows = projRaw( cropStartY : cropStopY, : );

      if numel( illumFile ) > 0
        muRows = -log( max( projRows, epsVal ) ./ illumRows );
        muRows( ~isfinite( muRows ) ) = 0;
        %muRows = max( muRows, 0 );

      else

        % Estimate air/reference intensity from raw border columns before shifting.
        I0row = median( projRows( :, airColsRaw ), 2, 'omitnan' );
        good = isfinite( I0row );
        if nnz( good ) >= 2
          I0row( ~good ) = interp1( find( good ), double( I0row( good ) ), ...
            find( ~good ), 'linear', 'extrap' );
        elseif nnz( good ) == 1
          I0row( ~good ) = I0row( good );
        else
          I0row(:) = 1;
        end
        I0row = smoothdata( I0row, 'movmedian', 31 );
        I0row = max( I0row, epsVal );
        I0img = repmat( I0row, [ 1, size( projRows, 2 ) ] );
    
        projRows = min( projRows, I0img );
    
        muRows = -log( max( projRows, epsVal ) ./ max( I0img, epsVal ) );
        muRows( ~isfinite( muRows ) ) = 0;
        muRows = max( muRows, 0 );
      end

      % Shift in mu-space; outside the detector support the line integral is zero.
      muRows = imtranslate( muRows, [ shiftX, 0 ], 'linear', 'FillValues', 0 );

      % Crop AFTER shifting and store only the reconstruction window.
      muFlatPanel{1,1,fileIndx} = muRows( :, cropStartX : cropStopX );

figure;  imshowscale( projRows( :, cropStartX : cropStopX ) );
figure;  imshowscale( muRows( :, cropStartX : cropStopX ) );
disp( 'I got here' );
    end

    muFlatPanel = cell2mat( muFlatPanel );

    rotAngle_rad = rotAngle_deg * pi / 180;
    rotDist = distCam2RotCenter_mm / pixelPitch_mm;  % source-to-rotation-center distance in detector pixels

    if ~exist( 'sImgOut', 'var' )
      sinoFan = squeeze( muFlatPanel( centerRow, :, : ) );
      sinoPara = fan2Parallel( sinoFan, dSize, focalLengthX, rotDist, 'dProjAngle', rotAngle_rad, ...
        'detCenter', detCenterX0, 'principalPoint', principalPointX0 );
      sinoPara( ~isfinite( sinoPara ) ) = 0;
      sImgOut = [ size( sinoPara, 1 ), size( sinoPara, 1 ) ];
    end
  
    recon3D = feldkampRecon( muFlatPanel, sImgOut, focalLengthX, rotDist, 'dProjAngle', rotAngle_rad, ...
      'dSizeX', dSize, 'detCenter', detCenterX0, 'principalPoint', principalPointX0, 'inputIsLineIntegrals', true, ...
      'verbose', true );

imwrite( recon3D / max( recon3D(:) ), ['./rotCenters/rcx_', indx2str( rotCenterX, max(rotCenterXs) ), '.jpg' ]);
  end

end


function files = sortFilesByNumericSuffix( files )
  if isempty( files ), return; end

  names = { files.name };
  nums = inf( numel( names ), 1 );
  for i = 1 : numel( names )
    token = regexp( names{i}, '(\d+)(?=\D*$)', 'tokens', 'once' );
    if ~isempty( token )
      nums(i) = str2double( token{1} );
    end
  end

  orderTable = [ isinf( nums ), nums, ( 1 : numel( nums ) )' ];
  [ ~, order ] = sortrows( orderTable, [ 1 2 3 ] );
  files = files( order );
end


