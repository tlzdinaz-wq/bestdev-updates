----
---- Created Date: [2025-03-03 08:06:53]
---- Author: Johnny
----
---- File: [permissions.lua]
----

-- Adapte a la base Aurora : la reference a ESX ne servait a rien ici (la
-- verification repond toujours oui) et faisait echouer le demarrage, ESX
-- n'existant pas sur ce serveur.

Permissions = {};

function Permissions:check(source)
    return true;
end