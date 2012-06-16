local self = {}
GCompute.UsingDirective = GCompute.MakeConstructor (self)

function self:ctor (qualifiedName)
	self.QualifiedName = qualifiedName
	self.NamespaceDefinition = nil
	self.Resolved = false
end

function self:GetNamespace ()
	return self.NamespaceDefinition
end

function self:GetQualifiedName ()
	return self.QualifiedName
end

function self:IsResolved ()
	return self.Resolved
end

function self:SetNamespace (namespaceDefinition)
	self.NamespaceDefinition = namespaceDefinition
	self.Resolved = true
end

function self:SetQualifiedName (qualifiedName)
	self.QualifiedName = qualifiedName
end

function self:ToString ()
	return "using " .. self.QualifiedName .. ";"
end