local self = {}
VFS.Protocol.RegisterResponse ("FolderListing", VFS.MakeConstructor (self, VFS.Protocol.Response))

function self:ctor ()
	self.FolderPath = nil
end

function self:HandleInitialPacket (inBuffer)
	self.FolderPath = inBuffer:String ()
	ErrorNoHalt ("FolderListing: Request for " .. self.FolderPath .. " received.\n")
	VFS.Root:GetChild (self:GetClient ():GetClientId (), self.FolderPath,
		function (returnCode, node)
			if returnCode == VFS.ReturnCode.None then
				node:EnumerateChildren (self:GetClient ():GetClientId (),
					function (returnCode, node)
						if returnCode == VFS.ReturnCode.None then
							self:SendReturnCode (returnCode, node)
						elseif returnCode == VFS.ReturnCode.Finished then
							self:SendReturnCode (VFS.ReturnCode.Finished)
							self:Close ()
						else
							self:SendReturnCode (returnCode)
						end
					end
				)
			else
				self:SendReturnCode (returnCode)
				self:SendReturnCode (VFS.ReturnCode.Finished)
				self:Close ()
			end
		end
	)
end

function self:SendReturnCode (returnCode, node)
	ErrorNoHalt ("FolderListing : " .. self.FolderPath .. " : return code " .. VFS.ReturnCode [returnCode] .. ".\n")
	local outBuffer = self:CreatePacket ()
	outBuffer:UInt8 (returnCode)
	
	if returnCode == VFS.ReturnCode.None then
		outBuffer:UInt8 (node:GetNodeType ())
		outBuffer:String (node:GetName ())
		if node:GetName () == node:GetDisplayName () then
			outBuffer:String ("")
		else
			outBuffer:String (node:GetDisplayName ())
		end
	end
	
	self:QueuePacket (outBuffer)
end