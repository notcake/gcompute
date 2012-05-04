local UnknownExpression = {}
UnknownExpression.__Type = "UnknownExpression"
GCompute.AST.UnknownExpression = GCompute.AST.MakeConstructor (UnknownExpression, GCompute.AST.Expression)

function UnknownExpression:ctor ()
end

function UnknownExpression:ToString ()
	return "[unknown expression]"
end