local self = {}
self.__Type = "MemberFunctionCall"
GCompute.AST.MemberFunctionCall = GCompute.AST.MakeConstructor (self, GCompute.AST.Expression)

function self:ctor ()
	self.LeftExpression = nil
	self.Identifier = nil
	
	self.ArgumentList = GCompute.AST.ArgumentList ()
end

function self:ComputeMemoryUsage (memoryUsageReport)
	memoryUsageReport = memoryUsageReport or GCompute.MemoryUsageReport ()
	if memoryUsageReport:IsCounted (self) then return end
	
	memoryUsageReport:CreditTableStructure ("Syntax Trees", self)
	memoryUsageReport:CreditString ("Syntax Trees", self.Identifier)
	
	if self.Identifier then
		self.Identifier:ComputeMemoryUsage (memoryUsageReport)
	end
	if self.LeftExpression then
		self.LeftExpression:ComputeMemoryUsage (memoryUsageReport)
	end
	if self.ArgumentList then
		self.ArgumentList:ComputeMemoryUsage (memoryUsageReport)
	end
	
	return memoryUsageReport
end

function self:Evaluate (executionContext)
end

function self:ExecuteAsAST (astRunner, state)
	-- State 0: Evaluate left
	-- State 1: Lookup function
	-- State 2: Evaluate arguments
	-- State 3: Call
	if state == 0 then
		-- Return to state 1
		astRunner:PushState (1)
		
		-- Expression, state 0
		astRunner:PushNode (self:GetLeftExpression ())
		astRunner:PushState (0)
	elseif state == 1 then
		-- Return to state 2
		astRunner:PushState (2)
		
		local functionCallPlan = self.FunctionCallPlan
		if functionCallPlan:GetFunctionDefinition () then
			astRunner:PushValue (functionCallPlan:GetFunctionDefinition ())
		elseif functionCallPlan:GetFunction () then
			astRunner:PushValue (functionCallPlan:GetFunction ())
		else
			GCompute.Error ("FAIL")
		end
	elseif state == 2 then
		-- Return to state 3
		astRunner:PushState (3)
		
		-- ArgumentList, state 0
		astRunner:PushNode (self:GetArgumentList ())
		astRunner:PushState (0)
	elseif state == 3 then
		-- Discard FunctionCall
		astRunner:PopNode ()
		
		local arguments = {}
		for i = self:GetArgumentList ():GetArgumentCount (), 1, -1 do
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
	end
end

function self:GetArgumentTypes (includeLeft)
	if includeLeft == nil then includeLeft = true end
	local argumentTypes = self.ArgumentList:GetArgumentTypes ()
	
	if includeLeft then
		table.insert (argumentTypes, 1, self.LeftExpression:GetType ())
	end
	return argumentTypes
end

function self:GetChildEnumerator ()
	local i = 0
	return function ()
		i = i + 1
		if i == 1 then
			return self.LeftExpression
		elseif i == 2 then
			return self.ArgumentList
		end
		return nil
	end
end

function self:GetLeftExpression ()
	return self.LeftExpression
end

function self:GetIdentifier ()
	return self.Identifier
end

function self:SetArgumentList (argumentList)
	self.ArgumentList = argumentList
	if self.ArgumentList then self.ArgumentList:SetParent (self) end
end

function self:SetLeftExpression (leftExpression)
	self.LeftExpression = leftExpression
	if self.LeftExpression then self.LeftExpression:SetParent (self) end
end

function self:SetIdentifier (identifier)
	self.Identifier = identifier
end

function self:ToString ()
	local leftExpression = self.LeftExpression and self.LeftExpression:ToString () or "[Nothing]"
	local identifier = self.Identifier and self.Identifier:ToString () or "[Nothing]"
	local argumentList = self.ArgumentList and self.ArgumentList:ToString () or "([Nothing])"
	
	return leftExpression .. ":" .. identifier .. " " .. argumentList
end

function self:Visit (astVisitor, ...)
	self:SetLeftExpression (self:GetLeftExpression ():Visit (astVisitor, ...) or self:GetLeftExpression ())
	self:SetArgumentList (self:GetArgumentList ():Visit (astVisitor, ...) or self:GetArgumentList ())
	
	return astVisitor:VisitExpression (self, ...)
end