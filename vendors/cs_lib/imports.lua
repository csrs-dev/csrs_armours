


local components = {}
components["blip"] = function(lib)
	local __cslib_internal = {
		library = {},
		shared = function()
			return {}
		end,
		source = IsDuplicityVersion() and function()
			return {}
		end or function()
			local blip = {}
			blip.__index = blip
			function blip.new(blip, params)
				if not (blip) then
					error("blip.new: blip is nil")
					return
				end
				local self = setmetatable({}, blip)
				return self
			end
			local blips = {
				{
					title = '<font face="font4thai">โรงพยาบาล</font>',
					scale = 1.0,
					colour = 0,
					id = 570,
					coords = vec(2044.8566, 3463.8008, 44.5799, 173.9882)
				},
			}
			Citizen.CreateThread(function()
				for _, info in pairs(blips) do
					local coords = info.coords
					info.blip = AddBlipForCoord(coords.x, coords.y, coords.z)
					SetBlipSprite(info.blip, info.id)
					SetBlipDisplay(info.blip, 4)
					SetBlipScale(info.blip, info.scale)
					SetBlipColour(info.blip, info.colour)
					SetBlipAsShortRange(info.blip, true)
					BeginTextCommandSetBlipName("STRING")
					AddTextComponentString(info.title)
					EndTextCommandSetBlipName(info.blip)
				end
			end)
			return {
				name = resourceName,
				setmetatable({
					area = function()
					end,
					coords = function()
					end,
					entity = function()
					end,
					pickup = function()
					end,
					radius = function()
					end
				}, {
					__call = function(t, eventname)
						return resourceName .. ":" .. eventname
					end
				})
			}
		end,
	}
	for key, value in pairs(__cslib_internal.shared()) do
		__cslib_internal.library[key] = value
	end
	for key, value in pairs(__cslib_internal.source()) do
		__cslib_internal.library[key] = value
	end
	return __cslib_internal.library
end
components["cache"] = function(lib)
	local __cslib_internal = {
		library = {},
		shared = function()
			return {}
		end,
		source = IsDuplicityVersion() and function()
			return {}
		end or function()
			return {}
		end,
	}
	for key, value in pairs(__cslib_internal.shared()) do
		__cslib_internal.library[key] = value
	end
	for key, value in pairs(__cslib_internal.source()) do
		__cslib_internal.library[key] = value
	end
	return __cslib_internal.library
