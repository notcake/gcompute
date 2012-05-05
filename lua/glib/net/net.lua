GLib.Net = {}
GLib.Net.PlayerMonitor = GLib.PlayerMonitor ("GLib.Net")
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
			datastream.StreamToServer (channelName, packet.Data)
		end
	end
end

function GLib.Net.IsChannelOpen (channelName)
	return GLib.Net.OpenChannels [channelName] and true or false
end

-- Packet reception
function GLib.Net.RegisterChannel (channelName, handler)
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
	GLib.Net.PlayerMonitor:AddEventListener ("PlayerConnected",
		function (_, ply)
			for channelName, _ in pairs (GLib.Net.OpenChannels) do
				umsg.Start ("glib_channel_open", ply)
					umsg.String (channelName)
				umsg.End ()
			end
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
elseif CLIENT then
	usermessage.Hook ("glib_channel_open", function (umsg)
		GLib.Net.OpenChannels [umsg:ReadString ()] = true
	end)
	
	timer.Simple (1,
		function ()
			RunConsoleCommand ("glib_request_channels")
		end
	)
end