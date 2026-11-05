
function run_calibrateTest
  close all; rng(1); clear;   %#ok<CLEAR0ARGS>

  img = rgb2gray( double( imread( './squares.jpg' ) ) / 255. );

  % Square 1 - X, Y
  square1 = [ ...
    845, 654; ...
    1978, 407; ...
    1058, 1931; ...
    1954, 1461; ];

  % Square 2 - X, Y
  square2 = [ ...
    2089, 413; ...
    3283, 694; ...
    2041, 1468; ...
    2976, 1943; ];

  % Square 3 - X, Y
  square3 = [ ...
    1996, 1550; ...
    2919, 2042; ...
    1106, 2042; ...
    2064, 2861; ];

  figure;  imshowscale( img );
  % labelImgPts( square1 );
  % labelImgPts( square2 );
  % labelImgPts( square3 );
  % showFeaturesOnImg( square1 );
  % showFeaturesOnImg( square2 );
  % showFeaturesOnImg( square3 );

  midIndxs = size2midIndxs( size( img ) );
  [ newPts, T ] = normalizePts2D( [ square1; square2; square3; ], 't', midIndxs );
  normSquare1 = newPts(1:4,:);
  normSquare2 = newPts(5:8,:);
  normSquare3 = newPts(9:12,:);
  normSquares = cat( 3, normSquare1, normSquare2, normSquare3 );

  K = calibrateCamFromSquares( normSquares );
  disp( 'K:' );
  disp( K );

  K_pixel = T \ K;
  K_pixel = K_pixel / K_pixel(3,3);
  disp('K in pixel units:');
  disp( K_pixel );


  sImg = size( img );
  pts = [ round( fliplr(sImg) / 2 );
          K_pixel(2,3) K_pixel(1,3) ];
  showFeaturesOnImg( pts );
end
