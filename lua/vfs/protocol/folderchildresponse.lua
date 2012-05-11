local self = {}
VFS.Protocol.RegisterResponse ("FolderChild", VFS.MakeConstructor (self, VFS.Protocol.Session))

function self:ctor ()
	self.FolderPath = nil
	self.ChildName = nil
end

function self:HandleInitialPacket (inBuffer)
	self.FolderPath = inBuffer:String ()
	self.ChildName = inBuffer:String ()
	ErrorNoHalt ("FolderChild: Request for " .. self.FolderPath .. "/" .. self.ChildName .. " received.\n")
	VFS.Root:GetChild (self:GetRemoteEndPoint ():GetRemoteId (), self.FolderPath .. "/" .. self.ChildName,
		function (returnCode, node)
			local outBuffer = self:CreatePacket ()
			outBuffer:UInt8 (returnCode)
			if returnCode == VFS.ReturnCode.Success then
				-- Warning: Duplicate code in FolderListingResponse:SendReturnCode
			
				outBuffer:UInt8 (node:GetNodeType ())
				outBuffer:String (node:GetName ())
				if node:GetName () == node:GetDisplayName () then
					outBuffer:String ("")
				else
					outBuffer:String (node:GetDisplayName ())
				end
				
				-- Now the permission block (urgh)
				local synchronizationTable = VFS.PermissionBlockNetworker:PreparePermissionBlockSynchronizationList (node:GetPermissionBlock ())
				outBuffer:UInt16 (#synchronizationTable)
				for _, session in ipairs (synchronizationTable) do
					outBuffer:UInt32 (session:GetTypeId ())
					session:GenerateInitialPacket (outBuffer)
				end
			end
			self:QueuePacket (outBuffer)
			self:Close ()
		end
	)
end