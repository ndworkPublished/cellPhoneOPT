
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
