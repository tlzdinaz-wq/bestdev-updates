fx_version 'cerulean'
game 'gta5'

author 'EVE'
description 'EVE bridge — remonte l\'état du serveur FiveM vers l\'agent local et expose les URLs branding aux autres resources'
version '1.1.0'

server_scripts {
  'config.lua',
  'server.lua',
}

server_exports {
  'getLogo',
  'getBackground',
  'getLoadingScreen',
  'getBanner',
  'getNotificationLogo',
  'getAsset',
  'getColors',
  'getBranding',
  -- core appelle exports.eve_bridge:GetBrandingManifest() (PascalCase) ;
  -- server.lua enregistre les deux orthographes.
  'getBrandingManifest',
  'GetBrandingManifest',
  'refreshBranding',
  'isReady',
  'refreshWebhooks',
  'logsReady',
  'postLog',
  'postCustomLog',
}
