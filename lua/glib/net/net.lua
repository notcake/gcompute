GLib.Net = {}
GLib.Net.PlayerMonitor = GLib.PlayerMonitor ("GLib.Net")
GLib.Net.ChannelHandlers = {}
GLib.Net.OpenChannels = {}

local function PlayerFromId (userId)
	local players = player.GetAll ()
	if userId == "Everyone" then return players end
	for _, ply in pairs (players) do
		if ply:SteamID () == userId then return ply end
	end
	ErrorNoHalt ("GLib: PlayerFromId (" .. tostring (userId) .. ") failed to find player!\n")
	return nil
end

-- Packet transmission
if SERVER then
	function GLib.Net.DispatchPacket (destinationId, channelName, packet)
		local ply = PlayerFromId (destinationId)
		if not ply then
			GLib.Error ("GLib.Net.DispatchPacket: Destination " .. destinationId .. " not found.")
			return
		end
		if packet:GetSize () + channelName:len () > 255 then
			datastream.StreamToClients (ply, channelName, packet.Data)
		else
			GLib.Net.UsermessageDispatcher:Dispatch (ply, channelName, packet)
		end
	end
elseif CLIENT then
	function GLib.Net.DispatchPacket (destinationId, channelName, packet)
		-- datastream time.
		if GLib.Net.IsChannelOpen (channelName) then
			GLib.Net.ConCommandDispatcher:Dispatch (destinationId, channelName, packet)
		else
			ErrorNoHalt ("GLib.Net : Channel " .. channelName .. " is not open.\n")
		end
	end
end

function GLib.Net.IsChannelOpen (channelName)
	return GLib.Net.OpenChannels [channelName] and true or false
end

-- Packet reception
function GLib.Net.RegisterChannel (channelName, handler)
	GLib.Net.ChannelHandlers [channelName] = handler

	if SERVER then
		datastream.Hook (channelName,
			function (ply, channelName, _, _, data)
				handler (ply:SteamID (), GLib.Net.DatastreamInBuffer (data))
			end
		)
		
		for _, ply in GLib.Net.PlayerMonitor:GetPlayerEnumerator () do
			umsg.Start ("glib_channel_open", ply)
				umsg.String (channelName)
			umsg.End ()
		end
		
		GLib.Net.OpenChannels [channelName] = true
	elseif CLIENT then
		datastream.Hook (channelName,
			function (channelName, _, _, data)
				handler (GAuth.GetServerId (), GLib.Net.DatastreamInBuffer (data))
			end
		)
		
		usermessage.Hook (channelName,
			function (umsg)
				handler (GAuth.GetServerId (), GLib.Net.UsermessageInBuffer (umsg))
			end
		)
	end
end

if SERVER then
	GLib.Net.ConCommandBuffers = {}

	GLib.Net.PlayerMonitor:AddEventListener ("PlayerConnected",
		function (_, ply)
			for channelName, _ in pairs (GLib.Net.OpenChannels) do
				umsg.Start ("glib_channel_open", ply)
					umsg.String (channelName)
				umsg.End ()
			end
		end
	)

	GLib.Net.PlayerMonitor:AddEventListener ("PlayerDisconnected",
		function (_, ply)
			GLib.Net.ConCommandBuffers [ply:SteamID ()] = nil
		end
	)
	
	concommand.Add ("glib_request_channels",
		function (ply, _, _)
			if not ply or not ply:IsValid () then return end
			for channelName, _ in pairs (GLib.Net.OpenChannels) do
				umsg.Start ("glib_channel_open", ply)
					umsg.String (channelName)
				umsg.End ()
			end
		end
	)
	
	concommand.Add ("glib_data",
		function (ply, _, args)
			local steamId = ply:SteamID ()
			if not args [1] then return end
			
			GLib.Net.ConCommandBuffers [steamId] = GLib.Net.ConCommandBuffers [steamId] or ""
			
			if args [1]:sub (1, 1) == "\2" or args [1]:sub (1, 1) == "\3" then
				if GLib.Net.ConCommandBuffers [steamId] ~= "" then
					local inBuffer = GLib.Net.ConCommandInBuffer (GLib.Net.ConCommandBuffers [steamId])
					local channelName = inBuffer:String ()
					local handler = GLib.Net.ChannelHandlers [channelName]
					if not handler then
						ErrorNoHalt ("No handler for " .. channelName .. "\n")
					end
					if handler then PCallError (handler, steamId, inBuffer) end
					GLib.Net.ConCommandBuffers [steamId] = ""
				end
			end
			GLib.Net.ConCommandBuffers [steamId] = GLib.Net.ConCommandBuffers [steamId] .. args [1]:sub (2)
		end
	)
elseif CLIENT then
	usermessage.Hook ("glib_channel_open", function (umsg)
		GLib.Net.OpenChannels [umsg:ReadString ()] = true
	end)
	
	local function RequestChannelList ()
		if not LocalPlayer or
			not LocalPlayer () or
			not LocalPlayer ():IsValid () then
			timer.Simple (0, RequestChannelList)
		end
		
		RunConsoleCommand ("glib_request_channels")
	end
end