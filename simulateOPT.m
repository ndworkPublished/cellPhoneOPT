
function [ sino, projAngles ] = simulateOPT( nAngles, sImg, K, dist, varargin )
  % sino = simulateOPT( nAngles, sImg, K, dist [, 'fullAngle', fullAngle, 'I0', I0 ] )
  %
  % Simulate Optical Projection Tomography of two cylinders with different attenuation
  % coefficients.
  %
  % Inputs:
  % nAngles - the number of angles at which data is acquired
  % sImg - a 2 element array specifying the number of pixels in the camera
  % K - a 3x3 matrix representing the intrinsic camera matrix
  % dist - a scalar specifying the distance (in same units as focal length) of the camera to the center of rotation
  %
  % Optional Inputs:
  % fullAngle - the angle between the principal ray of the first and last projections
  % I0 - the intensity image of the light source
  %
  % Written by Nicholas Dwork, Copyright 2024
  %
  % This software is offered under the GNU General Public License 3.0.  It
  % is offered without any warranty expressed or implied, including the
  % implied warranties of merchantability or fitness for a particular
  % purpose.

  p = inputParser;
  p.addParameter( 'fullAngle', 2*pi, @ispositive );
  p.addParameter( 'I0', 1 );
  p.parse( varargin{:} );
  fullAngle = p.Results.fullAngle;
  I0 = p.Results.I0;

  %-- Make the camera matrix P

  c = [ 0; 0; -dist; ];  % camera center
  cXZY = [ c(1); c(3); c(2); ];
  R = eye(3);
  P = K * R * [ eye(3), -c ];  % The camera matrix is located at the origin

  imgCoords = size2imgCoordinates( sImg );
  ys = imgCoords{1};  % positive y for the camera is pointed down
  xs = imgCoords{2};  % positive x for the camera is pointed right
  [ xs, ys ] = meshgrid( xs, ys );
  spacePts = P \ [ xs(:)'; ys(:)'; ones(1,numel(xs)); ];
  spacePts = bsxfun( @rdivide, spacePts(1:3,:), spacePts(4,:) );
  rays = bsxfun( @minus, spacePts, c );
  raysXZY = rays( [ 1 3 2 ], : );
  nRays = size( rays, 2 );

  %-- Make the cylinder objects

  mu1 = 0.01;  % attenuation coefficient of cylinder 1
  mu2 = 0.02;  % attenuation coefficient of cylinder 2

  rC1 = 50;   % radius of cylinder 1 in pixels
  rC2 = 30;   % radius of cylinder 2 in pixels

  cC1 = [ -60 -40 ];  % (x,z) center of cylinder 1 in pixels
  cC2 = [  50  20 ];  % (x,z) center of cylinder 2 in pixels

  dAngle = fullAngle / nAngles;
  projAngles = dAngle * ( 0 : nAngles-1 )';

  %-- Simulate the imaging
  source = I0 * ones( sImg );
  sino = cell( 1, 1, nAngles );
  pf = parforProgress( nAngles );
%fH = figure;
  parfor angleIndx = 1 : nAngles
    pf.progress( angleIndx, 10 );   %#ok<PFBNS>
    projAngle = projAngles( angleIndx );

    % Rotate the centers of the cylinders
    R = [ [  cos( projAngle )  0  sin( projAngle ) ]; ...
          [        0           1         0         ]; ...
          [ -sin( projAngle )  0  cos( projAngle ) ]; ];

    cC1Rot = R * [ cC1(1) 0 cC1(2) ]';   cC1RotXZY = cC1Rot([1 3 2]);  %#ok<PFBNS>
    cC2Rot = R * [ cC2(1) 0 cC2(2) ]';   cC2RotXZY = cC2Rot([1 3 2]);  %#ok<PFBNS>

    [ intersections1_XZY, ts1 ] = lineCylinderIntersect( cXZY, raysXZY', cC1RotXZY, rC1 );   %#ok<ASGLU>
    [ intersections2_XZY, ts2 ] = lineCylinderIntersect( cXZY, raysXZY', cC2RotXZY, rC2 );   %#ok<ASGLU>

    intersections1 = intersections1_XZY( :, [1 3 2] );
    intersections2 = intersections2_XZY( :, [1 3 2] );

    dist2intersect1 = LpNorms( bsxfun( @minus, intersections1, c' ), 2, 2 );
    dist2intersect2 = LpNorms( bsxfun( @minus, intersections2, c' ), 2, 2 );

    dist2intersect1( abs( imag( ts1(:) ) ) > 0 ) = 0;
    dist2intersect2( abs( imag( ts2(:) ) ) > 0 ) = 0;
    
    dist2intersect1 = [ dist2intersect1( 1 : nRays )  dist2intersect1( nRays+1 : end ) ];
    dist2intersect2 = [ dist2intersect2( 1 : nRays )  dist2intersect2( nRays+1 : end ) ];

    dDist1 = reshape( abs( dist2intersect1(:,1) - dist2intersect1(:,2) ), sImg );
    dDist2 = reshape( abs( dist2intersect2(:,1) - dist2intersect2(:,2) ), sImg );

    received = source .* exp( -mu1 * dDist1 ) .* exp( -mu2 * dDist2 );
%figure( fH );  imshow( received );

    sino{1,1,angleIndx} = reshape( received, sImg );
  end

  sino = cell2mat( sino );
end
