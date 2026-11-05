
function K_pixel = getKPixel( calDir, varargin )

  p = inputParser;
  p.addParameter( 'showScale', 1, @ispositive );
  p.parse( varargin{:} );
  showScale = p.Results.showScale;

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

  disp('image center [x;y]:');
  disp(midIndxsXY);

  disp('principal point [x;y] from the bare camera calibration:');
  disp(K_pixel(1:2,3));

end