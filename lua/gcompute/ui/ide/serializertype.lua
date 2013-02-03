local self = {}
GCompute.IDE.SerializerType = GCompute.MakeConstructor (self)

function self:ctor (typeName)
	self.Name = typeName
	self.DocumentType = nil
	
	self.DisplayName = typeName
	
	self.Constructor = nil
	
	-- Serializer info
	self.IsDeserializer = false
	self.IsSerializer   = false
	self.Extensions = {}
end

function self:AddExtension (extension)
	self.Extensions [string.lower (extension)] = true
end

function self:CanDeserialize ()
	return self.IsDeserializer
end

function self:CanHandleExtension (extension)
	return self.Extensions [string.lower (extension)] or false
end

function self:CanSerialize ()
	return self.IsSerializer
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

function self:SetCanDeserialize (canDeserialize)
	self.IsDeserializer = canDeserialize
end

function self:SetCanSerialize (canSerialize)
	self.IsSerializer = canSerialize
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