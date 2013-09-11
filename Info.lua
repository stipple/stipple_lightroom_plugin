return {
  LrSdkVersion = 4.0,
  LrSdkMinimumVersion = 3.0, -- minimum SDK version required by this plug-in

  LrToolkitIdentifier = 'com.adobe.lightroom.export.stipple',
  LrPluginName = LOC "$$$/Stipple/PluginName=Stipple",
  
  LrExportServiceProvider = {
    title = LOC "$$$/Stipple/Stipple-title=Stipple",
    file = 'StippleExportServiceProvider.lua',
  },

  LrMetadataProvider = 'StippleMetadataDefinition.lua',

  VERSION = { major=0, minor=1, revision=1, build=1, },
}