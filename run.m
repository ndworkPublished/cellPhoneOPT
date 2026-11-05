
load( 'junk.mat', 'sino', 'sOut', 'dSize', 'projAngles' );
recon = filtBackProject( sino, sOut, 'dSize', dSize, 'projAngles', projAngles );

