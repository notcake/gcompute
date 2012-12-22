local self = {}
GCompute.Module = GCompute.MakeConstructor (self)

function self:ctor ()
	-- Identity
	self.Name = "<anonymous>"
	self.FullName = "<anonymous>"
	self.OwnerId = GLib.GetSystemId ()
	
	-- Dependencies
	self.ReferencedModules   = {}
	self.ReferencedModuleSet = {}
	
	-- Namespace
	self.RootNamespace = nil
end

-- Identity
function self:GetFullName ()
	return self.FullName
end

function self:GetName ()
	return self.Name
end

function self:GetOwnerId ()
	return self.OwnerId
end

function self:SetFullName (fullName)
	self.FullName = fullName
	return self
end

function self:SetName (name)
	self.Name = name
	return self
end

function self:SetOwnerId (ownerId)
	self.OwnerId = ownerId
	return self
end

-- Dependencies
function self:AddReferencedModule (referencedModule)
	if self.ReferencedModuleSet [referencedModule] then return end
	
	self.ReferencedModuleSet [referencedModule] = true
	self.ReferencedModules [#self.ReferencedModules + 1] = referencedModule
end

function self:GetReferencedModule (index)
	return self.ReferencedModules [index]
end

function self:GetReferencedModuleCount ()
	return #self.ReferencedModules
end

function self:GetReferencedModuleEnumerator ()
	local i = 0
	return function ()
		i = i + 1
		return self.ReferencedModules [i]
	end
end

-- Namespace
function self:GetRootNamespace ()
	return self.RootNamespace
end

function self:SetRootNamespace (rootNamespace)
	self.RootNamespace = rootNamespace
	self.RootNamespace:SetModule (self)
end

function self:ToString ()
	local module = "[Module " .. self:GetFullName () .. " (" .. (self:GetOwnerId () or "Nobody") .. ")]"
	for referencedModule in self:GetReferencedModuleEnumerator () do
		module = module .. "\n    References " .. referencedModule:GetFullName () .. " (" .. (referencedModule:GetOwnerId () or "Nobody") .. ")"
	end
	return module
end