end
components["collision"] = function(lib)
	local __cslib_internal = {
		library = {},
		shared = function()
			local GetEntityCoords = GetEntityCoords
			local DoesEntityExist = DoesEntityExist
			local collisionBase = {}
			collisionBase.__index = collisionBase
			function collisionBase.new(self, class, options)
				options = options or {}
				self = class and setmetatable(self, class) or {}
				self.poolTypes = options.poolTypes or {
					"CObject",
					"CPed",
					"CVehicle"
				}
				self.bOnlyRelevant = options.bOnlyRelevant or false
				self.tickRate = options.tickRate or 500
				self.bDebug = options.bDebug or false
				self.color = {
					r = 0,
					g = 0,
					b = 255,
					a = 75
				}
				self.relevant = {
					entities = {},
					players = {}
				}
				self.overlapping = {}
				self.tickpool = lib.tickpool.new()
				self.interval = lib.setInterval(function()
					for key, entity in pairs(self.overlapping) do
						if not (DoesEntityExist(entity.id)) then
							if (self.tickpool and entity.interval) then
								self.tickpool:clearOnTick(entity.interval)
								entity.interval = nil
							end
							self.overlapping[key] = nil
						end
					end
					local entities = {}
					if (self.bOnlyRelevant) then
						local count = 0
						for _, entity in pairs(self:getRelevantEntities()) do
							if (DoesEntityExist(entity)) then
								count += 1
								entities[count] = entity
							end
						end
						for _, src in pairs(self:getRelevantPlayers()) do
							local playerId = lib.bIsServer and src or GetPlayerFromServerId(src)
							local entity = GetPlayerPed(playerId)
							if (DoesEntityExist(entity)) then
								count += 1
								entities[count] = entity
							end
						end
					else
						entities = lib.game.getEntitiesByTypes(self.poolTypes)
					end
					for i = 1, # entities, 1 do
						local entityId = entities[i]
						local entity = self.overlapping[entityId] or {
							id = entityId
						}
						entity.coords = GetEntityCoords(entity.id)
						local bInside = self:isPointInside(entity.coords)
						if (bInside) then
							if not (self.overlapping[entity.id]) then
								if (self.onBeginOverlap) then
									self:onBeginOverlap(entity)
								end
								if (self.tickpool and self.onOverlapping) then
									entity.interval = self.tickpool:onTick(function()
										local entityPara = {}
										entityPara.id = entity.id
										entityPara.coords = entity.coords
										self:onOverlapping(entityPara)
									end)
								end
							end
						else
							if (self.overlapping[entity.id]) then
								if (self.onOverlapping) then
									if (self.tickpool and entity.interval) then
										self.tickpool:clearOnTick(entity.interval)
										entity.interval = nil
									end
								end
								if (self.onEndOverlap) then
									self:onEndOverlap(entity)
								end
							end
						end
						self.overlapping[entity.id] = bInside and entity or nil
					end
				end, self.tickRate)
				if (self.debugThread and self.bDebug) then
					self:debugThread()
				end
				return self
			end
			function collisionBase:destroy()
				if (self.interval) then
					self.interval:destroy()
					self.interval = nil
				end
				if (self.debugInterval) then
					self.debugInterval:destroy()
					self.debugInterval = nil
				end
				if (self.tickpool) then
					self.tickpool:destroy()
					self.tickpool = nil
				end
			end
			function collisionBase:addRelevantEntity(entity)
				if not (DoesEntityExist(entity)) then
					return
				end
				if (self:isEntityRelevant(entity)) then
					return
				end
				self.relevant.entities[entity] = entity
			end
			function collisionBase:removeRelevantEntity(entity)
				if not (self:isEntityRelevant(entity)) then
					return
				end
				self.relevant.entities[entity] = nil
			end
			function collisionBase:isEntityRelevant(entity)
				return self.relevant.entities[entity] ~= nil
			end
			function collisionBase:clearRelevantEntities()
				self.relevant.entities = {}
			end
			function collisionBase:getRelevantEntities()
				return self.relevant.entities
			end
			function collisionBase:addRelevantPlayer(src)
				if (self:isPlayerRelevant(src)) then
					return
				end
				self.relevant.players[src] = src
			end
			function collisionBase:removeRelevantPlayer(src)
				if not (self:isPlayerRelevant(src)) then
					return
				end
				self.relevant.players[src] = nil
			end
			function collisionBase:isPlayerRelevant(src)
				return self.relevant.players[src] ~= nil
			end
			function collisionBase:clearRelevantPlayers()
				self.relevant.players = {}
			end
			function collisionBase:getRelevantPlayers()
				return self.relevant.players
			end
			function collisionBase:clearRelevant()
				self:clearRelevantEntities()
				self:clearRelevantPlayers()
			end
			local collisionSphere = {}
			collisionSphere.__index = collisionSphere
			setmetatable(collisionSphere, collisionBase)
			function collisionSphere.new(coords, radius, options)
				if not (coords) then
					error("no coords provide to collisionSphere")
				end
				if not (radius) then
					error("no radius provide to collisionSphere")
				end
				local self = {}
				self.type = "sphere"
				self.position = vector3(coords.x, coords.y, coords.z)
				self.radius = radius
				return collisionBase.new(self, collisionSphere, options)
			end
			function collisionSphere:isPointInside(coords)
				local distance = # (vec(coords.x, coords.y, coords.z) - self.position)
				return (distance <= self.radius)
			end
			function collisionSphere:isEntityInside(entity)
				return self:isPointInside(GetEntityCoords(entity))
			end
			if not (lib.bIsServer) then
				function collisionSphere:debugThread()
					local fRadius = self.radius + 0.0
					self.debugInterval = lib.setInterval(function()
						DrawMarker(28, self.position.x, self.position.y, self.position.z, 0, 0, 0, 0, 0, 0, fRadius, fRadius, fRadius, self.color.r, self.color.g, self.color.b, self.color.a, false, false, 0, false, nil, nil, false)
					end, 0)
				end
			end
			function collisionSphere:setOrigin(coords)
				self.position = vector3(coords.x, coords.y, coords.z)
			end
			function collisionSphere:setRadius(radius)
				self.radius = radius + 0.0
			end
			return {
				collisionBase = collisionBase,
				sphere = setmetatable({
					new = collisionSphere.new,
				}, {
					__call = function(t, ...)
						return t.new(...)
					end
				})
			}
		end,
		source = IsDuplicityVersion() and function()
			return {}
		end or function()
			return {}
		end,
	}
	for key, value in pairs(__cslib_internal.shared()) do
		__cslib_internal.library[key] = value
	end
	for key, value in pairs(__cslib_internal.source()) do
		__cslib_internal.library[key] = value
	end
	return __cslib_internal.library
