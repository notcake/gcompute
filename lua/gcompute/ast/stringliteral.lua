local self = {}
self.__Type = "StringLiteral"
GCompute.AST.StringLiteral = GCompute.AST.MakeConstructor (self, GCompute.AST.Expression)

function self:ctor (str)
	self.String = str
	
	self.IsConstant = true
	self.IsCached = true
	self.CachedValue = self.String
end

function self:Evaluate (executionContext)
	return self.String
end

function self:ToString ()
	return "\"" .. GCompute.String.Escape (self.String) .. "\""
end