local self = {}
self.__Type = "MemberFunctionCall"
GCompute.AST.MemberFunctionCall = GCompute.AST.MakeConstructor (self, GCompute.AST.Expression)

function self:ctor ()
	self.LeftExpression = nil
	self.Identifier = nil
	
	self.Arguments = {}
	self.ArgumentCount = 0
end

function self:AddArgument (argument)
	self.ArgumentCount = self.ArgumentCount + 1
	self.Arguments [self.ArgumentCount] = argument
	if argument then argument:SetParent (self) end
end

function self:AddArguments (arguments)
	for _, argument in ipairs (arguments) do
		self:AddArgument (argument)
	end
end

function self:ComputeMemoryUsage (memoryUsageReport)
	memoryUsageReport = memoryUsageReport or GCompute.MemoryUsageReport ()
	if memoryUsageReport:IsCounted (self) then return end
	
	memoryUsageReport:CreditTableStructure ("Syntax Trees", self)
	memoryUsageReport:CreditTableStructure ("Syntax Trees", self.Arguments)
	memoryUsageReport:CreditString ("Syntax Trees", self.MemberName)
	
	if self.Identifier then
		self.Identifier:ComputeMemoryUsage (memoryUsageReport)
	end
	if self.LeftExpression then
		self.LeftExpression:ComputeMemoryUsage (memoryUsageReport)
	end
	
	for i = 1, self:GetArgumentCount () do
		if self:GetArgument (i) then
			self:GetArgument (i):ComputeMemoryUsage (memoryUsageReport)
		end
	end
	
	return memoryUsageReport
end

function self:Evaluate (executionContext)
end

function self:ExecuteAsAST (astRunner, state)
	-- State 0: Evaluate left
	-- State 1: Lookup function
	-- State 3+: Evaluate arguments
	-- State 2: Call
	if state == 0 then
		-- Return to state 1
		astRunner:PushState (1)
		
		-- Expression, state 0
		astRunner:PushNode (self:GetLeftExpression ())
		astRunner:PushState (0)
	elseif state == 1 then
		-- Return to state 3
		astRunner:PushState (3)
		
		local functionCallPlan = self.FunctionCallPlan
		if functionCallPlan:GetFunctionDefinition () then
			astRunner:PushValue (functionCallPlan:GetFunctionDefinition ())
		elseif functionCallPlan:GetFunction () then
			astRunner:PushValue (functionCallPlan:GetFunction ())
		else
			GCompute.Error ("FAIL")
		end
	elseif state == 2 then
		-- Discard FunctionCall
		astRunner:PopNode ()
		
		local arguments = {}
		for i = self:GetArgumentCount (), 1, -1 do
			arguments [i] = astRunner:PopValue ()
		end
		local functionDefinition = astRunner:PopValue ()
		local object = astRunner:PopValue ()
		local func = functionDefinition
		if type (functionDefinition) == "table" then
			func = functionDefinition:GetNativeFunction ()
		else
			functionDefinition = nil
		end
		
		if func then
			astRunner:PushValue (func (object, unpack (arguments)))
		elseif functionDefinition then
			local block = functionDefinition:GetFunctionDeclaration ():GetBody ()
			if block then
				astRunner:PushNode (block)
				astRunner:PushState (0)
				astRunner:PushValue (object)
				astRunner:PushValue (arguments)
			else
				ErrorNoHalt ("Failed to run " .. self:ToString () .. " (FunctionDefinition has no native function or AST block node)\n")
			end
		else
			ErrorNoHalt ("Failed to run " .. self:ToString () .. " (no function or FunctionDefinition)\n")
		end
	else
		if state - 2 <= self:GetArgumentCount () then
			astRunner:PushState (state + 1)
			
			-- Expression, state 0
			astRunner:PushNode (self:GetArgument (state - 2))
			astRunner:PushState (0)
		else
			-- No more arguments
			astRunner:PushState (2)
		end
	end
end

function self:GetArgument (index)
	return self.Arguments [index]
end

function self:GetArgumentCount ()
	return self.ArgumentCount
end

function self:GetArgumentTypes (includeLeft)
	if includeLeft == nil then includeLeft = true end
	
	local argumentTypes = {}
	if includeLeft then
		argumentTypes [#argumentTypes + 1] = self.LeftExpression:GetType ()
	end
	for i = 1, self.ArgumentCount do
		argumentTypes [#argumentTypes + 1] = self.Arguments [i]:GetType ()
	end
	return argumentTypes
end

function self:GetLeftExpression ()
	return self.LeftExpression
end

function self:GetIdentifier ()
	return self.Identifier
end

function self:SetArgument (index, expression)
	self.Arguments [index] = expression
	if expression then expression:SetParent (self) end
end

function self:SetLeftExpression (leftExpression)
	self.LeftExpression = leftExpression
	if self.LeftExpression then self.LeftExpression:SetParent (self) end
end

function self:SetIdentifier (identifier)
	self.Identifier = identifier
end

function self:ToString ()
	local leftExpression = self.LeftExpression and self.LeftExpression:ToString () or "[Unknown Expression]"
	local identifier = self.Identifier and self.Identifier:ToString () or "[Unknown Identifier]"
	local arguments = ""
	for i = 1, self.ArgumentCount do
		if arguments ~= "" then
			arguments = arguments .. ", "
		end
		local argument = self.Arguments [i] and self.Arguments [i]:ToString () or "[Unknown Expression]"
		arguments = arguments .. argument
	end
	
	return leftExpression .. ":" .. identifier .. " (" .. arguments .. ")"
end

function self:Visit (astVisitor, ...)
	self:SetLeftExpression (self:GetLeftExpression ():Visit (astVisitor, ...) or self:GetLeftExpression ())
	for i = 1, self:GetArgumentCount () do
		self:SetArgument (i, self:GetArgument (i):Visit (astVisitor, ...) or self:GetArgument (i))
	end
	
	return astVisitor:VisitExpression (self, ...)
end