end
components["game"] = function(lib)
	local __cslib_internal = {
		library = {},
		shared = function()
			local function getEntitiesByTypes(types)
				local entities = {}
				local count = 0
				for i = 1, # types, 1 do
					local poolType = types[i]
					local pool = {}
					if (poolType == "CObject") then
						pool = lib.game.getObjects()
					end
					if (poolType == "CPed") then
						pool = lib.game.getPeds()
					end
					if (poolType == "CVehicle") then
						pool = lib.game.getVehicles()
					end
					if (poolType == "CPlayerPed") then
						pool = lib.game.getPlayerPeds()
					end
					for i = 1, # pool, 1 do
						count += 1
						entities[count] = pool[i]
					end
				end
				return entities
			end
			local function getPlayerPeds()
				local players = lib.bIsServer and lib.game.getPlayers() or GetActivePlayers()
				local peds = {}
				local count = 0
				for i = 1, # players, 1 do
					local ped = GetPlayerPed(players[i])
					if (DoesEntityExist(ped)) then
						count += 1
						peds[count] = ped
					end
				end
				return peds
			end
			return {
				getPlayerPeds = getPlayerPeds,
				getEntities = function()
					return getEntitiesByTypes({
						"CObject",
						"CPed",
						"CVehicle"
					})
				end,
				getEntitiesByTypes = getEntitiesByTypes,
			}
		end,
		source = IsDuplicityVersion() and function()
			local function getObjects()
				return GetAllObjects()
			end
			local function getPeds()
				return GetAllPeds()
			end
			local function getVehicles()
				return GetAllVehicles()
			end
			local function getPlayers()
				return GetPlayers()
			end
			return {
				getObjects = getObjects,
				getPeds = getPeds,
				getVehicles = getVehicles,
				getPlayers = getPlayers,
			}
		end or function()
			local GetActivePlayers = GetActivePlayers
			local GetGamePool = GetGamePool
			local function getObjects()
				return GetGamePool("CObject")
			end
			local function getPeds()
				return GetGamePool("CPed")
			end
			local function getVehicles()
				return GetGamePool("CVehicle")
			end
			local function getPlayers()
				local activePlayers = GetActivePlayers()
				local players = {}
				local count = 0
				for i = 1, # activePlayers, 1 do
					count += 1
					players[count] = GetPlayerServerId(activePlayers[i])
				end
				return players
			end
			local function drawText2d(data)
				local text = data.text
				if not (text) then
					return
				end
				local offset = data.offset or vec(0.5, 0.5)
				local scale = data.scale or 1.0
				local font = data.font or 0
				local color = data.color or {
					r = 255,
					g = 255,
					b = 255,
					a = 255
				}
				local bOutline = data.bOutline or false
				local bCenter = data.bCenter or true
				local bShadow = data.bShadow or false
				local align = data.align or 0
				SetTextFont(font)
				SetTextScale(1, scale)
				SetTextWrap(0.0, 1.0)
				SetTextCentre(bCenter)
				SetTextColour(color.r, color.g, color.b, color.a)
				SetTextJustification(align)
				SetTextEdge(1, 0, 0, 0, 255)
				if bOutline then
					SetTextOutline()
				end
				if bShadow then
					SetTextDropShadow()
				end
				BeginTextCommandDisplayText("STRING")
				AddTextComponentSubstringPlayerName(text)
				EndTextCommandDisplayText(offset.x, offset.y)
			end
			local function drawText3d(data)
				local text = data.text
				if not (text) then
					return
				end
				local coords = data.coords
				if not (coords) then
					return
				end
				coords = vec(coords.x, coords.y, coords.z)
				local scale = data.scale or 1.0
				local font = data.font or 0
				local color = data.color or {
					r = 255,
					g = 255,
					b = 255,
					a = 255
				}
				local bOutline = data.bOutline or false
				local bCenter = data.bCenter or true
				local bShadow = data.bShadow or false
				local camDistance = # (coords - GetFinalRenderedCamCoord())
				scale = (scale / camDistance) * 2
				local fov = (1 / GetGameplayCamFov()) * 100
				scale = scale * fov
				SetTextScale(0.0 * scale, 0.55 * scale)
				SetTextFont(font)
				SetTextProportional(true)
				SetTextColour(color.r, color.g, color.b, color.a)
				BeginTextCommandDisplayText("STRING")
				SetTextCentre(bCenter)
				AddTextComponentSubstringPlayerName(text)
				SetDrawOrigin(coords.x, coords.y, coords.z, 0)
				SetTextEdge(1, 0, 0, 0, 255)
				if (bOutline) then
					SetTextOutline()
				end
				if (bShadow) then
					SetTextDropShadow()
				end
				EndTextCommandDisplayText(0.0, 0.0)
				ClearDrawOrigin()
			end
			return {
				getPlayers = getPlayers,
				getObjects = getObjects,
				getPeds = getPeds,
				getVehicles = getVehicles,
				drawText2d = drawText2d,
				drawText3d = drawText3d,
			}
		end,
	}
	for key, value in pairs(__cslib_internal.shared()) do
		__cslib_internal.library[key] = value
	end
	for key, value in pairs(__cslib_internal.source()) do
		__cslib_internal.library[key] = value
	end
	return __cslib_internal.library
