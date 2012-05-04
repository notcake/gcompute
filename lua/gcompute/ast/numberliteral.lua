local NumberLiteral = {}
NumberLiteral.__Type = "NumberLiteral"
GCompute.AST.NumberLiteral = GCompute.AST.MakeConstructor (NumberLiteral, GCompute.AST.Expression)

function NumberLiteral:ctor (num)
	self.Number = tonumber (num)
	
	self.IsConstant = true
	self.IsCached = true
	self.CachedValue = self.Number
end

function NumberLiteral:Evaluate ()
	return self.Number
end

function NumberLiteral:ToString ()
	return tostring (self.Number)
end