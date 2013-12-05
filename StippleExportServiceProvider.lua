
-- Lightroom SDK
local LrBinding = import 'LrBinding'
local LrDialogs = import 'LrDialogs'
local LrErrors = import 'LrErrors'
local LrFileUtils = import 'LrFileUtils'
local LrPathUtils = import 'LrPathUtils'
local LrView = import 'LrView'

local logger = import 'LrLogger'( 'StippleAPI' )
logger:enable('print')

-- Common shortcuts
local bind = LrView.bind
local share = LrView.share

-- JSON Reading/Writing
local JSON = require 'json'

-- Stipple plug-in
require 'StippleAPI'
require 'StipplePublishSupport'

local exportServiceProvider = {}

-- A typical service provider would probably roll all of this into one file, but
-- this approach allows us to document the publish-specific hooks separately.
for name, value in pairs( StipplePublishSupport ) do
  exportServiceProvider[ name ] = value
end

exportServiceProvider.supportsIncrementalPublish = 'only'

--------------------------------------------------------------------------------
--- (optional) Plug-in defined value declares which fields in your property table should
 -- be saved as part of an export preset or a publish service connection. If present,
 -- should contain an array of items with key and default values. For example:
    -- <pre>
        -- exportPresetFields = {<br/>
            -- &nbsp;&nbsp;&nbsp;&nbsp;{ key = 'username', default = "" },<br/>
            -- &nbsp;&nbsp;&nbsp;&nbsp;{ key = 'fullname', default = "" },<br/>
            -- &nbsp;&nbsp;&nbsp;&nbsp;{ key = 'nsid', default = "" },<br/>
            -- &nbsp;&nbsp;&nbsp;&nbsp;{ key = 'privacy', default = 'public' },<br/>
            -- &nbsp;&nbsp;&nbsp;&nbsp;{ key = 'privacy_family', default = false },<br/>
            -- &nbsp;&nbsp;&nbsp;&nbsp;{ key = 'privacy_friends', default = false },<br/>
        -- }<br/>
    -- </pre>
 -- <p>The <code>key</code> item should match the values used by your user interface
 -- controls.</p>
 -- <p>The <code>default</code> item is the value to the first time
 -- your plug-in is selected in the Export or Publish dialog. On second and subsequent
 -- activations, the values chosen by the user in the previous session are used.</p>
 -- <p>First supported in version 1.3 of the Lightroom SDK.</p>
    -- @name exportServiceProvider.exportPresetFields
    -- @class property

exportServiceProvider.exportPresetFields = {
  { key = 'username', default = "" },
  { key = 'fullname', default = "" },
  { key = 'nsid', default = "" },
--    { key = 'isUserPro', default = false },
--    { key = 'auth_token', default = '' },
--    { key = 'privacy', default = 'public' },
--    { key = 'privacy_family', default = false },
--    { key = 'privacy_friends', default = false },
--    { key = 'safety', default = 'safe' },
--    { key = 'hideFromPublic', default = false },
  { key = 'type', default = 'photo' },
  { key = 'addToPhotoset', default = false },
  { key = 'photoset', default = '' },
  { key = 'titleFirstChoice', default = 'title' },
  { key = 'titleSecondChoice', default = 'filename' },
  { key = 'titleRepublishBehavior', default = 'replace' },
}

--------------------------------------------------------------------------------
--- (optional) Plug-in defined value restricts the display of sections in the Export
 -- or Publish dialog to those named. You can use either <code>hideSections</code> or
 -- <code>showSections</code>, but not both. If present, this should be an array
 -- containing one or more of the following strings:
    -- <ul>
        -- <li>exportLocation</li>
        -- <li>fileNaming</li>
        -- <li>fileSettings</li>
        -- <li>imageSettings</li>
        -- <li>outputSharpening</li>
        -- <li>metadata</li>
        -- <li>watermarking</li>
    -- </ul>
 -- <p>You cannot suppress display of the "Connection Name" section in the Publish Manager dialog.</p>
 -- <p>If you suppress the "exportLocation" section, the files are rendered into
 -- a temporary folder which is deleted immediately after the Export operation
 -- completes.</p>
 -- <p>First supported in version 1.3 of the Lightroom SDK.</p>
    -- @name exportServiceProvider.showSections
    -- @class property

