local self = {}
GCompute.Type = GCompute.MakeConstructor (self)

function self:ctor ()
	self.Inheritable = true
	self.PrimitiveType = false
	self.ScopeType = true
end

function self:GetArrayRank ()
	return 0
end

function self:GetElementType ()
	return nil
end

function self:GetFullName ()
	return "[Type]"
end

function self:HasElementType ()
	return self:GetElementType () ~= nil
end

function self:HasVTable ()
	return self:IsScopeType ()
end

function self:IsArrayType ()
	return false
end

--[[
	Type:IsInheritable ()
		Returns: bool inheritable
		
		Returns whether this type can be inherited from.
]]
function self:IsInheritable ()
	return self:HasVTable () and self.Inheritable
end

--[[
	Type:IsPrimitiveType ()
		Returns: bool primitiveType
		
		Returns whether objects of this type are basic lua types.
]]
function self:IsPrimitiveType ()
	return self.PrimitiveType
end

function self:IsReferenceType ()
	return false
end

--[[
	Type:IsScopeType ()
		Returns: bool scopeType
		
		Returns whether objects of this type are lua Scope objects.
]]
function self:IsScopeType ()
	return self.ScopeType
end

function self:IsTypeReference ()
	return false
end

--[[
	Type:SetInheritable (bool inheritable)
		Returns: Type self
		
		Sets whether this type can be inherited from.
]]
function self:SetInheritable (inheritable)
	self.Inheritable = inheritable
	
	return self
end

--[[
	Type:SetPrimitiveType (bool primitiveType)
		Returns: Type self
		
		Sets whether objects of this type are basic lua types.
]]
function self:SetPrimitiveType (primitiveType)
	self.PrimitiveType = primitiveType
	
	return self
end

--[[
	Type:SetScopeType (bool scopeType)
		Returns: Type self
		
		Sets whether objects of this type are lua Scope objects.
]]
function self:SetScopeType (scopeType)
	self.ScopeType = scopeType
	
	return self
end

self.ToString = self.GetFullName

function self:UnreferenceType ()
	if self:IsReferenceType () then
		return self:GetElementType ()
	end
	return self
end