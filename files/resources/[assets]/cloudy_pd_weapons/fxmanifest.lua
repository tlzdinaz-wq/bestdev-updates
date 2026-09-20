fx_version 'cerulean'
games {'gta5'}
lua54 'yes'

author 'Cloudy Development'
version '2.2.0'
description 'PD Weapon Pack'

files {
    'metas/**/*.meta'
}

data_file 'WEAPONCOMPONENTSINFO_FILE' 'metas/**/weaponcomponents.meta'
data_file 'WEAPON_METADATA_FILE' 'metas/**/weaponarchetypes.meta'
data_file 'WEAPON_ANIMATIONS_FILE' 'metas/**/weaponanimations.meta'
data_file 'WEAPONINFO_FILE' 'metas/**/weapons.meta'

dependency '/assetpacks'
