-- Lightroom SDK
local LrDialogs = import 'LrDialogs'
local LrFunctionContext = import 'LrFunctionContext'
local LrTasks = import 'LrTasks'
local logger = import 'LrLogger'( 'StippleAPI' )

require 'StippleAPI'

--============================================================================--

StippleUser = {}

--------------------------------------------------------------------------------

local function storedCredentialsAreValid( propertyTable )
  return propertyTable.username and string.len( propertyTable.username ) > 0
    and propertyTable.nsid 
end

--------------------------------------------------------------------------------

local function notLoggedIn( propertyTable )
  propertyTable.token = nil
  propertyTable.nsid = nil
  propertyTable.username = nil
  propertyTable.fullname = ''

  propertyTable.accountStatus = LOC "$$$/Stipple/AccountStatus/NotLoggedIn=Not logged in"
  propertyTable.loginButtonTitle = LOC "$$$/Stipple/LoginButton/NotLoggedIn=Log In"
  propertyTable.loginButtonEnabled = true
  propertyTable.validAccount = false
end

--------------------------------------------------------------------------------

local doingLogin = false

function StippleUser.login( propertyTable )
  if doingLogin then return end
  doingLogin = true

  LrFunctionContext.postAsyncTaskWithContext('Stipple login', function(context)
    if not propertyTable.LR_editingExistingPublishConnection then
      notLoggedIn( propertyTable )
    end

    propertyTable.accountStatus = LOC "$$$/Stipple/AccountStatus/LoggingIn=Logging in..."
    propertyTable.loginButtonEnabled = false

    LrDialogs.attachErrorDialogToFunctionContext(context)

    context:addCleanupHandler(function()
      doingLogin = false

      if not storedCredentialsAreValid( propertyTable ) then
        notLoggedIn( propertyTable )
      end
    end )

    StippleAPI.getApiKeyAndSecret()
    propertyTable.accountStatus = LOC "$$$/Stipple/AccountStatus/WaitingForStipple=Waiting for response from stipple.com..."

    local auth = StippleAPI.openAuthUrl()
    propertyTable.accountStatus = LOC "$$$/Stipple/AccountStatus/WaitingForStipple=Waiting for response from stipple.com..."

    if propertyTable.LR_editingExistingPublishConnection then
      if auth.user and propertyTable.nsid ~= auth.user.id then
        -- propertyTable.nsid = auth.user.id
        -- LrDialogs.message( LOC "$$$/Stipple/CantChangeUserID=You can not change Stipple accounts on an existing publish connection. Please log in again with the account you used when you first created this connection." )
        -- return
      end
    end

    propertyTable.nsid = auth.user.id
    propertyTable.username = auth.user.login
    propertyTable.fullname = auth.user.name

    StippleUser.updateUserStatusTextBindings( propertyTable )
  end )
end

--------------------------------------------------------------------------------

local function getDisplayUserNameFromProperties(propertyTable)
  local displayUserName = propertyTable.fullname
    
  if ( not displayUserName or #displayUserName == 0 )
    or displayUserName == propertyTable.username
  then
    displayUserName = propertyTable.username
  else
    displayUserName = LOC("$$$/Stipple/AccountStatus/UserNameAndLoginName=^1 (^2)", propertyTable.fullname, propertyTable.username)
  end
    	
  return displayUserName
end

--------------------------------------------------------------------------------

function StippleUser.verifyLogin(propertyTable)
  local function updateStatus()
    logger:trace( "verifyLogin: updateStatus() was triggered." )
    
    LrTasks.startAsyncTask(function()
      logger:trace( "verifyLogin: updateStatus() is executing." )
      if storedCredentialsAreValid(propertyTable) then
        local displayUserName = getDisplayUserNameFromProperties(propertyTable)
      
        propertyTable.accountStatus = LOC( "$$$/Stipple/AccountStatus/LoggedIn=Logged in as ^1", displayUserName )
      
        if propertyTable.LR_editingExistingPublishConnection then
          propertyTable.loginButtonTitle = LOC "$$$/Stipple/LoginButton/LogInAgain=Log In"
          propertyTable.loginButtonEnabled = false
          propertyTable.validAccount = true
        else
          propertyTable.loginButtonTitle = LOC "$$$/Stipple/LoginButton/LoggedIn=Switch User?"
          propertyTable.loginButtonEnabled = true
          propertyTable.validAccount = true
        end
      else
        propertyTable.LR_editingExistingPublishConnection = true
        notLoggedIn(propertyTable)
      end
      
      StippleUser.updateUserStatusTextBindings(propertyTable)
    end )
  end
  
  propertyTable:addObserver('nsid', updateStatus)
  updateStatus()
end

--------------------------------------------------------------------------------

function StippleUser.updateUserStatusTextBindings(settings)
  local nsid = settings.id

  if nsid and string.len(nsid) > 0 then
    LrFunctionContext.postAsyncTaskWithContext('Stipple account status check', function(context)
      context:addFailureHandler(function()
        if settings.LR_editingExistingPublishConnection then
          local displayUserName = getDisplayUserNameFromProperties( settings )

          settings.accountStatus = LOC( "$$$/Stipple/AccountStatus/LogInFailed=Log in failed, was logged in as ^1", displayUserName )
          settings.loginButtonTitle = LOC "$$$/Stipple/LoginButton/LogInAgain=Log In"
          settings.loginButtonEnabled = true
          settings.validAccount = false
          settings.isUserPro = false
          settings.accountTypeMessage = LOC "$$$/Stipple/AccountStatus/LoginFailed/Message=Could not verify this Stipple account. Please log in again. Please note that you can not change the Stipple account for an existing publish connection. You must log in to the same account."
        end
      end )

      settings.accountTypeMessage = LOC( "$$$/Stipple/ProAccountDescription=This Stipple Pro account can utilize collections, modified photos will be automatically be re-published, and there is no monthly bandwidth limit." )
      settings.isUserPro = true
    end )
  else
    settings.accountTypeMessage = LOC( "$$$/Stipple/SignIn=Sign in with your Stipple account." )
    settings.isUserPro = false
  end
end