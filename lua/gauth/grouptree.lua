local self = {}
GAuth.GroupTree = GAuth.MakeConstructor (self, GAuth.GroupTreeNode)

--[[
	Events:
		NotifyGroupAdded (name)
			Fire this when a child Group has been added to the host GroupTree
		NotifyGroupTreeAdded (name)
			Fire this when a child GroupTree has been added to the host GroupTree
		NotifyNodeRemoved (name)
			Fire this when a child node is removed from the host GroupTree
	
		GroupAdded (Group group)
			Fired when a child group has been added
		GroupTreeAdded (GroupTree groupTree)
			Fired when a child group tree has been added
		NodeAdded (GroupTreeNode groupTreeNode)
			Fired when a child node has been added
		NodeRemoved (GroupTreeNode groupTreeNode)
			Fired when a child node has been removed
]]

function self:ctor (name)
	self.Children = {}
	
	self.Icon = "gui/g_silkicons/folder_user"
	
	self:AddEventListener ("NotifyGroupAdded",
		function (_, name)
			if self.Children [name] then return end
			self.Children [name] = GAuth.Group (name)
			self.Children [name]:SetParentNode (self)
			self.Children [name]:SetHost (self:GetHost ())
			
			self:DispatchEvent ("GroupAdded", self.Children [name])
			self:DispatchEvent ("NodeAdded", self.Children [name])
		end
	)
	
	self:AddEventListener ("NotifyGroupTreeAdded",
		function (_, name)
			if self.Children [name] then return end
			self.Children [name] = GAuth.GroupTree (name)
			self.Children [name]:SetParentNode (self)
			self.Children [name]:SetHost (self:GetHost ())
			
			self:DispatchEvent ("GroupTreeAdded", self.Children [name])
			self:DispatchEvent ("NodeAdded", self.Children [name])
		end
	)
	
	self:AddEventListener ("NotifyNodeRemoved",
		function (_, name)
			local node = self.Children [name]
			if not node then return end
			self.Children [name] = nil
			node:DispatchEvent ("Removed")
			self:DispatchEvent ("NodeRemoved", node)
		end
	)
end

function self:AddGroup (authId, name, callback)
	callback = callback or GAuth.NullCallback
	name = name:gsub ("/", "")

	if self.Children [name] then
		if not self.Children [name]:IsGroupTree () then
			callback (GAuth.ReturnCode.Success, self.Children [name])
		else
			callback (GAuth.ReturnCode.NodeAlreadyExists)
		end
		return
	end
	if not self:GetPermissionBlock ():IsAuthorized (authId, "Create Group") then callback (GAuth.ReturnCode.AccessDenied) return end
	
	if not self:IsPredicted () and not self:IsHostedLocally () then
		local nodeAdditionRequest = GAuth.Protocol.NodeAdditionRequest (self, name, false,
			function (returnCode)
				callback (returnCode, self.Children [name])
			end
		)
		GAuth.NetClientManager:GetEndPoint (self:GetHost ()):StartSession (nodeAdditionRequest)
		return
	end
	
	self.Children [name] = GAuth.Group (name)
	self.Children [name]:SetParentNode (self)
	self.Children [name]:SetHost (self:GetHost ())
	
	self:DispatchEvent ("GroupAdded", self.Children [name])
	self:DispatchEvent ("NodeAdded", self.Children [name])
	
	callback (GAuth.ReturnCode.Success, self.Children [name])
end

function self:AddGroupTree (authId, name, callback)
	callback = callback or GAuth.NullCallback
	name = name:gsub ("/", "")

	if self.Children [name] then
		if self.Children [name]:IsGroupTree () then
			callback (GAuth.ReturnCode.Success, self.Children [name])
		else
			callback (GAuth.ReturnCode.NodeAlreadyExists)
		end
		return
	end
	if not self:GetPermissionBlock ():IsAuthorized (authId, "Create Group Tree") then callback (GAuth.ReturnCode.AccessDenied) return end
	
	if not self:IsPredicted () and not self:IsHostedLocally () then
		local nodeAdditionRequest = GAuth.Protocol.NodeAdditionRequest (self, name, true,
			function (returnCode)
				callback (returnCode, self.Children [name])
			end
		)
		GAuth.NetClientManager:GetEndPoint (self:GetHost ()):StartSession (nodeAdditionRequest)
		return
	end
	
	self.Children [name] = GAuth.GroupTree (name)
	self.Children [name]:SetParentNode (self)
	self.Children [name]:SetHost (self:GetHost ())
	
	self:DispatchEvent ("GroupTreeAdded", self.Children [name])
	self:DispatchEvent ("NodeAdded", self.Children [name])
	
	callback (GAuth.ReturnCode.Success, self.Children [name])
end

function self:ContainsUser (userId, permissionBlock)
	for _, groupTreeNode in pairs (self.Children) do
		if groupTreeNode:ContainsUser (userId, permissionBlock) then return true end
	end
	return false
end

function self:GetChild (name)
	return self.Children [name]
end

--[[
	GroupTree:GetChildEnumerator ()
		Returns: ()->(name, GroupTreeNode childNode)
]]
function self:GetChildEnumerator ()
	local next, tbl, key = pairs (self.Children)
	return function ()
		key = next (tbl, key)
		return key, tbl [key]
	end
end

function self:IsGroupTree ()
	return true
end

function self:RemoveNode (authId, name, callback)
	callback = callback or GAuth.NullCallback
	
	local node = self.Children [name]
	if not node then callback (GAuth.ReturnCode.Success) return end
	if not node:GetPermissionBlock ():IsAuthorized (authId, "Delete") then callback (GAuth.ReturnCode.AccessDenied) return end
	
	if not self:IsPredicted () and not self:IsHostedLocally () then
		local nodeRemovalRequest = GAuth.Protocol.NodeRemovalRequest (self, node,
			function (returnCode)
				callback (returnCode)
			end
		)
		GAuth.NetClientManager:GetEndPoint (self:GetHost ()):StartSession (nodeRemovalRequest)
	end
	
	self.Children [name] = nil
	node:DispatchEvent ("Removed")
	self:DispatchEvent ("NodeRemoved", node)
	
	callback (GAuth.ReturnCode.Success)
end