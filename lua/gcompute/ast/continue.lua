local self = {}
self.__Type = "Continue"
GCompute.AST.Continue = GCompute.AST.MakeConstructor (self, GCompute.AST.Control)

function self:ctor ()
end

function self:Evaluate (executionContext)
	executionContext:Continue ()
end

function self:ToString ()
	return "continue"
end