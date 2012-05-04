local self = {}
self.__Type = "Type"
GCompute.AST.Type = GCompute.AST.MakeConstructor (self)

function self:ctor ()
	self.TypeExpression = nil

	self.ResolvedType = nil
end

function self:GetResolvedType ()
	return self.ResolvedType
end

function self:GetTypeExpression ()
	return self.TypeExpression
end

function self:SetResolvedType (resolvedType)
	self.ResolvedType = resolvedType
end

function self:ToString ()
	return self.TypeExpression and self.TypeExpression:ToString () or "[Unknown Type]"
end