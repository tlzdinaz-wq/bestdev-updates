local minZ, maxZ = nil, nil

local function handleInput(center)
  local rot = GetGameplayCamRot(2)
  center = handleArrowInput(center, rot.z)
  return center
end

function polyStart(name)
  local coords = GetEntityCoords(PlayerPedId())
  createdZone = PolyZone:Create({vector2(coords.x, coords.y)}, {name = tostring(name), useGrid=false})
  Citizen.CreateThread(function()
    while createdZone do
      -- Have to convert the point to a vector3 prior to calling handleInput,
      -- then convert it back to vector2 afterwards
      lastPoint = createdZone.points[#createdZone.points]
      lastPoint = vector3(lastPoint.x, lastPoint.y, 0.0)
      lastPoint = handleInput(lastPoint)
      createdZone.points[#createdZone.points] = lastPoint.xy
      Wait(0)
    end
  end)
  minZ, maxZ = coords.z, coords.z
end

function polyFinish()
  TriggerServerEvent("polyzone:printPoly",
    {name=createdZone.name, points=createdZone.points, minZ=minZ, maxZ=maxZ})
end