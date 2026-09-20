---@meta _
---@diagnostic disable: duplicate-doc-field

-- ============================================================
-- CONFIGURATION RADIO
-- Offset appliqué au canal pma-voice selon le type de radio.
-- Indispensable pour que radio publique et radio service public
-- ne partagent pas le même canal pma-voice à fréquence identique.
-- ============================================================

RadioConfig = {}

RadioConfig.OffsetMap = {
    public = 0,
    job    = 100000,
}

---Retourne l'offset pma-voice pour un type de radio donné.
---@param radioType string  "public" | "job"
---@return number
function RadioConfig.GetOffset(radioType)
    return RadioConfig.OffsetMap[radioType] or 0
end