end
components["math"] = function(lib)
	local __cslib_internal = {
		library = {},
		shared = function()
			local chancePool = {}
			chancePool.__index = chancePool
			function chancePool.new()
				local self = setmetatable({}, chancePool)
				self.totalChance = 0
				self.key = 10
				self.pool = {}
				return self
			end
			function chancePool:addIntoPool(chance, data)
				self.key += 1
				self.pool[self.key] = {
					chanceEnd = self.totalChance + chance,
					data = data
				}
				self.totalChance = self.totalChance + chance
				return self.key
			end
			function chancePool:remove(key)
				local item = self.pool[key]
				if (item) then
					self.totalChance -= item.chanceEnd
					self.pool[key] = nil
				end
			end
			function chancePool:getRandomItem()
				local randomValue = math.random() * self.totalChance
				for _, item in pairs(self.pool) do
					if (randomValue <= item.chanceEnd) then
						return {
							randomValue = randomValue,
							data = item.data
						}
					end
				end
			end
			return {
				chancePool = chancePool
			}
		end,
		source = IsDuplicityVersion() and function()
			return {}
		end or function()
			return {}
		end,
	}
	for key, value in pairs(__cslib_internal.shared()) do
		__cslib_internal.library[key] = value
	end
	for key, value in pairs(__cslib_internal.source()) do
		__cslib_internal.library[key] = value
	end
	return __cslib_internal.library
end
components["native"] = function(lib)
	local __cslib_internal = {
		library = {},
		shared = function()
			return {}
		end,
		source = IsDuplicityVersion() and function()
			return {}
		end or function()
			return {}
		end,
	}
	for key, value in pairs(__cslib_internal.shared()) do
		__cslib_internal.library[key] = value
	end
	for key, value in pairs(__cslib_internal.source()) do
		__cslib_internal.library[key] = value
	end
	return __cslib_internal.library