--exportServiceProvider.showSections = { 'fileNaming', 'fileSettings', etc... } -- not used for Stipple plug-in

--------------------------------------------------------------------------------
--- (optional) Plug-in defined value suppresses the display of the named sections in
 -- the Export or Publish dialogs. You can use either <code>hideSections</code> or
 -- <code>showSections</code>, but not both. If present, this should be an array
 -- containing one or more of the following strings:
    -- <ul>
        -- <li>exportLocation</li>
        -- <li>fileNaming</li>
        -- <li>fileSettings</li>
        -- <li>imageSettings</li>
        -- <li>outputSharpening</li>
        -- <li>metadata</li>
        -- <li>watermarking</li>
    -- </ul>
 -- <p>You cannot suppress display of the "Connection Name" section in the Publish Manager dialog.</p>
 -- <p>If you suppress the "exportLocation" section, the files are rendered into
 -- a temporary folder which is deleted immediately after the Export operation
 -- completes.</p>
 -- <p>First supported in version 1.3 of the Lightroom SDK.</p>
    -- @name exportServiceProvider.hideSections
    -- @class property

exportServiceProvider.hideSections = {'exportLocation', 'fileNaming', 'video'}

--------------------------------------------------------------------------------
--- (optional, Boolean) If your plug-in allows the display of the exportLocation section,
 -- this property controls whether the item "Temporary folder" is available.
 -- If the user selects this option, the files are rendered into a temporary location
 -- on the hard drive, which is deleted when the export finished.
 -- <p>If your plug-in hides the exportLocation section, this temporary
 -- location behavior is always used.</p>
    -- @name exportServiceProvider.canExportToTemporaryLocation
    -- @class property

-- exportServiceProvider.canExportToTemporaryLocation = true -- not used for Stipple plug-in

--------------------------------------------------------------------------------
--- (optional) Plug-in defined value restricts the available file format choices in the
 -- Export or Publish dialogs to those named. You can use either <code>allowFileFormats</code> or
 -- <code>disallowFileFormats</code>, but not both. If present, this should be an array
 -- containing one or more of the following strings:
    -- <ul>
        -- <li>JPEG</li>
        -- <li>PSD</li>
        -- <li>TIFF</li>
        -- <li>DNG</li>
        -- <li>ORIGINAL</li>
    -- </ul>
 -- <p>This property affects the output of still photo files only;
 -- it does not affect the output of video files.
 --  See <a href="#exportServiceProvider.canExportVideo"><code>canExportVideo</code></a>.)</p>
 -- <p>First supported in version 1.3 of the Lightroom SDK.</p>
    -- @name exportServiceProvider.allowFileFormats
    -- @class property

exportServiceProvider.allowFileFormats = {'JPEG'}

--------------------------------------------------------------------------------
--- (optional) Plug-in defined value suppresses the named file formats from the list
 -- of available file format choices in the Export or Publish dialogs.
 -- You can use either <code>allowFileFormats</code> or
 -- <code>disallowFileFormats</code>, but not both. If present,
 -- this should be an array containing one or more of the following strings:
    -- <ul>
        -- <li>JPEG</li>
        -- <li>PSD</li>
        -- <li>TIFF</li>
        -- <li>DNG</li>
        -- <li>ORIGINAL</li>
    -- </ul>
 -- <p>Affects the output of still photo files only, not video files.
 -- See <a href="#exportServiceProvider.canExportVideo"><code>canExportVideo</code></a>.</p>
 -- <p>First supported in version 1.3 of the Lightroom SDK.</p>
    -- @name exportServiceProvider.disallowFileFormats
    -- @class property

--exportServiceProvider.disallowFileFormats = { 'PSD', 'TIFF', 'DNG', 'ORIGINAL' } -- not used for Stipple plug-in

