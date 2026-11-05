
function run_test
  close all; rng(1);
  showScale = 5;
  nProjections = 180;

  p = phantom( 'Modified Shepp-Logan', 256 );
  figure;  imshowscale( p, showScale );  titlenice( 'true' );
  sImg = size( p );

  sino = zeros( 256, nProjections );
  projAngles_deg = 0 : nProjections-1;
  for i = 0 : nProjections-1
    pRotated = imrotate( p, i, 'bilinear', 'crop' );
    sino(:,i+1) = sum( pRotated, 2 );
  end

  figure;  imshowscale( sino, showScale );

  projAngles = projAngles_deg * (pi/180);
  recon = filtBackProject( sino, sImg, 'projAngles', projAngles );

  figure; imshowscale( recon, showScale );
  figure;  imshowscale( p - recon, showScale );

  re = relErr( p, recon );
  disp([ 'RelErr: ', num2str( re ) ]);
end
