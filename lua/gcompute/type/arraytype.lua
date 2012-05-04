local self = {}
GCompute.ArrayType = GCompute.MakeConstructor (self, GCompute.Type)

function self:ctor (elementType, arrayRank)
	self.ResolutionScope = nil
	
	self.ElementType = GCompute.TypeReference (elementType)
	self.Rank = arrayRank or 1
end

function self:GetArgumentCount ()
	return 0
end

function self:GetElementType ()
	return self.ElementType
end

function self:GetFullName ()
	return self.ElementType:GetFullName () .. " [" .. string.rep (",", self:GetArrayRank () - 1) .. "]"
end

function self:GetResolutionScope ()
	return self.ResolutionScope
end

function self:GetArrayRank ()
	return self.Rank
end

function self:IsScopeType ()
	return false
end

function self:SetResolutionScope (resolutionScope)
	if self.ResolutionScope and self.ResolutionScope ~= resolutionScope then GCompute.Error ("Resolution scope already set!") end

	self.ResolutionScope = resolutionScope
	self.ElementType:SetResolutionScope (resolutionScope)
end

self.ToDefinitionString = self.GetFullName
self.ToString = self.GetFullName