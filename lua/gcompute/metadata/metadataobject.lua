local self = {}
GCompute.MetadataObject = GCompute.MakeConstructor (self)

--- @param name The name of this object
function self:ctor (name)
	self.Name = name
	self.ContainingNamespace = nil
end

--- Gets the namespace definition containing this object
-- @return The NamespaceDefinition containing this object
function self:GetContainingNamespace ()
	return self.ContainingNamespace
end

--- Gets the name of this object
-- @return The name of this object
function self:GetName ()
	return self.Name
end

--- Sets the containing namespace definition of this object
-- @param containingNamespaceDefinition The NamespaceDefinition containing this object
function self:SetContainingNamespace (containingNamespaceDefinition)
	self.ContainingNamespace = containingNamespaceDefinition
end