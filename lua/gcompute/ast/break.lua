local Break = {}
Break.__Type = "Break"
GCompute.AST.Break = GCompute.AST.MakeConstructor (Break, GCompute.AST.Control)

function Break:ctor ()
end

function Break:Evaluate (executionContext)
	executionContext:Break ()
end

function Break:ToString ()
	return "break"
end