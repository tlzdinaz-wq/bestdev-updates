-- shared_script '@WaveShield/resource/include.lua'

fx_version 'cerulean'
game 'gta5'

files {
	"audioconfig/*.dat151.rel",
	"audioconfig/*.dat54.rel",
	"audioconfig/*.dat10.rel",
	"audioconfig/sfx/**/*.awc",
	'*.meta',
}

data_file "AUDIO_GAMEDATA" "audioconfig/nspeedo_game.dat"
data_file "AUDIO_SOUNDDATA" "audioconfig/nspeedo_sounds.dat"
data_file "AUDIO_WAVEPACK" "audioconfig/sfx/dlc_nspeedo"

data_file 'HANDLING_FILE' 'handling.meta'
data_file 'VEHICLE_METADATA_FILE' 'vehicles.meta'
data_file 'CARCOLS_FILE' 'carcols.meta'
data_file 'VEHICLE_VARIATION_FILE' 'carvariations.meta'

client_script 'names.lua'