--------------------------------------------------------------------------------
--- (optional) Plug-in defined value restricts the available color space choices in the
 -- Export or Publish dialogs to those named.  You can use either <code>allowColorSpaces</code> or
 -- <code>disallowColorSpaces</code>, but not both. If present, this should be an array
 -- containing one or more of the following strings:
    -- <ul>
        -- <li>sRGB</li>
        -- <li>AdobeRGB</li>
        -- <li>ProPhotoRGB</li>
    -- </ul>
 -- <p>Affects the output of still photo files only, not video files.
 -- See <a href="#exportServiceProvider.canExportVideo"><code>canExportVideo</code></a>.</p>
 -- <p>First supported in version 1.3 of the Lightroom SDK.</p>
    -- @name exportServiceProvider.allowColorSpaces
    -- @class property

exportServiceProvider.allowColorSpaces = {'sRGB'}

--------------------------------------------------------------------------------
--- (optional) Plug-in defined value suppresses the named color spaces from the list
 -- of available color space choices in the Export or Publish dialogs. You can use either <code>allowColorSpaces</code> or
 -- <code>disallowColorSpaces</code>, but not both. If present, this should be an array
 -- containing one or more of the following strings:
    -- <ul>
        -- <li>sRGB</li>
        -- <li>AdobeRGB</li>
        -- <li>ProPhotoRGB</li>
    -- </ul>
 -- <p>Affects the output of still photo files only, not video files.
 -- See <a href="#exportServiceProvider.canExportVideo"><code>canExportVideo</code></a>.</p>
 -- <p>First supported in version 1.3 of the Lightroom SDK.</p>
    -- @name exportServiceProvider.disallowColorSpaces
    -- @class property


--exportServiceProvider.disallowColorSpaces = { 'AdobeRGB', 'ProPhotoRGB' } -- not used for Stipple plug-in

--------------------------------------------------------------------------------
--- (optional, Boolean) Plug-in defined value is true to hide print resolution controls
 -- in the Image Sizing section of the Export or Publish dialog.
 -- (Recommended when uploading to most web services.)
 -- <p>First supported in version 1.3 of the Lightroom SDK.</p>
    -- @name exportServiceProvider.hidePrintResolution
    -- @class property

exportServiceProvider.hidePrintResolution = true

--------------------------------------------------------------------------------
--- (optional, Boolean)  When plug-in defined value istrue, both video and
 -- still photos can be exported through this plug-in. If not present or set to false,
 --  video files cannot be exported through this plug-in. If set to the string "only",
 -- video files can be exported, but not still photos.
 -- <p>No conversions are available for video files. They are simply
 -- copied in the same format that was originally imported into Lightroom.</p>
 -- <p>First supported in version 3.0 of the Lightroom SDK.</p>
    -- @name exportServiceProvider.canExportVideo
    -- @class property

exportServiceProvider.canExportVideo = false -- video is not supported through this sample plug-in

--------------------------------------------------------------------------------
-- FLICKR SPECIFIC: Helper functions and tables.

local function updateCantExportBecause( propertyTable )
  if not propertyTable.validAccount then
    propertyTable.LR_cantExportBecause = LOC "$$$/Stipple/ExportDialog/NoLogin=You haven't logged in to Stipple yet."
    return
  end

  propertyTable.LR_cantExportBecause = nil
end

local displayNameForTitleChoice = {
  filename = LOC "$$$/Stipple/ExportDialog/Title/Filename=Filename",
  title = LOC "$$$/Stipple/ExportDialog/Title/Title=IPTC Title",
  empty = LOC "$$$/Stipple/ExportDialog/Title/Empty=Leave Blank",
}

--local kSafetyTitles = {
--  safe = LOC "$$$/Stipple/ExportDialog/Safety/Safe=Safe",
--  moderate = LOC "$$$/Stipple/ExportDialog/Safety/Moderate=Moderate",
--  restricted = LOC "$$$/Stipple/ExportDialog/Safety/Restricted=Restricted",
--}

local function booleanToNumber( value )
  return value and 1 or 0
end

local privacyToNumber = {
  private = 0,
  public = 1,
}

local safetyToNumber = {
  safe = 1,
  moderate = 2,
  restricted = 3,
}

