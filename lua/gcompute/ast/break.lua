local self = {}
self.__Type = "Break"
GCompute.AST.Break = GCompute.AST.MakeConstructor (self, GCompute.AST.Control)

function self:ctor ()
end

function self:Evaluate (executionContext)
	executionContext:Break ()
end

function self:ToString ()
	return "break"
end