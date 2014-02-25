local self = {}
GCompute.IDE.ViewType = GCompute.MakeConstructor (self)

function self:ctor (typeName)
	self.Name = typeName
	self.DocumentType = nil
	
	self.DisplayName = typeName
	
	self.AutoCreate = false
	self.AutoCreationCount = 1
	
	self.DefaultLocation = "Bottom"
	
	self.Constructor = nil
end

function self:Create (...)
	local _, view = xpcall (self.Constructor, GLib.Error, ...)
	return view
end

function self:GetAutoCreationCount ()
	return self.AutoCreationCount
end

function self:GetConstructor ()
	return self.Constructor
end

function self:GetDefaultLocation ()
	return self.DefaultLocation
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

function self:SetAutoCreate (autoCreate)
	self.AutoCreate = autoCreate
	return self
end

function self:SetAutoCreationCount (autoCreationCount)
	self.AutoCreationCount = autoCreationCount
	return self
end

function self:SetConstructor (constructor)
	self.Constructor = constructor
	return self
end

function self:SetDefaultLocation (defaultLocation)
	self.DefaultLocation = defaultLocation
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

function self:ShouldAutoCreate ()
	return self.AutoCreate
end