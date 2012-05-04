local self = {}
GCompute.ReferenceType = GCompute.MakeConstructor (self, GCompute.Type)

function self:ctor (baseType)
	self.ResolutionScope = nil
	
	self.ElementType = GCompute.TypeReference (baseType)
end

function self:GetArgumentCount ()
	return 0
end

function self:GetElementType ()
	return self.ElementType
end

function self:GetFullName ()
	return self.ElementType:GetFullName () .. " &"
end

function self:GetResolutionScope ()
	return self.ResolutionScope
end

function self:IsReferenceType ()
	return true
end

function self:SetResolutionScope (resolutionScope)
	if self.ResolutionScope and self.ResolutionScope ~= resolutionScope then GCompute.Error ("Resolution scope already set!") end

	self.ResolutionScope = resolutionScope
	self.ElementType:SetResolutionScope (resolutionScope)
end

self.ToDefinitionString = self.GetFullName
self.ToString = self.GetFullName