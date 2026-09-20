---@meta _
---@diagnostic disable: duplicate-doc-field

-- Client-side command suggestion queue system
-- This ensures all suggestions are sent AFTER the chat resource is ready
-- Fixes race condition where suggestions are lost if chat resource hasn't loaded yet

VFW.ClientCommandSuggestions = VFW.ClientCommandSuggestions or {}
VFW.ClientSuggestionsReady = false

--- Queue a single suggestion
---@param name string Command name (e.g., '/me')
---@param help string Command description
---@param params table|nil Command parameters
function VFW.AddChatSuggestion(name, help, params)
    table.insert(VFW.ClientCommandSuggestions, {
        name = name,
        help = help,
        params = params or {}
    })

    -- If already ready, send immediately
    if VFW.ClientSuggestionsReady then
        TriggerEvent('chat:addSuggestion', name, help, params or {})
    end
end

--- Queue multiple suggestions at once
---@param suggestions table Array of suggestion objects {name, help, params}
function VFW.AddChatSuggestions(suggestions)
    for _, suggestion in ipairs(suggestions) do
        table.insert(VFW.ClientCommandSuggestions, suggestion)
    end

    -- If already ready, send immediately
    if VFW.ClientSuggestionsReady then
        TriggerEvent('chat:addSuggestions', suggestions)
    end
end

-- Wait for chat resource and send all queued suggestions
CreateThread(function()
    -- Wait for chat resource to be started
    while GetResourceState('chat') ~= 'started' do
        Wait(100)
    end

    -- Additional safety delay to ensure handlers are registered
    Wait(500)

    -- Send all queued suggestions
    if #VFW.ClientCommandSuggestions > 0 then
        TriggerEvent('chat:addSuggestions', VFW.ClientCommandSuggestions)
    end

    VFW.ClientSuggestionsReady = true

    TriggerServerEvent('vfw:command:clientReady')

    Wait(500)

    local commandsToRemove = {
        'say', 'ooc', 'twt', 'news', 'ad', 'ano', 'ayuda', 'gme', 'gdo', '/', 'help',

        'qx-debug', 'DebugInfo', 'gpsdebug', 'gpsclear', 'radiodebug', 'radioStartTest',
        'radioStopTest', 'rewards:debug', 'rewards:test', 'skatedebug', 'skate_cleanup',
        'tuto_test', 'tuto_action', 'tuto_tip', 'tuto_reset', 'tuto_stop', 'testcaisse',
        'testcreator', 'monitorburglary', 'validateburglary', 'printallcomponents',
        'printzones', 'debuglastpoolshot',

        'getPlyData', 'green', 'stopgreen', 'shortcuts', 'staffcustom', 'orbital',
        'openplayer', 'sc', 'togglesc', 'hideplayerdroppedtext', 'categorizebags',
        'savebags', 'gsp', 'gtp', 'voiceAmplifierAdd', 'voiceRestrictionAdd',
        'voiceBuilderAmplifier', 'voiceBuilderRestriction', 'voiceShowZones', 'voiceHelp',
        'toggleterritories', 'valideCrew', 'requestchesthistory',

        'druguereset', 'droguestress', 'drogueclear', 'droguestate',

        'pointing', 'openRadio', 'voiceWhisper', 'voiceTalk', 'voiceLoud', 'voiceShout',
        'megaphone_close', 'Plateau_dep', 'Plateau_treuil', 'opendispatch',

        'pacific:tuto', 'pacific:scan', 'pacific:reset',

        'stretcher', 'delstretcher', 'mdstretcher', 'illegalcraft',

        'start', 'showrcorepool',

        'web_baseUrl',

        'giveperm',

        'staff_noclip', 'openStaffMenu', 'dismissReport', 'acceptReport',

        'dv', 'dvbed1', 'dvperf1', 'add', 'addlb',
    }

    for _, cmd in ipairs(commandsToRemove) do
        TriggerEvent('chat:removeSuggestion', '/' .. cmd)
    end
end)

RegisterNetEvent('vfw:command:verifiedBatch', function(commands)
    if #commands > 0 then
        TriggerEvent('chat:addSuggestions', commands)
    end
end)
