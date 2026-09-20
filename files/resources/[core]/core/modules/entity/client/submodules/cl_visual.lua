---@class Entity.Visual
cEntity.Visual = {}

local threadRunning = false
local exept = {}

---@param state boolean
---@return void
cEntity.Visual.HideAllEntities = function(state)
    threadRunning = state

    local pools = {
        "CPed",
        "CObject",
        "CNetObject",
        "CPickup",
        "CVehicle"
    }

    if threadRunning then
        CreateThread(function()
            while threadRunning do
                Wait(0)

                for i = 1, #pools do
                    local pool = GetGamePool(pools[i])

                    for j = 1, #pool do
                        local entity = pool[j]
                        if not exept[entity] then
                            SetEntityLocallyInvisible(entity)
                        end
                    end
                end
            end
        end)
    end
end

---@param state boolean
---@return void
cEntity.Visual.AddEntityToException = function(entity)
    exept[entity] = true
end

---@param entity number
---@return void
cEntity.Visual.RemoveEntityFromException = function(entity)
    exept[entity] = nil
end

local disablePlayerCollision = false

---@param state boolean
---@return void
cEntity.Visual.DisablePlayerCollisions = function(state)
    disablePlayerCollision = state
    if state then
        CreateThread(function()
            while disablePlayerCollision do
                local players = GetActivePlayers()

                for _, player in ipairs(players) do
                    local ped = GetPlayerPed(player)

                    SetEntityNoCollisionEntity(VFW.PlayerData.ped, ped, true)
                end

                Wait(0)
            end
        end)
    end
end
