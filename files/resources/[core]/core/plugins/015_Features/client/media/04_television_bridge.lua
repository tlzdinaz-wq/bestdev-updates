----
---- Pont entre le builder « Télévision » et PMMS.
----
---- Le builder stocke des modèles avec un render target (`target`) et d'anciens
---- offsets X/Y/Z pensés pour ptelevision. PMMS n'a besoin que du modèle + du
---- render target : on les injecte dans MediaConfig.models pour que la télé
---- apparaisse dans le lecteur et affiche la vidéo sur l'écran, sans saisir
---- de positions à la main.
----

local function registerTelevisionModels(models)
	if type(models) ~= "table" or not MediaConfig or type(MediaConfig.models) ~= "table" then
		return
	end

	for _, entry in ipairs(models) do
		if type(entry) == "table" and type(entry.model) == "string" and entry.model ~= "" then
			local hash = joaat(entry.model)
			local existing = MediaConfig.models[hash]
			local target = entry.target or "tvscreen"

			if existing then
				-- Ne pas écraser un renderTarget déjà correctement défini dans la config.
				if not existing.renderTarget or existing.renderTarget == "" then
					existing.renderTarget = target
				end
				if not existing.label then
					existing.label = "TV"
				end
			else
				MediaConfig.models[hash] = {
					label = "TV",
					renderTarget = target,
				}
			end
		end
	end
end

CreateThread(function()
	-- Attendre que MediaConfig soit bien là (ordre de chargement des scripts).
	local waited = 0
	while (not MediaConfig or type(MediaConfig.models) ~= "table") and waited < 10000 do
		Wait(100)
		waited = waited + 100
	end

	local ok, models = pcall(function()
		return TriggerServerCallback("television:getModels")
	end)
	if ok then
		registerTelevisionModels(models)
	end
end)

RegisterNetEvent("core:television:modelsUpdated", function(models)
	registerTelevisionModels(models)
end)

RegisterNetEvent("ptelevision:syncModels", function(models)
	-- Ancien format : table hash → true. On enregistre au moins le modèle.
	if type(models) ~= "table" then return end
	for hash, _ in pairs(models) do
		local n = tonumber(hash)
		if n and MediaConfig and MediaConfig.models and not MediaConfig.models[n] then
			MediaConfig.models[n] = {
				label = "TV",
				renderTarget = "tvscreen",
			}
		end
	end
end)