end
components["net"] = function(lib)
	local __cslib_internal = {
		library = {},
		shared = function()
			local msgpack = msgpack
			local msgpack_pack = msgpack.pack
			local replicator = {}
			replicator.__index = replicator
			replicator.service = IsDuplicityVersion() and "server" or "client"
			replicator.isServer = replicator.service == "server"
			replicator.resourceName = GetCurrentResourceName()
			replicator.bagName = "cslib_rep:global"
			function replicator.new(name, options)
				local self = setmetatable({}, replicator)
				options = options or {}
				self.name = name
				self.data = {}
				self.bagName = options.bagName and options.bagName or "global"
				self.bagName = self.bagName:format("cslib_rep:%s", self.bagName)
				if not (replicator.isServer) then
					self.changeHandlder = AddStateBagChangeHandler(nil, self.bagName, function(bagName, key, value, _, _)
						self.data[key] = value
					end)
				end
				return self
			end
			function replicator:destroy()
				if not (replicator.isServer) then
					RemoveStateBagChangeHandler(self.changeHandlder)
				end
				self.data = nil
			end
			function replicator:get(key)
				local value = self.data[key]
				if not (value) then
					value = GetStateBagValue(self.bagName, key)
					if (value) then
						self.data[key] = value
					end
				end
				return value
			end
			function replicator:set(key, value)
				if not (replicator.isServer) then
					return
				end
				local keyType = type(key)
				if (keyType ~= "number" and keyType ~= "string") then
					return
				end
				self.data[key] = value
				local payload = msgpack_pack(value)
				SetStateBagValue(self.bagName, key, payload, payload:len(), replicator.isServer)
			end
			return {
				replicator = setmetatable({
					new = function(...)
						local replicatorObject = replicator.new(...)
						return setmetatable({}, {
							__index = function(t, k)
								return replicatorObject:get(k)
							end,
							__newindex = function(table, key, value)
								replicatorObject:set(key, value)
							end
						})
					end
				}, {
					__call = function(t, ...)
						return t.new(...)
					end
				}),
			}
		end,
		source = IsDuplicityVersion() and function()
			local table_unpack = table.unpack
			local Citizen_Await = Citizen.Await
			local function registerServerCallback(eventname, listener)
				local cbEventName = "cslib:svcb:" .. eventname
				return RegisterNetEvent(cbEventName, function(id, ...)
					local src = source
					TriggerClientEvent(cbEventName .. id, src, listener(...))
				end)
			end
			local function triggerClientCallback(eventname, src, listener, ...)
				if not (src) then
					error("source for server callback is nil")
				end
				if not (listener) then
					error("listener for server callback is nil")
				end
				local callbackId = lib.utils.randomString(16)
				local cbEventName = "cslib:clcb:" .. eventname
				lib.onceNet(cbEventName .. callbackId, listener)
				TriggerClientEvent(cbEventName, src, callbackId, ...)
			end
			local function triggerClientCallbackSync(eventname, src, ...)
				local function handler(...)
					local p = promise.new()
					triggerClientCallback(eventname, src, function(...)
						p:resolve({
							...
						})
					end, ...)
					return Citizen_Await(p)
				end
				return table_unpack(handler(...))
			end
			return {
				callback = setmetatable({
					register = registerServerCallback,
					await = triggerClientCallbackSync
				}, {
					__call = function(t, ...)
						return triggerClientCallback(...)
					end
				})
			}
		end or function()
			local table_unpack = table.unpack
			local Citizen_Await = Citizen.Await
			local triggerServerCallback = function(eventname, listener, ...)
				if not (listener) then
					error("listener for server callback is nil")
				end
				local callbackId = lib.utils.randomString(16)
				local cbEventName = "cslib:svcb:" .. eventname
				lib.onceNet(cbEventName .. callbackId, listener)
				TriggerServerEvent(cbEventName, callbackId, ...)
			end
			local triggerServerCallbackSync = function(eventname, ...)
				local function handler(...)
					local p = promise.new()
					triggerServerCallback(eventname, function(...)
						p:resolve({
							...
						})
					end, ...)
					return Citizen_Await(p)
				end
				return table_unpack(handler(...))
			end
			local registerClientCallback = function(eventname, listener)
				local cbEventName = "cslib:clcb:" .. eventname
				return RegisterNetEvent(cbEventName, function(id, ...)
					TriggerServerEvent(cbEventName .. id, listener(...))
				end)
			end
			return {
				callback = setmetatable({
					register = registerClientCallback,
					await = triggerServerCallbackSync
				}, {
					__call = function(t, ...)
						return triggerServerCallback(...)
					end
				})
			}
		end,
	}
	for key, value in pairs(__cslib_internal.shared()) do
		__cslib_internal.library[key] = value
	end
	for key, value in pairs(__cslib_internal.source()) do
		__cslib_internal.library[key] = value
	end
	return __cslib_internal.library
