local self = {}
VFS.NetNode = VFS.MakeConstructor (self, VFS.INode)

function self:ctor (netClient, path, name, parentFolder)
	self.NetClient = netClient
	self.Path = path
	
	self.Name = name
	self.DisplayName = self.Name
	self.ParentFolder = parentFolder
	
	self.PermissionBlock = GAuth.PermissionBlock ()
	self.PermissionBlock:SetParentFunction (
		function ()
			if not self:GetParentFolder () then return end
			return self:GetParentFolder ():GetPermissionBlock ()
		end
	)
	self.PermissionBlock:SetDisplayNameFunction (function () return self:GetDisplayPath () end)
	self.PermissionBlock:SetNameFunction (function () return self:GetPath () end)
	
	self.Predicted = false
end

function self:ClearPredictedFlag ()
	self.Predicted = false
end

function self:FlagAsPredicted ()
	self.Predicted = true
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

function self:GetPermissionBlock ()
	return self.PermissionBlock
end

function self:SetDisplayName (displayName)
	self.DisplayName = displayName
end