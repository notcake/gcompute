local ForLoop = {}
ForLoop.__Type = "ForLoop"
GCompute.AST.ForLoop = GCompute.AST.MakeConstructor (ForLoop)

function ForLoop:ctor ()
	self.Initializer = nil
	self.Condition = nil
	self.PostLoop = nil
	
	self.Scope = GCompute.Scope ()
	self.Loop = nil
end

function ForLoop:Evaluate (executionContext)
	local pushedScope = false
	if self.Scope:HasVariables () then
		pushedScope = true
		executionContext:PushBlockScope (self.Scope)
	end
	
	if self.Initializer:Is ("VariableDeclaration") then	
		local value = nil
		if self.Initializer.Value then
			value = self.Initializer.Value:Evaluate (executionContext)
			if not value then
				executionContext:Error (self.Initializer.Value:ToString () .. " is nil in " .. self.Initializer:ToString () .. ".")
			end
		end
		executionContext.ScopeLookup.TopScope:SetMember (self.Initializer.Name, value)
	else
		self.Initializer:Evaluate (executionContext)
	end
	
	while self.Condition:Evaluate (executionContext) do
		self.Loop:Evaluate (executionContext)

		if executionContext.InterruptFlag then
			if executionContext.BreakFlag then
				executionContext:ClearBreak ()
				break
			elseif executionContext.ContinueFlag then
				executionContext:ClearContinue ()
			else
				break
			end
		end
		self.PostLoop:Evaluate (executionContext)
	end
	
	if pushedScope then
		executionContext:PopScope ()
	end
end

function ForLoop:ToString ()
	local Initializer = self.Initializer and self.Initializer:ToString () or "[unknown]"
	local Condition = self.Condition and self.Condition:ToString () or "[unknown]"
	local PostLoop = self.PostLoop and self.PostLoop:ToString () or "[unknown]"
	
	local Loop = "    [unknown]"
	
	if self.Loop then
		if self.Loop:Is ("Block") then
			Loop = self.Loop:ToString ()
		else
			Loop = "    " .. self.Loop:ToString ():gsub ("\n", "\n    ")
		end
	end
	return "for (" .. Initializer .. "; " .. Condition .. "; " .. PostLoop .. ")\n" .. Loop
end