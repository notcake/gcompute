local self = {}
GLib.PlayerMonitor = GLib.MakeConstructor (self)

function self:ctor (systemName)
	self.SystemName = systemName

	self.Players = {}
	self.EntitiesToUserIds = {}
	self.QueuedPlayers = {}
	GLib.EventProvider (self)
	
	hook.Add (CLIENT and "OnEntityCreated" or "PlayerInitialSpawn", self.SystemName .. ".PlayerConnected", function (ply)
		if type (ply) == "Player" then
			self.QueuedPlayers [ply] = true
		end
	end)

	hook.Add ("Think", self.SystemName .. ".PlayerConnected", function ()
		for ply, _ in pairs (self.QueuedPlayers) do
			if ply:IsValid () and
				ply.SteamID and
				ply:Name () ~= "unconnected" then
				local steamID = ply:SteamID ()
				if steamID == "BOT" or steamID == "NULL" then
					self.QueuedPlayers [ply] = nil
				elseif steamID ~= "STEAM_ID_PENDING" then
					self.QueuedPlayers [ply] = nil
					local isLocalPlayer = CLIENT and ply == LocalPlayer () or false
					if SinglePlayer () and isLocalPlayer then steamID = "STEAM_0:0:0" end
					self.Players [steamID] =
					{
						Player = ply,
						Name = ply:Name ()
					}
					self.EntitiesToUserIds [ply] = steamID
					self:DispatchEvent ("PlayerConnected", ply, isLocalPlayer)
					if isLocalPlayer then
						self:DispatchEvent ("LocalPlayerConnected", ply)
					end
				end
			end
		end
	end)

	hook.Add ("EntityRemoved", self.SystemName .. ".PlayerDisconnected", function (ply)
		if type (ply) == "Player" and
			ply:IsValid () then
			if SERVER then
				local steamID = ply:SteamID ()
				local isLocalPlayer = CLIENT and ply == LocalPlayer () or false
				if SinglePlayer () and isLocalPlayer then steamID = "STEAM_0:0:0" end
				self.Players [steamID] = nil
				self.EntitiesToUserIds [ply] = nil
			end
			self:DispatchEvent ("PlayerDisconnected", ply)
		end
	end)

	for _, ply in ipairs (player.GetAll ()) do
		self.QueuedPlayers [ply] = true
	end

	if type (_G [systemName]) == "table" and type (_G [systemName].AddEventListener) == "function" then
		_G [systemName]:AddEventListener ("Unloaded", function ()
			self:dtor ()
		end)
	end
end

function self:dtor ()
	hook.Remove (CLIENT and "OnEntityCreated" or "PlayerInitialSpawn", self.SystemName .. ".PlayerConnected")
	hook.Remove ("Think", self.SystemName .. ".PlayerConnected")
	hook.Remove ("EntityRemoved", self.SystemName .. ".PlayerDisconnected")
end

--[[
	PlayerMonitor:GetPlayerEnumerator
		Returns: ()->(userId, Player player)
		
		Enumerates connected players.
]]
function self:GetPlayerEnumerator ()
	local next, tbl, key = pairs (self.Players)
	return function ()
		key = next (tbl, key)
		return key, (key and tbl [key].Player:IsValid () and tbl [key].Player or nil)
	end
end

function self:GetUserEntity (userId)
	local userEntry = self.Players [userId]
	if not userEntry then return nil end
	
	return userEntry.Player:IsValid () and userEntry.Player or nil
end

--[[
	PlayerMonitor:GetUserEnumerator ()
		Returns: ()->userId userEnumerator
		
		Enumerates user ids.
]]
function self:GetUserEnumerator ()
	local next, tbl, key = pairs (self.Players)
	return function ()
		key = next (tbl, key)
		return key
	end
end

function self:GetUserName (userId)
	local userEntry = self.Players [userId]
	if not userEntry then return userId end
	if userEntry.Player:IsValid () then
		return userEntry.Player:Name ()
	end
	
	return userEntry.Name
end