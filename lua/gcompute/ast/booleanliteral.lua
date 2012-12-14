local self = {}
self.__Type = "BooleanLiteral"
GCompute.AST.BooleanLiteral = GCompute.AST.MakeConstructor (self, GCompute.AST.Expression)

function self:ctor (boolean)
	self.Boolean = tobool (boolean)
	
	self.IsConstant = true
	self.IsCached = true
	self.CachedValue = self.Boolean
end

function self:Evaluate ()
	return self.Boolean
end

function self:GetBoolean ()
	return self.Boolean
end

function self:GetChildEnumerator ()
	return GCompute.NullCallback
end

function self:SetBoolean (boolean)
	self.Boolean = boolean
end

function self:ToString ()
	return tostring (self.Boolean)
end