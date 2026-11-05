
function run_geoDistortion
  close all; rng(1);

  showScale = 2;
  radialDistortionOrder = 1;

  dataDir = '/Users/nicholasdwork/Documents/Data/optData/20240702_tubeInTubePhantoms/LightLowerDown';
  calibrationMovie = 'CalibrationTarget.MOV';
  
  v = VideoReader( [ dataDir, filesep, calibrationMovie ] );

  img100 = rgb2gray( double( read( v, 100 ) ) / 255. );

  figure;  imshowscale( img100, showScale );

  load( 'features.mat', 'features1', 'features2', 'features3', 'features4', 'features5', 'features6', 'features7' );
  showFeaturesOnImg( features1, 'scale', showScale, 'color', 'w', 'connect', true );
  showFeaturesOnImg( features2, 'scale', showScale, 'color', 'w', 'connect', true );
  showFeaturesOnImg( features3, 'scale', showScale, 'color', 'w', 'connect', true );
  showFeaturesOnImg( features4, 'scale', showScale, 'color', 'w', 'connect', true );
  showFeaturesOnImg( features5, 'scale', showScale, 'color', 'w', 'connect', true );
  showFeaturesOnImg( features6, 'scale', showScale, 'color', 'w', 'connect', true );
  showFeaturesOnImg( features7, 'scale', showScale, 'color', 'w', 'connect', true );

  %features = getFeaturesFromImg( 7, showScale );
  %features8 = features;
  %save( 'features.mat', 'features1', 'features2', 'features3', 'features4', 'features5', ...
  %  'features6', 'features7', 'features8' );

  lines = { fliplr(features1), fliplr(features2), fliplr(features3), ...
            fliplr(features4), fliplr(features5), fliplr(features6), fliplr( features7 ) };

  [ ks, c ] = findRadialDistortionFromLines( lines, radialDistortionOrder, 'fixedCenter', true );

  correctedImg = applyRadialDistortion( img100, ks, 'c', c, 'dir', -1, 'space', 'full' );
  figure;  imshowscale( correctedImg, showScale );
end
