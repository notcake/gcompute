local Continue = {}
Continue.__Type = "Continue"
GCompute.AST.Continue = GCompute.AST.MakeConstructor (Continue, GCompute.AST.Control)

function Continue:ctor ()
end

function Continue:Evaluate (executionContext)
	executionContext:Continue ()
end

function Continue:ToString ()
	return "continue"
end