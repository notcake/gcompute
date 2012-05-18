local self = {}
VFS.Protocol.RegisterResponse ("NodeRename", VFS.MakeConstructor (self, VFS.Protocol.Session))

function self:ctor ()
	self.FolderPath = nil
	self.OldName = nil
	self.NewName = nil
end

function self:HandleInitialPacket (inBuffer)
	self.FolderPath = inBuffer:String ()
	self.OldName = VFS.SanifyNodeName (inBuffer:String ())
	self.NewName = VFS.SanifyNodeName (inBuffer:String ())
	ErrorNoHalt ("NodeRename: Request for " .. self.FolderPath .. "/" .. self.OldName .. " -> " .. self.NewName .. " received.\n")
	VFS.Root:GetChild (self:GetRemoteEndPoint ():GetRemoteId (), self.FolderPath,
		function (returnCode, node)
			if returnCode == VFS.ReturnCode.Success then
				node:RenameChild (self:GetRemoteEndPoint ():GetRemoteId (), self.OldName, self.NewName,
					function (returnCode)
						self:SendReturnCode (returnCode)
						self:Close ()
					end
				)
			else
				self:SendReturnCode (returnCode)
				self:Close ()
			end
		end
	)
end