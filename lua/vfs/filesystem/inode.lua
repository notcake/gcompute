local self = {}
VFS.INode = VFS.MakeConstructor (self)

function self:ctor ()
	VFS.EventProvider (self)
end

--[[
	INode:Delete (authId, (returnCode)->() callback)
		
		Do not implement this, implement IFolder:DeleteDirectChild instead
		Delete this filesystem node
]]
function self:Delete (authId, callback)
	if not self:GetParentFolder () then
		VFS.Error ("IFolder:Delete : " .. self:GetPath () .. " has no parent folder from which to delete.")
		PrintTable (self)
		PrintTable (debug.getinfo (self.ctor))
		return
	end
	self:GetParentFolder ():DeleteDirectChild (authId, self:GetName (), callback)
end

function self:GetDisplayName ()
	return self:GetName ()
end

function self:GetDisplayPath ()
	local path = self:GetDisplayName ()
	local parent = self:GetParentFolder ()
	
	while parent do
		if path:len () > 1000 then
			error ("INode:GetDisplayPath : Path is too long!")
		end
		if parent:GetDisplayName () ~= "" then
			path = parent:GetDisplayName () .. "/" .. path
		end
		parent = parent:GetParentFolder ()
	end
	
	return path
end

function self:GetName ()
	VFS.Error ("INode:GetName : Not implemented")
    return "[Node]"
end

function self:GetNodeType ()
	VFS.Error ("INode:GetNodeType : Not implemented")
	return VFS.NodeType.Unknown
end

function self:GetOwner ()
	return self:GetPermissionBlock ():GetOwner ()
end

function self:GetParentFolder ()
	VFS.Error ("INode:GetParentFolder : Not implemented")
	return nil
end

function self:GetPermissionBlock ()
	VFS.Error ("INode:GetPermissionBlock : Not implemented")
end

function self:GetPath ()
	local path = self:GetName ()
	local parent = self:GetParentFolder ()
	
	while parent do
		if path:len () > 1000 then
			error ("INode:GetPath : Path is too long!")
		end
		if parent:GetName () ~= "" then
			path = parent:GetName () .. "/" .. path
		end
		parent = parent:GetParentFolder ()
	end
	
	return path
end

function self:IsFile ()
	return self:GetNodeType () & VFS.NodeType.File ~= 0
end

function self:IsFolder ()
	return self:GetNodeType () & VFS.NodeType.Folder ~= 0
end

function self:SetDisplayName (displayName)
end

function self:SetOwner (authId, ownerId, callback)
	self:GetPermissionBlock ():SetOwner (authId, ownerId, callback)
end