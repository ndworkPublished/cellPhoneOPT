
function muFlatPanel = getMuFlatPanel( dataDir, dataFiles, illumRows, shiftX, ...
  cropStartY, cropStopY, cropStartX, cropStopX, varargin )

  p = inputParser;
  p.addParameter( 'slices2keep', [], @isnumeric );
  p.parse( varargin{:} );
  slices2keep = p.Results.slices2keep;

  epsVal = 1e-6;
  nDataFiles = numel( dataFiles );

  if isempty( slices2keep )
    muFlatPanel = zeros( cropStopY - cropStartY + 1, cropStopX - cropStartX + 1, nDataFiles, 'single' );
    illumSelected = single( illumRows );
  else
    muFlatPanel = zeros( numel( slices2keep ), cropStopX - cropStartX + 1, nDataFiles, 'single' );
    illumSelected = single( illumRows( slices2keep, : ) );
  end

  for fileIndx = 1 : nDataFiles
  %parfor fileIndx = 1 : nDataFiles

    projRaw = single( readRawFrame( [ dataDir, filesep, dataFiles( fileIndx ).name ] ) );

    if isempty( slices2keep )
      projRows = projRaw( cropStartY : cropStopY, : );
    else
      projRows = projRaw( cropStartY - 1 + slices2keep, : );
    end

    muRows = -log( max( projRows, epsVal ) ./ illumSelected );
    muRows( ~isfinite( muRows ) ) = 0;

    % Shift in mu-space; outside the detector support the line integral is zero.
    muRows = imtranslate( muRows, [ shiftX, 0 ], 'linear', 'FillValues', 0 );

    muFlatPanel(:,:,fileIndx) = muRows( :, cropStartX : cropStopX );
  end

end
