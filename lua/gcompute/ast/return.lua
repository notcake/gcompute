local Return = {}
Return.__Type = "Return"
GCompute.AST.Return = GCompute.AST.MakeConstructor (Return, GCompute.AST.Control)

function Return:ctor ()
	self.ReturnValue = nil
end

function Return:Evaluate (executionContext)
	if self.ReturnValue then
		executionContext:Return (self.ReturnValue:Evaluate (executionContext))
	else
		executionContext:Return ()
	end
end

function Return:ToString ()
	if self.ReturnValue then
		return "return " .. self.ReturnValue:ToString ()
	end
	return "return"
end