local self = {}
VFS.NetFile = VFS.MakeConstructor (self, VFS.IFile)

function self:ctor (netClient, path, name, parentFolder)
	self.NetClient = netClient
	self.Path = path
	
	self.Name = name
	self.DisplayName = self.Name
	self.ParentFolder = parentFolder
	
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

function self:SetDisplayName (displayName)
	self.DisplayName = displayName
end