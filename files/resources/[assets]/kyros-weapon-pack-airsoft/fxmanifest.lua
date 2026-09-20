-- shared_script '@WaveShield/resource/include.lua'

fx_version 'cerulean'
games {'gta5'}
lua54 'yes'

author 'Kyros'
version '1.0.0'

files {
	'metas/**/*.meta'
}

data_file 'WEAPONCOMPONENTSINFO_FILE' 'metas/**/weaponcomponents.meta'
data_file 'WEAPON_METADATA_FILE' 'metas/**/weaponarchetypes.meta'
data_file 'WEAPON_ANIMATIONS_FILE' 'metas/**/weaponanimations.meta'
data_file 'WEAPONINFO_FILE' 'metas/**/weapons.meta'

client_script 'cl_weaponNames.lua'
