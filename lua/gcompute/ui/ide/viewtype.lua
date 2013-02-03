local self = {}
GCompute.IDE.ViewType = GCompute.MakeConstructor (self)

function self:ctor (typeName)
	self.Name = typeName
	self.DocumentType = nil
	
	self.DisplayName = typeName
	
	self.Constructor = nil
end

function self:Create (...)
	return self.Constructor (...)
end

function self:GetConstructor ()
	return self.Constructor
end

function self:GetDisplayName ()
	return self.DisplayName
end

function self:GetDocumentType ()
	return self.DocumentType
end

function self:GetName ()
	return self.Name
end

function self:SetConstructor (constructor)
	self.Constructor = constructor
	return self
end

function self:SetDisplayName (displayName)
	self.DisplayName = displayName or self:GetName ()
	return self
end

function self:SetDocumentType (documentType)
	self.DocumentType = documentType
	return self
end