local contentTypeToNumber = {
  photo = 1,
  screenshot = 2,
  other = 3,
}

local function getStippleTitle( photo, exportSettings, pathOrMessage )
  local title

  -- Get title according to the options in Stipple Title section.
  if exportSettings.titleFirstChoice == 'filename' then
    title = LrPathUtils.leafName( pathOrMessage )
  elseif exportSettings.titleFirstChoice == 'title' then
    title = photo:getFormattedMetadata 'title'

    if ( not title or #title == 0 ) and exportSettings.titleSecondChoice == 'filename' then
      title = LrPathUtils.leafName( pathOrMessage )
    end
  end
    
  return title
end

--------------------------------------------------------------------------------
--- (optional) This plug-in defined callback function is called when the
 -- user chooses this export service provider in the Export or Publish dialog,
 -- or when the destination is already selected when the dialog is invoked,
 -- (remembered from the previous export operation).
 -- <p>This is a blocking call. If you need to start a long-running task (such as
 -- network access), create a task using the <a href="LrTasks.html"><code>LrTasks</code></a>
 -- namespace.</p>
 -- <p>First supported in version 1.3 of the Lightroom SDK.</p>
    -- @param propertyTable (table) An observable table that contains the most
        -- recent settings for your export or publish plug-in, including both
        -- settings that you have defined and Lightroom-defined export settings
    -- @name exportServiceProvider.startDialog
    -- @class function

function exportServiceProvider.startDialog( propertyTable )
  -- Clear login if it's a new connection.
  if not propertyTable.LR_editingExistingPublishConnection then
    propertyTable.username = nil
    propertyTable.nsid = nil
  end

  -- Can't export until we've validated the login.
  propertyTable:addObserver( 'validAccount', function() updateCantExportBecause( propertyTable ) end )
  updateCantExportBecause( propertyTable )

  -- Make sure we're logged in.
  require 'StippleUser'
  StippleUser.verifyLogin( propertyTable )
end

--------------------------------------------------------------------------------
--- (optional) This plug-in defined callback function is called when the user
 -- chooses a different export service provider in the Export or Publish dialog
 --  or closes the dialog.
 -- <p>This is a blocking call. If you need to start a long-running task (such as
 -- network access), create a task using the <a href="LrTasks.html"><code>LrTasks</code></a>
 -- namespace.</p>
 -- <p>First supported in version 1.3 of the Lightroom SDK.</p>
    -- @param propertyTable (table) An observable table that contains the most
        -- recent settings for your export or publish plug-in, including both
        -- settings that you have defined and Lightroom-defined export settings
    -- @param why (string) The reason this function was called. One of
        -- 'ok', 'cancel', or 'changedServiceProvider'
    -- @name exportServiceProvider.endDialog
    -- @class function

--function exportServiceProvider.endDialog( propertyTable )
    -- not used for Stipple plug-in
--end

--------------------------------------------------------------------------------
--- (optional) This plug-in defined callback function is called when the user
 -- chooses this export service provider in the Export or Publish dialog.
 -- It can create new sections that appear above all of the built-in sections
 -- in the dialog (except for the Publish Service section in the Publish dialog,
 -- which always appears at the very top).
 -- <p>Your plug-in's <a href="#exportServiceProvider.startDialog"><code>startDialog</code></a>
 -- function, if any, is called before this function is called.</p>
 -- <p>This is a blocking call. If you need to start a long-running task (such as
 -- network access), create a task using the <a href="LrTasks.html"><code>LrTasks</code></a>
 -- namespace.</p>
 -- <p>First supported in version 1.3 of the Lightroom SDK.</p>
    -- @param f (<a href="LrView.html#LrView.osFactory"><code>LrView.osFactory</code> object)
        -- A view factory object.
    -- @param propertyTable (table) An observable table that contains the most
        -- recent settings for your export or publish plug-in, including both
        -- settings that you have defined and Lightroom-defined export settings
    -- @return (table) An array of dialog sections (see example code for details)
    -- @name exportServiceProvider.sectionsForTopOfDialog
    -- @class function

function exportServiceProvider.sectionsForTopOfDialog( f, propertyTable )
  return {
    {
      title = LOC "$$$/Stipple/ExportDialog/Account=Stipple Account",
      synopsis = bind 'accountStatus',

      f:row {
        spacing = f:control_spacing(),

        f:static_text {
          title = bind 'accountStatus',
          alignment = 'right',
          fill_horizontal = 1,
        },

        f:push_button {
          width = tonumber( LOC "$$$/locale_metric/Stipple/ExportDialog/LoginButton/Width=90" ),
          title = bind 'loginButtonTitle',
          enabled = bind 'loginButtonEnabled',
          action = function()
            require 'StippleUser'
            StippleUser.login(propertyTable)
          end,
        },
      },
    },{
      title = LOC "$$$/Stipple/ExportDialog/Title=Stipple Title",
      synopsis = function(props)
        if props.titleFirstChoice == 'title' then
          return LOC("$$$/Stipple/ExportDialog/Synopsis/TitleWithFallback=IPTC Title or ^1", displayNameForTitleChoice[ props.titleSecondChoice ])
        else
          return props.titleFirstChoice and displayNameForTitleChoice[ props.titleFirstChoice ] or ''
        end
      end,

      f:column {
        spacing = f:control_spacing(),

        f:row {
          spacing = f:label_spacing(),

          f:static_text {
            title = LOC "$$$/Stipple/ExportDialog/ChooseTitleBy=Set Stipple Title Using:",
            alignment = 'right',
            width = share 'stippleTitleSectionLabel',
          },

          f:popup_menu {
            value = bind 'titleFirstChoice',
            width = share 'stippleTitleLeftPopup',
            items = {
              { value = 'filename', title = displayNameForTitleChoice.filename },
              { value = 'title', title = displayNameForTitleChoice.title },
              { value = 'empty', title = displayNameForTitleChoice.empty },
            },
          },

          f:spacer { width = 20 },

          f:static_text {
            title = LOC "$$$/Stipple/ExportDialog/ChooseTitleBySecondChoice=If Empty, Use:",
            enabled = LrBinding.keyEquals( 'titleFirstChoice', 'title', propertyTable ),
          },

          f:popup_menu {
            value = bind 'titleSecondChoice',
            enabled = LrBinding.keyEquals( 'titleFirstChoice', 'title', propertyTable ),
            items = {
              { value = 'filename', title = displayNameForTitleChoice.filename },
              { value = 'empty', title = displayNameForTitleChoice.empty },
            },
          },
        },

        f:row {
          spacing = f:label_spacing(),

          f:static_text {
            title = LOC "$$$/Stipple/ExportDialog/OnUpdate=When Updating Photos:",
            alignment = 'right',
            width = share 'stippleTitleSectionLabel',
          },

          f:popup_menu {
            value = bind 'titleRepublishBehavior',
            width = share 'stippleTitleLeftPopup',
            items = {
              { value = 'replace', title = LOC "$$$/Stipple/ExportDialog/ReplaceExistingTitle=Replace Existing Title" },
              { value = 'leaveAsIs', title = LOC "$$$/Stipple/ExportDialog/LeaveAsIs=Leave Existing Title" },
            },
          },
        },
      },
    },
  }
end

--------------------------------------------------------------------------------
--- (optional) This plug-in defined callback function is called when the user
 -- chooses this export service provider in the Export or Publish dialog.
 -- It can create new sections that appear below all of the built-in sections in the dialog.
 -- <p>Your plug-in's <a href="#exportServiceProvider.startDialog"><code>startDialog</code></a>
 -- function, if any, is called before this function is called.</p>
 -- <p>This is a blocking call. If you need to start a long-running task (such as
 -- network access), create a task using the <a href="LrTasks.html"><code>LrTasks</code></a>
 -- namespace.</p>
 -- <p>First supported in version 1.3 of the Lightroom SDK.</p>
    -- @param f (<a href="LrView.html#LrView.osFactory"><code>LrView.osFactory</code> object)
        -- A view factory object
    -- @param propertyTable (table) An observable table that contains the most
        -- recent settings for your export or publish plug-in, including both
        -- settings that you have defined and Lightroom-defined export settings
    -- @return (table) An array of dialog sections (see example code for details)
    -- @name exportServiceProvider.sectionsForBottomOfDialog
    -- @class function

--------------------------------------------------------------------------------
--- (optional) This plug-in defined callback function is called at the beginning
 -- of each export and publish session before the rendition objects are generated.
 -- It provides an opportunity for your plug-in to modify the export settings.
 -- <p>First supported in version 2.0 of the Lightroom SDK.</p>
    -- @param exportSettings (table) The current export settings.
    -- @name exportServiceProvider.updateExportSettings
    -- @class function

--function exportServiceProvider.updateExportSettings( exportSettings ) -- not used for the Stipple sample plug-in
--  exportSettings.LR_format = 'JPEG'
--  exportSettings.LR_jpeg_quality = 100
-- end

--------------------------------------------------------------------------------
--- (optional) This plug-in defined callback function is called for each exported photo
 -- after it is rendered by Lightroom and after all post-process actions have been
 -- applied to it. This function is responsible for transferring the image file
 -- to its destination, as defined by your plug-in. The function that
 -- you define is launched within a cooperative task that Lightroom provides. You
 -- do not need to start your own task to run this function; and in general, you
 -- should not need to start another task from within your processing function.
 -- <p>First supported in version 1.3 of the Lightroom SDK.</p>
    -- @param functionContext (<a href="LrFunctionContext.html"><code>LrFunctionContext</code></a>)
        -- function context that you can use to attach clean-up behaviors to this
        -- process; this function context terminates as soon as your function exits.
    -- @param exportContext (<a href="LrExportContext.html"><code>LrExportContext</code></a>)
        -- Information about your export settings and the photos to be published.

function exportServiceProvider.processRenderedPhotos( functionContext, exportContext )
  local exportSession = exportContext.exportSession -- Make a local reference to the export parameters.
  local exportSettings = assert( exportContext.propertyTable ) 
  local nPhotos = exportSession:countRenditions() -- Get the # of photos.

  -- Set progress title.
  local progressScope = exportContext:configureProgress {
    title = nPhotos > 1
      and LOC( "$$$/Stipple/Publish/Progress=Publishing ^1 photos to Stipple", nPhotos )
      or LOC "$$$/Stipple/Publish/Progress/One=Publishing one photo to Stipple",
  }

  local uploadedPhotoIds = {} -- Save off uploaded photo IDs so we can take user to those photos later.
  local publishedCollectionInfo = exportContext.publishedCollectionInfo
  local isDefaultCollection = publishedCollectionInfo.isDefaultCollection

  -- Look for a photoset id for this collection.
  local photosetId = publishedCollectionInfo.remoteId

  -- Get a list of photos already in this photoset so we know which ones we can replace and which have
  -- to be re-uploaded entirely.
  local photosetPhotos = photosetId and StippleAPI.listPhotosFromPhotoset( exportSettings, { photosetId = photosetId } )

  local photosetPhotosSet = {} -- Turn it into a set for quicker access later.


  local couldNotPublishBecauseFreeAccount = {}
  local stipplePhotoIdsForRenditions = {}
  local photosetUrl

  for i, rendition in exportContext:renditions { stopIfCanceled = true } do
    progressScope:setPortionComplete( ( i - 1 ) / nPhotos ) -- Update progress scope.
    
    local photo = rendition.photo -- Get next photo.
    local stipplePhotoId = rendition.publishedPhotoId -- See if we previously uploaded this photo.

    if not rendition.wasSkipped then
      local success, pathOrMessage = rendition:waitForRender() -- Update progress scope again once we've got rendered photo.

      progressScope:setPortionComplete( ( i - 0.5 ) / nPhotos ) -- Check for cancellation again after photo has been rendered.

      if progressScope:isCanceled() then break end

      if success then
        local title = getStippleTitle( photo, exportSettings, pathOrMessage ) -- Build up common metadata for this photo.
        local description = photo:getFormattedMetadata( 'caption' )
        local keywordTags = photo:getFormattedMetadata( 'keywordTagsForExport' )
        local tags

        if keywordTags then
          tags = {}
          local keywordIter = string.gfind( keywordTags, "[^,]+" )

          for keyword in keywordIter do
            if string.sub( keyword, 1, 1 ) == ' ' then
              keyword = string.sub( keyword, 2, -1 )
            end

            if string.find( keyword, ' ' ) ~= nil then
              keyword = '"' .. keyword .. '"'
            end

            tags[ #tags + 1 ] = keyword
          end
        end

        local content_type = contentTypeToNumber[ exportSettings.type ]
        local previous_tags = photo:getPropertyForPlugin( _PLUGIN, 'previous_tags' )
        local didReplace = not not stipplePhotoId

        stipplePhotoId = StippleAPI.uploadPhoto(exportSettings, {
          id = stipplePhotoId,
          filePath = pathOrMessage,
          photo = { 
            caption = description, 
            source_page = "" 
          },
            claim = 1, -- always claim the photo
          }
        )

        -- if didReplace then
        --   -- The replace call used by StippleAPI.uploadPhoto ignores all of the metadata that is passed
        --   -- in above. We have to manually upload that info after the fact in this case.
        --   if exportSettings.titleRepublishBehavior == 'replace' then
        --     --StippleAPI.callRestMethod( exportSettings, {
        --                 --method = 'stipple.photos.setMeta',
        --                 --photo_id = stipplePhotoId,
        --                 --title = title or '',
        --                 --description = description or '',
        --                  --})
        --   end
        -- end

        -- When done with photo, delete temp file. There is a cleanup step that happens later,
        -- but this will help manage space in the event of a large upload.
        LrFileUtils.delete( pathOrMessage )

        -- Remember this in the list of photos we uploaded.
        uploadedPhotoIds[ #uploadedPhotoIds + 1 ] = stipplePhotoId

        -- If this isn't the Photostream, set up the photoset.
        if not photosetUrl then
          if not isDefaultCollection then
            -- Create or update this photoset.
            photosetUrl = 'https://stipple.com'
            photosetId, photosetUrl = StippleAPI.createOrUpdatePhotoset(exportSettings, {
              photosetId = photosetId,
              name = publishedCollectionInfo.name,
              description = '',
              primary_photo_id = uploadedPhotoIds[ 1 ],
            })
          else                        
            photosetUrl = StippleAPI.constructPhotostreamURL( exportSettings ) -- Photostream: find the URL.
          end
        end
        
        rendition:recordPublishedPhotoId(stipplePhotoId) -- Record this Stipple ID with the photo so we know to replace instead of upload.

        local photoUrl

        if (not isDefaultCollection) then
          photoUrl = StippleAPI.constructPhotoURL(exportSettings, {
            id = stipplePhotoId,
            photosetId = photosetId,
          })

          -- Add the uploaded photos to the correct photoset.
          StippleAPI.addPhotosToSet(exportSettings, {
            photoId = stipplePhotoId,
            photosetId = photosetId,
          })                
        else
          photoUrl = StippleAPI.constructPhotoURL(exportSettings, {
            id = stipplePhotoId,
          })
        end

        rendition:recordPublishedPhotoUrl( photoUrl )

        -- Because it is common for Stipple users (even viewers) to add additional tags
        -- via the Stipple web site, so we can avoid removing those user-added tags that
        -- were never in Lightroom to begin with. See earlier comment.
        photo.catalog:withPrivateWriteAccessDo(function()
          photo:setPropertyForPlugin( _PLUGIN, 'previous_tags', table.concat( tags, ',' ) )
        end )
      end
    else
      -- To get the skipped photo out of the to-republish bin.
      rendition:recordPublishedPhotoId(rendition.publishedPhotoId)
    end
  end

  if #uploadedPhotoIds > 0 then
    if (not isDefaultCollection) then
      exportSession:recordRemoteCollectionId( photosetId )
    end

    -- Set up some additional metadata for this collection.
    exportSession:recordRemoteCollectionUrl( photosetUrl )
  end

  progressScope:done()
end

--------------------------------------------------------------------------------

return exportServiceProvider