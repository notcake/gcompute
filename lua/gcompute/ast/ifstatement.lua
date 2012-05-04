local IfStatement = {}
IfStatement.__Type = "IfStatement"
GCompute.AST.IfStatement = GCompute.AST.MakeConstructor (IfStatement)

function IfStatement:ctor ()
	self.Condition = nil
	self.Statement = nil
	self.Else = nil
end

function IfStatement:Evaluate (executionContext)
	if self.Condition:Evaluate (executionContext) then
		self.Statement:Evaluate (executionContext)
	elseif self.Else then
		self.Else:Evaluate (executionContext)
	end
end

function IfStatement:ToString ()
	local Condition = self.Condition and self.Condition:ToString () or "[unknown expression]"
	local Statement = " {}"
	
	if self.Statement then
		Statement = self.Statement:ToString ()
		if not self.Statement:Is ("Block") then
			Statement = "    " .. Statement:gsub ("\n", "\n    ")
		end
		Statement = "\n" .. Statement
	end
	
	if self.Else then
		local Else = self.Else:ToString ()
		if not self.Else:Is ("Block") then
			Else = "    " .. Else:gsub ("\n", "\n    ")
		end
		Else = "\n" .. Else
		return "if (" .. Condition .. ")" .. Statement .. "\nelse " .. Else
	else
		return "if (" .. Condition .. ")" .. Statement
	end
end