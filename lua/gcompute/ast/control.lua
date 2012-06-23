local self = {}
self.__Type = "Control"
GCompute.AST.Control = GCompute.AST.MakeConstructor (self)

function self:ctor ()
end

function self:Evaluate (executionContext)
	executionContext:Error ("Unknown control statement.")
end

function self:ToString ()
	return "[Unknown Control Statement]"
end