GAuth.Protocol.ResponseTable = {}
GAuth.Protocol.StringTable = GAuth.Net.StringTable ()

function GAuth.Protocol.Register (packetType, class)
	GAuth.Protocol.StringTable:Add (packetType)
	class.Type = packetType
	class.TypeId = GAuth.Protocol.StringTable:HashFromString (packetType)
end

function GAuth.Protocol.RegisterResponse (packetType, ctor)
	GAuth.Protocol.StringTable:Add (packetType)
	GAuth.Protocol.ResponseTable [packetType] = ctor
	local class = GAuth.GetMetaTable (ctor)
	class.Type = packetType
	class.TypeId = GAuth.Protocol.StringTable:HashFromString (packetType)
end

GAuth.Net.RegisterChannel ("gauth_new_request",
	function (senderId, inBuffer)
		local client = GAuth.NetServer:GetClient (senderId)
		local requestId = inBuffer:UInt32 ()
		local typeId = inBuffer:UInt32 ()
		local packetType = GAuth.Protocol.StringTable:StringFromHash (typeId)
		
		local ctor = GAuth.Protocol.ResponseTable [packetType]
		if not ctor then
			ErrorNoHalt ("gauth_new_request : No handler for " .. packetType .. " is registered!")
			return
		end
		local response = ctor ()
		response:SetClient (client)
		response:SetServer (GAuth.NetServer)
		response:SetId (requestId)
		client:HandleNewRequest (response, inBuffer)
	end
)

GAuth.Net.RegisterChannel ("gauth_request_data",
	function (senderId, inBuffer)
		local client = GAuth.NetServer:GetClient (senderId)
	end
)

GAuth.Net.RegisterChannel ("gauth_response_data",
	function (senderId, inBuffer)
		local client = GAuth.NetClientManager:GetClient (senderId)
		client:HandleResponse (inBuffer:UInt32 (), inBuffer)
	end
)

GAuth.Net.RegisterChannel ("gauth_notification",
	function (senderId, inBuffer)
		local client = GAuth.NetClientManager:GetClient (senderId)
	end
)