end
components["network"] = function(lib)
	local __cslib_internal = {
		library = {},
		shared = function()
			local library = {}
			if (lib.isServer) then
				library.registerServerCallback = lib.net.callback.register
			else
				library.triggerServerCallback = lib.net.callback
				library.triggerServerCallbackSync = lib.net.callback.await
			end
			return library
		end,
		source = IsDuplicityVersion() and function()
			return {}
		end or function()
			return {}
		end,
	}
	for key, value in pairs(__cslib_internal.shared()) do
		__cslib_internal.library[key] = value
	end
	for key, value in pairs(__cslib_internal.source()) do
		__cslib_internal.library[key] = value
	end
	return __cslib_internal.library
end
components["replication"] = function(lib)
	local __cslib_internal = {
		library = {},
		shared = function()
			return {}
		end,
		source = IsDuplicityVersion() and function()
			return {}
		end or function()
			return {}
		end,
	}
	for key, value in pairs(__cslib_internal.shared()) do
		__cslib_internal.library[key] = value
	end
	for key, value in pairs(__cslib_internal.source()) do
		__cslib_internal.library[key] = value
	end
	return __cslib_internal.library
end
components["resource"] = function(lib)
	local __cslib_internal = {
		library = {},
		shared = function()
			local resourceName = GetCurrentResourceName()
			return {
				name = resourceName,
				event = setmetatable({}, {
					__call = function(t, eventname)
						return resourceName .. ":" .. eventname
					end
				})
			}
		end,
		source = IsDuplicityVersion() and function()
			return {}
		end or function()
			return {}
		end,
	}
	for key, value in pairs(__cslib_internal.shared()) do
		__cslib_internal.library[key] = value
	end
	for key, value in pairs(__cslib_internal.source()) do
		__cslib_internal.library[key] = value
	end
	return __cslib_internal.library
end
components["streaming"] = function(lib)
	local __cslib_internal = {
		library = {},
		shared = function()
			return {}
		end,
		source = IsDuplicityVersion() and function()
			return {}
		end or function()
			local function requestAnimDict(animDict, cb)
				if type(animDict) ~= "string" then
					error(("animDict expected \"string\" (received %s)"):format(type(animDict)))
				end
				if not (cb) then
					error("callback expected \"function\" (received nil)")
				end
				if not DoesAnimDictExist(animDict) then
					error(("animDict \"%s\" was not exist"):format(animDict))
				end
				if (HasAnimDictLoaded(animDict)) then
					cb()
					return
				end
				RequestAnimDict(animDict)
				local interval
				interval = lib.setInterval(function()
					if HasAnimDictLoaded(animDict) then
						if (cb) then
							cb()
						end
						lib.clearInterval(interval)
					end
				end, 100)
			end
			local function requestAnimDictSync(animDict)
				if not (coroutine.running()) then
					error("This function must be called in a coroutine")
				end
				local p = promise.new()
				requestAnimDict(animDict, function()
					p:resolve(animDict)
				end)
				return Citizen.Await(p)
			end
			local function requestModel(model, cb)
				if not (model) then
					error("model expected \"string\" or \"number\" (received nil)")
				end
				if not (cb) then
					error("callback expected \"function\" (received nil)")
				end
				local modelStr
				if type(model) ~= "number" then
					modelStr = model
					model = joaat(model)
				end
				if not IsModelValid(model) then
					error(("model \"%s\" is not valid"):format(modelStr and modelStr or model))
				end
				if (HasModelLoaded(model)) then
					cb()
					return
				end
				RequestModel(model)
				local interval
				interval = lib.setInterval(function()
					if HasModelLoaded(model) then
						if (cb) then
							cb()
						end
						lib.clearInterval(interval)
					end
				end, 100)
			end
			local function requestModelSync(model)
				if not (coroutine.running()) then
					error("This function must be called in a coroutine")
				end
				local p = promise.new()
				requestModel(model, function()
					p:resolve(model)
				end)
				return Citizen.Await(p)
			end
			return {
				animDict = {
					request = setmetatable({
						await = requestAnimDictSync
					}, {
						__call = function(_, ...)
							return requestAnimDict(...)
						end
					}),
					remove = RemoveAnimDict,
					hasLoaded = HasAnimDictLoaded,
					isValid = DoesAnimDictExist
				},
				model = {
					request = setmetatable({
						await = requestModelSync
					}, {
						__call = function(_, ...)
							return requestModel(...)
						end
					}),
					remove = SetModelAsNoLongerNeeded,
					hasLoaded = HasModelLoaded,
					isValid = IsModelValid
				}
			}
		end,
	}
	for key, value in pairs(__cslib_internal.shared()) do
		__cslib_internal.library[key] = value
	end
	for key, value in pairs(__cslib_internal.source()) do
		__cslib_internal.library[key] = value
	end
	return __cslib_internal.library
