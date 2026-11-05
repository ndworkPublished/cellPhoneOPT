
function img = readRawFrame( filename )
  imgRGB = demosaic( rawread( filename ), 'bggr' );
  img = rot90( im2single( imgRGB(:,:,2) ), 2 );
end


