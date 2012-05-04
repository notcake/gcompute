local self = {}
VFS.NetFolder = VFS.MakeConstructor (self, VFS.IFolder)

function self:ctor (netClient, path, name, parentFolder)
	self.NetClient = netClient
	self.Path = path
	self.FolderPath = self.Path .. "/"
	if self.Path == "" then
		self.FolderPath = ""
	end
	self.Name = name
	self.DisplayName = self.Name
	self.ParentFolder = parentFolder
	
	self.ReceivedChildren = false
	self.FolderListingRequest = nil
	self.Children = {}
	
	self.Predicted = false
end

function self:ClearPredictedFlag ()
	self.Predicted = false
end

function self:CreatePredictedFolder (name)
	self.Children [name] = VFS.NetFolder (self.NetClient, self.FolderPath .. name, name, self)
	self.Children [name].Predicted = true
	return self.Children [name]
end

function self:EnumerateChildren (authId, callback)
	callback = callback or VFS.NullCallback
	
	-- Enumerate received children
	for _, node in pairs (self.Children) do
		callback (VFS.ReturnCode.None, node)
	end
	
	-- TODO: Run callback on unreceived children
	if self.ReceivedChildren then
		callback (VFS.ReturnCode.Finished)
	else
		callback (VFS.ReturnCode.EndOfBurst)
		
		if not self.FolderListingRequest then
			self.FolderListingRequest = VFS.Protocol.FolderListingRequest (self)
			self.NetClient:StartRequest (self.FolderListingRequest)
			
			self.FolderListingRequest:AddEventListener ("ReceivedNodeInfo", function (request, nodeType, name, displayName)
				local child = self.Children [name]
				if child then
					if child.Predicted then
						child:ClearPredictedFlag ()
					end
				else
					if nodeType & VFS.NodeType.Folder ~= 0 then
						child = VFS.NetFolder (self.NetClient, self.FolderPath .. name, name, self)
						D = child
					elseif nodeType & VFS.NodeType.File ~= 0 then
						child = VFS.NetFile (self.NetClient, self.FolderPath .. name, name, self)
					end
					self.Children [name] = child
				end
				child:SetDisplayName (displayName or name)
				request:DispatchEvent ("RunCallback", VFS.ReturnCode.None, child)
			end)
			
			self.FolderListingRequest:AddEventListener ("TimedOut", function (request)
				request:DispatchEvent ("RunCallback", VFS.ReturnCode.TimedOut)
				request:DispatchEvent ("RunCallback", VFS.ReturnCode.Finished)
				self.FolderListingRequest = nil
			end)
			
			local failed = false
			self.FolderListingRequest:AddEventListener ("RunCallback", function (request, returnCode)
				if returnCode == VFS.ReturnCode.None then
				elseif returnCode == VFS.ReturnCode.Finished then
					self.ReceivedChildren = not failed
					self.FolderListingRequest = nil
				elseif returnCode == VFS.ReturnCode.EndOfBurst then
				else
					failed = true
				end
			end)
		end
		
		self.FolderListingRequest:AddEventListener ("RunCallback", function (request, returnCode, node)
			callback (returnCode, node)
		end)
	end
end

function self:FlagAsPredicted ()
	self.Predicted = true
end

function self:GetDirectChild (authId, name, callback)
	callback = callback or VFS.NullCallback
	
	if self.Children [name] then
		callback (VFS.ReturnCode.None, self.Children [name])
	elseif self.ReceivedChildren then
		callback (VFS.ReturnCode.NotFound)
	else
		local folderChildRequest = VFS.Protocol.FolderChildRequest (self, name)
		self.NetClient:StartRequest (folderChildRequest)
		
		folderChildRequest:AddEventListener ("RunCallback", function (request, returnCode, node)
			callback (returnCode, node)
		end)
	end
end

function self:GetDisplayName ()
	return self.DisplayName
end

function self:GetName ()
	return self.Name
end

function self:GetParentFolder ()
	return self.ParentFolder
end

function self:MountLocal (name, node)
	if not node then return end

	if node:IsFolder () then
		self.Children [name] = VFS.MountedFolder (name, node, self)
	else
		self.Children [name] = VFS.MountedFile (name, node, self)
	end
end

function self:SetDisplayName (displayName)
	self.DisplayName = displayName
end