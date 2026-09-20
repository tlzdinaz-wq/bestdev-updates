if not TestServer or not TestServer.enabled then return end

TestServer.Block("callback",
    "core:server:characterCreator",
    "vfw:server:getSkinByCharId"
)

TestServer.Block("event",
    "vfw:staff:sendGlobalAnnouncement",
    "core:vnotif:createAlert:staff",
    "core:vnotif:createAlert:zone"
)
