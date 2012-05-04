VFS.Protocol.ResponseTable = {}
VFS.Protocol.StringTable = VFS.Net.StringTable ()

function VFS.Protocol.Register (packetType, class)
	VFS.Protocol.StringTable:Add (packetType)
	class.Type = packetType
	class.TypeId = VFS.Protocol.StringTable:HashFromString (packetType)
end

function VFS.Protocol.RegisterResponse (packetType, ctor)
	VFS.Protocol.StringTable:Add (packetType)
	VFS.Protocol.ResponseTable [packetType] = ctor
	local class = VFS.GetMetaTable (ctor)
	class.Type = packetType
	class.TypeId = VFS.Protocol.StringTable:HashFromString (packetType)
end

VFS.Net.RegisterChannel ("vfs_new_request",
	function (senderId, inBuffer)
		local client = VFS.NetServer:GetClient (senderId)
		local requestId = inBuffer:UInt32 ()
		local typeId = inBuffer:UInt32 ()
		local packetType = VFS.Protocol.StringTable:StringFromHash (typeId)
		
		local ctor = VFS.Protocol.ResponseTable [packetType]
		if not ctor then
			ErrorNoHalt ("vfs_new_request : No handler for " .. packetType .. " is registered!")
			return
		end
		local response = ctor ()
		response:SetClient (client)
		response:SetServer (VFS.NetServer)
		response:SetId (requestId)
		client:HandleNewRequest (response, inBuffer)
	end
)

VFS.Net.RegisterChannel ("vfs_request_data",
	function (senderId, inBuffer)
		local client = VFS.NetServer:GetClient (senderId)
	end
)

VFS.Net.RegisterChannel ("vfs_response_data",
	function (senderId, inBuffer)
		local client = VFS.NetClientManager:GetClient (senderId)
		client:HandleResponse (inBuffer:UInt32 (), inBuffer)
	end
)

VFS.Net.RegisterChannel ("vfs_notification",
	function (senderId, inBuffer)
		local client = VFS.NetClientManager:GetClient (senderId)
	end
)