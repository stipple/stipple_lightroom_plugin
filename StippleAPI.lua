 -- Lightroom SDK
local LrBinding = import 'LrBinding'
local LrDate = import 'LrDate'
local LrDialogs = import 'LrDialogs'
local LrErrors = import 'LrErrors'
local LrFunctionContext = import 'LrFunctionContext'
local LrHttp = import 'LrHttp'
local LrMD5 = import 'LrMD5'
local LrPathUtils = import 'LrPathUtils'
local LrView = import 'LrView'
local LrXml = import 'LrXml'

local prefs = import 'LrPrefs'.prefsForPlugin()

local bind = LrView.bind
local share = LrView.share

local logger = import 'LrLogger'( 'StippleAPI' )
logger:enable('print')

local JSON = require 'json'
local urlBase = 'https://stipple.com'

--============================================================================--

StippleAPI = {}

--------------------------------------------------------------------------------

local appearsAlive

--------------------------------------------------------------------------------

local function formatError( nativeErrorCode )
  return LOC "$$$/Stipple/Error/NetworkFailure=Could not contact the Stipple web service. Please check your Internet connection."
end

--------------------------------------------------------------------------------

local function trim( s )
  return string.gsub( s, "^%s*(.-)%s*$", "%1" )
end

--------------------------------------------------------------------------------

function StippleAPI.showApiKeyDialog( message )
  LrFunctionContext.callWithContext( 'StippleAPI.showApiKeyDialog', function( context )
    local f = LrView.osFactory()
    local properties = LrBinding.makePropertyTable( context )

    properties.apiKey = prefs.apiKey

    local contents = f:column {
      bind_to_object = properties,
      spacing = f:control_spacing(),
      fill = 1,

      f:static_text {
        title = LOC "$$$/Stipple/ApiKeyDialog/Message=In order to use the Stipple plug-in, you must obtain an API key from Stipple.com. Sign on to Stipple and register for a key.",
        fill_horizontal = 1,
        width_in_chars = 55,
        height_in_lines = 2,
        size = 'small',
      },

      message and f:static_text {
        title = message,
        fill_horizontal = 1,
        width_in_chars = 55,
        height_in_lines = 2,
        size = 'small',
        text_color = import 'LrColor'( 1, 0, 0 ),
      } or 'skipped item',
        f:row {
          spacing = f:label_spacing(),

          f:static_text {
            title = LOC "$$$/Stipple/ApiKeyDialog/Key=API Key:",
            alignment = 'right',
            width = share 'title_width',
          },

          f:edit_field {
            fill_horizonal = 1,
            width_in_chars = 35,
            value = bind 'apiKey',
          },
        },
      }

      local result = LrDialogs.presentModalDialog {
        title = LOC "$$$/Stipple/ApiKeyDialog/Title=Enter Your Stipple API Key",
        contents = contents,
        accessoryView = f:push_button {
        title = LOC "$$$/Stipple/ApiKeyDialog/GoToStipple=Get Stipple API Key...",
        action = function()
          LrHttp.openUrlInBrowser( urlBase .. "/api_docs/v1" )
         end
      },
    }

    if result == 'ok' then
      prefs.apiKey = trim ( properties.apiKey )
    else
      LrErrors.throwCanceled()
    end
  end )
end

--------------------------------------------------------------------------------