end
components["tickpool"] = function(lib)
	local __cslib_internal = {
		library = {},
		shared = function()
			local Wait = Wait
			local tickpool = {}
			tickpool.__index = tickpool
			function tickpool.new(options)
				options = options or {}
				local self = {}
				self.handlers = {
					fn = {},
					list = {},
					length = 0,
				}
				self.bReassignTable = false
				self.key = 10
				self.tickRate = options.tickRate or 0
				self.interval = nil
				return setmetatable(self, tickpool)
			end
			function tickpool:onTick(fnHandler)
				self.key += 1
				self.handlers.fn[self.key] = fnHandler
				self.bReassignTable = true
				if not (self.interval) then
					self.interval = lib.setInterval(function()
						local listEntries = self.handlers.list
						if (self.bReassignTable) then
							table.wipe(listEntries)
							for _, value in pairs(self.handlers.fn) do
								listEntries[# listEntries + 1] = value
							end
							self.handlers.length = # listEntries
							if (self.handlers.length <= 0) then
								self.interval:destroy()
								self.interval = nil
							end
						end
						for i = 1, self.handlers.length, 1 do
							listEntries[i]()
						end
					end, self.tickRate)
				end
				return self.key
			end
			function tickpool:destroy()
				if (self.interval) then
					self.interval:destroy()
					self.interval = nil
				end
			end
			function tickpool:clearOnTick(key)
				self.handlers.fn[key] = nil
				self.bReassignTable = true
			end
			return setmetatable({
				new = tickpool.new,
			}, {
				__call = function(_, ...)
					return tickpool.new(...)
				end
			})
		end,
		source = IsDuplicityVersion() and function()
			return {}
		end or function()
			return {}
		end,
	}
	for key, value in pairs(__cslib_internal.shared()) do
		__cslib_internal.library[key] = value
	end
	for key, value in pairs(__cslib_internal.source()) do
		__cslib_internal.library[key] = value
	end
	return __cslib_internal.library
end
components["timer"] = function(lib)
	local __cslib_internal = {
		library = {},
		shared = function()
			local timer = {}
			timer.__index = timer
			local Wait = Wait
			local CitizenCreateThreadNow = Citizen.CreateThreadNow
			function timer.new(handler, delay, options)
				local self = {}
				self.delay = delay or 0
				self.bDestroyed = false
				self.isLoop = (options.isLoop ~= nil) and options.isLoop or false
				self.fnHandler = handler
				self.handler = function()
					if (self.bDestroyed) then
						return
					end
					Wait(self.delay)
					self.fnHandler()
				end
				CitizenCreateThreadNow(function(ref)
					self.id = ref
					if (self.isLoop) then
						while not (self.bDestroyed) do
							self.handler()
						end
					else
						self.handler()
					end
				end)
				return setmetatable(self, timer)
			end
			function timer:destroy()
				self.bDestroyed = true
			end
			return {
				new = timer.new
			}
		end,
		source = IsDuplicityVersion() and function()
			return {}
		end or function()
			return {}
		end,
	}
	for key, value in pairs(__cslib_internal.shared()) do
		__cslib_internal.library[key] = value
	end
	for key, value in pairs(__cslib_internal.source()) do
		__cslib_internal.library[key] = value
	end
	return __cslib_internal.library
end
components["utils"] = function(lib)
	local __cslib_internal = {
		library = {},
		shared = function()
			local math_random = math.random
			local Charset = {
				numeric = {
					len = 0,
					chars = {}
				},
				upper = {
					len = 0,
					chars = {}
				},
				lower = {
					len = 0,
					chars = {}
				},
			}
			do
				for i = 48, 57 do
					table.insert(Charset.numeric.chars, string.char(i))
				end
				Charset.numeric.len = # Charset.numeric.chars
				for i = 65, 90 do
					table.insert(Charset.upper.chars, string.char(i))
				end
				Charset.upper.len = # Charset.upper.chars
				for i = 97, 122 do
					table.insert(Charset.lower.chars, string.char(i))
				end
				Charset.lower.len = # Charset.lower.chars
			end
			local randomString
			randomString = function(length, options)
				if (length > 0) then
					options = options or {
						"lower",
						"upper",
						"numeric"
					}
					options.op_len = options.op_len or # options
					local charType = options[math_random(1, options.op_len)]
					local randomChar = Charset[charType].chars[math_random(1, Charset[charType].len)]
					return randomChar .. randomString(length - 1, options)
				end
				return ""
			end
			return {
				randomString = randomString,
			}
		end,
		source = IsDuplicityVersion() and function()
			return {}
		end or function()
			return {}
		end,
	}
	for key, value in pairs(__cslib_internal.shared()) do
		__cslib_internal.library[key] = value
	end
	for key, value in pairs(__cslib_internal.source()) do
		__cslib_internal.library[key] = value
	end
	return __cslib_internal.library
end
components["zone"] = function(lib)
	local __cslib_internal = {
		library = {},
		shared = function()
			return {}
		end,
		source = IsDuplicityVersion() and function()
			return {}
		end or function()
			return {
				sphere = setmetatable({
					new = function(coords, radius, options)
						options = options or {}
						options.bOnlyRelevant = true
						local collision = lib.collision.sphere(coords, radius, options)
						collision:addRelevantPlayer(GetPlayerServerId(PlayerId()))
						return collision
					end
				}, {
					__call = function(t, ...)
						return t.new(...)
					end
				})
			}
		end,
	}
	for key, value in pairs(__cslib_internal.shared()) do
		__cslib_internal.library[key] = value
	end
	for key, value in pairs(__cslib_internal.source()) do
		__cslib_internal.library[key] = value
	end
	return __cslib_internal.library
end
local lib = setmetatable({}, {
	__index = function(lib, key)
		local library = components[key]
		if not (library) then
			error(("^1[ Component %s not found ]^0"):format(key), 2)
		end
		rawset(lib, key, library(lib))
		return rawget(lib, key)
	end
})
_ENV.cslib = setmetatable({}, {
	__index = function(self, key)
		local isServer = IsDuplicityVersion()
		local function bindOnce(bIsNet, eventname, listener)
			local event
			local fn = function(...)
				lib.off(event)
				listener(...)
			end
			event = bIsNet and RegisterNetEvent(eventname, fn) or AddEventHandler(eventname, fn)
			return event
		end
		lib.setInterval = function(handler, time)
			return lib.timer.new(handler, time, {
				isLoop = true
			})
		end
		lib.setTimeout = function(handler, time)
			return lib.timer.new(handler, time, {
				isLoop = false
			})
		end
		lib.clearInterval = function(instance)
			if not (instance) then
				return
			end
			instance:destroy()
		end
		lib.isServer = isServer
		lib.bIsServer = isServer
		lib.on = AddEventHandler
		lib.off = RemoveEventHandler
		lib.emit = TriggerEvent
		lib.onNet = RegisterNetEvent
		lib.once = function(eventname, listener)
			return bindOnce(false, eventname, listener)
		end
		lib.onceNet = function(eventname, listener)
			return bindOnce(true, eventname, listener)
		end


-- Server
		lib.registerServerCallback = lib.net.registerServerCallback
		lib.emitClient = isServer and TriggerClientEvent
		lib.emitAllClients = isServer and function(eventname, ...)
			self.emitClient(eventname, - 1, ...)
		end

-- Client
		lib.triggerServerCallback = not isServer and lib.net.triggerServerCallback
		lib.triggerServerCallbackSync = not isServer and lib.net.triggerServerCallbackSync
		lib.emitServer = not isServer and TriggerServerEvent

-- Tick Pool
		local baseTickPool
		lib.onTick = function(fnHandler)
			if not (baseTickPool) then
				baseTickPool = lib.tickpool()
			end
			return baseTickPool:onTick(fnHandler)
		end
		lib.clearOnTick = function(key)
			if not (baseTickPool) then
				return
			end
			baseTickPool:clearOnTick(key)
		end
		rawset(_ENV, "cslib", lib)
		return lib[key]
	end
})