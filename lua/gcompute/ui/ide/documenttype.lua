local self = {}
GCompute.IDE.DocumentType = GCompute.MakeConstructor (self)

function self:ctor (typeName)
	self.Name = typeName
	self.ViewType = nil
	
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

function self:GetName ()
	return self.Name
end

function self:GetViewType ()
	return self.ViewType
end

function self:SetConstructor (constructor)
	self.Constructor = constructor
	return self
end

function self:SetDisplayName (displayName)
	self.DisplayName = displayName or self:GetName ()
	return self
end

function self:SetViewType (viewType)
	self.ViewType = viewType
	return self
end