function StippleAPI.getApiKeyAndSecret()
  local apiKey = prefs.apiKey

  while not(type( apiKey ) == 'string' and #apiKey > 10) do
    local message

    if apiKey then
      message = LOC "$$$/Stipple/ApiKeyDialog/Invalid=The key below is not valid."
    end

    StippleAPI.showApiKeyDialog( message )
    apiKey = prefs.apiKey
  end

  return apiKey
end

--------------------------------------------------------------------------------

function StippleAPI.makeApiSignature( params )
  local apiKey = StippleAPI.getApiKeyAndSecret()

  if not params.api_key then
    params.api_key = apiKey
  end

  -- Get list of arguments in sorted order.
  local argNames = {}
  for name in pairs( params ) do
    table.insert( argNames, name )
  end

  table.sort( argNames )

  -- Build the secret string to be MD5 hashed.
  local allArgs = sharedSecret
  for _, name in ipairs( argNames ) do
    if params[ name ] then  -- might be false
      allArgs = string.format( '%s%s%s', allArgs, name, params[ name ] )
    end
  end

  return LrMD5.digest( allArgs )
end

--------------------------------------------------------------------------------

function StippleAPI.callRestMethod( propertyTable, params )
  local apiKey = StippleAPI.getApiKeyAndSecret()

  if not params.api_key then
    params.api_key = apiKey
  end

  local suppressError = params.suppressError
  local suppressErrorCodes = params.suppressErrorCodes
  local skipAuthToken = params.skipAuthToken

  params.suppressError = nil
  params.suppressErrorCodes = nil
  params.skipAuthToken = nil

  local url = string.format( urlBase .. '/api/v1/%s', assert( params.url ) )

  for name, value in pairs( params ) do
    local query_seperator = '?'

    if name ~= 'url' and value then
      local gsubString = '([^0-9A-Za-z])'

      value = tostring( value )

      if name ~= 'tag_id' then
        value = string.gsub( value, gsubString, function( c ) return string.format( '%%%02X', string.byte( c ) ) end )
      end

      value = string.gsub( value, ' ', '+' )
      params[ name ] = value

      url = string.format( '%s%s%s=%s', url, query_seperator, name, value )
      query_seperator = '&'
    end
  end

  logger:info( 'calling Stipple API via URL:', url )
  local response, hdrs = LrHttp.get( url )
  logger:info( 'Stipple response:', response )

  if not response then
    appearsAlive = false

    if suppressError then
      return { stat = "noresponse" }
    else
      if hdrs and hdrs.error then
        LrErrors.throwUserError( formatError( hdrs.error.nativeCode ) )
      end
    end
  end

    -- Mac has different implementation with that on Windows when the server refuses the request.
  if hdrs.status ~= 200 then
    LrErrors.throwUserError( formatError( hdrs.status ) )
  end

  appearsAlive = true

  local json = JSON:decode(response)

  if suppressErrorCodes then
    local errorCode = simpleXml and simpleXml.err and tonumber( simpleXml.err.code )

    if errorCode and suppressErrorCodes[ errorCode ] then
      suppressError = true
    end
  end

  if tonumber(json.status) == 200 or suppressError then
    logger:info( 'Stipple API returned status ' .. json.status )
      
    return json, response
  else
    logger:warn( 'Stipple API returned error', tostring(json.status) )
    LrErrors.throwUserError( LOC( "$$$/Stipple/Error/API=Stipple API returned an error message (function ^1, status ^2, error ^3)",
      tostring(params.url), tostring(json.status), tostring(json.error)))
  end
end

--------------------------------------------------------------------------------

function StippleAPI.uploadPhoto( propertyTable, params )
  assert( type( params ) == 'table', 'StippleAPI.uploadPhoto: params must be a table' )

  local apiKey = StippleAPI.getApiKeyAndSecret()
  local postUrl = params.id and urlBase .. '/api/v1/photos/update' or urlBase .. '/api/v1/photos/upload/'
  local originalParams = params.id and table.shallowcopy( params )

  logger:info( 'uploading photo', params.filePath )

  local filePath = assert( params.filePath )
  params.filePath = nil
	
  local fileName = LrPathUtils.leafName( filePath )
  local mimeChunks = {}

  for argName, argValue in pairs( params ) do
    if argName ~= 'api_key' and argName ~= 'photo' and argValue then
      mimeChunks[ #mimeChunks + 1 ] = { name = argName, value = argValue }
    end
  end
 
  mimeChunks[ #mimeChunks + 1 ] = { name = 'api_key', value = apiKey }
    
  if params.photo.caption then
    mimeChunks[ #mimeChunks + 1 ] = { name = 'photo[caption]', value = params.photo.caption }
  end 
    
  mimeChunks[ #mimeChunks + 1 ] = { name = 'photo[source_page]', value = params.photo.source_page  }
  mimeChunks[ #mimeChunks + 1 ] = { name = 'file', fileName = fileName, filePath = filePath, contentType = 'application/octet-stream' }

  local response, hdrs = LrHttp.postMultipart( postUrl, mimeChunks ) -- Post it and wait for confirmation.

  if not response then
    if hdrs and hdrs.error then
      LrErrors.throwUserError( formatError( hdrs.error.nativeCode ) )
    end
  end

  -- Parse Stipple response for photo ID.
  local json = JSON:decode(response)

  if tonumber(json.status) == 200 then
    return json.data.photo.id
  elseif params.id and json.error and tonumber(hdrs.error.nativeCode) == 422 then
        -- Photo is missing. Most likely, the user deleted it outside of Lightroom. Just repost it.

--        originalParams.id = nil
--        return StippleAPI.uploadPhoto( propertyTable, originalParams )
    LrErrors.throwUserError( LOC( "$$$/Stipple/Error/API/Upload=Stipple API Falling into the elseif case"))
  else
    logger:info( 'uploading photo', json.status )

    LrErrors.throwUserError( LOC( "$$$/Stipple/Error/API/Upload=Stipple API returned an error message (function supload, message ^1)",
      tostring( json.status )))
  end
end

--------------------------------------------------------------------------------

function StippleAPI.openAuthUrl()
  local response = StippleAPI.callRestMethod( nil, { url = 'users/me' } )

  return response.data
end

--------------------------------------------------------------------------------

local function getPhotoInfo( propertyTable, params )
  return nil, nil
end

--------------------------------------------------------------------------------

function StippleAPI.constructPhotoURL( propertyTable, params )
  return urlBase .. '/photos/' .. params.id	
end

--------------------------------------------------------------------------------

function StippleAPI.constructPhotosetURL( propertyTable, photosetId )
  return urlBase .. "/photos/" .. propertyTable.nsid .. "/sets/" .. photosetId
end

--------------------------------------------------------------------------------

function StippleAPI.constructPhotostreamURL( propertyTable )
  return urlBase .. "/a#library/untagged"
end

-------------------------------------------------------------------------------

local function traversePhotosetsForTitle( node, title )
  return ''
end

--------------------------------------------------------------------------------

function StippleAPI.createOrUpdatePhotoset( propertyTable, params )
  return true
end

--------------------------------------------------------------------------------

function StippleAPI.listPhotosFromPhotoset( propertyTable, params )
  return nil
end

--------------------------------------------------------------------------------

function StippleAPI.setPhotosetSequence( propertyTable, params )
  return true
end

--------------------------------------------------------------------------------

function StippleAPI.addPhotosToSet( propertyTable, params )
  return true
end

--------------------------------------------------------------------------------

function StippleAPI.deletePhoto( propertyTable, params )
  return true
end

--------------------------------------------------------------------------------

function StippleAPI.deletePhotoset( propertyTable, params )
  return true
end

--------------------------------------------------------------------------------

local function removePhotoTags( propertyTable, node, previous_tag )
  return false
end

--------------------------------------------------------------------------------

function StippleAPI.setImageTags( propertyTable, params )
  return true
end

--------------------------------------------------------------------------------

function StippleAPI.getUserInfo( propertyTable, params )
  return { }
end

--------------------------------------------------------------------------------

function StippleAPI.getComments( propertyTable, params )
  return nil
end

--------------------------------------------------------------------------------

function StippleAPI.addComment( propertyTable, params )
  return
end

--------------------------------------------------------------------------------

function StippleAPI.testStippleConnection( propertyTable )
  return true
end