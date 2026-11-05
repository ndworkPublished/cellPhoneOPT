

function run_simulateOPT
  close all;  clear;

  totRot = 2*pi;
  nAngles = 720;
  sImg = [ 256 256 ];
  cam2RotCenterDist = 300;

  detSizeX = 1;
  detSizeY = 1;
  f = 100;
  dfx = detSizeX * f;
  dfy = detSizeY * f;
  K = [ [ dfx  0   0 ]; ...
        [  0  dfy  0 ]; ...
        [  0   0   1 ]; ];

  d2Rot = 200;  % distance from fulcrum to center of rotation

  I0 = 1;
  %[ sinoFlatPanel, projAngles ] = simulateOPT( nAngles, sImg, K, cam2RotCenterDist, 'fullAngle', totRot, 'I0', I0 );
load( 'junk.mat', 'sinoFlatPanel', 'projAngles' );

  sinoFan = squeeze( sinoFlatPanel(129,:,:) );
  sinoFan = -log( sinoFan / I0 );  % convert from received intensities to integrals of attenuation.


  sinoPara = fan2Parallel( sinoFan, detSizeX, f, d2Rot, 'projAngles', projAngles );
  sinoPara( ~isfinite( sinoPara ) ) = 0;

  % dProjAngle = totRot / (nAngles + 1);
  % dProjAngleDeg = dProjAngle * 180 / pi;
  % sinoParaBuiltIn = fan2para(sinoFanSlice, cam2RotCenterDist, ...
  %     'FanSensorGeometry', 'line', ...
  %     'FanSensorSpacing', detSizeX, ...
  %     'ParallelSensorSpacing', detSizeX, ...
  %     'ParallelCoverage', 'cycle', ...
  %     'FanRotationIncrement', dProjAngleDeg);
  % figure;  imshowscale( sinoParaBuiltIn );

  %sinoPara = imresize( sinoPara, [ sImg(1) size( sinoPara, 2 ) ], 'bilinear' );

  sImgOut = [ size( sinoPara, 1 ) size( sinoPara , 1 ) ];
  %out = filtBackProject( sinoPara, sImgOut, 'projAngles', projAngles, 'dSize', detSizeX );
  %figure;  imshowscale( out, 5 );

  recon3D = feldkampRecon( sinoFlatPanel, sImgOut, f, d2Rot, 'I0', I0, 'projAngles', projAngles,'verbose', true );

  figure;  showImageCube( squeeze( permute( recon3D([120, 129, 130],:,:), [2 3 1] ) ), 3 );
end

