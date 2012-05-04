local Control = {}
Control.__Type = "Control"
GCompute.AST.Control = GCompute.AST.MakeConstructor (Control)

function Control:ctor ()
end

function Control:Evaluate (executionContext)
	executionContext:Error ("Unknown control statement.")
end

function Control:ToString ()
	return "[unknown control statement]"
end