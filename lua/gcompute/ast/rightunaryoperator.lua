local self = {}
self.__Type = "RightUnaryOperator"
GCompute.AST.RightUnaryOperator = GCompute.AST.MakeConstructor (self, GCompute.AST.Expression)

local EvaluationFunctions =
{
	["default"] = function (self, executionContext, value) return value end,
	["++"] = function (self, executionContext, value) return value + 1 end,
	["--"] = function (self, executionContext, value) return value - 1 end
}

function self:ctor ()
	self.LeftExpression = nil
	
	self.Operator = "[Unknown Operator]"
	self.Precedence = 0
	
	self.EvaluationFunction = EvaluationFunctions.default
end

function self:ComputeMemoryUsage (memoryUsageReport)
	memoryUsageReport = memoryUsageReport or GCompute.MemoryUsageReport ()
	if memoryUsageReport:IsCounted (self) then return end
	
	memoryUsageReport:CreditTableStructure ("Syntax Trees", self)
	
	if self.LeftExpression then
		self.LeftExpression:ComputeMemoryUsage (memoryUsageReport)
	end
	
	memoryUsageReport:CreditString ("Syntax Trees", self.Operator)
	
	return memoryUsageReport
end

function self:Evaluate (executionContext)
	local value, reference = self.LeftExpression:Evaluate (executionContext)
	
	value = self:EvaluationFunction (executionContext, value, reference)
	reference:SetValue (value)
	
	return value
end

function self:ExecuteAsAST (astRunner, state)
	-- State 0: Evaluate left
	-- State 1: Call
	if state == 0 then
		-- Return to state 1
		astRunner:PushState (1)
	
		-- Expression, state 0
		astRunner:PushNode (self:GetLeftExpression ())
		astRunner:PushState (0)
	elseif state == 2 then
		-- Discard BinaryOperator
		astRunner:PopNode ()
		
		local left = astRunner:PopValue ()
		
		local functionCallPlan = self.FunctionCallPlan
		local functionDefinition = functionCallPlan:GetFunctionDefinition ()
		local func = functionCallPlan:GetFunction ()
		if not func and functionDefinition then
			func = functionDefinition:GetNativeFunction ()
		end
		
		if func then
			astRunner:PushValue (func (left))
		elseif functionDefinition then
			local block = functionDefinition:GetBlock ()
			if block then
				astRunner:PushNode (functionDefinition:GetBlock ())
				astRunner:PushState (0)
			else
				ErrorNoHalt ("Failed to run " .. self:ToString () .. " (FunctionDefinition has no native function or AST block node)\n")
			end
		else
			ErrorNoHalt ("Failed to run " .. self:ToString () .. " (no function or FunctionDefinition)\n")
		end
	end
end

function self:GetChildEnumerator ()
	local i = 0
	return function ()
		i = i + 1
		if i == 1 then
			return self.LeftExpression
		end
		return nil
	end
end

function self:GetLeftExpression ()
	return self.LeftExpression
end

function self:GetOperator ()
	return self.Operator
end

function self:SetLeftExpression (leftExpression)
	self.LeftExpression = leftExpression
	if self.LeftExpression then self.LeftExpression:SetParent (self) end
end

function self:SetOperator (operator)
	self.Operator = operator
	
	self.EvaluationFunction = EvaluationFunctions [operator] or EvaluationFunctions.default
end

function self:ToString ()
	local leftExpression = self.LeftExpression and self.LeftExpression:ToString () or "[Unknown Expression]"
	
	return leftExpression .. self.Operator
end

function self:Visit (astVisitor, ...)
	self:SetLeftExpression (self:GetLeftExpression ():Visit (astVisitor, ...) or self:GetLeftExpression ())
	
	return astVisitor:VisitExpression (self, ...)
end