local StringLiteral = {}
StringLiteral.__Type = "StringLiteral"
GCompute.AST.StringLiteral = GCompute.AST.MakeConstructor (StringLiteral, GCompute.AST.Expression)

function StringLiteral:ctor (str)
	self.String = str
	
	self.IsConstant = true
	self.IsCached = true
	self.CachedValue = self.String
end

function StringLiteral:Evaluate (executionContext)
	return self.String
end

function StringLiteral:ToString ()
	return "\"" .. self.String .. "\""
end